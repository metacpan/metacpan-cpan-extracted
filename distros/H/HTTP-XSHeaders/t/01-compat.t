use strict;
use warnings;

use Test::More;
plan skip_all => 'this test requires HTTP::Headers 5.822 or later' unless eval "use HTTP::Headers 5.822; 1;";
plan skip_all => 'this test requires HTTP::Headers::Fast' unless eval "use HTTP::Headers::Fast; 1;";
plan tests => 2;

use HTTP::XSHeaders;

sub test($&) {
    my ($title, $code) = @_;
    is $code->('HTTP::Headers::Fast'), $code->('HTTP::Headers'), $title;
}

test 'header' => sub {
    my $klass = shift;
    my $h = $klass->new;
    $h->header('foo' => 'bar');
    $h->push_header('foo' => undef);
};

test "push_header's return value" => sub {
    my $klass = shift;
    my $h = $klass->new;
    $h->header('foo' => 'bar');
    $h->push_header('foo' => 'baz');
};

