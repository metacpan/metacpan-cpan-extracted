#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/lib/HookTester.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   perl-Dist-Zilla-Plugin-Hook is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Hook is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Hook. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

package HookTester;

#   The test is written using `Moose`-based `Test::Routine`. It is not big deal, because we are
#   testing plugin for `Dist::Zilla`, and `Dist-Zilla` is also `Moose`-based.

use autodie ':all';
use namespace::autoclean;

use Test::Routine;

with 'Test::Dist::Zilla::Build';

sub _build_files {
    my ( $self ) = @_;
    return {
        'lib/Dummy.pm' => "package Dummy; 1;"
    };
};

sub _build_message_filter {
    return sub { grep( { $_ =~ m{^\[.*Hook.*\]}i } @_ ); };
};

1;

# end of file #
