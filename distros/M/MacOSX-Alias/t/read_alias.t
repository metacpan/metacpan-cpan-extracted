#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

use File::Spec;

my $class    = 'MacOSX::Alias';
my $function = 'read_alias';
my $target   = 'MANIFEST';
my $alias    = 'MANIFEST-alias';

use_ok( $class );
can_ok( $class, $function );
$class->import( ':all' );
ok( defined &{$function}, "main::${function} now defined (good)" );

ok( -e $target, "Target file [$target] exists" );
make_alias( $target, $alias );
ok( -e $alias, "Alias file [$alias] exists" );

my $full_path = File::Spec->rel2abs( $target );
#print STDERR "Full path is $full_path\n";

my $path = read_alias( $alias );
is( $path, $full_path );

END { unlink $alias }