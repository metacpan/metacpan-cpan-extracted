#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/lib/CustomPlugin.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Write.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Manifest-Write. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

package CustomPlugin;

use Moose;
use namespace::autoclean;

extends 'Dist::Zilla::Plugin::InlineFiles';

use Dist::Zilla::File::FromCode;
use Dist::Zilla::File::InMemory;

after gather_files => sub {
    my ( $self) = @_;
    $self->add_file( Dist::Zilla::File::FromCode->new(
        name => 'GeneratedFile.txt',
        code_return_type => 'bytes',
        code => sub {
            "Generated content.\n"
        }
    ) );
    my $file = Dist::Zilla::File::InMemory->new(
        name => 'lib/GeneratedModule.pm',
        content => join( "\n",
            "package GeneratedModule;",
            "",
            "1;"
        ) . "\n"
    );
    $self->add_file( $file );
};

1;

__DATA__
__[lib/InlineModule.pm]__
package InlineModule;
1;
__END__

# end of file #
