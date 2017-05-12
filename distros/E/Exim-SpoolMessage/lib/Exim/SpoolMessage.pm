package Exim::SpoolMessage;

use warnings;
use strict;
use vars qw($AUTOLOAD);

use Carp qw(carp croak);

use Fcntl qw(:DEFAULT SEEK_SET);
use Mail::Header;


=head1 NAME

Exim::SpoolMessage - Read and parse Exim spool files.

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Exim::SpoolMessage provides access to the messages stored in Exim's
spool directory.

The format of the Exim spool files is described in section 53 of the
Exim specification document.

    use Exim::SpoolMessage;

    my $msg = Exim::SpoolMessage->load('/var/spool/exim/input',
                                       '1N4toN-000G2Z-6M');
    print "Return-path: <", $msg->return_path, ">\n";
    print $msg->head->as_string(), "\n", @{$msg->body};

The module was written in order to be able to provide external commands
access to the contents of the message during message filtering process.

=head1 CONSTRUCTOR

=head2 Exim::SpoolMessage->load($input_dir, $message_id)

Takes to parameters - location of the input directory where spool files
are located and the message id of the desired message.

NOTE: $input_dir has to be location of the directory where spool files
are located. If split_spool_directory it will not equal to the spool
directory.

Returns an object with a lot of methods, please see below for details.

The constructor croaks on errors.

=cut

sub load {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $dir = shift or croak 'Missing input directory';
    my $id = shift or croak 'Missing message id';
    my $self = {input_dir => $dir, message_id => $id};
    bless $self, $class;

    my %keys = keys %{$self};
    delete @keys{qw(input_dir message_id)};
    delete @{$self}{keys %keys};

    open my $hh, "$self->{'input_dir'}/$self->{'message_id'}-H" or
        croak "Cannot open '$self->{'input_dir'}/$self->{'message_id'}-H': $!";
    open my $dh, "$self->{'input_dir'}/$self->{'message_id'}-D" or
        croak "Cannot open '$self->{'input_dir'}/$self->{'message_id'}-D': $!";

    # The format of the Exim spool files is described in section 53 of the
    # Exim specification.

    # The first line contains the final component of the file name.
    chomp(my $tmp = <$hh>);
    croak "Corrupted spool file '$self->{'message_id'}-H'"
        if $tmp ne "$self->{'message_id'}-H";


    # The second line contains the login name for the uid of the process
    # that called Exim to read the message, followed by the numerical uid
    # and gid.
    chomp($tmp = <$hh>);
    @{$self}{qw(caller_name caller_uid caller_gid)} = split / /, $tmp, 3;

    # The third line of the file contains the address of the message’s
    # sender as transmitted in the envelope, contained in angle brackets.
    # The sender address is empty for bounce messages.
    chomp($tmp = <$hh>);
    ($self->{'return_path'} = $tmp) =~ s/^<(.+)>$/$1/;

    # The fourth line contains two numbers. The first is the time that the
    # message was received, in the conventional Unix form – the number of
    # seconds since the start of the epoch. The second number is a count of
    # the number of messages warning of delayed delivery that have been
    # sent to the sender.
    chomp($tmp = <$hh>);
    @{$self}{qw(time_received warning_count)} = split / /, $tmp, 2;

    # There follow a number of lines starting with a hyphen.
    # These can appear in any order, and are omitted when not relevant.
    while (1) {
        # -acl <number> <length>
        # -aclc <rest-of-name> <length>
        # -aclm <rest-of-name> <length>
        # -active_hostname <hostname>
        # -allow_unqualified_recipient
        # -allow_unqualified_sender
        # -auth_id <text>
        # -auth_sender <address>
        # -body_linecount <number>
        # -body_zerocount <number>
        # -deliver_firsttime
        # -frozen <time>
        # -helo_name <text>
        # -host_address <address>.<port>
        # -host_auth <text>
        # -host_lookup_failed
        # -host_name <text>
        # -ident <text>
        # -interface_address <address>.<port>
        # -local
        # -localerror
        # -local_scan <string>
        # -manual_thaw
        # -N
        # -received_protocol
        # -sender_set_untrusted
        # -spam_score_int <number>
        # -tls_certificate_verified
        # -tls_cipher <cipher name>
        # -tls_peerdn <peer DN>
        chomp($tmp = <$hh>);
        if ($tmp =~ /^-(acl[mc]) (\d+) (\d+)/) {
            my ($key, $num, $len) = ($1, $2 + 1);
            read $hh, $tmp, $len;
            chomp($self->{$key} = $tmp);
            next;
        } elsif ($tmp =~ /^-acl (\d+) (\d+)/) {
            my ($num, $len) = ($1, $2 + 1);
            my $key = ($num < 10) ? 'acl_c' . $num : 'acl_m' . ($num - 10);
            read $hh, $tmp, $len;
            chomp($self->{$key} = $tmp);
            next;
        }
        last if $tmp !~ s/^-//;
        my ($key, $val) = split / /, $tmp, 2;
        $self->{"opt_$key"} = $val;
    }

    # Following the options there is a list of those addresses to which the
    # message is not to be delivered. This set of addresses is initialized from
    # the command line when the -t option is used and
    # extract_addresses_remove_arguments is set; otherwise it starts out empty.
    # Whenever a successful delivery is made, the address is added to this set.
    # The addresses are kept internally as a balanced binary tree, and it is a
    # representation of that tree which is written to the spool file. If an
    # address is expanded via an alias or forward file, the original address is
    # added to the tree when deliveries to all its child addresses are
    # complete.
    #
    # If the tree is empty, there is a single line in the spool file containing
    # just the text "XX”. Otherwise, each line consists of two letters, which
    # are either Y or N, followed by an address.
    while (1) {
        chomp($tmp = <$hh>);
        last if $tmp !~ /^[XYN][XYN]/;
    }

    # After the non-recipients tree, there is a list of the message’s
    # recipients. This is a simple list, preceded by a count. It includes all
    # the original recipients of the message, including those to whom the
    # message has already been delivered.
    #
    # In the simplest case, the list contains one address per line.
    #
    # However, when a child address has been added to the top-level addresses
    # as a result of the use of the one_time option on a redirect router, each
    # line is of the following form:
    #
    # <top-level address> <errors_to address> <length>,<parent number>#<flag bits>
    #
    # The 01 flag bit indicates the presence of the three other fields that
    # follow the top-level address. Other bits may be used in future to support
    # additional fields. The <parent number> is the offset in the recipients
    # list of the original parent of the "one time" address. The first two
    # fields are the envelope sender that is associated with this address and
    # its length. If the length is zero, there is no special envelope sender
    # (there are then two space characters in the line). A non-empty field can
    # arise from a redirect router that has an errors_to setting.
    $self->{'recipients'} = [];
    for my $i (1 .. $tmp) {
        chomp($tmp = <$hh>);
        push @{$self->{'recipients'}}, $tmp;
    }

    # A blank line separates the envelope and status information from the
    # headers which follow.
    $tmp = <$hh>;

    # A header may occupy several lines of the file, and
    # to save effort when reading it in, each header is preceded by a number
    # and an identifying character. The number is the number of characters in
    # the header, including any embedded newlines and the terminating newline.
    # The character is one of the following:
    #
    # <blank> header in which Exim has no special interest
    # B Bcc: header
    # C Cc: header
    # F From: header
    # I Message-id: header
    # P Received: header – P for "postmark"
    # R Reply-To: header
    # S Sender: header
    # T To: header
    # * replaced or deleted header
    my $pos = tell $hh;
    my @headers;
    while (defined(my $line = <$hh>)) {
        $line =~ /^((\d+)([ BCFIPRST*]) )/ or next;
        $pos += length($1);
        my ($len, $char) = ($2, $3);
        seek $hh, $pos, SEEK_SET;
        read $hh, $tmp, $len;
        push @headers, $tmp if $char ne '*';
        $pos = tell $hh;
    }

    # The first line contains the final component of the file name.
    chomp($tmp = <$dh>);
    croak "Corrupted spool file '$self->{'message_id'}-D'"
        if $tmp ne "$self->{'message_id'}-D";

    # The data portion of the message is kept in the -D file on its own.
    my @body;
    while (defined(my $line = <$dh>)) {
        push @body, $line;
    }

    close $hh;
    close $dh;

    $self->{'head'} = Mail::Header->new(\@headers, Modify => 0);
    $self->{'body'} = \@body;

    return $self;
}

=head1 METHODS

=head2 $msg->head

Mail::Header object with the message headers.

=head2 $msg->body

Reference to an array with the contents of the message body. Each
item represents a line of the body.

=head2 Other methods

In addition, there are many other mehotds that will provide access to
various details related to the message. Please consult the Exim
documentation.

Available methods (not all may be present and there may be
other as well):

=over

=item * $msg->message_id

=item * $msg->caller_name

=item * $msg->caller_uid

=item * $msg->caller_gid

=item * $msg->return_path

=item * $msg->time_received

=item * $msg->warning_count

=item * $msg->aclc*

=item * $msg->aclm*

=item * $msg->opt_active_hostname

=item * $msg->opt_allow_unqualified_recipient

=item * $msg->opt_allow_unqualified_sender

=item * $msg->opt_auth_id

=item * $msg->opt_auth_sender

=item * $msg->opt_body_linecount

=item * $msg->opt_body_zerocount

=item * $msg->opt_deliver_firsttime

=item * $msg->opt_frozen

=item * $msg->opt_helo_name

=item * $msg->opt_host_address

=item * $msg->opt_host_auth

=item * $msg->opt_host_lookup_failed

=item * $msg->opt_host_name

=item * $msg->opt_ident

=item * $msg->opt_interface_address

=item * $msg->opt_local

=item * $msg->opt_localerror

=item * $msg->opt_local_scan

=item * $msg->opt_manual_thaw

=item * $msg->opt_received_protocol

=item * $msg->opt_sender_set_untrusted

=item * $msg->opt_spam_score_int

=item * $msg->opt_tls_certificate_verified

=item * $msg->opt_tls_cipher

=item * $msg->opt_tls_peerdn

=item * $msg->recipients

=back

=cut


=head1 AUTHOR

Kirill Miazine <km@krot.org>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Kirill Miazine.

This software is distributed under an ISC style license, please see
<http://km.krot.org/code/license.txt> for details.

=cut

sub DESTROY { 1; }

sub AUTOLOAD {
    my $self = shift;
    my ($attr) = ($AUTOLOAD =~ /::([^:]+)$/);

    if ($attr =~ /^([a-zA-Z0-9_]+)$/ and exists $self->{$attr}) {
        eval "sub $attr { shift->{'$attr'} }";
        return $self->{$attr};
    } else {
        croak "Unknown attribute '$attr'";
    }
}

1;
