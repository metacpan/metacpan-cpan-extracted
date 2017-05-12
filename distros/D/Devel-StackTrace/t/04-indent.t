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

    for my $line ( split /\n/, $dst->as_string() ) {
        unlike( $line, qr/^\s/, 'line does not start with whitespace' );
    }
}

{
    my $dst = make_dst( indent => 1 );

    my @lines = split /\n/, $dst->as_string();
    shift @lines;

    for my $line (@lines) {
        like( $line, qr/^\s/, 'line starts with whitespace' );
    }
}

done_testing();
