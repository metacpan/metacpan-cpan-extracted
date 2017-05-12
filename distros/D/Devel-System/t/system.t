#!perl -w
use strict;
use Test::More tests => 8;
use IO::Scalar;
BEGIN { use_ok('Devel::System') }

my $out;
$Devel::System::fh = IO::Scalar->new(\$out);
$Devel::System::dry_run = 1;

$out = '';
system 'foo bar baz';
is( $out, "+ foo bar baz\n", "standard shell call" );

$out = '';
system 'foo', 'bar baz';
is( $out, "+ foo 'bar baz'\n", "with shell quoting" );

is( (system "$^X -e'exit 1'"), 0, "dry_run returns 0" );

$Devel::System::return = 42;
is( (system "$^X -e'exit 1'"), 42, "retval setting" );

$Devel::System::dry_run = 0;
is( (system "$^X -e'exit 1'"), 1<<8, "non-dry_run returns correct value" );

# perl -MDevel::System=dry_run
Devel::System->import('dry_run');

is( $Devel::System::dry_run, 1, "turning dry_run on via import line" );

eval { Devel::System->import('bogus') };
like( $@, qr/^unknown option 'bogus'/, "bogus import croaked" );

