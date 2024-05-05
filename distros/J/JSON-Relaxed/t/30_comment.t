#! perl

use v5.26;

use Test::More tests => 2;
use JSON::Relaxed 0.061;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# In 0.5 there was a problem that a newline after a space was
# combined into a single whitespace. Relatively harmless except when
# the newline was supposed to end a // comment.

my $json = <<'EOD';
{
    "empty"  : 1.0, // 
}
EOD
my $p = JSON::Relaxed::Parser->new;
my $res = $p->parse($json);
is_deeply( $res, { empty => '1.0' }, "trailing space in comment" );
diag($p->err_msg) if $p->is_error;

# In 0.61 there was a problem that an escaped newline would not
# terminate a // comment.

$json = <<'EOD';
{
    "empty"  : 1.0,
// blah\
}
EOD
$p = JSON::Relaxed::Parser->new;
$res = $p->parse($json);
is_deeply( $res, { empty => '1.0' }, "trailing newline in comment" );
diag($p->err_msg) if $p->is_error;


