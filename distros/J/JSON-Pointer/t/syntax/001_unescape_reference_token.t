#!perl -w
use strict;
use Test::More;
use JSON::Pointer::Syntax qw(unescape_reference_token);

sub test_unescape_reference_token {
    my ($unescaped_reference_token, $expect, $desc) = @_;
    my $actual = unescape_reference_token($unescaped_reference_token);
    is($actual, $expect, $desc);
}

### 4. Evaluation
### https://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-09#section-4

test_unescape_reference_token("~1", "/", "escaped /");
test_unescape_reference_token("~0", "~", "escaped ~");
test_unescape_reference_token("~01", "~1", "escaped ~ and 1");

done_testing;
