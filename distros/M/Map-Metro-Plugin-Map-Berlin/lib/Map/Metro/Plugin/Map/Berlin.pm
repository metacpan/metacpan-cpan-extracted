# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2014,2015,2017,2018,2019,2020,2021 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

{
    package Map::Metro::Plugin::Map::Berlin;

    our $VERSION = '2021.0709';

    use Moose;
    use File::ShareDir 'dist_dir';
    use Path::Tiny;
    with 'Map::Metro::Plugin::Map';
 
    has '+mapfile' => (
		       default => sub { path(dist_dir('Map-Metro-Plugin-Map-Berlin'))->child('map-berlin.metro')->absolute },
		      );
}

1;

__END__

=encoding utf-8
 
=head1 NAME
 
Map::Metro::Plugin::Map::Berlin - Map::Metro map for Berlin
 
=head1 SYNOPSIS
 
    use Map::Metro;
    my $graph = Map::Metro->new('Berlin')->parse;

From commandline:

    map-metro.pl route Berlin "Rathaus Spandau" "Rudow"
 
=head1 DESCRIPTION
 
See L<Map::Metro> for usage information.
 
=head1 Status
 
The network currently contains both U-Bahn and S-Bahn.

=head1 AUTHOR
 
Slaven Rezic E<lt>srezic@cpan.orgE<gt>
 
=head1 SEE ALSO

L<Map::Metro>, L<Map::Tube::Berlin>.

=cut
