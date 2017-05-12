#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Role/HgRunner.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-PluginBundle-Author-VDB.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-PluginBundle-Author-VDB. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

package Dist::Zilla::Role::Author::VDB::HgRunner;

use Moose::Role;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: TODO
our $VERSION = 'v0.11.3'; # VERSION

use Path::Tiny;
use Carp qw{ croak };

with 'Dist::Zilla::Role::Author::VDB::ProgramRunner';

# --------------------------------------------------------------------------------------------------

#pod =method run_hg
#pod
#pod     @stdout = @{ $self->run_hg( @arguments ) };
#pod
#pod =cut

sub run_hg {
    my ( $self, @args ) = @_;
    @args > 0 or croak "run_hg: at least one argument expected";
    my $root = path( $self->zilla->root );
    return $self->run_program(
        'hg',
        '--cwd', "$root",
        $args[ 0 ] ne 'init' ? ( '-R', '.' ) : (),  # `hg init` does not like `-R` option.
        @args
    );
};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Author::VDB::HgRunner - TODO

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=head1 OBJECT METHODS

=head2 run_hg

    @stdout = @{ $self->run_hg( @arguments ) };

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
