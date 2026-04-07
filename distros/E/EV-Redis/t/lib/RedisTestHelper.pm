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
    });
    EV::run;
    return ($major, $minor);
}

1;
