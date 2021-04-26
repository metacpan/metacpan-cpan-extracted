#!/usr/bin/perl -w
#
# Copyright (C) 2002-2021 National Marrow Donor Program. All rights reserved.
#
# For a description of this module, please refer to the POD documentation
# embedded at the bottom of the file (e.g. perldoc EMDIS::ECS).

package EMDIS::ECS;

use CPAN::Version;
use Fcntl qw(:DEFAULT :flock);
use File::Basename;
use File::Copy;
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempfile);
use IO::File;
use IO::Handle;
use IPC::Open2;
use Net::SMTP;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
            $ECS_CFG $ECS_NODE_TBL $FILEMODE @LOG_LEVEL
            $configured $pidfile $cmd_output $pid_saved);

# load OS specific modules at compile time, in BEGIN block
BEGIN
{
    if( $^O =~ /MSWin32/ )
    {
        # Win32 only modules
        eval "require Win32::Process";
    }
}

# module/package version
$VERSION = '0.43';

# file creation mode (octal, a la chmod)
$FILEMODE = 0660;

# subclass Exporter and define Exporter set up
require Exporter;
@ISA = qw(Exporter);
@EXPORT = ();      # items exported by default
@EXPORT_OK = ();   # items exported by request
%EXPORT_TAGS = (   # tags for groups of items
    ALL => [ qw($ECS_CFG $ECS_NODE_TBL $FILEMODE $VERSION
       load_ecs_config delete_old_files dequote ecs_is_configured
       log log_debug log_info log_warn log_error log_fatal
       copy_to_dir move_to_dir read_ecs_message_id
       send_admin_email send_amqp_message send_ecs_message
       send_email send_encrypted_message format_datetime
       format_doc_filename
       format_msg_filename openpgp_decrypt openpgp_encrypt
       pgp2_decrypt pgp2_encrypt check_pid save_pid
       timelimit_cmd remove_pidfile trim valid_encr_typ EOL
       is_yes is_no) ] );
Exporter::export_ok_tags('ALL');   # use tag handling fn to define EXPORT_OK

BEGIN {
    $configured = '';  # boolean indicates whether ECS has been configured
    @LOG_LEVEL = ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'FATAL');
    $pid_saved = '';
}

# ----------------------------------------------------------------------
# Return platform specific end-of-line string
sub EOL
{
    return "\r\n" if $^O =~ /MSWin32/;
    return "\n";
}

# ----------------------------------------------------------------------
# test for YES or TRUE
sub is_yes
{
    my $val = shift;
    return 0 if not defined $val;
    return 1 if $val =~ /^\s*YES\s*$/io or $val =~ /^\s*TRUE\s*$/io;
    return 0;
}

# ----------------------------------------------------------------------
# test for NO or FALSE
sub is_no
{
    my $val = shift;
    return 0 if not defined $val;
    return 1 if $val =~ /^\s*NO\s*$/io or $val =~ /^\s*FALSE\s*$/io;
    return 0;
}

# ----------------------------------------------------------------------
# Load ECS configuration into global variables.
# returns empty string if successful or error message if error encountered
sub load_ecs_config
{
    my $cfg_file = shift;

    require EMDIS::ECS::Config;
    my $cfg = new EMDIS::ECS::Config($cfg_file);
    return "Unable to load ECS configuration ($cfg_file): $cfg"
        unless ref $cfg;

    require EMDIS::ECS::LockedHash;
    my $node_tbl = new EMDIS::ECS::LockedHash($cfg->NODE_TBL, $cfg->NODE_TBL_LCK);
    return "Unable to open ECS node_tbl (" . $cfg->NODE_TBL .
        "): $node_tbl"
            unless ref $node_tbl;

    $pidfile = catfile($cfg->ECS_DAT_DIR, basename($0) . ".pid");

    # assign values to global config variables
    $ECS_CFG = $cfg;
    $ECS_NODE_TBL = $node_tbl;
    $configured = 1;

    # successful
    return '';
}

# ----------------------------------------------------------------------
# delete old files (mtime < cutoff time) from specified directory
# no recursion
sub delete_old_files
{
    my $dirname = shift;
    my $cutoff_time = shift;

    if(! -d $dirname)
    {
        warn "Not a directory name: $dirname";
        return;
    }
    if($cutoff_time !~ /^\d+$/)
    {
        warn "Cutoff time not numeric: $cutoff_time";
        return;
    }
    opendir DELDIR, $dirname;
    my @names = readdir DELDIR;
    closedir DELDIR;
    foreach my $name (@names)
    {
        my $filename = catfile($dirname, $name);
        next unless -f $filename;
        # delete file if mtime < $cutoff_time
        my @stat = stat $filename;
        if($stat[9] < $cutoff_time)
        {
            unlink $filename
                or warn "Unable to delete file: $filename";
        }
    }
}

# ----------------------------------------------------------------------
# Return string value with enclosing single or double quotes removed.
sub dequote {
    my $str = shift;
    return if not defined $str;
    if($str =~ /^"(.*)"$/) {
        $str = $1;
    }
    elsif($str =~ /^'(.*)'$/) {
        $str = $1;
    }
    return $str;
}

# ----------------------------------------------------------------------
# Return boolean indicating whether ECS has been configured.
sub ecs_is_configured {
    return $configured;
}

# ----------------------------------------------------------------------
# Write message to ECS log file.  Takes two arguments: a level which is
# used to classify logged messages and the text to be logged.
# Push an aditional email to admin if the error is encountering 
# the MAIL_LEVEL.
# Returns empty string if successful or error message if error encountered.
sub log {
    if(not ecs_is_configured()) {
        my $warning = "EMDIS::ECS::log(): ECS has not been configured.";
        warn "$warning\n";
        return $warning;
    }
    my $cfg = $ECS_CFG;
    my $level = shift;
    $level = '1' if (not defined $level) or
        ($level < 0) or ($level > $#LOG_LEVEL);
    return if $level < $cfg->LOG_LEVEL && ! $cfg->ECS_DEBUG; # check log-level
    my $text = join("\n  ", @_);
    $text = '' if not defined $text;
    my $timestamp = localtime;
    my $origin = $0;

    my $setmode = not -e $cfg->LOG_FILE;
    open LOG, ">>" . $cfg->LOG_FILE or do {
        warn "Error within ECS library: $! " . $cfg->LOG_FILE;
        return;
    };
    print LOG join("|",$timestamp,$origin,$LOG_LEVEL[$level],$text),"\n";
    close LOG;
    chmod $FILEMODE, $cfg->LOG_FILE if $setmode;
    if ( $level >= $cfg->MAIL_LEVEL )
    {
      send_admin_email (join("|",$timestamp,$origin,$LOG_LEVEL[$level],$text));
    }
    return '';
}
# logging subroutines for specific logging levels
sub log_debug { return &log(0, @_); }
sub log_info  { return &log(1, @_); }
sub log_warn  { return &log(2, @_); }
sub log_error { return &log(3, @_); }
sub log_fatal { return &log(4, @_); }

# ----------------------------------------------------------------------
# Copy file to specified directory. If necessary, rename file to avoid
# filename collision.
# Returns empty string if successful or error message if error encountered.
sub copy_to_dir {
    my $filename = shift;
    my $targetdir = shift;
    my $err;

    return "file not found: $filename" unless -f $filename;
    return "directory not found: $targetdir" unless -d $targetdir;

    # do some fancy footwork to avoid name collision in target dir,
    # then copy file
    my $basename = basename($filename);
    my $template = $basename;
    my $suffix = '';
    if($basename =~ /^(\d{8}_\d{6}_(.+_)?).{4}(\..{3})$/) {
        $template = "$1XXXX";
        $suffix = $3;
    }
    else {
        $template .= '_XXXX';
    }
    my ($fh, $tempfilename) = tempfile($template,
                                       DIR    => $targetdir,
                                       SUFFIX => $suffix);
    return "unable to open tempfile in directory $targetdir: $!"
        unless $fh;
    $err = "unable to copy $filename to $tempfilename: $!"
        unless copy($filename, $fh);
    close $fh;
    chmod $FILEMODE, $tempfilename;
    return $err;
}

# ----------------------------------------------------------------------
# Move file to specified directory. If necessary, rename file to avoid
# filename collision.
# Returns empty string if successful or error message if error encountered.
sub move_to_dir {
    my $filename = shift;
    my $targetdir = shift;

    my $err = copy_to_dir($filename, $targetdir);
    unlink $filename unless $err;
    return $err;
}

# ----------------------------------------------------------------------
# Read ECS message id from specified file.  File is presumed to be in the
# format of an email message;  message id is comprised of node_id and seq_num,
# with optional $part_num and $num_parts or DOC suffix.
# Returns empty array if unable to retrieve ECS message id from file.
sub read_ecs_message_id
{
    my $filename = shift;

    return "EMDIS::ECS::read_ecs_message_id(): ECS has not been configured."
        unless ecs_is_configured();
    my $mail_mrk = $ECS_CFG->MAIL_MRK;

    my $fh = new IO::File;
    return () unless $fh->open("< $filename");
    while(<$fh>) {
        /^Subject:.*$mail_mrk:(\S+?):(\d+):(\d+)\/(\d+)\s*$/io and do {
            return ($1,$2,$3,$4,0);
        };
        /^Subject:.*$mail_mrk:(\S+?):(\d+)\s*$/io and do {
            return ($1,$2,1,1,0);
        };
        /^Subject:.*$mail_mrk:(\S+?):(\d+):DOC\s*$/io and do {
            return ($1,$2,1,1,1);
        };
        /^Subject:.*$mail_mrk:(\S+)\s*$/io and do {
            return ($1,undef,undef,undef,0);
        };
        /^$/ and last;  # blank line marks end of mail headers
    }
    close $fh;
    return ();  # return empty array
}

# ----------------------------------------------------------------------
# Send email to administrator and also archive the email message in the
# mboxes/out directory.  Takes one or more arguments:  the body lines to
# be emailed.
# Returns empty string if successful or error message if error encountered.
# Also logs error if error encountered.
sub send_admin_email {

    my $err = '';
    $err = "EMDIS::ECS::send_admin_email(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    # record message contents in 'out' file
    if(not $err) {
        my $template = format_datetime(time, '%04d%02d%02d_%02d%02d%02d_XXXX');
        my ($fh, $filename) = tempfile($template,
                                       DIR    => $cfg->ECS_MBX_OUT_DIR,
                                       SUFFIX => '.msg');
        $err = "EMDIS::ECS::send_admin_email(): unable to create 'out' file"
            unless $fh;
        if($fh) {
            print $fh @_;
            close $fh;
            chmod $FILEMODE, $filename;
        }
    }

    if(not $err)
    {
        my @recipients = split /,/, $cfg->ADM_ADDR;
        foreach my $recipient (@recipients)
        {
            $err = send_email($recipient, '[' . $cfg->MAIL_MRK . '] ECS Error',
                undef, "Origin: $0\n", @_);

            log_error("Unable to send admin email to $recipient: $err")
                if $err and $_[$#_] !~ /Unable to send admin email/iso;
        }
    }

    return $err;
}

# ----------------------------------------------------------------------
# Send ECS email message.
# Returns empty string if successful or error message if error encountered.
sub send_ecs_message {
    my $node_id = shift;
    my $seq_num = shift;
    # @_ now contains message body

    # initialize
    return "EMDIS::ECS::send_ecs_message(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;
    my $node_tbl = $ECS_NODE_TBL;
    my $err = '';

    # do some validation
    my ($hub_rcv, $hub_snd);
    if($seq_num && !$node_id) {
        # parse FML to determing $node_id:
        # do some cursory validation, extract HUB_RCV and HUB_SND
        my $fml = join('', @_);
        return "EMDIS::ECS::send_ecs_message(): message does not contain valid FML"
                unless $fml =~ /^.+:.+;/s;
        if($fml =~ /HUB_RCV\s*=\s*([^,;]+)/is) {  # presumes [^,;] in HUB_RCV
            $hub_rcv = dequote(trim($1));
        }
        else {
            return "EMDIS::ECS::send_ecs_message(): message does not specify " .
                "HUB_RCV";
        }
        if($fml =~ /HUB_SND\s*=\s*([^,;]+)/is) {  # presumes [^,;] in HUB_SND
            $hub_snd = dequote(trim($1));
        }
        else {
            return "EMDIS::ECS::send_ecs_message(): message does not specify " .
                "HUB_SND";
        }
        return "EMDIS::ECS::send_ecs_message(): HUB_SND is incorrect: $hub_snd"
            unless $hub_snd eq $ECS_CFG->THIS_NODE;
        $node_id = $hub_rcv unless $node_id;
        return "EMDIS::ECS::send_ecs_message(): node_id ($node_id) and FML " .
            "HUB_RCV ($hub_rcv) do not match"
            unless $node_id eq $hub_rcv;
    }

    # look up specified node in node_tbl
    my $was_locked = $node_tbl->LOCK;
    if(not $was_locked) {
        $node_tbl->lock()     # lock node_tbl if needed
            or return "EMDIS::ECS::send_ecs_message(): unable to lock node_tbl: " .
                $node_tbl->ERROR;
    }
    my $node = $node_tbl->read($node_id);
    if(not $node) {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "EMDIS::ECS::send_ecs_message(): node not found: " . $node_id;
    }
    if(not $node->{addr}) {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "EMDIS::ECS::send_ecs_message(): addr not defined for node: $node_id";
    }
    if($seq_num =~ /auto/i) {
        # automatically get next sequence number
        $node->{out_seq}++;
        $seq_num = $node->{out_seq};
    }

    my $subject = $cfg->MAIL_MRK . ':' . $cfg->THIS_NODE;
    $subject .= ":$seq_num" if $seq_num;

    my $filename;

    # if not meta-message, copy to mboxes/out_NODE subdirectory
    if($seq_num) {
        $filename = format_msg_filename($node_id,$seq_num);
        # create directory if it doesn't already exist
        my $dirname = dirname($filename);
        mkdir $dirname unless -e $dirname;
     }
     else { 
        # if meta-message, copy to mboxes/out subdirectory
        $filename = sprintf("%s_%s_%s.msg",
                       $cfg->THIS_NODE, $node_id, "META");
        my $dirname = $cfg->ECS_MBX_OUT_DIR; 
        # create directory if it doesn't already exist
        mkdir $dirname unless -e $dirname;
        $filename = catfile($dirname, $filename);
     }

     # don't overwrite $filename file if it already exists
     my $fh;
     if(-e $filename) {
         my $template = $filename . "_XXXX";
         ($fh, $filename) = tempfile($template);
         return "EMDIS::ECS::send_ecs_message(): unable to open _XXXX file: " .
             "$filename"
                 unless $fh;
     }
     else {
         $fh = new IO::File;
         return "EMDIS::ECS::send_ecs_message(): unable to open file: " .
             "$filename"
                 unless $fh->open("> $filename");
     }

     $fh->print("Subject: $subject\n");
     $fh->print("To: $node->{addr}\n");
     $fh->print("From: " . $cfg->SMTP_FROM . "\n\n");
     $fh->print(@_);
     $fh->close();
     chmod $FILEMODE, $filename;

    if ( $err ) {
        $err = "EMDIS::ECS::send_ecs_message(): unable to update node $node_id: $err";
    }
    elsif ( not $seq_num and ($node->{encr_meta} !~ /true/i) ) {
        # if indicated, don't encrypt meta-message
        if(is_yes($cfg->ENABLE_AMQP) and exists $node->{amqp_addr_meta} and $node->{amqp_addr_meta}) {
            # send meta-message via AMQP (if indicated by node config)
            $err = send_amqp_message(
                $node->{amqp_addr_meta},
                $subject,
                $node,
                undef,
                @_);
        }
        elsif(is_yes($node->{amqp_only})) {
            $err = "EMDIS::ECS::send_ecs_message(): unable to send " .
                "email META message to node " . $node->{node} .
                ": amqp_only selected.";
        }
        else {
            $err = send_email($node->{addr}, $subject, undef, @_);
        }
    }
    else {
        # otherwise, send encrypted message
        $err = send_encrypted_message(
            $node->{encr_typ},
            $node->{addr_r},
            $node->{addr},
            $node->{encr_out_keyid},
            $node->{encr_out_passphrase},
            $node,
            $subject,
            undef,
            @_);
    }

    if ( ! $err ) {
        # update node last_out, possibly out_seq
        $node->{last_out} = time();
        $err = $node_tbl->ERROR
            unless $node_tbl->write($node_id, $node);
    }
    $node_tbl->unlock()  # unlock node_tbl
        unless $was_locked;

    return $err;
}

# ----------------------------------------------------------------------
# Send email message.  Takes four or more arguments: the recipient,
# subject line, custom headers (hash ref), and body lines to be emailed.
# Returns empty string if successful or error message if error encountered.
sub send_email {
    my $recipient = shift;
    my $subject = shift;
    my $custom_headers = shift;
    # @_ now contains message body

    return "EMDIS::ECS::send_email(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    return "EMDIS::ECS::send_email(): custom_headers must be undef or HASH ref (found " .
        ref($custom_headers) . ")"
        if defined $custom_headers and not 'HASH' eq ref $custom_headers;

    my $smtp;
    if(is_yes($cfg->SMTP_USE_SSL) or is_yes($cfg->SMTP_USE_STARTTLS)) {
        return "To use SSL or TLS please install Net::SMTP with version >= 3.05"
            if CPAN::Version->vlt($Net::SMTP::VERSION, '3.05');
    }
    if(is_yes($cfg->SMTP_USE_SSL)) {
        $smtp = Net::SMTP->new($cfg->SMTP_HOST,
                              Hello   => $cfg->SMTP_DOMAIN,
                              Timeout => $cfg->SMTP_TIMEOUT,
                              Debug   => $cfg->SMTP_DEBUG,
                              Port    => $cfg->SMTP_PORT,
                              SSL     => 1)
        or return "Unable to open SMTP connection to " .
            $cfg->SMTP_HOST . ": $@";
    }
    else {
        $smtp = Net::SMTP->new($cfg->SMTP_HOST,
                              Hello   => $cfg->SMTP_DOMAIN,
                              Timeout => $cfg->SMTP_TIMEOUT,
                              Debug   => $cfg->SMTP_DEBUG,
                              Port    => $cfg->SMTP_PORT)
        or return "Unable to open SMTP connection to " .
            $cfg->SMTP_HOST . ": $@";
        if(is_yes($cfg->SMTP_USE_STARTTLS)) {
            if(not $smtp->starttls()) {
                my $err = "STARTTLS failed:  " . $smtp->message();
                $smtp->quit();
                return $err;
            }
        }
    }
    if($cfg->SMTP_USERNAME and $cfg->SMTP_PASSWORD) {
        if(not $smtp->auth($cfg->SMTP_USERNAME, $cfg->SMTP_PASSWORD)) {
            my $err = "Unable to authenticate with " . $cfg->SMTP_DOMAIN .
                " SMTP server as user " . $cfg->SMTP_USERNAME . ":  " .
                $smtp->message();
            $smtp->quit();
            return $err;
        }
    }
    $smtp->mail($cfg->SMTP_FROM)
        or return "Unable to initiate sending of email message.";
    $smtp->to($recipient)
        or return "Unable to define email recipient.";
    $smtp->data()
        or return "Unable to start sending of email data.";
    if(defined $custom_headers)
    {
        for my $key (keys %$custom_headers)
        {
            my $value = $custom_headers->{$key};
            $smtp->datasend("$key: $value\n")
                or return "Unable to send email data.";
        }
    }
    $smtp->datasend("Subject: $subject\n")
        or return "Unable to send email data.";
    $smtp->datasend("To: $recipient\n")
        or return "Unable to send email data.";
    if($cfg->ADM_ADDR =~ /\b$recipient\b/) {
        # set reply-to header when sending mail to admin
        $smtp->datasend("Reply-To: $recipient\n")
            or return "Unable to send email data.";
    }
    $smtp->datasend("MIME-Version: 1.0\n")
        or return "Unable to send email data.";
    $smtp->datasend("Content-Type: text/plain\n")
        or return "Unable to send email data.";
    $smtp->datasend("Content-Transfer-Encoding: 7bit\n")
        or return "Unable to send email data.";
    $smtp->datasend("\n")
        or return "Unable to send email data.";
    $smtp->datasend(@_)
        or return "Unable to send email data.";
    $smtp->dataend()
        or return "Unable to end sending of email data.";
    $smtp->quit()
        or return "Unable to close the SMTP connection.";
    return '';  # successful
}

# ----------------------------------------------------------------------
# Send AMQP message.  AMQP analog for send_email().  Takes five or more
# arguments: the AMQP address (queue name), subject line, node_info
# (hash ref), custom properties (hash ref), and body lines to be
# emailed.  Returns empty string if successful or error message if
# error encountered.
sub send_amqp_message {
    my $amqp_addr = shift;
    my $subject = shift;
    my $node = shift;
    my $custom_properties = shift;
    # @_ now contains message body

    if(not defined $amqp_addr) {
        return 'send_amqp_message():  Missing amqp_addr (required).';
    }

    if(not defined $subject) {
        return 'send_amqp_message():  Missing subject (required).';
    }

    if(not defined $node) {
        return 'send_amqp_message():  Missing node details (required).';
    }
    elsif(not 'HASH' eq ref $node) {
        return 'send_amqp_message():  unexpected node details; expected HASH ref, found ' .
            (ref $custom_properties ? ref $custom_properties . ' ref' : '(non reference)');
    }

    if(defined $custom_properties and not 'HASH' eq ref $custom_properties) {
        return 'send_amqp_message():  unexpected custom_properties value; expected undef or HASH ref, found ' .
            (ref $custom_properties ? ref $custom_properties . ' ref' : '(non reference)');
    }

    if ((exists $node->{node_disabled}) and is_yes($node->{node_disabled}) )
    {
        return('send_amqp_message(): node_disabled is set for node ' .
               $node->{node} . '.  Message not sent.');
        next;
    }

    # default send_opts
    my $send_opts = {
        'amqp_broker_url'   => $ECS_CFG->AMQP_BROKER_URL,
        'amqp_cmd_send'     => $ECS_CFG->AMQP_CMD_SEND,
#        'amqp_content_type' => 'text/plain',
        'amqp_debug_level'  => $ECS_CFG->AMQP_DEBUG_LEVEL,
#        'amqp_encoding'     => 'utf-8',
        'amqp_password'     => (exists $ECS_CFG->{AMQP_PASSWORD} ? $ECS_CFG->AMQP_PASSWORD : ''),
        'amqp_sslcert'      => (exists $ECS_CFG->{AMQP_SSLCERT} ? $ECS_CFG->AMQP_SSLCERT : ''),
        'amqp_sslkey'       => (exists $ECS_CFG->{AMQP_SSLKEY} ? $ECS_CFG->AMQP_SSLKEY : ''),
        'amqp_sslpass'      => (exists $ECS_CFG->{AMQP_SSLPASS} ? $ECS_CFG->AMQP_SSLPASS : ''),
        'amqp_truststore'   => (exists $ECS_CFG->{AMQP_TRUSTSTORE} ? $ECS_CFG->AMQP_TRUSTSTORE : ''),
        'amqp_username'     => (exists $ECS_CFG->{AMQP_USERNAME} ? $ECS_CFG->AMQP_USERNAME : ''),
        'amqp_vhost'        => (exists $ECS_CFG->{AMQP_VHOST} ? $ECS_CFG->AMQP_VHOST : '')
    };

    # override default send_opts with node-specific opts (where indicated)
    foreach my $opt (keys %$send_opts) {
        $send_opts->{$opt} = $node->{$opt}
            if exists $node->{$opt};
    }

    # default send_props
    my $mail_mrk = $ECS_CFG->MAIL_MRK;
    my $hub_snd = '';
    my $seq_num = '';
    if($subject =~ /$mail_mrk:(\S+?):(\d+):(\d+)\/(\d+)\s*$/io) {
        $hub_snd = $1;
        $seq_num = "$2:$3/$4";
    }
    elsif($subject =~ /$mail_mrk:(\S+?):(\d+)\s*$/io) {
        $hub_snd = $1;
        $seq_num = $2;
    }
    elsif($subject =~ /$mail_mrk:(\S+?):(\d+):DOC\s*$/io) {
        $hub_snd = $1;
        $seq_num = $2;
    }
    elsif($subject =~ /$mail_mrk:(\S+)\s*$/io) {
        $hub_snd = $1;
    }
    # sanity check
    if($ECS_CFG->THIS_NODE ne $hub_snd) {
        return "send_amqp_message():  hub_snd ($hub_snd) ne THIS_NODE (" . $ECS_CFG->THIS_NODE . ")";
    }
    my $send_props = {
        'x-emdis-hub-snd'           => $ECS_CFG->THIS_NODE,
        'x-emdis-hub-rcv'           => ($node->{node} ? $node->{node} : ''),
        'x-emdis-sequential-number' => ($seq_num ? $seq_num : '')
    };

    # add custom properties to send_props (where indicated)
    if(defined $custom_properties) {
        foreach my $prop (keys %$custom_properties) {
            $send_props->{$prop} = $custom_properties->{$prop};
        }
    }

    # construct AMQP send command
    my $cmd = sprintf('%s --inputfile - --debug %s --address %s --broker %s ' .
                          '--subject %s',
                      $send_opts->{amqp_cmd_send},
                      $send_opts->{amqp_debug_level},
                      $amqp_addr,
                      $send_opts->{amqp_broker_url},
                      $subject);
    $cmd .= sprintf(' --type %s', $send_opts->{amqp_content_type})
        if $send_opts->{amqp_content_type};
    $cmd .= sprintf(' --encoding %s', $send_opts->{amqp_encoding})
        if $send_opts->{amqp_encoding};
    $cmd .= sprintf(' --vhost %s', $send_opts->{amqp_vhost})
        if $send_opts->{amqp_vhost};
    $cmd .= sprintf(' --truststore %s', $send_opts->{amqp_truststore})
        if $send_opts->{amqp_truststore};
    $cmd .= sprintf(' --sslcert %s --sslkey %s',
                    $send_opts->{amqp_sslcert},
                    $send_opts->{amqp_sslkey})
        if $send_opts->{amqp_sslcert} and $send_opts->{amqp_sslkey};
    $cmd .= sprintf(' --username %s', $send_opts->{amqp_username})
        if $send_opts->{amqp_username};
    foreach my $prop (keys %$send_props) {
        $cmd .= sprintf(' --property %s=%s', $prop, $send_props->{$prop})
            if $send_props->{$prop};
    }

    # set environment variables containing passwords:
    # ECS_AMQP_PASSWORD and ECS_AMQP_SSLPASS
    $ENV{ECS_AMQP_PASSWORD} = $send_opts->{amqp_password}
        if $send_opts->{amqp_password};
    $ENV{ECS_AMQP_SSLPASS} = $send_opts->{amqp_sslpass}
        if $send_opts->{amqp_sslpass};

    # execute command to send AMQP message
    print "<DEBUG>: AMQP send command: $cmd\n"
        if $ECS_CFG->ECS_DEBUG > 0;
    my $err = timelimit_cmd($ECS_CFG->AMQP_SEND_TIMELIMIT, $cmd, join('', @_));
    if($err) {
        return "send_amqp_message(): unable to send AMQP message to $amqp_addr: $err";
    }

    return '';
}

# ----------------------------------------------------------------------
# Send encrypted email message.
# Returns empty string if successful or error message if error encountered.
sub send_encrypted_message
{
    my $encr_typ = shift;
    my $encr_recip = shift;
    my $recipient = shift;
    my $encr_out_keyid = shift;
    my $encr_out_passphrase = shift;
    my $node = shift;
    my $subject = shift;
    my $custom_headers = shift;
    # @_ now contains message body

    return "EMDIS::ECS::send_encrypted_message(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    # compose template for name of temp file
    my $template = format_datetime(time, '%04d%02d%02d_%02d%02d%02d_XXXX');

    # write message body to temp file
    my ($fh, $filename) = tempfile($template,
                                   DIR    => $cfg->ECS_TMP_DIR,
                                   SUFFIX => '.tmp');
    return "EMDIS::ECS::send_encrypted_message(): unable to create temporary file"
        unless $fh;
    print $fh @_;
    close $fh;
    chmod $FILEMODE, $filename;
    
    # create file containing encrypted message
    my $encr_filename = "$filename.pgp";
    my $result = '';
    for ($encr_typ) {
        /PGP2/i and do {
            $result = pgp2_encrypt($filename, $encr_filename, $encr_recip,
                $encr_out_keyid, $encr_out_passphrase);
            last;
        };
        /OpenPGP/i and do {
            $result = openpgp_encrypt($filename, $encr_filename, $encr_recip,
                $encr_out_keyid, $encr_out_passphrase);
            last;
        };
        $result = "unrecognized encr_typ: $encr_typ";
    }

    # delete first temp file
    unlink $filename;

    # check for error
    return "EMDIS::ECS::send_encrypted_message(): $result" if $result;

    # read contents of encrypted file
    $fh = new IO::File;
    return "EMDIS::ECS::send_encrypted_message(): unable to open file: " .
        "$encr_filename"
            unless $fh->open("< $encr_filename");
    my @body = $fh->getlines();
    $fh->close();

    # delete encrypted (temp) file
    unlink $encr_filename;

    if(is_yes($cfg->ENABLE_AMQP)) {
        # send message via AMQP, if indicated by node config
        my $amqp_addr = '';
        if($subject =~ /^[^:]+:[^:]+$/io) {
            return "EMDIS::ECS::send_encrypted_message(): unable to send " .
                "AMQP META message to node " . $node->{node} . ": amqp_only " .
                "selected, but amqp_addr_meta not configured."
                if not $node->{amqp_addr_meta} and is_yes($node->{amqp_only});
            $amqp_addr = $node->{amqp_addr_meta};
        }
        elsif($subject =~ /^[^:]+:[^:]+:[0123456789]+:DOC/io) {
            return "EMDIS::ECS::send_encrypted_message(): unable to send " .
                "AMQP document to node " . $node->{node} . ": amqp_only " .
                "selected, but amqp_addr_doc not configured."
                if not $node->{amqp_addr_doc} and is_yes($node->{amqp_only});
            $amqp_addr = $node->{amqp_addr_doc};
        }
        elsif($subject =~ /^[^:]+:[^:]+:[0123456789]+/io) {
            return "EMDIS::ECS::send_encrypted_message(): unable to send " .
                "AMQP regular message to node " . $node->{node} . ": amqp_only " .
                "selected, but amqp_addr_msg not configured."
                if not $node->{amqp_addr_msg} and is_yes($node->{amqp_only});
            $amqp_addr = $node->{amqp_addr_msg};
        }
        elsif(is_yes($node->{amqp_only})) {
            return "EMDIS::ECS::send_encrypted_message(): unable to send " .
                "via AMQP to node " . $node->{node} . ": amqp_only selected, " .
                "but unable to determine amqp_addr from Subject: $subject"
        }
        if($amqp_addr) {
            return send_amqp_message(
                $amqp_addr,
                $subject,
                $node,
                $custom_headers,
                @body);
        }
    }

    if(is_yes($node->{amqp_only})) {
        return "EMDIS::ECS::send_encrypted_message(): unable to send " .
            "via email to node " . $node->{node} . ": amqp_only selected"
    }

    if($node->{amqp_addr_meta} or $node->{amqp_addr_msg} or $node->{amqp_addr_doc}) {
        # print debug message if AMQP is only partially configured for recipient node
        print "<DEBUG> EMDIS::ECS::send_encrypted_message(): sending via " .
            "email (not AMQP) to node " . $node->{node} . ": $subject\n"
            if $cfg->ECS_DEBUG > 0;
    }

    # send message via email
    return send_email($recipient, $subject, $custom_headers, @body);
}

# ----------------------------------------------------------------------
# Format a datetime value
sub format_datetime
{
    my $datetime = shift;
    my $format = shift;
    $format = '%04d-%02d-%02d %02d:%02d:%02d'
        unless defined $format;
    my ($seconds, $minutes, $hours, $mday, $month, $year, $wday, $yday,
        $isdst) = localtime($datetime);
    return sprintf($format, $year + 1900, $month + 1, $mday,
                   $hours, $minutes, $seconds);
}

# ----------------------------------------------------------------------
# Format filename for document.
sub format_doc_filename
{
    return "EMDIS::ECS::format_doc_filename(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;
    my $node_id = shift;
    my $seq_num = shift;
    my $template = sprintf("%s_%s_d%010d",
                           $cfg->THIS_NODE, $node_id, $seq_num);
    my $dirname = $cfg->ECS_MBX_OUT_DIR . "_$node_id";
    return catfile($dirname, "$template.doc");
}

# ----------------------------------------------------------------------
# Format filename for regular message.
sub format_msg_filename
{
    return "EMDIS::ECS::format_msg_filename(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;
    my $node_id = shift;
    my $seq_num = shift;
    my $template = sprintf("%s_%s_%010d",
                           $cfg->THIS_NODE, $node_id, $seq_num);
    my $dirname = $cfg->ECS_MBX_OUT_DIR . "_$node_id";
    return catfile($dirname, "$template.msg");
}

# ----------------------------------------------------------------------
# Use OpenPGP (GnuPG) to decrypt a file.
# Returns empty string if successful or error message if error encountered.
sub openpgp_decrypt
{
    my $input_filename = shift;
    my $output_filename = shift;
    my $required_signature = shift;
    my $encr_out_passphrase = shift;

    # initialize
    return "EMDIS::ECS::openpgp_decrypt(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    # compose command
    my $cmd = $cfg->OPENPGP_CMD_DECRYPT;
    $cmd =~ s/__INPUT__/$input_filename/g;
    $cmd =~ s/__OUTPUT__/$output_filename/g;
    print "<DEBUG> openpgp_decrypt() command: $cmd\n"
        if $cfg->ECS_DEBUG > 0;

    # set GNUPGHOME environment variable
    $ENV{GNUPGHOME} = $cfg->GPG_HOMEDIR;

    # attempt to execute command
    my $result = timelimit_cmd($cfg->T_MSG_PROC, $cmd,
        (defined $encr_out_passphrase and 0 < length $encr_out_passphrase) ?
            $encr_out_passphrase :
            (defined $cfg->GPG_PASSPHRASE and 0 < length $cfg->GPG_PASSPHRASE ?
                $cfg->GPG_PASSPHRASE : undef));
    $result = "EMDIS::ECS::openpgp_decrypt(): $result" if $result;

    # check signature, if indicated
    if(defined($required_signature) and not $result) {
        if($cmd_output !~ /Good signature from[^\n]+$required_signature/is) {
            $result = "EMDIS::ECS::openpgp_decrypt(): required signature not " .
                "present: $required_signature";
        }
    }

    return $result;
}

# ----------------------------------------------------------------------
# Use OpenPGP (GnuPG) to encrypt a file.
# Returns empty string if successful or error message if error encountered.
sub openpgp_encrypt
{
    my $input_filename = shift;
    my $output_filename = shift;
    my $recipient = shift;
    my $encr_out_keyid = shift;
    my $encr_out_passphrase = shift;

    # initialize
    return "EMDIS::ECS::openpgp_encrypt(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    # compose command
    my $keyid = (defined $encr_out_keyid and 0 < length $encr_out_keyid) ?
        $encr_out_keyid : $cfg->GPG_KEYID;
    my $cmd = $cfg->OPENPGP_CMD_ENCRYPT;
    $cmd =~ s/__INPUT__/$input_filename/g;
    $cmd =~ s/__OUTPUT__/$output_filename/g;
    $cmd =~ s/__RECIPIENT__/$recipient/g;
    $cmd =~ s/__SELF__/$keyid/g;
    print "<DEBUG> openpgp_encrypt() command: $cmd\n"
        if $cfg->ECS_DEBUG > 0;

    # set GNUPGHOME environment variable
    $ENV{GNUPGHOME} = $cfg->GPG_HOMEDIR;

    # attempt to execute command
    my $result = timelimit_cmd($cfg->T_MSG_PROC, $cmd,
        (defined $encr_out_passphrase and 0 < length $encr_out_passphrase) ?
            $encr_out_passphrase :
            (defined $cfg->GPG_PASSPHRASE and 0 < length $cfg->GPG_PASSPHRASE ?
                $cfg->GPG_PASSPHRASE : undef));
    $result = "EMDIS::ECS::openpgp_encrypt(): $result" if $result;
    return $result;
}

# ----------------------------------------------------------------------
# Use PGP2 (PGP) to decrypt a file.
# Returns empty string if successful or error message if error encountered.
sub pgp2_decrypt
{
    my $input_filename = shift;
    my $output_filename = shift;
    my $required_signature = shift;
    my $encr_out_passphrase = shift;

    # initialize
    return "EMDIS::ECS::pgp2_decrypt(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    # compose command
    my $cmd = $cfg->PGP2_CMD_DECRYPT;
    $cmd =~ s/__INPUT__/$input_filename/g;
    $cmd =~ s/__OUTPUT__/$output_filename/g;
    print "<DEBUG> pgp2_decrypt() command: $cmd\n"
        if $cfg->ECS_DEBUG > 0;

    # set PGPPATH and PGPPASS environment variables
    $ENV{PGPPATH} = $cfg->PGP_HOMEDIR;
    $ENV{PGPPASS} = (defined $encr_out_passphrase and 0 < length $encr_out_passphrase) ?
        $encr_out_passphrase : $cfg->PGP_PASSPHRASE;

    # attempt to execute command
    my $result = timelimit_cmd($cfg->T_MSG_PROC, $cmd);
    $result = '' if($result =~ /^Status 0x0100/);  # ignore exit value = 1
    $result = "EMDIS::ECS::pgp2_decrypt(): $result" if $result;

    # check signature, if indicated
    if(defined($required_signature) and not $result) {
        if($cmd_output !~ /Good signature from[^\n]+$required_signature/is) {
            $result = "EMDIS::ECS::pgp2_decrypt(): required signature not " .
                "present: $required_signature";
        }
    }

    return $result;
}

# ----------------------------------------------------------------------
# Use PGP to encrypt a file.
# Returns empty string if successful or error message if error encountered.
sub pgp2_encrypt
{
    my $input_filename = shift;
    my $output_filename = shift;
    my $recipient = shift;
    my $encr_out_keyid = shift;
    my $encr_out_passphrase = shift;

    # initialize
    return "EMDIS::ECS::pgp2_encrypt(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;

    # compose command
    my $keyid = (defined $encr_out_keyid and 0 < length $encr_out_keyid) ?
        $encr_out_keyid : $cfg->PGP_KEYID;
    my $cmd = $cfg->PGP2_CMD_ENCRYPT;
    $cmd =~ s/__INPUT__/$input_filename/g;
    $cmd =~ s/__OUTPUT__/$output_filename/g;
    $cmd =~ s/__RECIPIENT__/$recipient/g;
    $cmd =~ s/__SELF__/$keyid/g;
    print "<DEBUG> pgp2_encrypt() command: $cmd\n"
        if $cfg->ECS_DEBUG > 0;

    # set PGPPATH and PGPPASS environment variables
    $ENV{PGPPATH} = $cfg->PGP_HOMEDIR;
    $ENV{PGPPASS} = (defined $encr_out_passphrase and 0 < length $encr_out_passphrase) ?
        $encr_out_passphrase : $cfg->PGP_PASSPHRASE;
    
    # attempt to execute command
    my $result = timelimit_cmd($cfg->T_MSG_PROC, $cmd);
    $result = "EMDIS::ECS::pgp2_encrypt(): $result" if $result;
    return $result;
}

# ----------------------------------------------------------------------
# Check whether another copy of the program is already running.
# If so, this one dies.
sub check_pid
{
    die "EMDIS::ECS::check_pid(): ECS has not been configured."
        unless ecs_is_configured();

    if(open PIDFILE, $pidfile) {
        my $pid = <PIDFILE>;
        $pid =~ s/\s+//g;
        die "Error: $0 is already running (pid $pid).\n"
            if kill(0, $pid);
        close PIDFILE;
    }

    save_pid();
}

# ----------------------------------------------------------------------
# Update PID file.
sub save_pid
{
    die "EMDIS::ECS::save_pid(): ECS has not been configured."
        unless ecs_is_configured();

    open PIDFILE, ">$pidfile";
    print PIDFILE "$$\n";
    close PIDFILE;
    chmod $FILEMODE, $pidfile;
    $pid_saved = 1;
}

# ----------------------------------------------------------------------
# Select the Win32 or Unix version of timelimit_cmd
sub timelimit_cmd
{
    $^O =~ /MSWin32/ ? timelimit_cmd_win32(@_) : timelimit_cmd_unix(@_);
}



# Returns empty string if successful or error message if error encountered.
sub timelimit_cmd_win32
{
    my $timelimit = shift;
    my $cmd = shift;
    my $input_data = shift;
    my $cfg = $ECS_CFG;
    my @msgs = ();
    my $result = "";
    my ($ProcessObj, $rc, $appname, $cmdline);

    pipe(READ, WRITE);
    select(WRITE);
    $| = 1;
    select(STDOUT);
    open(OLDIN, "< &STDIN")  ||  die "Can not save STDIN\n";
    open(STDIN, "< &READ")    ||  die "Can not redirect STDIN\n";

    open(OLDOUT, ">&STDOUT")  ||  die "Can not save STDOUT\n";
    open(STDOUT, ">$$.txt" )  || die( "Unable to redirect STDOUT ");

    open(OLDERR, ">&STDERR" )  ||  die "Can not redirect STDERR\n";
    open(STDERR, ">&STDOUT" )  || die( "Unable to dup STDOUT to STDERR" );

    select(STDERR);
    $| = 1;
    select(STDIN);
    $| = 1;
    select(STDOUT);

    if(! defined $input_data) { $input_data = ""; }

    # compute $appname and $cmdline
    $cmd =~ /\s*(\S+)\s*(.*)/;
    $appname = $1;
    $cmdline = "$1 $2";
    # if applicable, append .exe or .bat extension to $appname
    if(-x "$appname.exe")
    {
        $appname = "$appname.exe";
    }
    elsif(-x "$appname.bat")
    {
        $appname = "$appname.bat";
    }
    
    print "\n<DEBUG>: Running External Command" .
        "\nappname=" . $appname . 
        "\ncmdline=" . $cmdline . 
#        "\nSTDIN=" . $input_data .    # (don't print out PGP passphrase)
        "\nTimelimit=" . $timelimit . "\n"
        if $cfg->ECS_DEBUG > 0;

    $rc =  Win32::Process::Create(
        $ProcessObj,
        $appname,
        $cmdline,
        1,
        Win32::Process::constant('NORMAL_PRIORITY_CLASS'),
        ".");

    if ($rc) {
        print "<DEBUG>: PID = " . $ProcessObj->GetProcessID() . "\n"
            if $cfg->ECS_DEBUG > 0;
    }
    else {
        my $winMsg = Win32::FormatMessage(Win32::GetLastError());
        if (defined $winMsg) {
            $result = $winMsg;
        } else {
            print "<DEBUG>: Windows error\n"
                if $cfg->ECS_DEBUG > 0;
            $result = "Windows error";
        }
    }

    if($rc)
    {
        print WRITE "$input_data\n";
        close(WRITE);

        print "<DEBUG>: Waiting\n"
            if $cfg->ECS_DEBUG > 0;
        $rc = $ProcessObj->Wait($timelimit * 1000);

        # Check for return code	
        if ($rc ) {     	
            my $ret;
            $ProcessObj->GetExitCode($ret);
            print "<DEBUG>: Process OK ($ret)\n\n"
                if $cfg->ECS_DEBUG > 0;	
        } else {
          Win32::Process::KillProcess($ProcessObj->GetProcessID(), 0);
            print "<DEBUG>: Process Timeout\n\n"
                if $cfg->ECS_DEBUG > 0;	
            $result = "Process Timeout";
        }
    }

    # Restore STDIN, STDOUT, STDERR
    open(STDIN,  "<&OLDIN");
    open(STDOUT, ">&OLDOUT" );
    open(STDERR, ">&OLDERR" );

    if(0)
    {
        # just leave these hanging until next time around ...
        # (avoid potential deadlock waiting for child process to end)
        close(READ);
        close(OLDIN);
        close(OLDOUT);
        close(OLDERR);
    }


    if(open FILETEMP, "< $$.txt")
    {
        @msgs = <FILETEMP>;
        close FILETEMP;
        unlink "$$.txt";
        print "\n======== EXTERNAL BEGIN =============\n";
        print @msgs;
        print "========= EXTERNAL END ==============\n";
    }

    # set module-level variable containing command output
    if($#msgs >= 0) { $cmd_output = join('', @msgs); }
    else            { $cmd_output = ''; }

    return $result;
}


# ----------------------------------------------------------------------
# Unix version
# Execute specified command, with time limit and optional input data.
# Returns empty string if successful or error message if error encountered.
sub timelimit_cmd_unix
{
    my $timelimit = shift;
    my $cmd = shift;
    my $input_data = shift;

    # initialize
    my ($reader, $writer) = (IO::Handle->new, IO::Handle->new);
    my ($pid, @msgs, $status);
    my $result = '';

    # set up "local" SIG_PIPE and SIG_ALRM handlers
    # (Note:  not using "local $SIG{PIPE}" because it ignores die())
    my $broken_pipe = '';
    my $oldsigpipe = $SIG{PIPE};
    $SIG{PIPE} = sub { $broken_pipe = 1; };
    my $oldsigalrm = $SIG{ALRM};
    $SIG{ALRM} = sub {
        die "timeout - $timelimit second processing time limit exceeded\n";
    };

    # use eval {}; to enforce time limit (see Perl Cookbook, 16.21)
    eval {
        alarm($timelimit);  # set time limit
        $broken_pipe = '';
        $pid = open2($reader, $writer, $cmd);
        print $writer $input_data if defined $input_data;
        close $writer;
        @msgs = $reader->getlines();
        close $reader;
        waitpid $pid, 0;
        $status = $?;
        die "broken pipe\n" if $broken_pipe;
        alarm(0);
    };
    if($@) {
        alarm(0);
        # detect runaway child from open2() fork/exec
        die "runaway child, probably caused by bad command\n"
            if (not defined $pid) and ($@ =~ /^open2/);
        # construct error message
        chomp $@;
        $result = "$@: $cmd\n";
    }
    elsif ($status) {
        my $exit_value = $status >> 8;
        my $signal_num = $status & 127;
        my $dumped_core = $status & 128;
        # construct error message
        $result = sprintf("Status 0x%04x (exit %d%s%s)",
                          $status, $exit_value,
                          ($signal_num ? ", signal $signal_num" : ''),
                          ($dumped_core ? ', core dumped' : ''));
    }
    $writer->close if $writer->opened;
    $reader->close if $reader->opened;
    if(defined $oldsigpipe) { $SIG{PIPE} = $oldsigpipe; }
    else                    { delete $SIG{PIPE}; }
    if(defined $oldsigalrm) { $SIG{ALRM} = $oldsigalrm; }
    else                    { delete $SIG{ALRM}; }
    $result .= "\n----------\n" . join("", @msgs) if($result and $#msgs >= 0);
    # set module-level variable containing command output
    if($#msgs >= 0) { $cmd_output = join('', @msgs); }
    else            { $cmd_output = ''; }
    return $result;
}

# ----------------------------------------------------------------------
# Unlink PID file.
sub remove_pidfile
{
    unlink $pidfile if $pidfile;
}

# ----------------------------------------------------------------------
# Return string value with leading and trailing whitespace trimmed off.
sub trim {
    my $str = shift;
    return if not defined $str;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

# ----------------------------------------------------------------------
# Return boolean indicating whether specified encr_typ is valid.
sub valid_encr_typ
{
    my $encr_typ = shift;
    for ($encr_typ) {
        /PGP2/i and return 1;
        /OpenPGP/i and return 1;
    }
    return '';
}

1;

__DATA__

# embedded POD documentation
# for more info:  man perlpod


=head1 NAME

EMDIS::ECS - ECS utility module

=head1 SYNOPSIS

 use vars qw($ECS $ECS_CFG $ECS_NODE_TBL);
 use EMDIS::ECS;
 $err = EMDIS::ECS::load_config("ecs.cfg");
 die "Unable to initialize ECS: $err\n" if $err;

 ECS::log_error("This is an error.");

 $err = EMDIS::ECS::send_admin_email("Something happened.\n",
     "Here are details.\n");
 ECS::log_error("error sending admin email: $err") if $err;

 $err = EMDIS::ECS::send_ecs_message('UX', '', "msg_type=READY\n",
     "# comment\n");
 ECS::log_error("error sending ECS message: $err") if $err;


=head1 DESCRIPTION

This module contains a bunch of miscellaneous ECS related subroutines.
However, most of the documentation found here pertains to the Perl ECS
implementation in general, not those specific subroutines.


=head2 Introduction

This Perl implementation of the EMDIS Communication System (ECS),
herein referred to as "Perl-ECS", is generally compatible with
the ECS specification published by the ZKRD, though it differs from
the specification in some of its implementation details.
A PDF document containing the original ECS specification is available
from the ZKRD web site (see http://www.zkrd.de/).


=head2 Getting Started

Before Perl-ECS can be used, a number of pre-requisites must
be satisfied.

=over 4

=item Install Perl-ECS

Install Perl, preferably version 5.6.1 or higher.  Then install the
EMDIS::ECS package.  (Presumably already done if you're reading this
documentation online.)

=item Email Account

Acquire an email account to be used by the ECS system.  Perl-ECS
uses SMTP to send outbound mail, so a SMTP server will need to be
available for this purpose.

To read incoming email, Perl-ECS can use IMAP protocol, POP3 protocol,
or a DIRECTORY method.  If IMAP or POP3 protocol is used, that service
will also need to be available.

=item Encryption Software

Install and configure PGP and/or GnuPG encryption software.  Refer to
http://www.pgp.com/, http://www.pgpi.org/, http://www.gnupg.org/,
and http://www.philzimmermann.com/ for more information on the topic
of PGP and related software.

=item GnuPG Version 2.2 - Additional Notes

The default OpenPGP configuration used by Perl-ECS is intended for use
with GnuPG (gpg) versions 1.4 and 2.0.  However, gpg version 2.2 is a
standard component of newer Linux systems such as Ubuntu 18.

For systems using gpg version 2.2, configuration adjustments are needed
in order to enable Perl-ECS to transmit the passphrase to gpg via stdin
(pinentry-mode loopback).

1. Create or edit $GNUPGHOME/gpg-agent.conf, adding the line:

 allow-loopback-pinentry

2. Execute the command:

 gpg-connect-agent /bye

3. In the ecs.cfg configuration file, revise the OPENPGP_CMD_ENCRYPT and
OPENPGP_CMD_DECRYPT settings to add the following.  (If needed, first
uncomment those settings.):

 --pinentry-mode loopback

4. If upgrading from an earlier gpg version, use ecstool --tweak to modify
all (addr_r) key IDs in the node table, because the IDs change when the
keyring is converted to gpg 2.2.

=item AMQP Messaging

As an experimental new feature, version 0.41 added support for use of
AMQP messaging as an alternative to email.

To use AMQP messaging, the ENABLE_AMQP setting must be set to YES or TRUE.
AMQP communications utilize a mboxes/amqp_staging directory, which will
need to be created manually, e.g.:

 mkdir mboxes/amqp_staging

Additionally, the node table now accepts new AMQP-related settings.
These can be added via the "ecstool --tweak" command, e.g.:

 ecstool --tweak BB amqp_addr_meta emdis.bb.meta
 ecstool --tweak BB amqp_addr_msg emdis.bb.msg

AMQP settings configured at the individual node level override equivalent
global settings when communicating with that node.   The presence of
amqp_addr_meta and amqp_addr_msg in the node configuration, respectively,
enable use of AMQP for transmission of META and regular EMDIS messages to
that node (assuming ENABLE_AMQP is also set in ecs.cfg).

The node table also recognizes an amqp_only yes/no option.  If enabled,
the amqp_only option disables use of email when transmitting
meta-messages, documents, or regular messages messages to that node.

=item Document Exchange

As an experimental new feature, version 0.41 added support for document
exchange.

The ecs_scan_mail program, when processing files in the
mboxes/to_dir/to_XX subdirectories, now looks for filenames with the
suffix .doc or .doc.xml and sends those files as documents.

Similarly, the "ecstool --send" command now sends files with a .doc or
.doc.xml suffix as documents, e.g. "ecstool --send EE test01.doc"

The ecs_scan_mail program copies documents received to the
mboxes/from_dir/from_XX subdirectories, to a filename with a .doc suffix.

Document exchange uses a Subject header of the form EMDIS:AA:123:DOC
to indicate the presence of a document and its sequence number.
DOC_MSG_ACK and DOC_RE_SEND are meta messages used for document exchange.

=back

=head2 Configuration

Once the above prerequisites are in place, it's time to configure your
ECS system.  Create a directory to hold the ECS data files and then run
the ecs_setup program to help create a basic configuration file.  The
ECS configuration file can also be created and edited using a regular
text editor.


=head2 NODE_TBL

The NODE_TBL used by Perl-ECS contains several additional fields not
described in the ECS specification.  See below for descriptions of
NODE_TBL fields;  the names of added fields are shown I<emphasized>.
The ecstool program provides commands to manipulate the NODE_TBL.

=over 4

=item ack_seq

The highest sequence number acknowledged by this node.

=item addr

The email address of this node.

=item addr_r

The PGP or GnuPG userid of this ECS node.

=item I<amqp_addr_doc>

Name of AMQP queue to use when sending ECS document messages to this node.

=item I<amqp_addr_meta>

Name of AMQP queue to use when sending ECS meta messages to this node.

=item I<amqp_addr_msg>

Name of AMQP queue to use when sending regular ECS messages to this node.

=item I<amqp_broker_url>

Node-specific AMQP_BROKER_URL configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_cmd_recv>

Node-specific AMQP_CMD_RECV configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_cmd_send>

Node-specific AMQP_CMD_SEND configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_debug_level>

Node-specific AMQP_DEBUG_LEVEL configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_password>

Node-specific AMQP_PASSWORD configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_recv_timeout>

Node-specific AMQP_RECV_TIMEOUT configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_send_timelimit>

Node-specific AMQP_SEND_TIMELIMIT configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_sslcert>

Node-specific AMQP_SSLCERT configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_sslkey>

Node-specific AMQP_SSLKEY configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_sslpass>

Node-specific AMQP_SSLPASS configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_truststore>

Node-specific AMQP_TRUSTSTORE configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_username>

Node-specific AMQP_USERNAME configuration.
See also EMDIS:ECS::Config documentation.

=item I<amqp_vhost>

Node-specific AMQP_VHOST configuration.
See also EMDIS:ECS::Config documentation.

=item I<contact>

Email address of administrator for this node.

=item I<doc_in_seq>

Sequence number assigned to the most recent document received from this
node (intended for internal use only).

=item I<doc_out_seq>

Sequence number assigned to the most recent document sent to this node
(intended for internal use only).

=item I<encr_meta>

Indicates whether meta-messages to/from this node should be encrypted
("true" or "false").

=item I<encr_out_keyid>

ID of secret key to be used for encrypted messages to/from this node.
For this node only, overrides the ECS configuration file's GPG_KEYID or
PGP_KEYID.

=item I<encr_out_passphrase>

Passphrase for I<encr_out_keyid>.  For this node only, overrides the
ECS configuration file's GPG_PASSPHRASE or PGP_PASSPHRASE.

=item I<encr_sig>

Identifies the PGP or GnuPG signature for this node.

=item I<encr_typ>

The type of encryption used by this node.  Currently supported encryption
types are "PGP2", "PGP2-verify", "OpenPGP", and "OpenPGP-verify" ("verify"
indicates messages from the node are cryptographically signed and the
signature should be verified).

=item in_seq

The sequence number of the last message accepted from this node.

=item I<in_seq_ack>

The sequence number of the last message from this node for which a MSG_ACK
has been sent.

=item last_in

Date and time when the last message from this node was accepted.

=item I<last_in_adm>

Date and time when local ECS administrator was notified of communication
loss with this node.

=item last_out

Date and time when the last message from this node was received.

=item I<msg_part_size>

Maximum message part size, in bytes, for this node.  Defaults to
MSG_PART_SIZE_DFLT from ECS config file if not specified or zero.  Refer
to the EMDISCORD email parts RFC (RFC-20091021-EmailParts.pdf) for
additional information about message parts.

=item node

The ECS node name. (Primary key)

=item I<node_disabled>

Indicates whether processing is currently disabled for this node
(YES or NO).

=item out_seq

The sequence number of the last message sent to this node.

=item I<q_first_file>

Name of first file in processing queue.
The filename shows the date and time when the file was retrieved from the
email inbox.
This field is automatically updated by the ecs_scan_mail program, once per
T_SCN interval.

=item I<q_gap_seq>

Minimum message seq_num of "early" message in processing queue.
This value is updated only when a gap in message seq_num values is
encountered.  During message processing, if the "early" message
situation persists longer than the number of seconds specified by
the T_RESEND_DELAY configuration parameter and I<q_gap_seq> does
not change during this time period, the ecs_scan_mail program will
automatically generate a batch of RE_SEND requests.

=item I<q_gap_time>

Date and time when I<q_gap_seq> value was observed.  This value is used
to compute whether the T_RESEND_DELAY time interval has elapsed.

=item I<q_max_seq>

Maximum message seq_num in processing queue.
This field is automatically updated by the ecs_scan_mail program, once per
T_SCN interval.

=item I<q_min_seq>

Minimum message seq_num in processing queue.
This field is automatically updated by the ecs_scan_mail program, once per
T_SCN interval.

=item I<q_size>

Number of messages in processing queue.
This field is automatically updated by the ecs_scan_mail program, once per
T_SCN interval.

=item I<proc_file>

File containing message currently being processed.
For THIS_NODE only, this field is automatically updated by the ecs_scan_mail
program during message processing.

=item I<proc_node>

Node id for message currently being processed.
For THIS_NODE only, this field is automatically updated by the ecs_scan_mail
program during message processing.

=item I<proc_seq>

Sequence number of message currently being processed.
For THIS_NODE only, this field is automatically updated by the ecs_scan_mail
program during message processing.

=item I<ready_num_disabled>

Indicates whether READY meta-messages sent to this node will include
last_recv_num and last_sent_num values (YES or NO).

=back

=head2 Special Features

A few notes regarding differences between Perl-ECS and the ECS
specification.

=over 4

=item Serialized Message Processing

Incoming messages are processed one at a time, with a processing time
limit.  Because of this, Perl-ECS is not susceptible to "fork bomb"
problems that could occur when many messages are received in a short
period of time.

=item No MSG_TBL

There is no MSG_TBL to track "early" messages.  Instead, the
ecs_scan_mail program performs a brute force analysis of the
mboxes/store directory once during each T_SCN interval.

=item RE_SEND Protocol

If a gap in message seq_num values for a given node is encountered, and the
lowest incoming message seq_num for that node has not changed for
T_RESEND_DELAY seconds, the ecs_scan_mail program automatically issues a
batch of up to 100 RE_SEND requests.
Because missing email messages may indicate the existence of unusual problems,
the ecs_scan_mail program also sends email to notify the ECS administrator
when this happens.

=item Email Protocols

To send email, Perl-ECS requires a SMTP server.  Likewise, to read email,
it requires a POP3 or IMAP server.  It does not use mailx or other
system specific software.

=item Expanded NODE_TBL

The NODE_TBL contains several additional fields: encr_meta, encr_sig,
encr_typ, last_in_adm.  See the above NODE_TBL section for details.

=item mboxes/in_fml

Incoming FML messages are archived in the mboxes/in_fml subdirectory.

=item The ecstool Program

The ecstool program has been given additional capabilities.  For
details, refer to the ecstool documentation (e.g. "perldoc ecstool" or
"man ecstool").

=item ECS Configuration File

A significant number of new settings have been added to the ECS
configuration file.  For details, refer to the EMDIS::ECS::Config
documentation (e.g. "perldoc EMDIS::ECS::Config" or "man
EMDIS::ECS::Config").  The ecs_setup program is designed to help in
the creation of a basic ECS configuration file.

=item PID Files

The files in ECS_DAT_DIR that contain the PIDs for the ecs_chk_com
and ecs_scan_mail daemons are ecs_chk_com.pid and ecs_scan_mail.pid,
respectively.

=item Log Files

The ecs_chk_com and ecs_scan_mail daemons do not share common log
and err files.

=item The ecs_off.lck File

The ECS daemons do not check for the presence of an ecs_off.lck file.

=item MSG_PROC

The ecs_scan_mail daemon sets ADAPTER_CMD and ECS_DRP_DIR environment
variables during execution of the MSG_PROC command.  The default
MSG_PROC script provided with Perl-ECS ("ecs_proc_msg") executes the
command specified by ADAPTER_CMD when processing a message.
ECS_DRP_DIR specifies the location of the ECS_DAT_DIR/maildrop directory.

=item ECS_DAT_DIR/maildrop

The "maildrop" directory holds outbound messages generated
by the MSG_PROC, ADAPTER_CMD, or "ecstool --maildrop" commands.  During
each T_SCN interval, after messages in the mboxes/store directory have
been processed, FML files found in the maildrop directory are automatically
sent to the appropriate destination, based on the values of the HUB_SND and
HUB_RCV fields.  (However, the maildrop FML parser is currently unable to
process HUB_SND and HUB_RCV values formatted using /FIELDS or /CONST.)

=item ADM_ADDR

Any incoming non-ECS messages are passed to ADM_ADDR.

=item mboxes/active

There is no mboxes/active subdirectory.  This directory is not needed
when reading mail from a POP3 or IMAP inbox.

=item ecs, ecs_send_msg, ecs_resend_req

Scripts or programs named ecs, ecs_send_msg, and ecs_resend_req are
not provided.

=back

=head1 BUGS

Possibly.


=head1 SEE ALSO

EMDIS::ECS::Config, EMDIS::ECS::FileBackedMessage,
EMDIS::ECS::LockedHash, EMDIS::ECS::Message, ecs_chk_com,
ecs_proc_meta, ecs_proc_msg, ecs_scan_mail, ecs_setup, ecstool


=head1 AUTHOR

Neil Smeby <nsmeby@nmdp.org>

Joel Schneider <jschneid@nmdp.org> - modifications, refactoring,
documentation, etc.


=head1 COPYRIGHT AND LICENSE

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Copyright (C) 2002-2021, National Marrow Donor Program. All rights reserved.

See LICENSE file for license details.


=head1 HISTORY

ECS, the EMDIS Communication System, was originally designed and
implemented by the ZKRD (http://www.zkrd.de/).  This Perl implementation
of ECS was developed by the National Marrow Donor Program
(http://www.marrow.org/).

2004-03-12	
Canadian Blood Services - Tony Wai
Added MS Windows support for Windows 2000 and Windows XP
Added "DIRECTORY" inBox Protocol. This can interface with any mail
system that can output the new messages to text files.

2007-08-01
ZKRD - emdisadm@zkrd.de
Added new error report management using the new variable MAIL_LEVEL. 
All email to admin statements are removed.
In relation to the error code ECS.pm will send an email to admin or not.
Bugfix for the regular expression in sub read_ecs_message_id():
The regular expression now ignores spam tags in the subject line.
Hold lock in send_ecs_message until msg. is successfully send.
