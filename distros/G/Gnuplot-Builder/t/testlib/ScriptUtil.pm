package testlib::ScriptUtil;
use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Builder;
use Exporter qw(import);

our @EXPORT_OK = qw(plot_str);

sub plot_str {
    my ($builder, $method, %args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = "";
    $args{writer} = sub {
        my $part = shift;
        $result .= $part;
    };
    is $builder->$method(%args), "", "$method should return an empty string if writer is set.";
    return $result;
}

1;

