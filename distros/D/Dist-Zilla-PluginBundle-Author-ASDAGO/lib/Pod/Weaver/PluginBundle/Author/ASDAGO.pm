# ABSTRACT: ASDAGO's Pod::Weaver plugin bundle

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

package Pod::Weaver::PluginBundle::Author::ASDAGO;
$Pod::Weaver::PluginBundle::Author::ASDAGO::VERSION = '0.001';
#pod =head1 DESCRIPTION
#pod
#pod This is ASDAGO's plugin bundle for Pod::Weaver. Currently, there are
#pod no configuration options.
#pod
#pod =cut

use v5.10.0;
use strict;
use warnings;
use namespace::autoclean;
use Pod::Weaver::Config::Assembler;

my $me = __PACKAGE__;
$me =~ s/^Pod::Weaver::PluginBundle:://
    or die 'Invalid package name: '.__PACKAGE__;
$me = "\@$me";

my @plugins = (
    [ 'CorePrep',		'@CorePrep'		=> {} ],
    [ 'SingleEncoding',		'-SingleEncoding'	=> {} ],
    [ 'Name',			'Name'			=> {} ],
    [ 'Version',		'Version',		=> {} ],

    [ 'prelude', 'Region' => { region_name => 'prelude'  } ],

    [ '=SYNOPSIS',	'Generic'	=> {} ],
    [ '=DESCRIPTION',	'Generic'	=> {} ],
    [ '=OVERVIEW',	'Generic'	=> {} ],

    [ '=FUNCTIONS',	'Collect'	=> { command => 'func'   } ],
    [ '=VARIABLES',	'Collect'	=> { command => 'var'    } ],
    [ '=OVERLOADS',	'Collect'      => { command => 'overload' } ],
    [ '=METHODS',	'Collect'	=> { command => 'method' } ],
    [ '=ATTRIBUTES',	'Collect'	=> { command => 'attr'   } ],

    [ 'Leftovers', 'Leftovers' => {} ],

    [ 'postlude', 'Region' => { region_name => 'postlude' } ],

    [ 'Bugs',		'Bugs'		=> {} ],
    [ '=SEE ALSO',	'Generic'	=> {} ],
    # Yes, it can be spelled either way.
    [ '=ACKNOWLEDGMENTS',  'Generic'	=> {} ],
    [ '=ACKNOWLEDGEMENTS', 'Generic'	=> {} ],
    [ 'Contributors',	'Contributors'	=> {} ],
    [ 'Authors',	'Authors'	=> {} ],
    [ 'Legal',		'Legal'		=> {} ],

    [ 'List', '-Transformer' => { transformer => 'List' } ],
);

my @process = (
    sub { s/^=// ? $_ : "$me/$_" },
    sub { Pod::Weaver::Config::Assembler->expand_package($_) },
    sub { $_ // {} },
);

foreach my $plugin (@plugins) {
    for my $i (0 .. $#process) {
	local $_ = $plugin->[$i];
	$plugin->[$i] = $process[$i]->();
    }
}

sub mvp_bundle_config { @plugins }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::ASDAGO - ASDAGO's Pod::Weaver plugin bundle

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is ASDAGO's plugin bundle for Pod::Weaver. Currently, there are
no configuration options.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-ASDAGO>
or by email to
L<bug-Dist-Zilla-PluginBundle-Author-ASDAGO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-ASDAGO@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Asher Gordon <AsDaGo@posteo.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
