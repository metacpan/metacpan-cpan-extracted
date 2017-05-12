package Math::SymbolicX::Statistics::Distributions;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.02';

use Math::Symbolic qw/parse_from_string/;
use Carp qw/confess cluck/;

require Exporter;
# Exporter stuff is implemented at the end of the module because
# we need to access the different distribution functions.




=head1 NAME

Math::SymbolicX::Statistics::Distributions - Statistical Distributions

=head1 SYNOPSIS

  use Math::SymbolicX::Statistics::Distributions ':all';
  
  #####################################################
  # The following demonstrates the procedural interface
  
  # (included in :all)
  use Math::SymbolicX::Statistics::Distributions ':functions';
  
  $dist = normal_distribution('mean', 'rmsd');
  print $dist->value(mean => 5, rmsd => 2, x => 1);
  
  # similar:
  $dist = gauss_distribution('mean', 'rmsd'); # same as normal_distribution
  $dist = bivariate_normal_distribution( 'mean1', 'rmsd1',
                                         'mean2', 'rmsd2',
                                         'correlation      );
  
  # plug in any expression: (y*2 will be mean, z^3 root mean square deviation)
  $dist = normal_distribution('y*2', 'z^3');
  print $dist->value(x => 0.5, y => 3, z => 0.2);
  
  # To generate the error function: (mean = 0; rmsd = 1)
  $dist = normal_distribution(0, 1);
  print $dist->value(x => 1);
  
  #########################################################
  # The following demonstrates the parser/grammar interface
  # We'll do the exact same as above with the other interface.  
  
  # (included in :all)
  use Math::SymbolicX::Statistics::Distributions ':grammar';
  use Math::Symbolic qw/parse_from_string/;
  
  $dist = parse_from_string('normal()');
  print $dist->value(mean => 5, rmsd => 2, x => 1);
  
  # similar:
  $dist = parse_from_string('gauss(mean, rmsd)'); # same as normal()
  $dist = parse_from_string( 'bivariate_normal(mean1, rmsd1,'
                                             .'mean2, rmsd2,'
                                             .'correlation  )' );
  
  # plug in any expression: (y*2 will be mean, z^3 root mean square deviation)
  $dist = parse_from_string('normal(y*2, z^3)');
  print $dist->value(x => 0.5, y => 3, z => 0.2);
  
  # To generate the error function: (mean = 0; rmsd = 1)
  $dist = parse_from_string('normal(0, 1)');
  print $dist->value(x => 1);
  
  # same works for the keywords 'boltzmann', 'bose', 'fermi'

=head1 DESCRIPTION

This module offers easy access to formulas for a few often-used
distributions. For that, it uses the Math::Symbolic module which gives the
user an opportunity to manufacture distributions to his liking.

The module can be used in two styles: It has a procedural interface which
is demonstrated in the first half of the synopsis. But it also
features a wholly different interface: It can modify the Math::Symbolic
parser so that you can use the distributions right inside strings
that will be parsed as Math::Symbolic trees. This is demonstrated for
very simple cases in the second half of the synopsis.

All arguments in both interface styles are optional.
Whichever expression is used instead of, for examle C<'mean'>, is plugged
into the formula for the distribution as a Math::Symbolic tree.
Details on argument handling are explained below.

Please see the section on I<Export> for details
on how to choose the interface style you want to use.

The arguments for the grammar-interface version of the module
follow the same concept as for the function interface which is described
in L<Distributions> in detail. The only significant difference is that the
arguments must all be strings to be parsed as Math::Symbolic trees.
There is one exception: If the string 'undef' is passed as one argument
to the function, that string is converted to a real undef, but nevermind and
see below.

=head2 Export

By default, the module does not export any functions and does not modify
the Math::Symbolic parser. You have to explicitly request that does so
using the usual L<Exporter> semantics.

If using the module without parameters
(C<use Math:SymbolicX::Statistics::Distributions;>), you can access the
distributions via the fully qualified subroutine names such as
C<Math::SymbolicX::Statistics::Distributions::normal_distribution()>. But that
would be annoying, no?

You can choose to export any of the distribution functions (see below) by
specifying one or more function names:

  use Math::SymbolicX::Statistics::Distributions qw/gauss_distribution/;
  # then:
  $dist = gauss_distribution(...);

You can also import all of them by using the ':functions' tag:

  use Math::SymbolicX::Statistics::Distributions qw/:functions/;
  ...

Alternatively, you can choose to modify the Math::Symbolic parser by using
any of the following keywords in the same way we used the function names
above.

  normal_grammar
  gauss_grammar
  bivariate_normal_grammar
  cauchy_grammar
  boltzmann_grammar
  bose_grammar
  fermi_grammar

To add all the keywords (C<normal()>, C<gauss()>, C<bivariate_normal()>,
C<cauchy()>, C<boltzmann()>, C<bose()>, and C<fermi()>
to the grammar, you can specify C<:grammar> instead.

Finally, the module supports the exporter tag C<:all> to both export
all functions and add all keywords to the parser.

=head2 Distributions

The following is a list of distributions that can be generated using 
this module.

=over 2

=cut

=item Normal (Gauss) Distribution

Normal (or Gauss) distributions are availlable through the functions
C<normal_distribution> or C<gauss_distribution> which are equivalent.
The functions return the Math::Symbolic representation of a
gauss distribution.

The gauss distribution has three parameters: The mean C<mu>, the
root mean square deviation C<sigma> and the variable C<x>.

The functions take two optional arguments: The Math::Symbolic trees (or strings)
to be plugged into the formula for 1) C<mu> and 2) C<sigma>.

If any argument is undefined or omitted, the corresponding variable will
remain unchanged.

The variable C<x> always remains in the formula.

Please refer to the literature referenced in the SEE ALSO section for 
details.

=cut

{
	my $parsed;
	sub normal_distribution {
		my ($mu, $sigma) = @_;
		$mu    = 'mu'    if not defined $mu;
		$sigma = 'sigma' if not defined $sigma;
		
		# parse arguments
		$mu    = _parse_arguments($mu   , 'mu'   );
		$sigma = _parse_arguments($sigma, 'sigma');
		
		# Generate the template object tree
		if (not defined $parsed) {
			$parsed = parse_from_string(
			'e^(-1*(x-mu)^2/(2*sigma^2))/(sigma*(2*pi)^0.5)'
			);
			
			# Implement special numbers
			$parsed->implement(
				e  => Math::Symbolic::Constant->euler(),
				pi => Math::Symbolic::Constant->pi(),
			);
		}

		# Always return a clone of the template object tree.
		my $distribution = $parsed->new();
		

		# Implement specified variables in a separate step in case
		# they contain e's and pi's.
		$distribution->implement(
			sigma => $sigma,
			mu    => $mu,
		);

		return $distribution;
	}
}

*gauss_distribution = \&normal_distribution;






=item Bivariate Normal Distribution

Bivariate normal distributions are availlable through the function
C<bivariate_normal_distribution>.
The function returns the Math::Symbolic representation of a
bivariate normal distribution.

The bivariate normal distribution has seven parameters:
The mean C<mu1> of the first variable,
the root mean square deviation C<sigma1> of the first variable,
the mean C<mu2> of the second variable,
the root mean square deviation C<sigma2> of the second variable,
the first variable C<x1>,
the second variable C<x2>,
and the correlation of the first and second variables, C<sigma12>.

The function takes five optional arguments: The Math::Symbolic trees
(or strings) to be plugged into the formula for
1) C<mu1>,
2) C<sigma1>,
3) C<mu1>,
4) C<sigma1>, and
5) C<sigma12>.

If any argument is undefined or omitted, the corresponding variable will
remain unchanged.

The variables C<x1> and C<x2> always remain in the formula.

Please refer to the literature referenced in the SEE ALSO section for 
details.

=cut

{
	my $parsed;
	sub bivariate_normal_distribution {
		my ($mu1, $sigma1, $mu2, $sigma2, $corr) = @_;
		$mu1    = 'mu1'         if not defined $mu1;
		$sigma1 = 'sigma1'      if not defined $sigma1;
		$mu2    = 'mu2'         if not defined $mu2;
		$sigma2 = 'sigma2'      if not defined $sigma2;
		$corr   = 'sigma12'     if not defined $corr;
		
		# parse arguments
		$mu1    = _parse_arguments($mu1   , 'mu1'        );
		$sigma1 = _parse_arguments($sigma1, 'sigma1'     );
		$mu2    = _parse_arguments($mu2   , 'mu2'        );
		$sigma2 = _parse_arguments($sigma2, 'sigma2'     );
		$corr   = _parse_arguments($corr  , 'sigma12'    );
		
		# Generate the template object tree
		if (not defined $parsed) {
			$parsed = parse_from_string(<<'HERE');
e ^ (
      (
        2 * sigma12 * (x1-mu1) * (x2-mu2) / (sigma1*sigma2)^2
        - ( (x1-mu1)/sigma1 )^2 - ( (x2-mu2)/sigma2 )^2
      )
      / (
          2 - 2*(sigma12/sigma1/sigma2)^2
        )
    )
/ (
    2 * pi * sigma1 * sigma2
    * ( 1 - (sigma12/sigma1/sigma2)^2 )^0.5
  )
HERE
			
			# Implement special numbers
			$parsed->implement(
				e  => Math::Symbolic::Constant->euler(),
				pi => Math::Symbolic::Constant->pi(),
			);
		}

		# Always return a clone of the template object tree.
		my $distribution = $parsed->new();
		

		# Implement specified variables in a separate step in case
		# they contain e's and pi's.
		$distribution->implement(
			sigma1      => $sigma1,
			mu1         => $mu1,
			sigma2      => $sigma2,
			mu2         => $mu2,
			sigma12     => $corr,
		);
		
		return $distribution;
	}
}





=item Cauchy Distribution

Cauchy distributions are availlable through the function
C<cauchy_distribution>.
The function returns the Math::Symbolic representation of a
cauchy distribution.

The cauchy distribution has three parameters:
The median C<m>,
the full width at half maximum C<lambda> of the curve,
and the variable C<x>.

The function takes two optional arguments: The Math::Symbolic trees
(or strings) to be plugged into the formula for
1) C<m> and
2) C<lambda>.

If any argument is undefined or omitted, the corresponding variable will
remain unchanged.

The variable C<x> always remains in the formula.

Please refer to the literature referenced in the SEE ALSO section for 
details.

=cut

{
	my $parsed;
	sub cauchy_distribution {
		my ($median, $fwhm) = @_;
		$median = 'm'      if not defined $median;
		$fwhm   = 'lambda' if not defined $fwhm;
		
		# parse arguments
		$median = _parse_arguments($median, 'm'     );
		$fwhm   = _parse_arguments($fwhm,   'lambda');
		
		# Generate the template object tree
		if (not defined $parsed) {
			$parsed = parse_from_string(
			'lambda/(2*pi*( (x-m)^2 + lambda^2/4 ))'
			);
			
			# Implement special numbers
			$parsed->implement(
				pi => Math::Symbolic::Constant->pi(),
			);
		}

		# Always return a clone of the template object tree.
		my $distribution = $parsed->new();
		

		# Implement specified variables in a separate step in case
		# they contain e's and pi's.
		$distribution->implement(
			lambda => $fwhm,
			m      => $median,
		);

		return $distribution;
	}
}



=item Boltzmann Distribution

Boltzmann distributions are availlable through the function
C<boltzmann_distribution>.
The function returns the Math::Symbolic representation of a
Boltzmann distribution.

The Boltzmann distribution has four parameters:
The energy C<E>,
the weighting factor C<gs> that describes the number of states at
energy C<E>, the temperature C<T>,
and the chemical potential C<mu>.

The function takes fouroptional arguments: The Math::Symbolic trees
(or strings) to be plugged into the formula for
1) C<E>,
2) C<gs>,
3) C<T>, and
4) C<mu>

If any argument is undefined or omitted, the corresponding variable will
remain unchanged.

The formula used is: C<N = gs * e^(-(E-mu)/(k_B*T))>.

Please refer to the literature referenced in the SEE ALSO section for 
details. Boltzmann's constant C<k_B> is used as C<1.3807 * 10^-23 J/K>.

=cut

{
	my $parsed;
	sub boltzmann_distribution {
		my ($E, $gs, $T, $mu) = @_;
		$E  = 'E'       if not defined $E;
		$gs = 'gs'      if not defined $gs;
		$T  = 'T'       if not defined $T;
		$mu = 'mu'      if not defined $mu;
		
		# parse arguments
		$E     = _parse_arguments($E    , 'E'        );
		$gs    = _parse_arguments($gs   , 'gs'       );
		$T     = _parse_arguments($T    , 'T'        );
		$mu    = _parse_arguments($mu   , 'mu'       );
		
		# Generate the template object tree
		if (not defined $parsed) {
			$parsed = parse_from_string(<<'HERE');
gs /
e ^ (
	(E - mu) / (k_B * T)
)
HERE
			
			# Implement special numbers
			$parsed->implement(
				e  => Math::Symbolic::Constant->euler(),
#				pi => Math::Symbolic::Constant->pi(),
				k_B => Math::Symbolic::Constant->new(1.3807e-23),
			);
		}

		# Always return a clone of the template object tree.
		my $distribution = $parsed->new();
		

		# Implement specified variables in a separate step in case
		# they contain e's and pi's.
		$distribution->implement(
			E  => $E,
			gs => $gs,
			T  => $T,
			mu => $mu,
		);
		
		return $distribution;
	}
}



=item Fermi Distribution

Fermi distributions are availlable through the function
C<fermi_distribution>.
The function returns the Math::Symbolic representation of a
Fermi distribution.

The Fermi distribution has four parameters:
The energy C<E>,
the weighting factor C<gs> that describes the number of states at
energy C<E>, the temperature C<T>,
and the chemical potential C<mu>.

The function takes fouroptional arguments: The Math::Symbolic trees
(or strings) to be plugged into the formula for
1) C<E>,
2) C<gs>,
3) C<T>, and
4) C<mu>

If any argument is undefined or omitted, the corresponding variable will
remain unchanged.

The formula used is: C<N = gs / ( e^((E-mu)/(k_B*T)) + 1)>.

Please refer to the literature referenced in the SEE ALSO section for 
details. Boltzmann's constant C<k_B> is used as C<1.3807 * 10^-23 J/K>.

=cut

{
	my $parsed;
	sub fermi_distribution {
		my ($E, $gs, $T, $mu) = @_;
		$E  = 'E'       if not defined $E;
		$gs = 'gs'      if not defined $gs;
		$T  = 'T'       if not defined $T;
		$mu = 'mu'      if not defined $mu;
		
		# parse arguments
		$E     = _parse_arguments($E    , 'E'        );
		$gs    = _parse_arguments($gs   , 'gs'       );
		$T     = _parse_arguments($T    , 'T'        );
		$mu    = _parse_arguments($mu   , 'mu'       );
		
		# Generate the template object tree
		if (not defined $parsed) {
			$parsed = parse_from_string(<<'HERE');
gs /
(
	e ^ (
		(E - mu) / (k_B * T)
	)
	+ 1
)
HERE
			
			# Implement special numbers
			$parsed->implement(
				e  => Math::Symbolic::Constant->euler(),
#				pi => Math::Symbolic::Constant->pi(),
				k_B => Math::Symbolic::Constant->new(1.3807e-23),
			);
		}

		# Always return a clone of the template object tree.
		my $distribution = $parsed->new();
		

		# Implement specified variables in a separate step in case
		# they contain e's and pi's.
		$distribution->implement(
			E  => $E,
			gs => $gs,
			T  => $T,
			mu => $mu,
		);
		
		return $distribution;
	}
}








sub _parse_arguments {
	my $argument = shift;
	my $name = shift;

	unless (ref($argument) =~ /^Math::Symbolic/) {
		my $tmp;
		eval {
			$tmp = parse_from_string($argument)
		};
		confess "Could not parse arguments: '$name' was\n"
			."'$argument'. Error was '$@'" if $@;
		$argument = $tmp;
	}

	return $argument;
}





# Now follows all the exporter stuff!

our @ISA = qw(Exporter);

# this works as usual, but more follows
our %EXPORT_TAGS = (
	'all' => [ qw(
		gauss_distribution
		normal_distribution
		bivariate_normal_distribution
		cauchy_distribution
		boltzmann_distribution
		bose_distribution
		fermi_distribution
		) ],
	'functions' => [ qw(
		gauss_distribution
		normal_distribution
		bivariate_normal_distribution
		cauchy_distribution
		boltzmann_distribution
		bose_distribution
		fermi_distribution
		) ],
);

# associate export names with function names and numbers of arguments.
my %GRAMMAR_EXTENSIONS = (
		gauss_grammar =>
		{name => 'gauss', args => 2, function => \&gauss_distribution},
		normal_grammar => {name => 'normal', args => 2, function => \&gauss_distribution},
		bivariate_normal_grammar => {name => 'bivariate_normal', args => 5, function => \&bivariate_normal_distribution},
		cauchy_grammar => {name => 'cauchy', args => 2, function => \&cauchy_distribution},
		boltzmann_grammar => {name => 'boltzmann', args => 4, function => \&boltzmann_distribution},
		bose_grammar => {name => 'bose', args => 4, function => \&bose_distribution},
		fermi_grammar => {name => 'fermi', args => 4, function => \&fermi_distribution},
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

# We do some fancy stuff in import:
# If the grammar bits are wanted (either via :all, :grammar or the individual
# bits), we amend the parser and then hand control to the default import()
# from Exporter.

sub import {
	my @args = @_;
	my $class = shift;
	
	# cache bits that are to be imported.
	my %import;

	# find all the grammar related stuff and leave the ordinary
	# exporter function related stuff.
	for (my $i = 0; $i <= $#args; $i++) {
		
		# grammar tag
		if ($args[$i] eq ':grammar') {
			%import = %GRAMMAR_EXTENSIONS;
			
			# remove from args so exporter doesn't hiccup.
			splice(@args, $i, 1);
			
			last if $i == @args;
			redo;
		}
		# all tag
		elsif ($args[$i] eq ':all') {
			%import = %GRAMMAR_EXTENSIONS;
			
			last if $i == @args;
			next;
		}
		# individual tags
		elsif (exists $GRAMMAR_EXTENSIONS{$args[$i]}) {
			$import{$args[$i]} = undef;
			
			# remove from args so exporter doesn't hiccup.
			splice(@args, $i, 1);

			last if $i == @args;
			redo;
		}
	}

	# Now handle all the grammar related stuff
	foreach my $import (keys %import) {
		require Math::SymbolicX::ParserExtensionFactory;

		# create new M::S function
		Math::SymbolicX::ParserExtensionFactory->import(
			$GRAMMAR_EXTENSIONS{$import}{name} => sub {
				# argument checking
				my $args = shift;

				my $name = $GRAMMAR_EXTENSIONS{$import}{name};
				my $noargs = $GRAMMAR_EXTENSIONS{$import}{args};
				my $func=$GRAMMAR_EXTENSIONS{$import}{function};

				my @args = split /\s*,\s*/, $args;
				my $no_args = @args;
				confess(<<"HERE")
Too many arguments ($no_args > $noargs) to '$name()' while
parsing Math::Symbolic tree from string.
HERE
				if $no_args > $GRAMMAR_EXTENSIONS{$import}{args};

				# individual argument checking
				foreach (@args) {
					# map "undef" to undef
					if (/\s*undef\s*/io) {
						$_ = undef;
						next;
					}

					# make sure the argument parses as M::S
					my $tmp;
					eval { $tmp = parse_from_string($_) };
					confess(<<"HERE")
Invalid argument ('$_') to '$name()' while
parsing Math::Symbolic tree from string. Error message (if any):
$@
HERE
					if $@ or not defined $tmp;
					$_ = $tmp;
				}
				
				# function application
				my $res;
				eval { $res = $func->(@args); };
				confess(<<"HERE") if $@ or not defined $res;
Unknown error applying '$name()' while
parsing Math::Symbolic tree from string. Error message (if any):
$@
HERE
				return $res;
			}
		);
	}

	# I wonder whether this class is inheritable at all, but well, here
	# goes...
	$class->export_to_level(1, @args);
}




1;
__END__

=pod

=back

=head1 SEE ALSO

Have a look at L<Math::Symbolic>, L<Math::Symbolic::Parser>,
L<Math::SymbolicX::ParserExtensionFactory> and all associated modules. 

New versions of this module can be found on
http://steffen-mueller.net or CPAN. 

Details on several distributions implemented in the code can be found on
the MathWorld site:

I<Eric W. Weisstein. "Normal Distribution." From MathWorld --
A Wolfram Web Resource. http://mathworld.wolfram.com/NormalDistribution.html>

I<Eric W. Weisstein. "Bivariate Normal Distribution." From MathWorld --
A Wolfram Web Resource. http://mathworld.wolfram.com/BivariateNormalDistribution.html>

I<Eric W. Weisstein. "Cauchy Distribution." From MathWorld --
A Wolfram Web Resource. http://mathworld.wolfram.com/CauchyDistribution.html>

The Boltzmann, Bose, and Fermi distributions are discussed in detail in 
I<N.W. Ashcroft, N.D. Mermin. "Solid State Physics". Brooks/Cole, 1976>

=head1 AUTHOR

Steffen Mueller, E<lt>symbolic-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
