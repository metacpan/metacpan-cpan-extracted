#!/usr/bin/env perl
# FILENAME: simple_io.pl
# CREATED: 06/02/14 17:41:09 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test simple INI parsing capacity with bundles without loading them

use strict;
use warnings;
use Test::More;

my $SAMPLE = <<'EOF';
name = Foo
value = bar

[Package / Name]
value = baz
foo = quux

[@Classic]

[PackageTwo / NameTwo]
value = baz
foo = quux
EOF

use Dist::Zilla::Util::ExpandINI;

my $ct = Dist::Zilla::Util::ExpandINI->new();
$ct->_load_string($SAMPLE);
my $ds = $ct->_data;

is( $ds->[0]->{name}, '_',    '_ section' );
is( $ds->[1]->{name}, 'Name', 'First Package' );
is_deeply( $ds->[1]->{lines}, [ 'value', 'baz', 'foo', 'quux' ], 'Values retain order' );
is( $ds->[3]->{name}, 'NameTwo', 'First Package' );
is_deeply( $ds->[3]->{lines}, [ 'value', 'baz', 'foo', 'quux' ], 'Plugins retain order' );

#note explain $ds;
my $out = $ct->_store_string;

is( $out, $SAMPLE, "Round trip preserves format!" );

done_testing;
