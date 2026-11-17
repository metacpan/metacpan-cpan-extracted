#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: Dienste mit Konfigurationsdatei und reload.
# Behauptet wird: ohne reload_config (dnsmasq & Co.) uebernimmt erst ein
# Neustart die Datei; mit reload_config (nginx & Co.) auch ein reload, und der
# zaehlt nicht als Neustart.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = {
    srv => {
        type     => 'linux',
        files    => { '/etc/a.conf' => "alt\n", '/etc/b.conf' => "alt\n" },
        services => {
            dnsmasq => { active => JSON::MaybeXS::true(), config => '/etc/a.conf', running => "alt\n" },
            nginx   => { active => JSON::MaybeXS::true(), config => '/etc/b.conf', running => "alt\n", reload_config => JSON::MaybeXS::true() },
        },
    },
};
my $state = clone($start);
sub sh { my ( $o, $ok ) = run_command( $state, 'srv', $_[0] ); ok( $ok, $_[0] ) or diag $o }
my $svc = $state->{srv}{services};

sh('echo neu > /etc/a.conf; echo neu > /etc/b.conf');
sh('systemctl reload dnsmasq nginx');
is( $svc->{dnsmasq}{running}, "alt\n", 'dnsmasq: reload uebernimmt die Datei nicht' );
is( $svc->{nginx}{running},   "neu\n", 'nginx (reload_config): reload uebernimmt die Datei' );
ok( !$svc->{nginx}{restarts}, 'reload zaehlt nicht als Neustart' );
sh('systemctl restart dnsmasq');
is( $svc->{dnsmasq}{running}, "neu\n", 'dnsmasq: erst der Neustart uebernimmt sie' );
is( $svc->{dnsmasq}{restarts}, 1, 'und zaehlt' );

done_testing;
