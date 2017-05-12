package Mac::EyeTV::Channel;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(channel name number enabled));

1;

__END__

=head1 NAME

Mac::EyeTV::Channel - An EyeTV channel

=head1 SYNOPSIS

  use Mac::EyeTV;
  my $eyetv = Mac::EyeTV->new();

  foreach my $channel ($eyetv->channels) {
    my $name   = $channel->name;
    my $number = $channel->number;
    print "$number $name\n";
  }

=head1 DESCRIPTION

This module represents an EyeTV channel. The channels() method in
Mac::EyeTV returns a list of Mac::EyeTV::Channel objects.

=head1 METHODS

=head2 name

The name() method returns the name of the channel:

  my $name    = $channel->name;

=head2 number

The number() method returns the channel number of the channel:

  my $number  = $channel->number;

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2004-5, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
