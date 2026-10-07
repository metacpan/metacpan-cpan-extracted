package RedisTestHelper;
use strict;
use warnings;
use Exporter 'import';
use EV;
use EV::Redis;

our @EXPORT_OK = qw(get_redis_version);

sub get_redis_version {
    my ($sock) = @_;
    my ($major, $minor, $done) = (0, 0);
    my $r = EV::Redis->new(path => $sock);
    $r->info('server', sub {
        return if $done;
        my ($info, $err) = @_;
        if ($info && $info =~ /redis_version:(\d+)\.(\d+)/) {
            ($major, $minor) = ($1, $2);
        }
        $r->disconnect;
        EV::break;
    });
    # the INFO reply may never arrive; the loop's clock was last read before
    # the caller's slow setup
    EV::now_update;
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;
    $done = 1;
    return ($major, $minor);
}

1;
