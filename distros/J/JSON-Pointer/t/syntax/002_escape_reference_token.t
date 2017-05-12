#!perl -w
use strict;
use Test::More;

use JSON::Pointer::Syntax qw(escape_reference_token);

sub test_escape_reference_token {
    my ($escaped_reference_token, $expect, $desc) = @_;
    my $actual = escape_reference_token($escaped_reference_token);
    is($actual, $expect, $desc);
}

### 4. Evaluation
### https://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-09#section-4

test_escape_reference_token("/", "~1", "escapes /");
test_escape_reference_token("~", "~0", "escapes ~");
test_escape_reference_token("~1", "~01", "escapes ~1");

done_testing;
