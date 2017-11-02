use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Audio::Soundconverter"); $@ ? 0 : 1 }, 1, $@);
