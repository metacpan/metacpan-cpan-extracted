use v5.14;
use warnings;
use Benchmark 'cmpthese';

package Using_FP_TT {
	use Function::Parameters ':strict';
	use Types::Standard -types;
	method foo ( (Int) $x, (ArrayRef[Int]) $y ) {
		return [ $x, $y ];
	}
}

package Using_FP_Moose {
	use Function::Parameters ':strict';
	method foo ( Int $x, ArrayRef[Int] $y ) {
		return [ $x, $y ];
	}
}

package Using_Kavorka {
	use Kavorka;
	method foo ( Int $x, ArrayRef[Int] $y ) {
		return [ $x, $y ];
	}
}

package Using_MS {
	use Moose;
	use Method::Signatures;
	method foo ( Int $x, ArrayRef[Int] $y ) {
		return [ $x, $y ];
	}
}

package Using_MXMS {
	use Moose;
	use MooseX::Method::Signatures;
	method foo ( $class : Int $x, ArrayRef[Int] $y ) {
		return [ $x, $y ];
	}
}

package Using_TParams {
	use Types::Standard -types;
	use Type::Params 'compile';
	sub foo {
		state $signature = compile( 1, Int, ArrayRef[Int] );
		my ($self, $x, $y) = $signature->(@_);
		return [ $x, $y ];
	}
}

cmpthese(-3, {
	map {
		my $class = "Using_$_";
		$_ => qq[ $class\->foo(0, [1..10]) ];
	} qw( FP_Moose FP_TT Kavorka TParams MS MXMS )
});

=pod

=encoding utf-8

=head1 PURPOSE

Benchmarking the following method call defined with several different
modules:

	method foo ( Int $x, ArrayRef[Int] $y ) {
		return [ $x, $y ];
	}

Modules tested are:

=over

=item *

L<Kavorka> (of course)

=item *

L<Type::Params> (not as sugary, but probably the fastest pure Perl method
signature implementation on CPAN)

=item *

L<Function::Parameters> plus L<Moose> type constraints

=item *

L<Function::Parameters> plus L<Type::Tiny> type constraints

=item *

L<Method::Signatures>

=item *

L<MooseX::Method::Signatures>

=back

In all cases, L<Type::Tiny::XS> is installed. This gives a speed boost to
Kavorka, Type::Params, and one of the Function::Parameters examples.

=head1 RESULTS

=head2 Standard Results

Running C<< perl -Ilib examples/benchmarks.pl >>:

             Rate     MXMS       MS FP_Moose  TParams    FP_TT  Kavorka
 MXMS       654/s       --     -91%     -93%     -98%     -98%     -98%
 MS        7129/s     990%       --     -18%     -78%     -82%     -83%
 FP_Moose  8719/s    1233%      22%       --     -74%     -78%     -79%
 TParams  32905/s    4933%     362%     277%       --     -17%     -20%
 FP_TT    39648/s    5964%     456%     355%      20%       --      -3%
 Kavorka  41008/s    6172%     475%     370%      25%       3%       --

Kavorka is the winner.

Yes, that's right, it's about 60 or so times faster than
MooseX::Method::Signatures.

Note that if L<Any::Moose> is loaded before L<Moose>, then Method::Signatures
will be able to use Mouse's type constraints instead of Moose's. In that case,
the Method::Signatures results are much closer to Kavorka. (In the table above
they'd be about 30000/s.)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
