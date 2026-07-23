package RedisTestHelper;
use strict;
use warnings;
use Exporter 'import';
use EV;
use EV::Redis;

our @EXPORT_OK = qw(get_redis_version);

sub get_redis_version {
    my ($sock) = @_;
    my ($major, $minor) = (0, 0);
    my $r = EV::Redis->new(path => $sock);
    $r->info('server', sub {
        my ($info, $err) = @_;
        if ($info && $info =~ /redis_version:(\d+)\.(\d+)/) {
            ($major, $minor) = ($1, $2);
        }
        $r->disconnect;
        EV::break;
    });
    # Guard timer: never depend on ambient loop state (an idle caller
    # connection would otherwise keep this EV::run from returning).
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;
    return ($major, $minor);
}

1;
