use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

foreach my $case (
    {label => "no arg", args => [], exp => ""},
    {label => "undef", args => [key => undef], exp => "unset key\n"},
    {label => "string", args => [term => 'png size 100,100 enhanced'],
     exp => "set term png size 100,100 enhanced\n"},
    {label => "array-ref", args => [arrow => ['1 from 0,0 to 1,1',
                                              '2 from 0,0 to 2,2']],
     exp => "set arrow 1 from 0,0 to 1,1\nset arrow 2 from 0,0 to 2,2\n"},
    {label => "array-ref with undef", args => [arrow => [undef, '1']],
     exp => "unset arrow\nset arrow 1\n"},
    {label => "empty array-ref", args => [arrow => []], exp => ""},
    {label => "code-ref -> undef", args => [foo => sub { undef }], exp => "unset foo\n"},
    {label => "code-ref -> string", args => [foo => sub { "bar" }], exp => "set foo bar\n"},
    {label => "code-ref -> list", args => [foo => sub { ("bar", "buzz") }],
     exp => "set foo bar\nset foo buzz\n"},
    {label => "code-ref -> empty", args => [foo => sub { () }], exp => ""},
    {label => "single name", args => ["key"], exp => "set key\n"},
    {label => "single unset name", args => ["-key"], exp => "unset key\n"},
) {
    my $label = $case->{label};
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->set(@{$case->{args}}), $builder, "$label: set() should return the object.";
    is $builder->to_string, $case->{exp}, "$label: result OK";
}

done_testing;

