package Mail::MBX::Message;

=head1 NAME

Mail::MBX::Message - An MBX mailbox message object

=head1 SYNOPSIS

    use Mail::MBX ();

    my $mbx = Mail::MBX->open('mailbox.mbx');

    #
    # Fetch and read first message in mailbox
    #
    my $message = $mbx->message;

    #
    # Write message body to standard output
    #
    while (my $readlen = $message->read(my $buf, 4096)) {
        print $buf;
    }

    $mbx->close;

=head1 DESCRIPTION

C<Mail::MBX::Message> represents an MBX message object within an existing
C<L<Mail::MBX>> file object.  Because C<Mail::MBX::Message> objects contain
state specific to the parent object's file handle, only one message can be
read per mailbox at a time.

=head1 USAGE

=over

=cut

use strict;
use warnings;

use Time::Local ();

my %MONTHS = (
    'Jan' => 0,
    'Feb' => 1,
    'Mar' => 2,
    'Apr' => 3,
    'May' => 4,
    'Jun' => 5,
    'Jul' => 6,
    'Aug' => 7,
    'Sep' => 8,
    'Oct' => 9,
    'Nov' => 10,
    'Dec' => 11
);

=item C<Mail::MBX::Message-E<gt>parse(I<$fh>)>

Not intended to be used as part of a public interface.  Given the file handle
specified in I<$fh>, this method will return a new C<Mail::MBX::Message> object
representing the message found at the current position of I<$fh>.

=cut

sub parse {
    my ( $class, $fh ) = @_;

    if ( eof $fh ) {
        return;
    }

    my $header = readline($fh);
    my $offset = tell($fh);

    #
    # tidyoff -- perltidy would wreak havoc on this poor expression
    #
    my ( $date, $time, $metadata ) = split /\s+/, $header;

    my ( $day, $month, $year ) = (
        $date =~ /^( \d|\d\d)-(\w{3})-(\d{4})$/
    ) or die('Invalid syntax: Bad date');

    my ( $hour, $minute, $second ) = (
        $time =~ /^(\d{2}):(\d{2}):(\d{2})$/
    ) or die('Invalid syntax: Bad timestamp');

    my ( $tz, $size, $attributes ) = (
        $metadata =~ /^([+\-]\d{4}),(\d+);(\S+)$/
    ) or die('Invalid syntax: Bad metadata');

    my ( $tzNegative, $tzHourOffset, $tzMinuteOffset ) = (
        $tz =~ /^([+\-])(\d{2})(\d{2})$/
    ) or die('Invalid syntax: Bad timezone offset');

    my ( $hexFlags, $hexUid ) = (
        $attributes =~ /^[[:xdigit:]]{8}([[:xdigit:]]{4})-([[:xdigit:]]{8})$/
    ) or die('Invalid syntax: Bad attributes');

    my $flags =
        ( ( hex($hexFlags) & 0x1 ) ? 'S' : '' )
      . ( ( hex($hexFlags) & 0x2 ) ? 'T' : '' )
      . ( ( hex($hexFlags) & 0x4 ) ? 'F' : '' )
      . ( ( hex($hexFlags) & 0x8 ) ? 'R' : '' );

    my $timestamp = Time::Local::timegm(
        $second, $minute, $hour, $day + 0, $MONTHS{$month}, $year
    ) + ( ( $tzNegative eq '-' ? 1 : -1 )
      * ( $tzHourOffset * 60 + $tzMinuteOffset ) * 60 );

    #
    # tidyon
    #

    return bless {
        'fh'        => $fh,
        'uid'       => hex($hexUid),
        'timestamp' => $timestamp,
        'flags'     => $flags,
        'size'      => $size,
        'offset'    => $offset,
        'remaining' => $size,
        'current'   => $offset
    }, $class;
}

=item C<$message-E<gt>reset()>

Reset internal file handle position to beginning of message.

=cut

sub reset {
    my ($self) = @_;

    @{$self}{qw(remaining current)} = @{$self}{qw(size offset)};

    seek( $self->{'fh'}, $self->{'offset'}, 0 );

    return;
}

=item C<$message-E<gt>read(I<$buf>, I<$len>)>

Read at most I<$len> bytes from the current message, into a scalar variable
in the argument of I<$buf>, and return the number of bytes actually read from
the current message.

=cut

sub read {
    my ( $self, $buf, $len ) = @_;

    if ( $self->{'remaining'} <= 0 ) {
        return;
    }

    $len = $self->{'remaining'} if $len > $self->{'remaining'};

    my $readlen = CORE::read( $self->{'fh'}, $_[1], $len );

    $self->{'remaining'} -= $readlen;

    return $readlen;
}

1;

=back

=cut

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the MIT license.
