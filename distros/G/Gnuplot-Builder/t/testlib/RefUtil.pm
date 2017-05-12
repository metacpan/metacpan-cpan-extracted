package testlib::RefUtil;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Exporter qw(import);

our @EXPORT_OK = qw(is_different);

sub is_different {
    my ($obj1, $obj2, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isnt refaddr($obj1), refaddr($obj2), $msg;
}

1;
