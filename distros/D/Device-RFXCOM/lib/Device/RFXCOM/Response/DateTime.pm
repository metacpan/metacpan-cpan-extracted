use strict;
use warnings;
package Device::RFXCOM::Response::DateTime;
$Device::RFXCOM::Response::DateTime::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for DateTime message from RFXCOM receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_DATETIME_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { 'datetime' }


sub device { shift->{device} }


sub date { shift->{date} }


sub time { shift->{time} }


sub day { shift->{day} }


sub summary {
  my $self = shift;
  $self->type.'/'.$self->device.'='.$self->date.' '.$self->time.' '.$self->day;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response::DateTime - Device::RFXCOM::Response class for DateTime message from RFXCOM receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for DateTime messages from an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns 'datetime'.

=head2 C<device()>

This method returns a string representing the name of the device that
sent the date and time data.

=head2 C<date()>

This method returns a string of the form 'YYYYMMDD' representing the
date from the date and time RF message.

=head2 C<time()>

This method returns a string of the form 'HHMMSS' representing the
time from the date and time RF message.

=head2 C<day()>

This method returns the day (in English) from the date and time RF
message.  It is probably best to avoid using this and calculate the
correct value for the locale from the other data.

=head2 C<summary()>

This method returns a string summary of the date and time information.

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
