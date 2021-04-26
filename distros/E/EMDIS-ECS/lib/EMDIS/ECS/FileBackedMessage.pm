#!/usr/bin/perl -w
#
# Copyright (C) 2010-2021 National Marrow Donor Program. All rights reserved.
#
# For a description of this module, please refer to the POD documentation
# embedded at the bottom of the file (e.g. perldoc EMDIS::ECS::FileBackedMessage).

package EMDIS::ECS::FileBackedMessage;

use EMDIS::ECS qw($ECS_CFG $ECS_NODE_TBL $FILEMODE $VERSION ecs_is_configured
           format_datetime format_doc_filename format_msg_filename
           log_debug log_info log_warn log_error log_fatal
           send_amqp_message send_encrypted_message send_email
           dequote trim is_yes);
use Fcntl qw(:DEFAULT :flock);
use File::Basename;
use File::Spec::Functions qw(catdir catfile);
use File::Temp qw(tempfile);
use IO::File;
use strict;

# ----------------------------------------------------------------------
# Constructor.
# If error encountered, returns error message instead of object reference.
sub new
{
    my $arg1 = shift;
    my $this;
    if(ref $arg1)
    {
        # invoked as instance method
        $this = $arg1;
    }
    else
    {
        # invoked as class method
        $this = {};
        bless $this, $arg1;
    }

    my $err = '';
    my ($sender_node_id, $seq_num, $filename);
    my $argc = scalar(@_);
    if($argc <= 1)
    {
        $filename = shift;
    }
    elsif($argc == 3)
    {
        ($sender_node_id, $seq_num, $filename) = @_;
        $this->{sender_node_id} = $sender_node_id if $sender_node_id;
        $this->{seq_num} = $seq_num if $seq_num;
    }
    else
    {
        return "Illegal usage -- expected 0, 1, or 3 parameters: " .
            "[filename] or <sender_node_id>, <seq_num>, <filename>";
    }

    # set presumed message type flags - can be overridden by email headers or subject
    $this->{is_ecs_message} = 1;
    $this->{is_meta_message} = '';
    $this->{is_document} = '';
    if(defined $filename and $filename =~ /(\.doc|\.doc\.xml)$/io)
    {
        # filename ending in .doc or .doc.xml indicates document (not message)
        $this->{is_ecs_message} = '';
        $this->{is_meta_message} = '';
        $this->{is_document} = 1;
    }

    $this->{temp_files} = [];
    $this->{is_closed} = 0;

    # if $filename not specified, read input from stdin
    if(not $filename)
    {
        # read from stdin, create temp file
        my $template = sprintf('%s_XXXX', format_datetime(time,
            '%04d%02d%02d_%02d%02d%02d'));
        return "Unable to create temp file from stdin: ECS is not configured!"
            unless ecs_is_configured();
        my $fh;
        ($fh, $filename) = tempfile($template,
            DIR => catdir($ECS_CFG->ECS_TMP_DIR),
            SUFFIX => '.msg');
        binmode(STDIN);
        binmode($fh);
        while(1)
        {
            my $buffer;

            my $readlen = read STDIN, $buffer, 65536;
            if(not defined $readlen)
            {
                $err = "Unexpected problem reading STDIN: $!";
                last;
            }

            last if $readlen == 0;

            if(not print $fh $buffer)
            {
                $err = "Unexpected problem writing file $filename: $!";
                last;
            }
        }
        close $fh;
        if($err)
        {
            unlink $filename;
            return $err;
        }
        push @{$this->{temp_files}}, $filename;
    }

    $this->{filename} = $filename;
    my $file_handle;
    return "Unable to open input file $filename: $!"
        unless  open $file_handle, "+< $filename";
    $this->{file_handle} = $file_handle;
    binmode $file_handle;

    # get exclusive lock (with retry loop)
    # protects against reading a file while another process is writing it
    my $locked = '';
    for my $retry (1..5)
    {
        $locked = flock $file_handle, LOCK_EX | LOCK_NB;
        last if $locked;
    }
    if(!$locked)
    {
        $err = "Unable to lock input file $filename: $!";
        close $file_handle;
        return $err;
    }

    my $email_headers = '';
    my $data_offset = 0;

    # attempt to read email headers only if sender_node_id not yet defined
    if(not exists $this->{sender_node_id})
    {
        # attempt to read email headers from file, determine data offset
        my $buf;
        while(1)
        {
            my $bytecount = read $file_handle, $buf, 1;

            if(not defined $bytecount)
            {
                $err = "Unexpected problem reading from file $filename: $!";
                last;
            }

            if($bytecount > 0)
            {
                $email_headers .= $buf;
                $data_offset++;

                # first empty line ends potential email header
                last if $email_headers =~ /\r?\n\r?\n$/so;
            }
            elsif($bytecount == 0 or $data_offset >= 1048576)
            {
                # assume file does not contain email header
                # if EOF encountered or no empty line found in first X bytes
                $data_offset = 0;
                last;
            }
        }
        if($err)
        {
            close $file_handle;
            return $err;
        }
    }

    if($data_offset > 0)
    {
        # convert headers to more easily parseable format, store in this obj
        $email_headers =~ s/\r?\n/\n/go;

        # look for "Subject" line
        if($email_headers =~ /^Subject:\s*(.+?)$/imo)
        {
            $this->{subject} = $1;
            $this->{email_headers} = $email_headers;
            $this->{data_offset} = $data_offset;
        }
    }

    # absence of "Subject" line indicates file contains data only
    if(not exists $this->{subject})
    {
        $this->{data_offset} = 0;
        return $this;
    }

    # parse "Subject" into MAIL_MRK:sender_node_id[:seqnum]
    my $mail_mrk = 'EMDIS';
    if(ecs_is_configured())
    {
        $mail_mrk = $ECS_CFG->MAIL_MRK;
    }
    else
    {
        warn "ECS not configured, using MAIL_MRK = '$mail_mrk'\n";
    }
    if($this->{subject} =~ /$mail_mrk:(\S+?):(\d+)(:(\d+)\/(\d+))?\s*$/i)
    {
        # regular message
        $this->{is_ecs_message} = 1;
        $this->{is_meta_message} = '';
        $this->{is_document} = '';
        $this->{sender_node_id} = $1;
        $this->{seq_num} = $2;
        $this->{part_num} = $4 if defined $4;
        $this->{num_parts} = $5 if defined $5;
        if(exists $this->{part_num} and exists $this->{num_parts}
           and $this->{part_num} > $this->{num_parts})
        {
            close $file_handle;
            return "part_num is greater than num_parts: " . $this->{subject};
        }
    }
    elsif($this->{subject} =~ /$mail_mrk:(\S+?):(\d+):DOC\s*$/io) {
        # document
        $this->{sender_node_id} = $1;
        $this->{is_ecs_message} = '';
        $this->{is_meta_message} = '';
        $this->{is_document} = 1;
        $this->{seq_num} = $2;
    }
    elsif($this->{subject} =~ /$mail_mrk:(\S+)\s*$/i)
    {
        # meta-message
        $this->{sender_node_id} = $1;
        $this->{is_ecs_message} = 1;
        $this->{is_meta_message} = 1;
        $this->{is_document} = '';
    }
    else
    {
        # subject line indicates this is not an ECS message or document
        $this->{is_ecs_message} = '';
        $this->{is_meta_message} = '';
        $this->{is_document} = '';
    }

    return $err if $err;

    return $this;
}

# ----------------------------------------------------------------------
# prepare for object destruction: close $this->{file_handle}, delete
# temp files
sub cleanup
{
    my $this = shift;
    die "cleanum() must only be called as an instance method!"
        unless ref $this;
    close $this->{file_handle}
        if exists $this->{file_handle};
    foreach my $temp_file (@{$this->{temp_files}})
    {
        unlink $temp_file;
    }
    $this->{is_closed} = 1;
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub data_offset
{
    my $this = shift;
    die "data_offset() must only be called as an instance method!"
        unless ref $this;
    return $this->{data_offset};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub email_headers
{
    my $this = shift;
    die "email_headers() must only be called as an instance method!"
        unless ref $this;
    return $this->{email_headers};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub filename
{
    my $this = shift;
    die "filename() must only be called as an instance method!"
        unless ref $this;
    return $this->{filename};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub hub_rcv
{
    my $this = shift;
    die "hub_rcv() must only be called as an instance method!"
        unless ref $this;
    return $this->{hub_rcv};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub hub_snd
{
    my $this = shift;
    die "hub_snd() must only be called as an instance method!"
        unless ref $this;
    return $this->{hub_snd};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub is_ecs_message
{
    my $this = shift;
    die "is_ecs_message() must only be called as an instance method!"
        unless ref $this;
    return $this->{is_ecs_message};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub is_meta_message
{
    my $this = shift;
    die "is_meta_message() must only be called as an instance method!"
        unless ref $this;
    return $this->{is_meta_message};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub is_document
{
    my $this = shift;
    die "is_document() must only be called as an instance method!"
        unless ref $this;
    return $this->{is_document};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub num_parts
{
    my $this = shift;
    die "num_parts() must only be called as an instance method!"
        unless ref $this;
    return $this->{num_parts};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub part_num
{
    my $this = shift;
    die "part_num() must only be called as an instance method!"
        unless ref $this;
    return $this->{part_num};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub sender
{
    my $this = shift;
    die "sender() must only be called as an instance method!"
        unless ref $this;
    return $this->{sender_node_id};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub sender_node_id
{
    my $this = shift;
    die "sender_node_id() must only be called as an instance method!"
        unless ref $this;
    return $this->{sender_node_id};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub seq_num
{
    my $this = shift;
    die "seq_num() must only be called as an instance method!"
        unless ref $this;
    return $this->{seq_num};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub subject
{
    my $this = shift;
    die "subject() must only be called as an instance method!"
        unless ref $this;
    return $this->{subject};
}

# ----------------------------------------------------------------------
# Accessor method (read only)
sub temp_files
{
    my $this = shift;
    die "temp_files() must only be called as an instance method!"
        unless ref $this;
    return @{$this->{temp_files}};
}

# ----------------------------------------------------------------------
# object destructor, called by perl garbage collector
sub DESTROY
{
    my $this = shift;
    die "DESTROY() must only be called as an instance method!"
        unless ref $this;
    $this->cleanup unless $this->{is_closed};
}

# ----------------------------------------------------------------------
# read first portion of message, attempt to extract HUB_SND and HUB_RCV
# (deprecated -- may be called explicitly, but is no longer used by FileBackedMessage constructor)
sub inspect_fml
{
    my $this = shift;
    return "inspect_fml() must only be called as an instance method!"
        unless ref $this;
    return "inspect_fml(): this FileBackedMessage object is closed!"
        if $this->{is_closed};

    # read first part of FML payload, look for HUB_SND, HUB_RCV

    return "Unable to position file pointer for file $this->{filename}" .
        " to position $this->{data_offset}: $!"
        unless seek $this->{file_handle}, $this->{data_offset}, 0;
    my $fml;
    my $bytecount = read $this->{file_handle}, $fml, 65536;
    return "Unable to read from file " . $this->{filename} . ": $!"
        unless defined $bytecount;

    # compute is_ecs_message and is_meta_message
    if($fml =~ /^\s*(BLOCK_BEGIN\s+\w+\s*;\s*)?\w+\s*:/iso)
    {
        $this->{is_ecs_message} = 1;
        $this->{is_meta_message} = '';
        $this->{is_document} = '';
    }
    elsif($fml =~ /^\s*msg_type\s*=\s*\S+/isom)
    {
        $this->{is_ecs_message} = 1;
        $this->{is_meta_message} = 1;
        $this->{is_document} = '';
        return '';
    }
    else
    {
        $this->{is_ecs_message} = '';
        $this->{is_meta_message} = '';
        $this->{is_document} = '';
        return '';
    }

    # Note: this code only understands the simple forms of FML assignments
    # (not the extended /FIELDS form)

    # look for HUB_RCV
    if($fml =~ /HUB_RCV\s*=\s*([^,;]+)/iso) # presumes [^,;] in HUB_RCV
    {
        $this->{hub_rcv} = dequote(trim($1));
    }

    # look for HUB_SND
    if($fml =~ /HUB_SND\s*=\s*([^,;]+)/iso) # presumes [^,;] in HUB_SND
    {
        $this->{hub_snd} = dequote(trim($1));
    }

    return '';
}

# ----------------------------------------------------------------------
sub send_this_message
{
    my $this = shift;
    return "send_this_message() must only be called as an instance method!"
        unless ref $this;
    return "send_this_message(): this FileBackedMessage object is closed!"
        if $this->{is_closed};
    return "send_this_message(): this FileBackedMessage object represents " .
        "only a partial message!"
        if defined $this->{num_parts} and $this->{num_parts} > 1;

    # initialize
    my $rcv_node_id = shift;
    my $is_re_send = shift;
    my $part_num = shift;
    return "send_this_message(): ECS has not been configured."
        unless ecs_is_configured();
    my $cfg = $ECS_CFG;
    my $node_tbl = $ECS_NODE_TBL;
    my $err = '';

    return "send_this_message(): Missing \$rcv_node_id!"
        unless defined $rcv_node_id and $rcv_node_id;

    # lock node_tbl, look up $rcv_node_id
    my $was_locked = $node_tbl->LOCK;
    if(not $was_locked)
    {
        $node_tbl->lock()  # lock node_tbl
            or return "send_this_message(): unable to lock node_tbl: " .
                $node_tbl->ERROR;
    }
    my $node = $node_tbl->read($rcv_node_id);
    if(not $node)
    {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "send_this_message(): node not found: $rcv_node_id";
    }
    if(not $node->{addr})
    {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "send_this_message(): addr not defined for node: $rcv_node_id";
    }

    # compute or assign message seq_num
    my $seq_num = '';
    if($is_re_send and not $this->{is_document})
    {
        # sanity checks
        if(not defined $this->{seq_num})
        {
            $node_tbl->unlock() unless $was_locked; # unlock node_tbl if needed
            return "send_this_message(): seq_num not defined for RE_SEND";
        }
        if($this->{seq_num} > $node->{out_seq})
        {
            $node_tbl->unlock() unless $was_locked; # unlock node_tbl if needed
            return "send_this_message(): seq_num for RE_SEND (" .
                $this->{seq_num} . ") is greater than out_seq for node " .
                "$rcv_node_id (" . $node->{out_seq} . ")!";
        }
        $seq_num = $this->{seq_num};
    }
    elsif($is_re_send and $this->{is_document})
    {
        # sanity checks
        if(not defined $this->{seq_num})
        {
            $node_tbl->unlock() unless $was_locked; # unlock node_tbl if needed
            return "send_this_message(): seq_num not defined for DOC_RE_SEND";
        }
        if($this->{seq_num} > $node->{doc_out_seq})
        {
            $node_tbl->unlock() unless $was_locked; # unlock node_tbl if needed
            return "send_this_message(): seq_num for DOC_RE_SEND (" .
                $this->{seq_num} . ") is greater than doc_out_seq for node " .
                "$rcv_node_id (" . $node->{doc_out_seq} . ")!";
        }
        $seq_num = $this->{seq_num};
    }
    elsif($this->{is_document})
    {
        # automatically get next (doc) sequence number
        $node->{doc_out_seq}++;
        $seq_num = $node->{doc_out_seq};
    }
    elsif(not $this->{is_meta_message})
    {
        # only allow $part_num to be specified if this is a RE_SEND request
        if($part_num)
        {
            $node_tbl->unlock() unless $was_locked; # unlock node_tbl if needed
            return "send_this_message(): part_num specified ($part_num), for " .
                "non- RE_SEND request!";
        }
        # automatically get next (msg) sequence number
        $node->{out_seq}++;
        $seq_num = $node->{out_seq};
    }

    # compute message part size
    my $msg_part_size = $cfg->MSG_PART_SIZE_DFLT;
    if(defined $node->{msg_part_size} and $node->{msg_part_size} > 0)
    {
        $msg_part_size = $node->{msg_part_size};
    }

    # compute data size
    my $file_size = (stat $this->{file_handle})[7];
    my $data_size = $file_size - $this->{data_offset};
    if($data_size <= 0)
    {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "send_this_message(): data_size is <= 0 ($data_size)!";
    }

    # for document, force num_parts = 1
    if($this->{is_document})
    {
        $msg_part_size = $data_size;
    }

    # compute num_parts
    my $num_parts = int($data_size / $msg_part_size);
    $num_parts++ if ($data_size % $msg_part_size) > 0;
    # num_parts should be 1 for meta message
    if($this->{is_meta_message} and $num_parts > 1)
    {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "send_this_message(): num_parts cannot be > 1 for meta message!";
    }
    # $part_num cannot be greater than $num_parts
    if(defined $part_num and $part_num and $part_num > $num_parts)
    {
        $node_tbl->unlock() unless $was_locked;  # unlock node_tbl if needed
        return "send_this_message(): part_num ($part_num) cannot be greater " .
            "than num_parts ($num_parts)!";
    }

    # compute base subject
    my $subject = $cfg->MAIL_MRK . ':' . $cfg->THIS_NODE;
    $subject .= ":$seq_num" if $seq_num;
    $subject .= ":DOC" if $this->{is_document};

    if($is_re_send)
    {
        # to save disk space, don't copy message to file for RE_SEND
        log_info("send_this_message(): transmitting $rcv_node_id RE_SEND " .
                 "message $seq_num" . ($part_num ? ":$part_num" : '') . "\n");
    }
    else
    {
        # copy message to file (for non- RE_SEND)

        my $filename;

        if($this->{is_meta_message})
        {
            # copy meta message to mboxes/out subdirectory
            $filename = sprintf("%s_%s_%s.msg",
                                $cfg->THIS_NODE, $rcv_node_id, "META");
            my $dirname = $cfg->ECS_MBX_OUT_DIR;
            # create directory if it doesn't already exist
            mkdir $dirname unless -e $dirname;
            $filename = catfile($dirname, $filename);
        }
        else
        {
            # copy regular message or document file to mboxes/out_NODE subdirectory
            if($this->{is_document})
            {
                $filename = format_doc_filename($rcv_node_id, $seq_num);
            }
            else
            {
                $filename = format_msg_filename($rcv_node_id, $seq_num);
            }
            # create directory if it doesn't already exist
            my $dirname = dirname($filename);
            mkdir $dirname unless -e $dirname;
        }

        # don't overwrite $filename file if it already exists
        my $fh;
        if(-e $filename)
        {
            my $template = $filename . "_XXXXXX";
            ($fh, $filename) = tempfile($template);
            return "send_this_message(): unable to open _XXXX file: " .
                "$filename"
                    unless $fh;
        }
        else
        {
            $fh = new IO::File;
            return "send_this_message(): unable to open file: " .
                "$filename"
                unless $fh->open("> $filename");
        }

        print $fh "Subject: $subject\n";
        print $fh "To: $node->{addr}\n";
        print $fh "From: " . $cfg->SMTP_FROM . "\n\n";
        # copy data to $fh
        $err = "Unable to position file pointer for file $this->{filename}" .
            " to position $this->{data_offset}: $!"
            unless seek $this->{file_handle}, $this->{data_offset}, 0;
        my $buffer;
        while(1)
        {
            if($err)
            {
                $node_tbl->unlock() unless $was_locked;  # unlock if needed
                close $fh;
                unlink $filename;
                return $err;
            }

            my $bytecount = read $this->{file_handle}, $buffer, 65536;
            if(not defined $bytecount)
            {
                $err = "send_this_message(): Problem reading input file " .
                    "$this->{filename}: $!";
            }
            elsif($bytecount == 0)
            {
                last; # EOF
            }
            else
            {
                print $fh $buffer
                    or $err = "send_this_message(): Problem writing output " .
                        "file $filename: $!";
            }
        }
        close $fh;
        chmod $FILEMODE, $filename;
    }

    my $custom_headers = {};
    $custom_headers->{'x-emdis-hub-rcv'} = $rcv_node_id;
    $custom_headers->{'x-emdis-hub-snd'} = $cfg->THIS_NODE;

    if($num_parts == 1)
    {
        # read all data, send single email message
        $err = "send_this_message(): Unable to position file pointer for " .
            "file $this->{filename} to position $this->{data_offset}: $!"
            unless seek $this->{file_handle}, $this->{data_offset}, 0;

        if(not $err)
        {
            my $all_data;
            my $bytecount = read $this->{file_handle}, $all_data, $data_size;

            if(not defined $bytecount)
            {
                $err = "send_this_message(): Problem reading input file " .
                    "$this->{filename}: $!";
            }
            elsif($bytecount != $data_size)
            {
                $err = "send_this_message(): Problem reading from input file " .
                    "$this->{filename}: expected $msg_part_size bytes, " .
                        "found $bytecount bytes.";
            }
            elsif($this->{is_meta_message}
                  and ($node->{encr_meta} !~ /true/io))
            {
                # don't encrypt meta-message
                if(is_yes($cfg->ENABLE_AMQP) and exists $node->{amqp_addr_meta} and $node->{amqp_addr_meta}) {
                    # send meta-message via AMQP (if indicated by node config)
                    $err = send_amqp_message(
                        $node->{amqp_addr_meta},
                        $subject,
                        $node,
                        $custom_headers,
                        $all_data);
                }
                elsif(is_yes($node->{amqp_only})) {
                    $err = "send_this_message(): Unable to send email META message " .
                        "to node $rcv_node_id: amqp_only selected.";
                }
                else {
                    $err = send_email($node->{addr}, $subject, undef, $all_data);
                }
            }
            else
            {
                # send encrypted message
                $err = send_encrypted_message(
                    $node->{encr_typ},
                    $node->{addr_r},
                    $node->{addr},
                    $node->{encr_out_keyid},
                    $node->{encr_out_passphrase},
                    $node,
                    $subject,
                    $custom_headers,
                    $all_data);
            }
        }
    }
    else
    {
        # process message parts ...

        my $min_part_num = 1;
        my $max_part_num = $num_parts;
        if($part_num)
        {
            # if $part_num specified, limit to that $part_num
            $min_part_num = $part_num;
            $max_part_num = $part_num;
        }

        # iterate through message part(s), send email message(s)
        my $parts_sent = 0;
        for($part_num = $min_part_num; $part_num <= $max_part_num; $part_num++)
        {
            my $part_offset = $this->{data_offset} +
                ($part_num -1) * $msg_part_size;
            $err = "send_this_message(): Unable to position file pointer for " .
                "file $this->{filename} to position $this->{data_offset}: $!"
                unless seek $this->{file_handle}, $part_offset, 0;

            if(not $err)
            {
                my $part_data;
                my $bytecount = read $this->{file_handle}, $part_data,
                    $msg_part_size;

                if(not defined $bytecount)
                {
                    $err = "send_this_message(): Problem reading input file " .
                        "$this->{filename}: $!";
                }
                elsif($part_num < $num_parts and $bytecount != $msg_part_size)
                {
                    $err = "send_this_message(): Problem reading $rcv_node_id " .
                        "message part $part_num/$num_parts from input file " .
                        "$this->{filename}: expected $msg_part_size bytes, " .
                        "found $bytecount bytes.";
                }
                elsif($bytecount <= 0)
                {
                    $err = "send_this_message(): Problem reading $rcv_node_id " .
                        "message part $part_num/$num_parts from input file " .
                            "$this->{filename}: found $bytecount bytes.";
                }
                else
                {
                    # send encrypted email message
                    $err = send_encrypted_message(
                        $node->{encr_typ},
                        $node->{addr_r},
                        $node->{addr},
                        $node->{encr_out_keyid},
                        $node->{encr_out_passphrase},
                        $node,
                        "$subject:$part_num/$num_parts",
                        $custom_headers,
                        $part_data);
                }
            }

            if($err)
            {
                if($parts_sent == 0)
                {
                    # nothing sent yet, so quit now (possible smtp problem?)
                    last;
                }
                else
                {
                    # part of message was sent, so log error and continue
                    log_error($err);
                    $err = '';
                }
            }
            else
            {
                $parts_sent++;
            }
        }
    }

    if(not $err)
    {
        # update node last_out, possibly out_seq
        $node->{last_out} = time();
        $err = $node_tbl->ERROR
            unless $node_tbl->write($rcv_node_id, $node);
    }
    $node_tbl->unlock()  # unlock node_tbl if needed
        unless $was_locked;

    return $err;
}

1;

__DATA__

# embedded POD documentation
# for more info:  man perlpod

=head1 NAME

EMDIS::ECS::FileBackedMessage - an ECS email message

=head1 SYNOPSIS

 use EMDIS::ECS::FileBackedMessage;

 $msg = new EMDIS::ECS::FileBackedMessage($message_file);
 die "unable to define message: $msg\n" unless ref $msg;

 $msg = EMDIS::ECS::FileBackedMessage($sender_node_id, $seq_num, $data_file);
 die "unable to define message: $msg\n" unless ref $msg;

 $msg->send_this_message($rcv_node_id);

=head1 DESCRIPTION

ECS file-backed message object, capable of handling very large messages.

The send_this_message subroutine of this object knows how to split a large data
file into multiple encrypted email messages, as specified by the EMDISCORD RFC.

=head1 SEE ALSO

EMDIS::ECS, EMDIS::ECS::Config, EMDIS::ECS::LockedHash, EMDIS::ECS::Message

=head1 AUTHOR

Joel Schneider <jschneid@nmdp.org>

=head1 COPYRIGHT AND LICENSE

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Copyright (C) 2010-2021 National Marrow Donor Program. All rights reserved.

See LICENSE file for license details.

=head1 HISTORY

ECS, the EMDIS Communication System, was originally designed and
implemented by the ZKRD (http://www.zkrd.de/).  This Perl implementation
of ECS was originally developed by the National Marrow Donor Program
(http://www.marrow.org/).
