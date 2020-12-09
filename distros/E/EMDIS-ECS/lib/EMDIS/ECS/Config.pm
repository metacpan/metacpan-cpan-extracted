#!/usr/bin/perl -w
#
# Copyright (C) 2002-2020 National Marrow Donor Program. All rights reserved.
#
# For a description of this module, please refer to the POD documentation
# embedded at the bottom of the file (e.g. perldoc EMDIS::ECS::Config).

package EMDIS::ECS::Config;

use Carp;
use Cwd;
use EMDIS::ECS qw($VERSION is_yes is_no);
use File::Basename;
use File::Spec::Functions qw(catdir catfile file_name_is_absolute rel2abs);
use strict;
use Text::ParseWords;
use vars qw($AUTOLOAD %ok_attr);

# ----------------------------------------------------------------------
# initialize %ok_attr hash with valid attribute names
BEGIN
{
    my @attrlist = qw(
        MSG_PROC MAIL_MRK THIS_NODE T_CHK T_SCN ERR_FILE LOG_FILE ADM_ADDR
        M_MSG_PROC BCK_DIR ACK_THRES LOG_LEVEL MAIL_LEVEL
        ECS_BIN_DIR ECS_DAT_DIR ECS_TO_DIR ECS_FROM_DIR ECS_DEBUG
        NODE_TBL NODE_TBL_LCK T_ADM_DELAY T_ADM_REMIND T_MSG_PROC
        ADAPTER_CMD ALWAYS_ACK GNU_TAR T_RESEND_DELAY
        SMTP_HOST SMTP_DOMAIN SMTP_TIMEOUT SMTP_DEBUG SMTP_FROM SMTP_PORT
        SMTP_USE_SSL SMTP_USE_STARTTLS SMTP_USERNAME SMTP_PASSWORD
        INBOX_PROTOCOL INBOX_HOST INBOX_PORT INBOX_TIMEOUT INBOX_DEBUG
        INBOX_FOLDER INBOX_USERNAME INBOX_PASSWORD INBOX_MAX_MSG_SIZE
        INBOX_DIRECTORY INBOX_USE_SSL INBOX_USE_STARTTLS
        MSG_PART_SIZE_DFLT
        GPG_HOMEDIR GPG_KEYID GPG_PASSPHRASE
        OPENPGP_CMD_ENCRYPT OPENPGP_CMD_DECRYPT
        PGP_HOMEDIR PGP_KEYID PGP_PASSPHRASE
        PGP2_CMD_ENCRYPT PGP2_CMD_DECRYPT
        ENABLE_AMQP
        AMQP_BROKER_URL AMQP_VHOST AMQP_ADDR_META AMQP_ADDR_MSG AMQP_ADDR_DOC
        AMQP_TRUSTSTORE AMQP_SSLCERT AMQP_SSLKEY AMQP_SSLPASS
        AMQP_USERNAME AMQP_PASSWORD
        AMQP_RECV_TIMEOUT AMQP_RECV_TIMELIMIT AMQP_SEND_TIMELIMIT
        AMQP_DEBUG_LEVEL AMQP_CMD_SEND AMQP_CMD_RECV
        EMDIS_MESSAGE_VERSION
    );
    for my $attr (@attrlist)
    {
        $ok_attr{$attr} = 1;
    }
}

# ----------------------------------------------------------------------
# use AUTOLOAD method to provide accessor methods
# (as described in Perl Cookbook)
sub AUTOLOAD
{
    my $this = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
                                      # (for EMDIS::ECS::Config, all valid
                                      # attribute names contain at least
                                      # one underscore)
    croak "invalid attribute method: ->$attr()" unless $ok_attr{$attr};
    return $this->{uc $attr};
}

# ----------------------------------------------------------------------
# Constructor.
# Returns EMDIS::ECS::Config reference if successful or error message if
# error encountered.
sub new
{
    my $class = shift;
    my $cfg_file = shift;
    my $skip_val = shift;
    $skip_val = '' unless defined $skip_val;
    my $this = {};
    bless $this, $class;
    $cfg_file = 'ecs.cfg' unless defined($cfg_file);
    $this->{CFG_FILE} = $cfg_file;
    $this->{CFG_CWD} = cwd();   # remember cwd in case it may be needed
    $this->_set_defaults();
    return $this if $cfg_file eq '';  # default config (used by ecs_setup)
    my $err = $this->_read_config();
    return $err if $err;
    return $this if $skip_val;        # skip validation (used by ecs_setup)
    $err = $this->_massage_config();
    return $err if $err;
    $err = $this->_validate_config();
    return $err if $err;
    return $this;
}

# ----------------------------------------------------------------------
# Display configuration data.
sub display
{
    my $this = shift;
    my $fmt = "%-20s   %s\n";
    print "ECS_CFG\n";
    print "---------------------------------------------------------------\n";
    for my $attr (sort keys %$this) {
        my $value = $this->{$attr};
        $value = '********' if $attr =~ /PASSWORD|PASSPHRASE/i;
        printf $fmt, $attr, $value;
    }
}

# ----------------------------------------------------------------------
# Parse config file data.
# Returns empty string if successful or error message if error encountered.
sub _read_config
{
    my $this = shift;

    # read config file
    my $err = '';
    if(not open CONFIG, "< $this->{CFG_FILE}")
    {
        return "Unable to open config file '$this->{CFG_FILE}': $!";
    }
    while(<CONFIG>)
    {
        chomp;               # trim EOL character(s)
        s/^\s+//;            # trim leading whitespace
        s/\s+$//;            # trim trailing whitespace
        next unless length;  # skip blank line
        next if /^#/;        # skip comment line
        my @fields = ();
        my @tokens = split '\|';  # split on pipe ('|') delimiter
        for my $token (@tokens)
        {
            if($#fields >= 0 and $fields[$#fields] =~ /\\$/)
            {
                # rejoin tokens separated by escaped pipe ('\|')
                chop($fields[$#fields]);
                $fields[$#fields] .= "|$token";
            }
            else
            {
                push(@fields, $token);
            }
        }
        # trim leading & trailing whitespace
        @fields = map { s/^\s+//; s/\s+$//; $_; } @fields;
        my ($attr, $value, $comment) = @fields;
        if($ok_attr{$attr})
        {
            # store value
            $this->{$attr} = $value;
        }
        else
        {
            $err .=
                "Unexpected input '$attr' at $this->{CFG_FILE} line $.\n";
        }
    }
    close CONFIG;
    if($err)
    {
        return $err .
            "Error(s) encountered while attempting to process " .
                "$this->{CFG_FILE}.";
    }

    return '';
}

# ----------------------------------------------------------------------
# Massage config data.
# Returns empty string if successful or error message if error encountered.
sub _massage_config
{
    my $this = shift;

    # initialize
    my $script_dir = dirname($0);
    $script_dir = rel2abs($script_dir)
        unless file_name_is_absolute($script_dir);
    my $config_dir = dirname($this->{CFG_FILE});
    $config_dir = rel2abs($config_dir)
        unless file_name_is_absolute($config_dir);

    # parse some special tokens
    for my $attr (keys %ok_attr)
    {
        if(exists $this->{$attr})
        {
            my $value = $this->{$attr};
            $value =~ s/__SCRIPT_DIR__/$script_dir/;
            $value =~ s/__CONFIG_DIR__/$config_dir/;
            $this->{$attr} = $value;
        }
    }

    # prepend ECS_DAT_DIR to non-absolute file/path names
    for my $attr (qw(ERR_FILE GPG_HOMEDIR LOG_FILE NODE_TBL NODE_TBL_LCK
                     PGP_HOMEDIR ECS_TO_DIR ECS_FROM_DIR))
    {
        $this->{$attr} = catfile($this->{ECS_DAT_DIR}, $this->{$attr})
            if exists($this->{$attr})
                and not ($this->{$attr} eq '')
                and not file_name_is_absolute($this->{$attr});
    }

    # prepend ECS_BIN_DIR to non-absolute executable command names
    for my $attr (qw(MSG_PROC M_MSG_PROC))
    {
        $this->{$attr} = catfile($this->{ECS_BIN_DIR}, $this->{$attr})
            if exists($this->{$attr})
                and not file_name_is_absolute($this->{$attr});
    }

    # compute derived values
    $this->{ECS_TMP_DIR} = catdir($this->{ECS_DAT_DIR}, 'tmp');
    if ( ! defined($this->{ECS_TO_DIR}) || $this->{ECS_TO_DIR} eq '')
    {
       $this->{ECS_DRP_DIR} = catdir($this->{ECS_DAT_DIR}, 'maildrop');
    }
    else
    {
       $this->{ECS_DRP_DIR} = $this->{ECS_TMP_DIR};
    }
    $this->{ECS_MBX_DIR} = catdir($this->{ECS_DAT_DIR}, 'mboxes');
    $this->{ECS_MBX_AMQP_STAGING_DIR} = catdir($this->{ECS_MBX_DIR}, 'amqp_staging');
    $this->{ECS_MBX_IN_DIR}     = catdir($this->{ECS_MBX_DIR}, 'in');
    $this->{ECS_MBX_IN_FML_DIR} = catdir($this->{ECS_MBX_DIR}, 'in_fml');
    $this->{ECS_MBX_OUT_DIR}    = catdir($this->{ECS_MBX_DIR}, 'out');
    $this->{ECS_MBX_TRASH_DIR}  = catdir($this->{ECS_MBX_DIR}, 'trash');
    $this->{ECS_MBX_STORE_DIR}  = catdir($this->{ECS_MBX_DIR}, 'store');
    for my $attr (qw(ECS_TMP_DIR ECS_DRP_DIR ECS_MBX_DIR
                     ECS_MBX_AMQP_STAGING_DIR ECS_MBX_IN_DIR
                     ECS_MBX_IN_FML_DIR ECS_MBX_OUT_DIR ECS_MBX_TRASH_DIR
                     ECS_MBX_STORE_DIR))
    {
        $ok_attr{$attr} = 1;
    }

    # parse more special tokens
    for my $attr (keys %ok_attr)
    {
        if(exists $this->{$attr})
        {
            my $value = $this->{$attr};
            $value =~ s/__MAILDROP_DIR__/$this->{ECS_DRP_DIR}/;
            $this->{$attr} = $value;
        }
    }

    # if indicated, assign SMTP_PORT default value
    if(not defined($this->{SMTP_PORT})) {
        $this->{SMTP_PORT} = 25;
        $this->{SMTP_PORT} = 465 if is_yes($this->{SMTP_USE_SSL});
        $this->{SMTP_PORT} = 587 if is_yes($this->{SMTP_USE_STARTTLS});
    }

    # if indicated, assign INBOX_PORT default value
    if(not defined($this->{INBOX_PORT})) {
        for($this->{INBOX_PROTOCOL})
        {
            /POP3/ and do {
                $this->{INBOX_PORT} = 110;
                $this->{INBOX_PORT} = 995 if is_yes($this->{INBOX_USE_SSL});
            };
            /IMAP/ and do {
                $this->{INBOX_PORT} = 143;
                $this->{INBOX_PORT} = 993 if is_yes($this->{INBOX_USE_SSL});
            };
        }
    }

    return '';
}

# ----------------------------------------------------------------------
# Assign default values to configuration settings.
# Note:  no default value for THIS_NODE, ADM_ADDR, ADAPTER_CMD, SMTP_DOMAIN,
# SMTP_FROM, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, INBOX_PORT,
# INBOX_FOLDER, INBOX_USERNAME, INBOX_PASSWORD, GPG_HOMEDIR, GPG_KEYID,
# GPG_PASSPHRASE, PGP_HOMEDIR, PGP_KEYID, PGP_PASSPHRASE,
# AMQP_BROKER_URL, AMQP_VHOST, AMQP_TRUSTSTORE, AMQP_SSLCERT AMQP_SSLKEY,
# AMQP_SSLPASS, AMQP_USERNAME, AMQP_PASSWORD
sub _set_defaults
{
    my $this = shift;
    $this->{MSG_PROC}          = "ecs_proc_msg";
    $this->{MAIL_MRK}          = "EMDIS";
    $this->{T_CHK}             = "7200";
    $this->{T_SCN}             = "3600";
    my $basename = basename($0);   # default;  use magic logfile name
    $this->{ERR_FILE}          = "$basename.err";
    $this->{LOG_FILE}          = "$basename.log";
    $this->{M_MSG_PROC}        = "ecs_proc_meta";
    $this->{BCK_DIR}           = "NONE";
    $this->{ACK_THRES}         = "100";
    $this->{ALWAYS_ACK}        = "NO";
    $this->{GNU_TAR}           = "/usr/bin/tar";
    $this->{ECS_BIN_DIR}       = "__SCRIPT_DIR__";
    $this->{ECS_DAT_DIR}       = "__CONFIG_DIR__";
    $this->{ECS_DEBUG}         = "0";
    $this->{NODE_TBL}          = "node_tbl.dat";
    $this->{NODE_TBL_LCK}      = "node_tbl.lock";
    $this->{T_ADM_DELAY}       = "0";
    $this->{T_ADM_REMIND}      = "86400";
    $this->{T_MSG_PROC}        = "3600";
    $this->{T_RESEND_DELAY}    = "14400";
    $this->{LOG_LEVEL}         = 1;
    $this->{MAIL_LEVEL}        = 2;
    $this->{MSG_PART_SIZE_DFLT} = "1073741824";
    $this->{SMTP_HOST}         = "smtp";
    $this->{SMTP_TIMEOUT}      = "60";
    $this->{SMTP_DEBUG}        = "0";
    $this->{SMTP_USE_SSL}      = "NO";
    $this->{SMTP_USE_STARTTLS} = "NO";
    $this->{INBOX_PROTOCOL}    = "POP3";
    $this->{INBOX_HOST}        = "mail";
    $this->{INBOX_FOLDER}      = "INBOX";
    $this->{INBOX_TIMEOUT}     = "60";
    $this->{INBOX_DEBUG}       = "0";
    $this->{INBOX_USE_SSL}     = "NO";
    $this->{INBOX_USE_STARTTLS} = "NO";
    $this->{INBOX_MAX_MSG_SIZE} = "1048576";
    $this->{OPENPGP_CMD_ENCRYPT} = '/usr/local/bin/gpg --armor --batch ' .
        '--charset ISO-8859-1 --force-mdc --logger-fd 1 --openpgp ' .
            '--output __OUTPUT__ --passphrase-fd 0 --quiet ' .
                '--recipient __RECIPIENT__ --recipient __SELF__ --yes ' .
                    '--sign --local-user __SELF__ --encrypt __INPUT__';
    $this->{OPENPGP_CMD_DECRYPT} = '/usr/local/bin/gpg --batch ' .
        '--charset ISO-8859-1 --logger-fd 1 --openpgp --output __OUTPUT__ ' .
            '--passphrase-fd 0 --quiet --yes --decrypt __INPUT__';
    $this->{PGP2_CMD_ENCRYPT} = '/usr/local/bin/pgp +batchmode +verbose=0 ' .
        '+force +CharSet=latin1 +ArmorLines=0 -o __OUTPUT__ ' .
            '-u __SELF__ -eats __INPUT__ __RECIPIENT__ __SELF__';
    $this->{PGP2_CMD_DECRYPT} = '/usr/local/bin/pgp +batchmode +verbose=0 ' .
        '+force +CharSet=latin1 -o __OUTPUT__ __INPUT__';
    $this->{ENABLE_AMQP}       = "NO";
    $this->{AMQP_RECV_TIMEOUT} = 5;
    $this->{AMQP_RECV_TIMELIMIT} = 300;
    $this->{AMQP_SEND_TIMELIMIT} = 60;
    $this->{AMQP_DEBUG_LEVEL}  = 0;
    $this->{AMQP_CMD_SEND}     = 'ecs_amqp_send.py';
    $this->{AMQP_CMD_RECV}     = 'ecs_amqp_recv.py';
}

# ----------------------------------------------------------------------
# Do a few sanity checks on the configuration data.
# Returns empty string if successful or error message if error encountered.
sub _validate_config
{
    my $this = shift;
    my @errors = ();
    my @required_attrlist = qw(
        MSG_PROC MAIL_MRK THIS_NODE T_CHK T_SCN ERR_FILE LOG_FILE ADM_ADDR
        M_MSG_PROC BCK_DIR ACK_THRES
        ECS_BIN_DIR ECS_DAT_DIR ECS_DEBUG
        NODE_TBL NODE_TBL_LCK T_ADM_REMIND T_MSG_PROC
        SMTP_HOST SMTP_DOMAIN SMTP_TIMEOUT SMTP_DEBUG SMTP_FROM
        INBOX_PROTOCOL INBOX_HOST INBOX_TIMEOUT INBOX_DEBUG
        INBOX_MAX_MSG_SIZE
        MSG_PART_SIZE_DFLT
    );

    # check for required values that are undefined
    for my $attr (@required_attrlist)
    {
        push(@errors, "$attr not defined.")
            unless exists($this->{$attr});
    }

    # validate INBOX_PROTOCOL
    
    # username/password not needed for DIRECTORY inbox
    if($this->{INBOX_PROTOCOL} !~ /DIRECTORY/i)
    { 
        for my $attr (qw( INBOX_USERNAME INBOX_PASSWORD))
        {
            push(@errors, "$attr not defined.")
                unless exists($this->{$attr});
        }
   }

    if($this->{INBOX_PROTOCOL} =~ /IMAP/i)
    {
        $this->{INBOX_PROTOCOL} = 'IMAP';  # force uppercase
        push(@errors,
            "INBOX_FOLDER not defined, but is required for IMAP protocol.")
            unless defined($this->{INBOX_FOLDER});
    }
    elsif($this->{INBOX_PROTOCOL} =~ /POP3/i)
    {
        $this->{INBOX_PROTOCOL} = 'POP3';  # force uppercase
    }
    elsif($this->{INBOX_PROTOCOL} =~ /DIRECTORY/i)
    {
        $this->{INBOX_PROTOCOL} = 'DIRECTORY';  # force uppercase
        push(@errors, "INBOX_DIRECTORY not defined, but is required for " .
            "DIRECTORY protocol.")
            unless defined($this->{INBOX_DIRECTORY});           
    }
    elsif($this->{INBOX_PROTOCOL} =~ /NONE/i)
    {
        $this->{INBOX_PROTOCOL} = 'NONE';  # force uppercase
    }
    else
    {
        push(@errors,
            "Unrecognized INBOX_PROTOCOL:  $this->{INBOX_PROTOCOL}");
    }

    if(is_yes($this->{ENABLE_AMQP}))
    {
        # sanity checks on AMQP configuration
        for my $attr (qw(AMQP_ADDR_META AMQP_ADDR_MSG AMQP_BROKER_URL
                         AMQP_CMD_SEND AMQP_CMD_RECV AMQP_DEBUG_LEVEL
                         AMQP_RECV_TIMEOUT AMQP_RECV_TIMELIMIT
                         AMQP_SEND_TIMELIMIT))
        {
            push(@errors, "$attr not defined, but is required for AMQP " .
                 "messaging.")
                unless exists($this->{$attr});
        }
    }

    # check whether an encryption method is configured
    if(!exists($this->{GPG_HOMEDIR}) && !exists($this->{PGP_HOMEDIR}))
    {
        push(@errors, "No encryption method configured.  Need to " .
             "configure either GPG_HOMEDIR or PGP_HOMEDIR, etc.");
    }

    # check OpenPGP encryption setup
    if(exists($this->{GPG_HOMEDIR}))
    {
        for my $attr (qw(GPG_HOMEDIR GPG_KEYID GPG_PASSPHRASE
                         OPENPGP_CMD_ENCRYPT OPENPGP_CMD_DECRYPT))
        {
            push(@errors, "$attr not defined, but is required for OpenPGP " .
                 "encryption setup (GPG_HOMEDIR = " .
                 $this->{GPG_HOMEDIR} . ").")
                unless exists($this->{$attr});
        }
    }

    # check PGP encryption setup
    if(exists($this->{PGP_HOMEDIR}))
    {
        for my $attr (qw(PGP_HOMEDIR PGP_KEYID PGP_PASSPHRASE
                         PGP2_CMD_ENCRYPT PGP2_CMD_DECRYPT))
        {
            push(@errors, "$attr not defined, but is required for PGP2 " .
                 "encryption setup (PGP_HOMEDIR = " .
                 $this->{PGP_HOMEDIR} . ").")
                unless exists($this->{$attr});
        }
    }

    # validate T_CHK
    if($this->{T_CHK} <= 0)
    {
        push(@errors,
            "T_CHK ($this->{T_CHK}) is required to be greater than zero.");
    }

    # validate T_SCN
    if($this->{T_SCN} <= 0)
    {
        push(@errors,
            "T_SCN ($this->{T_SCN}) is required to be greater than zero.");
    }

    # validate T_ADM_REMIND
    if($this->{T_ADM_REMIND} <= 0)
    {
        push(@errors,
             "T_ADM_REMIND ($this->{T_ADM_REMIND}) is required " .
             "to be greater than zero.");
    }

    # validate T_MSG_PROC
    if($this->{T_MSG_PROC} <= 0)
    {
        push(@errors,
             "T_MSG_PROC ($this->{T_MSG_PROC}) is required " .
             "to be greater than zero.");
    }

    # validate YES/NO values
    for my $name (qw(ALWAYS_ACK INBOX_USE_SSL INBOX_USE_STARTTLS SMTP_USE_SSL SMTP_USE_STARTTLS))
    {
        if(exists $this->{$name} and not is_yes($this->{$name})
            and not is_no($this->{$name}))
        {
            push(@errors, "Unrecognized $name (YES/NO) value:  " .
                $this->{$name});
        }
    }

    if(is_yes($this->{INBOX_USE_SSL})
        and is_yes($this->{INBOX_USE_STARTTLS}))
    {
        push(@errors, "INBOX_USE_SSL and INBOX_USE_STARTTLS " .
            "are both selected, but they are mutually exclusive.");
    }

    if(is_yes($this->{SMTP_USE_SSL})
        and is_yes($this->{SMTP_USE_STARTTLS}))
    {
        push(@errors, "SMTP_USE_SSL and SMTP_USE_STARTTLS " .
            "are both selected, but they are mutually exclusive.");
    }

    # check whether directories exist
    my @dirs = qw(ECS_BIN_DIR ECS_DAT_DIR ECS_TMP_DIR ECS_MBX_DIR
                  ECS_MBX_IN_DIR ECS_MBX_IN_FML_DIR ECS_MBX_OUT_DIR
                  ECS_MBX_TRASH_DIR ECS_MBX_STORE_DIR GPG_HOMEDIR
                  PGP_HOMEDIR);
    push(@dirs, 'BCK_DIR') if($this->{BCK_DIR} ne 'NONE');
    push(@dirs, 'ECS_DRP_DIR')
       if( ! defined($this->{ECS_TO_DIR})
           || $this->{ECS_TO_DIR} eq '');
    push(@dirs, 'ECS_MBX_AMQP_STAGING_DIR') if is_yes($this->{ENABLE_AMQP});
    for my $dir (@dirs)
    {
        if(exists $this->{$dir} and not -d $this->{$dir})
        {
            push(@errors,
                 "$dir ($this->{$dir}) directory not found.");
        }
    }

    # return error messages, if any
    if($#errors >= 0)
    {
        push(@errors,
            "Error(s) detected in configuration file $this->{CFG_FILE}");
        push(@errors, "Fatal configuration error(s) encountered.\n");
        return "\n" . join("\n", @errors);
    }
    return '';
}

1;

__DATA__

# embedded POD documentation
# for more info:  man perlpod

=head1 NAME

EMDIS::ECS::Config - ECS configuration data

=head1 SYNOPSIS

 use EMDIS::ECS::Config;
 $cfg = new EMDIS::ECS::Config("ecs.cfg");
 $cfg->display();
 print "ECS data directory: " . $cfg->ECS_DAT_DIR . "\n";

=head1 DESCRIPTION

ECS configuration object.  Parses configuration file, performs basic
validation of configuration, and provides interface to configuration
settings.

=head2 Modifiable Configuration Settings

=over 4

=item ACK_THRES

seq_num threshold for deleting outbound messages

=item ADAPTER_CMD

executable command for use by MSG_PROC;  for example:

 fml2pars.pl -mdf emdis-v31.mdf -proc msg_proc.pl $1 $2 $3

=item ADM_ADDR

email address(es) of ECS administrator(s) (separated by comma)

=item ALWAYS_ACK

YES/NO value.  If set to YES, the ecs_scan_mail program sends a MSG_ACK
meta message after each successfully processed incoming message.  Otherwise,
the ecs_chk_com program will periodically send MSG_ACK messages, for those
nodes with in_seq_ack less than in_seq.

=item AMQP_ADDR_DOC

AMQP queue (or address) for inbound documents.

=item AMQP_ADDR_META

AMQP queue (or address) for inbound META messages

=item AMQP_ADDR_MSG

AMQP queue (or address) for inbound EMDIS messages

=item AMQP_BROKER_URL

URL for AMQP broker, e.g. amqps://msg01.emdis.net

=item AMQP_CMD_RECV

AMQP receive command, e.g. ecs_amqp_recv.py

=item AMQP_CMD_SEND

AMQP send command, e.g. ecs_amqp_send.py

=item AMQP_DEBUG_LEVEL

AMQP debug output level, e.g. 0

=item AMQP_PASSWORD

Password for AMQP SASL PLAIN authentication (see also AMQP_USERNAME)

=item AMQP_RECV_TIMEOUT

Inactivity timeout threshold, in seconds, before tearing down AMQP
receiver link.  E.g. 5

=item AMQP_RECV_TIMELIMIT

Time limit, in seconds, after which AMQP_CMD_RECV command is
forcibly terminated.

=item AMQP_SEND_TIMELIMIT

Time limit, in seconds, after which AMQP_CMD_SEND command is
forcibly terminated.

=item AMQP_SSLCERT

Client-side SSL certificate for AMQP communications.
E.g. sslcert.pem (see also AMQP_SSLKEY, AMQP_SSLPASS)

=item AMQP_SSLKEY

Client-side SSL secret key for AMQP communications.
E.g. sslkey.pem (see also AMQP_SSLCERT, AMQP_SSLPASS)

=item AMQP_SSLPASS

Password for AMQP_SSLKEY (see also AMQP_SSLCERT)

=item AMQP_TRUSTSTORE

Trust store for verifying SSL connection to AMQP broker,
e.g. truststore.pem

=item AMQP_USERNAME

User name for AMQP SASL PLAIN authentication (see also AMQP_PASSWORD)

=item AMQP_VHOST

AMQP broker virtual host namespace (if needed), e.g. default

=item BCK_DIR

backup directory for incoming messages (or NONE)

=item ECS_BIN_DIR

directory containing ECS scripts (typically set to __SCRIPT_DIR__)

=item ECS_DAT_DIR

directory containing ECS node_tbl, mboxes subdirectories, etc.
(typically set to __CONFIG_DIR__)

=item ECS_DEBUG

debug level for ECS

=item ECS_FROM_DIR

location of a directory which has a subdirectory for each partner
node;  each subdirectory here holds files containing the decrypted
payload for messages from the corresponding partner node

=item ECS_TO_DIR

location of a directory which has a subdirectory for each partner
node;  each subdirectory here contains untransmitted outbound messages
for the corresponding partner node

=item ENABLE_AMQP

YES/NO value.  If set to YES, enable use of AMQP messaging.

=item ERR_FILE

full pathname of ECS error file (optional - defaults to program_name.err)

=item GNU_TAR

location of GNU tar program;  required for ecstool --archive command

=item GPG_HOMEDIR

home directory for GnuPG (defines value for GNUPGHOME environment variable)

=item GPG_KEYID

GnuPG key id for this node, for signing encrypted messages and creating
encrypted messages that are decryptable by self

=item GPG_PASSPHRASE

passphrase for GnuPG private key

=item INBOX_DEBUG

debug level for mailbox interactions (using POP3/IMAP)

=item INBOX_FOLDER

inbox folder, used by IMAP only

=item INBOX_HOST

POP3/IMAP server name

=item INBOX_MAX_MSG_SIZE

size limit for incoming email messages

=item INBOX_PASSWORD

password for POP3/IMAP inbox

=item INBOX_PORT

POP3/IMAP server port (default 110/143, or 995/993 if INBOX_USE_SSL is YES)

=item INBOX_PROTOCOL

inbox protocol:  DIRECTORY, POP3, IMAP, or NONE

=item INBOX_TIMEOUT

time limit for mailbox interactions		

=item INBOX_USE_SSL

YES/NO value; default is NO.  If set to YES, when reading inbox, use immediate
SSL/TLS encryption on the POP3 or IMAP server connection.
Mutually exclusive with INBOX_USE_STARTTLS.

=item INBOX_USE_STARTTLS

YES/NO value; default is NO.  If set to YES, when reading inbox, use STARTTLS
to initiate SSL/TLS encryption on the POP3 or IMAP server connection.
Mutually exclusive with INBOX_USE_SSL.

=item INBOX_USERNAME

username for POP3/IMAP inbox

=item DIRECTORY
	  
Directory for message files for the DIRECTORY protocol 

=item INBOX_USERNAME

username for POP3/IMAP mailbox

=item LOG_FILE

full pathname of ECS log file (optional - defaults to program_name.log)

=item LOG_LEVEL

Numeric value which controls level of messages written to log files
(0=debug, 1=info, 2=warn, 3=error, 4=fatal).

=item M_MSG_PROC

command executed to process ECS meta-message

=item MAIL_LEVEL

Numeric value which controls level of messages emailed to ECS
administrators (0=debug, 1=info, 2=warn, 3=error, 4=fatal).

=item MAIL_MRK

ECS mark in subject header of incoming email

=item MSG_PART_SIZE_DFLT

Default message part maximum size, in bytes.  Applies to nodes which do not
have a msg_part_size value specified in the NODE_TBL. A node-specific,
non-zero msg_part_size value in the NODE_TBL takes precedence over
MSG_PART_SIZE_DFLT for that node.  Refer to the EMDISCORD email parts RFC
(RFC-20091021-EmailParts.pdf) for additional information about message
parts.

=item MSG_PROC

command executed to process FML message

=item NODE_TBL

basename of node_tbl

=item NODE_TBL_LCK

name of node_tbl lockfile

=item OPENPGP_CMD_DECRYPT

template for OpenPGP decrypt command

=item OPENPGP_CMD_ENCRYPT

template for OpenPGP encrypt command

=item PGP_HOMEDIR

home directory for PGP (defined value for PGPPATH environment variable)

=item PGP_KEYID

PGP key id for this node, for signing encrypted messages and creating
encrypted messages that are decryptable by self

=item PGP_PASSPHRASE

passphrase for PGP private key

=item PGP2_CMD_DECRYPT

template for PGP2 decrypt command

=item PGP2_CMD_ENCRYPT

template for PGP2 encrypt command

=item SMTP_DEBUG

debug level for outgoing email (SMTP) communications

=item SMTP_DOMAIN

mail domain

=item SMTP_FROM

email "from" address

=item SMTP_HOST

SMTP server hostname

=item SMTP_PASSWORD

password for SMTP server

=item SMTP_PORT

SMTP server port, typically 25, 465, or 587 (465 if SMTP_USE_SSL is selected,
587 if SMTP_USE_STARTTLS is selected)

=item SMTP_TIMEOUT

maximum time, in seconds, to wait for response from SMTP server

=item SMTP_USE_SSL

YES/NO value; default is NO.  If set to YES, when sending email, use immediate
SSL/TLS encryption on the SMTP server connection.
Mutually exclusive with SMTP_USE_STARTTLS.

=item SMTP_USE_STARTTLS

YES/NO value; default is NO.  If set to YES, when sending mail, use STARTTLS
to initiate SSL/TLS encryption on the SMTP server connection.
Mutually exclusive with SMTP_USE_SSL.

=item SMTP_USERNAME

username for SMTP server

=item T_ADM_DELAY

seconds after detection of communication loss to delay notification of
administrator (this may be useful to reduce  the number of comm loss "nag"
emails)

=item T_ADM_REMIND

seconds to wait before repeating admin notification of communication loss

=item T_CHK

seconds between ECS connection checks

=item T_MSG_PROC

message processing time limit, in seconds

=item T_RESEND_DELAY

seconds to delay before automatically sending a batch of RE_SEND requests

=item T_SCN

seconds between scans of email inbox

=item THIS_NODE

EMDIS id of this ECS node

=back

=head2 Derived Configuration Settings

=over 4

=item ECS_DRP_DIR

"maildrop" directory:  contains outbound FML messages created by the adapter
program or the ecstool --maildrop command

=item ECS_MBX_ACTIVE_DIR

"active" mailbox subdirectory (not currently used in this ECS implementation)

=item ECS_MBX_DIR

"mboxes" (mailbox) directory:  contains mailbox subdirectories

=item ECS_MBX_IN_DIR

"in" mailbox subdirectory:  all ECS messages received via email

=item ECS_MBX_OUT_DIR

"out" mailbox subdirectory:  all messages sent to local ECS administrator 

=item ECS_MBX_STORE_DIR

"store" mailbox subdirectory:  ECS messages waiting to be processed,
including early messages and any message from an unknown node

=item ECS_MBX_TRASH_DIR

"trash" mailbox subdirectory:  ECS messages that arrived more than one time
which were discarded and never processed

=item ECS_TMP_DIR

"tmp" directory:  temporary files, typically ECS messages being
passed to message processing scripts that are deleted after processing

=back

=head1 SEE ALSO

EMDIS::ECS, EMDIS::ECS::FileBackedMessage, EMDIS::ECS::LockedHash,
EMDIS::ECS::Message, ecs_setup

=head1 AUTHOR

Joel Schneider <jschneid@nmdp.org>

=head1 COPYRIGHT AND LICENSE

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Copyright (C) 2002-2020 National Marrow Donor Program. All rights reserved.

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
