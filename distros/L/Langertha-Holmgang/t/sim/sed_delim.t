#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# sed mit eigenem Trenner: in s|…|…| ist \|
# das Zeichen | und keine Alternative (GNU sed), in BRE wie in ERE; mit / bleibt \/
# ein /. Behauptet wird die Ersetzung genau der gemeinten Zeile.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = { h => { type => 'linux', files => { '/etc/c.yaml' => qq{test: ["CMD-SHELL", "wget -qO- http://localhost:\$PORT/health || exit 1"]\nweiter: 1\n} } } };
my $state;
sub sh { my ( $o, $ok ) = run_command( $state, 'h', $_[0] ); return wantarray ? ( $o, $ok ) : $o }

$state = clone($start);
my ( $o, $ok ) = sh(q{sed -i 's|wget -qO- http://localhost:$PORT/health \|\| exit 1|wget -qO- http://localhost:$${PORT}/health|' /etc/c.yaml});
ok( $ok, 'sed mit \| im Muster gelingt' ) or diag $o;
is( $state->{h}{files}{'/etc/c.yaml'}, qq{test: ["CMD-SHELL", "wget -qO- http://localhost:\$\${PORT}/health"]\nweiter: 1\n}, 'BRE: \| ist der Trenner als Zeichen' );

$state = clone($start);
sh(q{sed -E -i 's|health \|\| exit 1|health|' /etc/c.yaml});
like( $state->{h}{files}{'/etc/c.yaml'}, qr{/health"\]\n}, 'ERE: ebenso' );

$state = clone($start);
sh(q{sed -i 's/localhost:\$PORT\/health/localhost:8080\/health/' /etc/c.yaml});
like( $state->{h}{files}{'/etc/c.yaml'}, qr{localhost:8080/health}, 'mit / bleibt \/ ein /' );

done_testing;
