package GBPVR::CDBI::RecTracker;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'GBPVR::CDBI';

__PACKAGE__->db_setup(file => 'rectracker.mdb');

1;

__END__

=head1 NAME

GBPVR::CDBI::RecTracker - GBPVR RecTracker utility access

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

