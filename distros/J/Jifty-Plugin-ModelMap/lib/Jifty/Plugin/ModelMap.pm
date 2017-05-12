package Jifty::Plugin::ModelMap;
use base qw/Jifty::Plugin/;

use warnings;
use strict;

=head1 NAME

Jifty::Plugin::ModelMap - Render model map with GraphViz.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - ModelMap: {}

This makes the following URL available:

    http://your.app/model_map

=head1 SEE ALSO

L<Jifty>, L<GraphViz>

=head1 AUTHOR

bokutin, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Jifty::Plugin::ModelMap
