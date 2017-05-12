package Flickr::Photoset;

use warnings;
use strict;
use Carp;

#use Flickr::API::Photosets;
use Flickr::Person;
use Flickr::Photo;

=head1 NAME

Flickr::Photoset - Represents a photoset on Flickr.

=head1 VERSION

Version 1.22_01

=cut

our $VERSION = '1.22_01';

=head1 SYNOPSIS

    use Flickr::Photoset;

    print "\nFlickr::Photosets < 1.0 is not compatible with Flickr::Tools >= 1.0\n";

This module is being re-worked and not all methods from the 0.x series will be
part of the 1.x series.

=head1 DESCRIPTION

This class represents a photoset on Flickr.

=head1 METHODS

=head2 new

Warn caller.

$photo = Flickr::Photoset->new();

=cut


sub new {

        croak 'Flickr::Photoset < 1.0 is not compatible with Flickr::Tools >= 1.0';

}

1; # End of Flickr::Photo


__END__

