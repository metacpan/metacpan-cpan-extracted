package File::VirusScan::Engine::Daemon;
use strict;
use warnings;

use File::VirusScan::Engine;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine );

1;

__END__

=head1 NAME

File::VirusScan::Engine::Daemon - File::VirusScan::Engine class for scaning daemons

=head1 SYNOPSIS

    use File::VirusScan::Engine::Daemon;
    @ISA = qw( File::VirusScan::Engine::Daemon );

=head1 DESCRIPTION

File::VirusScan::Engine::Daemon provides a base class and utility methods for
implementing File::VirusScan support for daemon-based virus scanners.

=head1 INSTANCE METHODS

=head2 scan ( $path )

Generic scan() method.  Takes a pathname to scan.  Returns a
File::VirusScan::Result object which can be queried for status.

Generally, this will be implemented by the subclass.

=head1 DEPENDENCIES

L<File::VirusScan::Engine>

=head1 AUTHOR

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
