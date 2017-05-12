# $Id: Postdrop.pm 2376 2008-10-27 09:36:02Z makholm $
package Mail::Postfix::Postdrop;

use strict;
use warnings;

our $VERSION = '0.3';

use Carp;
use Exporter qw(import);
our @EXPORT_OK = qw(inject);

use Email::Abstract;
use Email::Address;

use File::Temp qw(tempfile);

use IO::Socket::UNIX;

# Can we deduce these?
our $MAILDROP_QUEUE_DIR    = '/var/spool/postfix/maildrop/';
our $PICKUP_SERVICE_SOCKET = '/var/spool/postfix/public/pickup';

my %rec_types;
%rec_types = (
    REC_TYPE_SIZE => 'C',    # first record, created by cleanup
    REC_TYPE_TIME => 'T',    # time stamp, required
    REC_TYPE_FULL => 'F',    # full name, optional
    REC_TYPE_INSP => 'I',    # inspector transport
    REC_TYPE_FILT => 'L',    # loop filter transport
    REC_TYPE_FROM => 'S',    # sender, required
    REC_TYPE_DONE => 'D',    # delivered recipient, optional
    REC_TYPE_RCPT => 'R',    # todo recipient, optional
    REC_TYPE_ORCP => 'O',    # original recipient, optional
    REC_TYPE_WARN => 'W',    # warning message time
    REC_TYPE_ATTR => 'A',    # named attribute for extensions

    REC_TYPE_MESG => 'M',    # start message records

    REC_TYPE_CONT => 'L',    # long data record
    REC_TYPE_NORM => 'N',    # normal data record

    REC_TYPE_XTRA => 'X',    # start extracted records

    REC_TYPE_RRTO => 'r',    # return-receipt, from headers
    REC_TYPE_ERTO => 'e',    # errors-to, from headers
    REC_TYPE_PRIO => 'P',    # priority
    REC_TYPE_VERP => 'V',    # VERP delimiters

    REC_TYPE_END => 'E',     # terminator, required

);

sub inject {
    my $postdrop = __PACKAGE__->new(@_);

    $postdrop->build   or return;
    $postdrop->write   or return;
    $postdrop->release or return;

    $postdrop->notify;

    return 1;
}

sub new {
    my ( $class, $message, %overrides ) = @_;

    # Email::Abstract->new() is just a no-op when called with
    # an object taht allready is an Email::Abstract. So this is ok:
    $message = Email::Abstract->new($message);

    $overrides{Attr}      ||= { rewrite_context => 'local' };
    $overrides{Timestamp}   = time() unless exists $overrides{Timestamp};

    unless ( exists $overrides{Sender} ) {
        my $sender = $message->get_header("Sender");
        $sender ||= $message->get_header("From");

        $overrides{Sender} = ( Email::Address->parse($sender) )[0]->address;
    }

    unless ( exists $overrides{Recipients} ) {
        $overrides{Recipients} = [
            map   { $_->address }
              map { Email::Address->parse($_) }
              map { $message->get_header($_) } qw(To Cc Bcc)
        ];
    }

    return bless {
        message => $message,
        args    => \%overrides,
    }, $class;
}

sub build {
    my ($self) = @_;

    $self->_build_rec_time();
    $self->_build_attr( %{ $self->{args}->{Attr} } );
    $self->_build_rec( 'REC_TYPE_FROM', $self->{args}->{Sender} || "" );
    for ( @{ $self->{args}->{Recipients} } ) {
        $self->_build_rec( 'REC_TYPE_RCPT', $_ );
    }

    # add an empty message length record.
    # cleanup is supposed to understand that.
    # see src/pickup/pickup.c
    $self->_build_rec( 'REC_TYPE_MESG', "" );

    # a received header has already been added in SMTP.pm
    # so we can just copy the message:

    for ( split( /\r?\n/, $self->{message}->as_string() ) ) {
        $self->_build_msg_line($_);
    }

    # finish it.
    $self->_build_rec( 'REC_TYPE_XTRA', "" );
    $self->_build_rec( 'REC_TYPE_END',  "" );

    return $self->{content};
}

# We're a method so it ok
sub write {    ## no critic  (ProhibitBuiltinHomonyms)
    my $self = shift;

    my $oldumask = umask oct(177)
      or return;

    my ( $fh, $filename ) = tempfile( DIR => $MAILDROP_QUEUE_DIR )
      or return;

    $self->{filename} = $filename;

    print $fh $self->{content}
      or return;

    close $fh
      or return;

    umask $oldumask;

    return 1;
}

sub release {
    my $self = shift;

    chmod oct(744), $self->{filename}
      or return;

    return 1;
}

sub drop {
    my $self = shift;

    unlink $self->{filename};

    return 1;
}

sub notify {
    my $fh;

    open $fh, ">", $PICKUP_SERVICE_SOCKET
      or return;

    print $fh "W"
      or return;

    close $fh;

    return 1;
}

############################################################
#
# Auxillary functions for building the queue file
#
############################################################

sub _build_rec {
    my ( $self, $type, @list ) = @_;

    croak "unknown record type" unless ( $rec_types{$type} );
    $self->{content} .= ( $rec_types{$type} );

    # the length is a little endian base-128 number where each
    # byte except the last has the high bit set:
    my $s  = "@list";
    my $ln = length($s);
    while ( $ln >= 0x80 ) {
        my $lnl = $ln & 0x7F;
        $ln >>= 7;
        $self->{content} .= ( chr( $lnl | 0x80 ) );
    }
    $self->{content} .= ( chr($ln) );

    $self->{content} .= ($s);

    return;
}

sub _build_rec_size {
    my ( $self, $content_size, $data_offset, $rcpt_count ) = @_;

    my $s = sprintf( "%15ld %15ld %15ld", $content_size, $data_offset, $rcpt_count );
    $self->_build_rec( 'REC_TYPE_SIZE', $s );
    return;
}

sub _build_rec_time {
    my ( $self, $time ) = @_;

    $time = $self->{args}->{Timestamp} unless ( defined($time) );

    return unless defined $time;

    my $s = sprintf( "%d", $time );
    $self->_build_rec( 'REC_TYPE_TIME', $s );
    return;
}

sub _build_attr {
    my ( $self, %kv ) = @_;
    for ( keys %kv ) {
        $self->_build_rec( 'REC_TYPE_ATTR', "$_=$kv{$_}" );
    }
    return;
}

sub _build_msg_line {
    my ( $self, $line ) = @_;

    $line =~ s/\r?\n$//s;

    # split into 1k chunks.
    while ( length($line) > 1024 ) {
        my $s = substr( $line, 0, 1024 );
        $line = substr( $line, 1024 );
        $self->_build_rec( 'REC_TYPE_CONT', $s );
    }
    $self->_build_rec( 'REC_TYPE_NORM', $line );
    return;
}

1;

__END__

=head1 NAME

Mail::Postfix::Postdrop - Inject mails to a Postfix maildrop directory

=head1 SYNOPSIS

  # Functional interface
  use Mail::PostFix::Postdrop 'inject';

  inject $message, Sender     => 'alice@example.net',
                   Recipients => [ qw(bob@example.com carol@example.net) ];

  
  # OOish interface

  my $postdrop = Mail::Postfix::Postdrop->new( $message );

  $postdrop->build;    # Build the content of the queue file 
  $postdrop->write;    # Write it to the maildrop queue
  $postdrop->release;  # Let pickup(8) process the queue file
  $postdrop->notify;   # Notify pickup(8) about new files (Optional)

  # Or through postdrop(1)

  my $postdrop = Mail::Postfix::Postdrop->new( $message, Timestamp => undef );
  open my $fh, "|-", "/usr/sbin/postdrop"
      or die "...";
  print $fh $postdrop->build
      or die "...";
  close $fh
      or die "...";


=head1 DESCRIPTION

Bone::Mail::Postfix::Postdrop implements parts of postfix's postdrop(1)
utility. Using the functionel interface you can inject messages directly
into the maildrop queu and using the OOish interface you can control parts
of the process.

The main use case is writing the mail to a queue where postfix will take
the responsability to deliver the mail without letting postfix handle the
mail immediately. This can be used for sending mails in transactions.

=head1 FUNCTIONS

=head2 inject

  inject $message, %overrides;

Given a message, either as a Email::Abstract object or as something 
Email::Abstract->new() will process (like a string), this function will
inject the mail into Postfix's maildrop queue. If not overridden sender
and recipients will be extracted from the message. (Need to be in group
'postdrop')

The following overrides is supported:

=head3 Sender (string)

Default: content of the Sender or From header 

=head3 Recipients (arrayref)

Default: content of To, CC, and BCc headers.

=head3 Attr (hashref)

Attributes to further posfix processing. Default:

  { rewrite_context => 'local' }

=head3 Timestamp (integer or undef)

Timestamp to stamp the queue file with (posix timestamp). The default is the
current time. If timestamp is explicitly set to undef no timestamp will be
created. This is needed for sending through postdrop(1).
                                             
=head1 METHODS

The following methods is supported:

=head2 new

Takes the same arguments as the inject function without injecting the
mail immediately.

=head2 build

Builds the queue content. If you change the content you'll have to call
build again or you will inject old mail. Returns a string containing the 
queue content.

=head2 write

Write the content to a maildrop file. Returns a false value on failure and
sets $! arcordingly. (Need to be in group 'postdrop')

=head2 release

Releases the queue file so pickup(8) will indeed pick it up next time
it scans the maildrop queue. (Need to be in group 'postdrop')

=head2 notify

Notifies pickup(8) that new mail has been placed in the maildrop queue.
By calling this function you mail should be processed immediately otherwise
pickup should automatically scan the queue each minute.

=head2 check

Checks if the queue file still exists. Notice that notify is nonblocking
and on a loaded system it may take a while for the mail to be processed.
There is also a minor chance that some other mail with the same name might
be generated in the mean time.

=head1 BUGS AND INCONVENIENCES

Some of the methods needs to run as the postdrop group. If you can't run you
script in this group you have to pipe through postdrop.

Please report any bugs or feature requests to C<bug-mail-postfix-postdrop at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-Postfix-Postdrop>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

It would be nice to restore the ability from Qpsmtpd::Postfix to talk
directly to the cleanup(8)-daemon.

=head1 AUTHOR

Peter Makholm, <F<makholm at one.com>>

=head1 COPYRIGHT & LICENSE

Copyright 2008 One.com, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Partly based on Qpsmptd::Postfix by Ask Bjoern Hansen, Develooper LCC

# vim:sw=2
