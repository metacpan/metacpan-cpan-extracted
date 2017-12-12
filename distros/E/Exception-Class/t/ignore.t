use strict;
use warnings;

use Test::More;

## no critic (Modules::ProhibitMultiplePackages)
{
    package Foo;

    sub foo {
        my $class = shift;

        TestException->throw(@_) unless $class eq 'Foo';

        Bar->bar(@_);
    }
}

{
    package Bar;

    sub bar {
        shift;
        Baz->baz(@_);
    }
}

{
    package Baz;

    use base 'Foo';

    sub baz {
        shift->foo(@_);
    }
}

use strict;

use Exception::Class qw(TestException);

sub check_trace {
    my ( $trace, $unwanted_pkg, $unwanted_class ) = @_;

    my ($bad_frame);
    while ( my $frame = $trace->next_frame ) {
        if (   ( grep { $frame->package eq $_ } @$unwanted_pkg )
            || ( grep { $frame->package->isa($_) } @$unwanted_class ) ) {
            $bad_frame = $frame;
            last;
        }
    }

    ok( !$bad_frame, 'Check for unwanted frames' );
    diag( 'Unwanted frame found: ' . $bad_frame->as_string )
        if $bad_frame;
}

## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
eval { Foo->foo() };
my $e = $@;

check_trace( $e->trace, [], [] );

eval { Foo->foo( ignore_package => ['Baz'] ) };
$e = $@;

check_trace( $e->trace, ['Baz'], [] );

eval { Foo->foo( ignore_class => ['Foo'] ) };
$e = $@;

check_trace( $e->trace, [], ['Foo'] );

eval { Foo->foo( ignore_package => [ 'Foo', 'Baz' ] ) };
$e = $@;

check_trace( $e->trace, [ 'Foo', 'Baz' ], [] );

eval { Foo->foo( skip_frames => 5 ) };
$e = $@;

check_trace( $e->trace, ['Baz'], [] );

eval {
    Foo->foo(
        frame_filter => sub {
            my $p = shift;
            return 0 if defined $p->{args}[0] && $p->{args}[0] eq 'Baz';
            return 1;
        }
    );
};
$e = $@;

check_trace( $e->trace, ['Baz'], [] );

done_testing();
