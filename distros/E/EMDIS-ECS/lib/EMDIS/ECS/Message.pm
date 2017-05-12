#!/usr/bin/perl -w
#
# Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.
#
# For a description of this module, please refer to the POD documentation
# embedded at the bottom of the file (e.g. perldoc EMDIS::ECS::Message).

package EMDIS::ECS::Message;

use EMDIS::ECS qw($ECS_CFG $VERSION ecs_is_configured
           pgp2_decrypt openpgp_decrypt);
use IO::File;
use MIME::QuotedPrint qw( decode_qp );
use strict;
use vars qw($EOL_PATTERN);

BEGIN {
    $EOL_PATTERN = "\r?\n";
}

# ----------------------------------------------------------------------
# Constructor.
# If error encountered, returns error message instead of object reference.
sub new {
    my $arg1 = shift;
    my $this;
    if(ref $arg1) {
        # invoked as instance method
        $this = $arg1;
    }
    else {
        # invoked as class method
        $this = {};
        bless $this, $arg1;
    }

    # remember raw text
    my $raw_text = shift;
    $this->{raw_text} = $raw_text;

    # parse raw email message text
    $raw_text =~ s/$EOL_PATTERN/\n/g; # convert to more easily parseable format
    if($raw_text =~ /(.*?\n)\n(.*)/s) {
        $this->{headers} = $1;
        $this->{body} = $2;
        $this->{cleartext} = '';
    } else {
        return "unable to parse message raw text.";
    }

    # get "Subject" (required)
    if($this->{headers} =~ /^Subject:\s*(.+?)$/im) {
        $this->{subject} = $1;
    } else {
        return "message subject not found.";
    }

    # attempt to parse "Subject" into MAIL_MRK:sender[:seqnum]
    my $mail_mrk = 'EMDIS';
    if(ecs_is_configured()) {
        $mail_mrk = $ECS_CFG->MAIL_MRK;
    }
    else {
        warn "ECS not configured, using MAIL_MRK = '$mail_mrk'\n";
    }
    my ($mark, $sender, $seq_num);
    if($this->{subject} =~ /$mail_mrk:(\S+?):(\d+)(:(\d+)\/(\d+))?\s*$/i) {
        # regular message
        $this->{is_ecs_message} = 1;
        $this->{is_meta_message} = '';
        $this->{sender} = $1;
        $this->{seq_num} = $2;
        $this->{part_num} = defined $4 ? $4 : 1;
        $this->{num_parts} = defined $5 ? $5 : 1;
        if($this->{part_num} > $this->{num_parts}) {
            return "part_num is greater than num_parts: " . $this->{subject};
        }
    }
    elsif($this->{subject} =~ /$mail_mrk:(\S+)\s*$/i) {
        # meta-message
        $this->{is_ecs_message} = 1;
        $this->{is_meta_message} = 1;
        $this->{sender} = $1;
    }
    else {
        # not an ECS message
        $this->{is_ecs_message} = '';
        $this->{is_meta_message} = '';
    }

    # get "Content-type" (optional)
    if($this->{headers} =~ /^Content-type:\s*(.+?)$/im) {
        $this->{content_type} = $1;
    }

    # get "From" (optional)
    if($this->{headers} =~ /^From:\s*(.+?)$/im) {
        $this->{from} = $1;
    }

    # get "To" (optional)
    if($this->{headers} =~ /^To:\s*(.+?)$/im) {
        $this->{to} = $1;
    }

    # decode quoted printable e-mails if necessary
    if($this->{headers} =~ /^Content-Transfer-Encoding\s*:\s*quoted-printable$/im) {
       $this->{headers} =~
         s/^(Content-Transfer-Encoding)\s*:\s*quoted-printable$/$1: 8bit/im;
       $this->{body} = decode_qp($this->{body}); 
    }

    return $this;
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub content_type {
    my $this = shift;
    return $this->{content_type};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub cleartext {
    my $this = shift;
    return $this->{cleartext};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub body {
    my $this = shift;
    return $this->{body};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub from {
    my $this = shift;
    return $this->{from};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub headers {
    my $this = shift;
    return $this->{headers};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub is_ecs_message {
    my $this = shift;
    return $this->{is_ecs_message};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub is_meta_message {
    my $this = shift;
    return $this->{is_meta_message};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub num_parts {
    my $this = shift;
    return $this->{num_parts};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub part_num {
    my $this = shift;
    return $this->{part_num};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub raw_text {
    my $this = shift;
    return $this->{raw_text};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub sender {
    my $this = shift;
    return $this->{sender};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub seq_num {
    my $this = shift;
    return $this->{seq_num};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub subject {
    my $this = shift;
    return $this->{subject};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub to {
    my $this = shift;
    return $this->{to};
}

# ----------------------------------------------------------------------
# Accessor method (read-only).
sub full_msg {
    my $this = shift;
    return $this->{headers} . "\n" . $this->{body};
}

# ----------------------------------------------------------------------
# save raw message to file
# returns empty string if successful, otherwise returns error message
sub save_to_file
{
    my $err = '';
    my $arg1 = shift;
    my ($filename,$msg);
    if(ref $arg1) {
        # invoked as instance method
        $msg = $arg1;
        $filename = shift;
    }
    else {
        # invoked as class method
        $filename = $arg1;
        my $raw_text = shift;
        $msg = new EMDIS::ECS::Message($raw_text);
    }
    open MSGFILE, ">$filename"
        or return "Unable to create file $filename: $!";
    print MSGFILE $msg->full_msg()
        or $err = "Unable to write file $filename: $!";
    close MSGFILE;
    chmod $EMDIS::ECS::FILEMODE, $filename;
    return $err;  # return error message (if any)
}

# ----------------------------------------------------------------------
# read message from file
# returns object reference if successful, otherwise returns error message
sub read_from_file
{
    my $err = '';
    my $arg1 = shift;
    my ($filename,$raw_text,$this);
    if(ref $arg1) {
        # invoked as instance method
        $this = $arg1;
        $filename = shift;
    }
    else {
        # invoked as class method
        $filename = $arg1;
    }

    # read file
    open(MSGFILE, "< $filename")
        or return "Unable to open file $filename: $!";
    $raw_text = join('', <MSGFILE>)
        or $err = "Unable to read file $filename: $!";
    close MSGFILE;
    return $err if $err;  # return error message (if any)

    # attempt to construct object
    my $newmsg;
    if(ref $arg1) {
        $newmsg = $this->new($raw_text);  # re-define this object
    }
    else {
        $newmsg = new EMDIS::ECS::Message($raw_text);
    }

    # set 'cleartext' attribute of message object
    $newmsg->{cleartext} = $newmsg->{body}
        if ref $newmsg;

    return $newmsg;
}

# ----------------------------------------------------------------------
# read and decrypt message from encrypted file
# returns object reference if successful, otherwise returns error message
sub read_from_encrypted_file
{
    my $err = '';
    my $arg1 = shift;
    my ($filename,$raw_text,$this);
    if(ref $arg1) {
        # invoked as instance method
        $this = $arg1;
        $filename = shift;
    }
    else {
        # invoked as class method
        $filename = $arg1;
    }

    # read encrypted file
    my $newmsg = read_from_file($filename);
    return $newmsg unless ref $newmsg;   # check for error
    return "not an ECS message" unless $newmsg->is_ecs_message;

    # read relevant node info from node_tbl
    my $node_tbl = $main::ECS_NODE_TBL;
    my $was_locked = $node_tbl->LOCK;
    if(not $was_locked) {
        $node_tbl->lock()     # lock node_tbl
            or return "unable to lock node_tbl: " .
                $node_tbl->ERROR;
    }
    my $node = $node_tbl->read($newmsg->sender);
    if(not $was_locked) {
        $node_tbl->unlock();  # unlock node_tbl
    }
    if(not $node) {
        return "node not found: " . $newmsg->sender;
    }

    # decrypt message into temp file
    my $decr_filename = "$filename.asc";
    for ($node->{encr_typ}) {
        /PGP2/i and do {
            $err = pgp2_decrypt(
                $filename,
                $decr_filename,
                (/verify/i ? $node->{encr_sig} : undef),
                $node->{encr_out_passphrase});
            last;
        };
        /OpenPGP/i and do {
            $err = openpgp_decrypt(
                $filename,
                $decr_filename,
                (/verify/i ? $node->{encr_sig} : undef),
                $node->{encr_out_passphrase});
            last;
        };
        $err = "unrecognized encr_typ: $node->{encr_typ}\n";
    }
    if($err) {
        unlink $decr_filename;
        chomp($err);
        return $err;
    }

    # read message cleartext from temp file
    my $fh = new IO::File;
    return "unable to open file: $decr_filename"
        unless $fh->open("< $decr_filename");
    my @cleartext = $fh->getlines();
    close $fh;

    # remove temp file
    unlink $decr_filename;

    # set 'cleartext' message attribute
    $newmsg->{cleartext} = join('', @cleartext);

    return $newmsg;
}


1;

__DATA__

# embedded POD documentation
# for more info:  man perlpod

=head1 NAME

EMDIS::ECS::Message - an ECS email message

=head1 SYNOPSIS

 use EMDIS::ECS::Message;

 $msg = new EMDIS::ECS::Message($raw_text);
 die "unable to parse message: $msg\n" unless ref $msg;
 die "not an ECS message\n" unless $msg->is_ecs_message;
 $err = $msg->save_to_file($filename);
 die "couldn't save to file: $err\n" if $err;

 $msg = EMDIS::ECS::Message::read_from_file($filename);
 die "unable to read message from file: $msg\n" unless ref $msg;
 print "Subject: " . $msg->subject . "\n";
 print ($msg->is_meta_message ? "meta-message\n" : '');
 print "\n" . $msg->body . "\n";

 $msg = EMDIS::ECS::Message::read_from_encrypted_file($filename);
 die "unable to read message from encrypted file: $msg\n"
     unless ref $msg;
 print "sender:  " . $msg->sender . "\n";
 print "seq_num: " . $msg->seq_num . "\n" if $msg->seq_num;
 print "cleartext:\n" . $msg->cleartext . "\n";

=head1 DESCRIPTION

ECS message object.

=head1 SEE ALSO

EMDIS::ECS, EMDIS::ECS::Config, EMDIS::ECS::FileBackedMessage,
EMDIS::ECS::LockedHash

=head1 AUTHOR

Joel Schneider <jschneid@nmdp.org>

=head1 COPYRIGHT AND LICENSE

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.

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
