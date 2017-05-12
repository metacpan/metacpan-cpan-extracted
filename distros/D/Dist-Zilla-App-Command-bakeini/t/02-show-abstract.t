use strict;
use warnings;

use Test::More;
use Dist::Zilla::Util::Test::KENTNL 1.005000 qw( dztest );

# ABSTRACT: ensure abstract { } is called.

my $test = dztest;
my $result = $test->run_command( ['commands'] );
ok( ref $result, 'self test executed' );
is( $result->error,     undef, 'no errors' );
is( $result->exit_code, 0,     'exit == 0' );
my (@lines) = split /\r?\n/msx, $result->stdout;
my (@baked) = grep { $_ =~ /\sbakeini:/ } @lines;

my $lines_ok = 1;

$lines_ok &&= is( scalar @baked, 1, 'One bakeini line' );
$lines_ok &&= like( $baked[0], qr/bake dist\.ini from dist\.ini\.meta/, "Abstract is as expected" );

diag explain \@lines if not $lines_ok;

done_testing;

