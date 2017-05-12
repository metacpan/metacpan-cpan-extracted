use strict;
use Test::More tests => 18;
use Iterator;

# Check that new() fails when it should.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($iter, $x);

# New: too few (4)
eval
{
    $iter = Iterator->new();
};

$x = $@;
isnt $x, q{},   q{Too few parameters to new -> exception thrown};

ok (Iterator::X->caught(), q{Too-few exception base class ok});

ok (Iterator::X::Parameter_Error->caught(),  q{Too-few exception specific class ok});

begins_with $x,
    q{Too few parameters to Iterator->new()},
    q{Too-few exception works as a string, too};

# New: too many (4)
eval
{
    $iter = Iterator->new(sub {die}, 'whoa there');
};

$x = $@;
isnt $x, q{},   q{Too many parameters to new -> exception thrown};

ok (Iterator::X->caught(), q{Too-many exception base class ok});

ok (Iterator::X::Parameter_Error->caught(),  q{Too-many exception specific class ok});

begins_with $x,
    q{Too many parameters to Iterator->new()},
    q{Too-many exception works as a string, too};

# New: wrong type (4)
eval
{
    $iter = Iterator->new('whoa there');
};

$x = $@;
isnt $x, q{},   q{Wrong type of parameter to new -> exception thrown};

ok (Iterator::X->caught(), q{Wrong-type exception base class ok});

ok (Iterator::X::Parameter_Error->caught(),  q{Wrong-type exception specific class ok});

begins_with $x,
    q{Parameter to Iterator->new() must be code reference},
    q{Wrong-type exception works as a string, too};

# New: wrong type (looks like code but isn't) (4)
eval
{
    $iter = Iterator->new({qw/whoa there/});
};

$x = $@;
isnt $x, q{},   q{Bad code ref parameter to new -> exception thrown};

ok (Iterator::X->caught(), q{Bad-coderef exception base class ok});

ok (Iterator::X::Parameter_Error->caught(),  q{Bad-coderef exception specific class ok});

begins_with $x,
    q{Parameter to Iterator->new() must be code reference},
    q{Bad-coderef exception works as a string, too};

# New: everything fine (1)
eval
{
    my $i = 0;
    $iter = Iterator->new( sub {return $i++});
};

$x = $@;
is $x, q{},   q{Simple invocation: no exception};


# New: everything fine (1)
eval
{
    my $i = 0;
    $iter = Iterator->new( sub {
        Iterator::X::Am_Now_Exhausted->throw if $i > 10;
        return $i++;
    });
};

$x = $@;
is $x, q{},   q{more-complicated invocation: no exception};

