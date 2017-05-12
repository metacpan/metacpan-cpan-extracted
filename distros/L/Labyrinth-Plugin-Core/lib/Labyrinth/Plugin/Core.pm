package Labyrinth::Plugin::Core;

use warnings;
use strict;

our $VERSION = '5.19';

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Variables;

#----------------------------------------------------------------------------
# Public Interface Functions

sub Editor      { return  unless AccessUser(EDITOR);    }
sub Publisher   { return  unless AccessUser(PUBLISHER); }
sub Admin       { return  unless AccessUser(ADMIN);     }
sub Master      { return  unless AccessUser(MASTER);    }

1;

__END__

=head1 NAME

Labyrinth::Plugin::Core - Core Plugin documentation for Labyrinth

=head1 DESCRIPTION

Documentation overview for Labyrinth Core Plugins.

Labyrinth began life in 2002, with a small set of plugins to enable various
features of web site management. The core set of plugins here are those most 
useful to provide a basic web site management system. 

These plugins provide the functionality to manipulate core aspects of the data
used within Labyrinth. Several of these plugins only provide administration 
features.

See the individual files for more details on how to use them.

=head1 ADDITIONAL FILES

As with the Labyrinth core package, additional files are needed to enable
Labyrinth and any installed plugins to work correctly. These files consist of 
SQL, HTML template and configuration files, together with some basic CSS and 
Javascript files.

Please see the L<Labyrinth::Demo> distribution for a set of these files.

However, these files are only the beginning, and to implement your website,
you will need to update the appropriate files to use your layout design.

=head1 ADDITION INFORMATION

Although Labyrinth has long been in development, documentation has not been a
priority. As such much of the documentation you may need to understand how to
use Labyrinth is the code itself. If you have the inclination, documentation
patches would be very gratefully received.

The Labyrinth website [1] will eventually feature a documentation site, wiki
and other features which are intended to provide you with the information to
use and extend Labyrinth as you wish.

[1] http://labyrinth.missbarbell.co.uk

=head1 METHODS

The Core module provides some convience methods for the dispatch tables.

=over 4

=item Editor

Redirects to login page if user doesn't have Editor access.

=item Publisher

Redirects to login page if user doesn't have Publisher access.

=item Admin

Redirects to login page if user doesn't have Admin access.

=item Master

Redirects to login page if user doesn't have Master access.

=back

=head1 SEE ALSO

L<Labyrinth>, 
L<Labyrinth::Demo>

L<http://labyrinth.missbarbell.co.uk>,
L<http://demo.missbarbell.co.uk>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
