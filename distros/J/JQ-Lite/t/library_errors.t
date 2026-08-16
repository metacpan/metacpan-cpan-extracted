use strict;
use warnings;
use Test::More;
use JQ::Lite;
use JQ::Lite::Error ();

my $jq = JQ::Lite->new;

sub capture_error (&) {
    my ($code) = @_;
    local $@;
    my $ok = eval { $code->(); 1 };
    return ($ok, $@);
}

{
    my ($ok, $error) = capture_error { $jq->run_query('{', '.') };
    ok(!$ok, 'invalid JSON throws');
    isa_ok($error, 'JQ::Lite::Error::Input');
    is($error->category, 'input', 'input error exposes input category');
    like("$error", qr/(?:expected|malformed|unexpected|JSON)/i, 'input error preserves a useful message');
}

{
    my ($ok, $error) = capture_error { $jq->run_query('{}', '.foo |') };
    ok(!$ok, 'malformed query throws');
    isa_ok($error, 'JQ::Lite::Error::Parse');
    is($error->category, 'parse', 'parse error exposes parse category');
    like("$error", qr/Invalid query syntax/, 'parse error stringifies to human-readable message');
}

{
    my ($ok, $error) = capture_error { $jq->run_query('{"a":1}', '1/0') };
    ok(!$ok, 'evaluation failure throws');
    isa_ok($error, 'JQ::Lite::Error::Evaluation');
    is($error->category, 'evaluation', 'evaluation error exposes evaluation category');
    like("$error", qr/Division by zero/, 'evaluation error preserves previous message text');
}

{
    my ($ok, $error) = capture_error { die JQ::Lite::Error::Parse->new(message => "example message\n") };
    ok(!$ok, 'structured error can be thrown directly');
    is("$error", 'example message', 'structured errors stringify without an added class prefix');
    is($error->message, 'example message', 'message accessor returns normalized message');
}

done_testing;
