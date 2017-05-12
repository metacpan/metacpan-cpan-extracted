#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

#use Cwd qw(cwd);
#print STDERR "cwd is ", cwd(), "\n";

my $class    = 'MacOSX::Alias';
my $function = 'make_alias';
my $target   = 'MANIFEST';
my $alias    = 'MANIFEST-alias';

use_ok( $class );
can_ok( $class, $function );
$class->import( $function );
ok( defined &{$function}, "main::${function} now defined (good)" );

ok( -e $target, "Target file [$target] is there" );
ok( ! -e $alias, "Alias file [$alias] is not there yet (good)" );

make_alias( 'MANIFEST', 'MANIFEST-alias' );

ok( -e $alias, "Alias file [$alias] is now there" );

END { unlink $alias }