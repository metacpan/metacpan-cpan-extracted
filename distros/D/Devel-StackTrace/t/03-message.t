use strict;
use warnings;

use Test::More;

use Devel::StackTrace;

sub foo {
    return Devel::StackTrace->new(@_);
}

sub make_dst {
    foo(@_);
}

{
    my $dst = make_dst();

    like(
        $dst->as_string(), qr/^Trace begun/,
        q{default message is "Trace begun"}
    );
}

{
    my $dst = make_dst( message => 'Foo bar' );

    like(
        $dst->as_string(), qr/^Foo bar/,
        q{set explicit message for trace}
    );
}

done_testing();
