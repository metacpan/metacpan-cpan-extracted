use v5.14;
use warnings;
use Benchmark 'cmpthese';

{
	package Using_Kavorka;
	use Moose;
	use Kavorka 0.005 qw( multi method );
	
	multi method fib ( Int $i where { $_ <= 1 } ) {
		return $i;
	}
	
	multi method fib ( Int $i ) {
		return $self->fib($i-1) + $self->fib($i-2);
	}
}

{
	package Using_MXMM;
	use Moose;
	use MooseX::MultiMethods;
	
	multi method fib ( Int $i where { $_ <= 1 } ) {
		return $i;
	}
	
	multi method fib ( Int $i ) {
		return $self->fib($i-1) + $self->fib($i-2);
	}
}

{
	package Using_Plain;
	use Moose;
	use Scalar::Util;
	
	sub fib {
		my $self = shift;
		my ($i) = @_;
		
		defined($i) && !ref($i) && $i =~ /\A-?[0-9]+\z/ or die;
		
		return $i if $i <= 1;
		return $self->fib($i-1) + $self->fib($i-2);
	}
}

cmpthese(-5, {
	Kavorka => q{
		my $obj = Using_Kavorka->new;
		$obj->fib($_) for 0..10;
	},
	MXMM => q{
		my $obj = Using_MXMM->new;
		$obj->fib($_) for 0..10;
	},
	Plain => q{
		my $obj = Using_Plain->new;
		$obj->fib($_) for 0..10;
	},
});

=pod

=encoding utf-8

=head1 PURPOSE

Benchmarking the following multi method:

   multi method fib ( Int $i where { $_ <= 1 } ) {
      return $i;
   }
   
   multi method fib ( Int $i ) {
      return $self->fib($i-1) + $self->fib($i-2);
   }

The code that invokes the multi method is:

   my $obj = $implementation->new;
   $obj->fib($_) for 0..10;

Modules tested are:

=over

=item *

L<Kavorka> (of course)

=item *

L<MooseX::MultiMethods>

=item

Plain old Perl 5 subs, for comparison.

=back

=head1 RESULTS

Running C<< perl -Ilib examples/benchmarks-multisub.pl >>:

            Rate    MXMM Kavorka   Plain
 MXMM    0.861/s      --    -89%   -100%
 Kavorka  7.81/s    807%      --    -97%
 Plain     276/s  32026%   3441%      --

Kavorka is the faster multi-method implementation, though is
significantly slower than avoiding multi-methods.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
