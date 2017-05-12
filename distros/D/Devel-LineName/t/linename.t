use strict;
use warnings;

use Carp;
use Test::More tests => 7;


# The line number used for a multiline block eval varies with perl version,
# so experiment to find out where it is with the perl.
sub eval_stackframe_at_open_line {
	my $open_line = __LINE__ ; eval {
		confess "testing eval line";
	} ; my $close_line = __LINE__;
	my $err = $@;

	if ($err =~ /eval .* called at .* line (\d+)/) {
		my $line = $1;
		if ($line == $open_line) {
			return 1;
		} elsif ($line == $close_line) {
			return 0;
		} else {
			confess "eval stackframe on unexpected line $line, expecting $open_line or $close_line";
		}
	} else {
		confess "unable to parse confess backtrace [$err]";
	}
}
our $eval_key = eval_stackframe_at_open_line() ? 'eval_open' : 'eval_close';


{
    my %Line;
    use Devel::LineName linename => \%Line;

    eval {
        die "oops";   use linename 'foo';
    };

    is $@, "oops at $0 line $Line{foo}.\n", "SYNOPSIS example";
}

{
    my %Line;
    use Devel::LineName linename => \%Line;

    eval {                use linename 'eval_open';
        outer_sub();      use linename 'outer_call';
    };                    use linename 'eval_close';

    my $goterr = $@;
    $goterr =~ s/[.]\n/\n/g;
    is $goterr, <<END, "DESCRIPTION example";
woo at $0 line $Line{confess}
\tmain::inner_sub() called at $0 line $Line{inner_call}
\tmain::outer_sub() called at $0 line $Line{outer_call}
\teval {...} called at $0 line $Line{$eval_key}
END

    sub outer_sub {
        inner_sub();      use linename 'inner_call';
    }

    sub inner_sub {
        confess "woo";    use linename 'confess';
    }
}

{
    my %Line;
    use Devel::LineName linename => \%Line;

    eval {                use linename 'eval_open';
        outer_sub2();     use linename 'outer_call';
    };                    use linename 'eval_close';

    my $goterr = $@;
    $goterr =~ s/[.]\n/\n/g;
    is $goterr, <<END, "DESCRIPTION example repeated";
woo at $0 line $Line{confess}
\tmain::inner_sub2() called at $0 line $Line{inner_call}
\tmain::outer_sub2() called at $0 line $Line{outer_call}
\teval {...} called at $0 line $Line{$eval_key}
END

    sub outer_sub2 {
        inner_sub2();     use linename 'inner_call';
    }

    sub inner_sub2 {
        confess "woo";    use linename 'confess';
    }
}

{
    my %Line;
    use Devel::LineName linename => \%Line;

    eval {
        die 'foo'; use linename 'foo';
    };
    like $@, qr/ line $Line{foo}\./, "linename on same line";

    eval {
        die 'bar';
        use linename 'bar', -1;
    };
    like $@, qr/ line $Line{bar}\./, "linename on line below";

    eval {
        use linename 'baz', +1;
        die 'baz';
    };
    like $@, qr/ line $Line{baz}\./, "linename on line above";
}

{
    my %Line;
    use Devel::LineName linename => \%Line;

    sub foo {
        return 17;  use linename 'fooreturn';
    }

    is foo(), 17, "linename doesn't interfere with return value";
}

