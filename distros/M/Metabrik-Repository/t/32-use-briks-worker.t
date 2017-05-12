use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Worker::Fork"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Worker::Parallel"); $@ ? 0 : 1 }, 1, $@);
