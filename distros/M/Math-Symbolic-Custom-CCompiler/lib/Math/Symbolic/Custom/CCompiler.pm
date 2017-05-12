package Math::Symbolic::Custom::CCompiler;

use 5.006;
use strict;
use warnings;
use Inline;
use Carp qw/croak carp cluck confess/;

use Math::Symbolic::Custom::Base;
BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}

use Math::Symbolic::ExportConstants qw/:all/;
our $VERSION = '1.04';

our $Aggregate_Export = [qw/to_c to_compiled_c/];

our @Operators_To_C = (
    # B_SUM
	'$_[0] + $_[1]',
    # B_DIFFERENCE
	'$_[0] - $_[1]',
    # B_PRODUCT
	'$_[0] * $_[1]',
    # B_DIVISION
	'$_[0] / $_[1]',
    # U_MINUS
	'-$_[0]',
    # U_P_DERIVATIVE
	'ERROR',
    # U_T_DERIVATIVE
	'ERROR',
    # B_EXP
	'pow($_[0], $_[1])',
    # B_LOG
	'log($_[1]) / log($_[0])',
    # U_SINE
	'sin($_[0])',
    # U_COSINE
	'cos($_[0])',
    # U_TANGENT
	'tan($_[0])',
    # U_COTANGENT
	'cos($_[0]) / sin($_[0])',
    # U_ARCSINE
	'asin($_[0])',
    # U_ARCCOSINE
	'acos($_[0])',
    # U_ARCTANGENT
	'atan($_[0])',
    # U_ARCCOTANGENT
	'atan2( 1 / $_[0], 1 )',
    # U_SINE_H
	'sinh($_[0])',
    # U_COSINE_H
	'cosh($_[0])',
    # U_AREASINE_H
	'log( $_[0] + sqrt( $_[0] * $_[0] + 1 ) )',
    # U_AREACOSINE_H
	'log( $_[0] + sqrt( $_[0] * $_[0] - 1 ) )',
    # B_ARCTANGENT_TWO
	'atan2($_[0], $_[1])',
);

sub to_compiled_c {
	my $tree = shift;
	my $order = shift || [];
	my $code = $tree->to_c($order);
	Math::Symbolic::Custom::CCompiler::_Compiled::compile($code);
	$code =~ /^\s*double\s*(\w+)\(/
		or croak "Compilation to C failed for unknown reasons.";
	my $f_name = $1;
	no strict 'refs';
	my $ref = *{"Math::Symbolic::Custom::CCompiler::_Compiled::$f_name"}{CODE};
	delete(${Math::Symbolic::Custom::CCompiler::_Compiled::}{$f_name});
	return $ref;
}

sub to_c {
	my $tree = shift;
	my $order = shift || [];
	my $count = 0;
	my %order = map { ( $_, $count++ ) } @$order;
	no warnings 'recursion';

	my $vars = [ $tree->explicit_signature() ];

	my %vars;
	my @not_placed;
	foreach (@$vars) {
		my $pos = $order{$_};
		if ( defined $pos ) {
			$vars{$_} = $pos;
		}
		else {
			push @not_placed, $_;
		}
	}

	$count = 0;
	foreach ( sort @not_placed ) {
		$vars{$_} = @$vars - @not_placed + $count++;
	}
	my @sorted_vars = sort {$vars{$a} <=> $vars{$b}} keys %vars;

	my $subname = _find_subname(
		'Math::Symbolic::Custom::CCompiler::_Compiled'
	);
	my $code = "double $subname(";
	my $first = 1;
	my @varmap;
	my $startvar = 'aaaaaa';
	foreach (@sorted_vars) {
		push @varmap, '_V'.$startvar;
		$code .= ', ' unless $first-- == 1;
		$code .= "double _V$startvar";
		$startvar++;
	}
	$code .= ") {\nreturn( ";
	
	no warnings 'recursion';
	
	$code .= _rec_ms_to_c($tree, \%vars, \@varmap);

	$code .= " );\n}\n";
	return $code;
}

sub _rec_ms_to_c {
    my $tree  = shift;
    my $vars  = shift;
    my $varmap = shift;

    my $code  = '';
    my $ttype = $tree->term_type();

    if ( $ttype == T_CONSTANT ) {
	my $value = $tree->value();
	$value .= '.' if $value !~ /\./;
        $code .= $value;
    }
    elsif ( $ttype == T_VARIABLE ) {
        $code .= ' ' . $varmap->[$vars->{ $tree->name() }] . ' ';
    }
    else {
        my $type  = $tree->type();
        my $otype = $Math::Symbolic::Operator::Op_Types[$type];
        my $app   = $otype->{application};
        if ( ref($app) eq 'CODE' ) {
		confess("Trying to compile differential operator to C.\n" . 
			"This is not supported by " .
			"Math::Symbolic::Custom::CCompiler\n");
	}
        else {
	    $app = $Operators_To_C[$type];
            my @app = split /\$_\[(\d+)\]/, $app;
            if ( @app > 1 ) {
                for ( my $i = 1 ; $i < @app ; $i += 2 ) {
                    $app[$i] = '('
                      . _rec_ms_to_c( $tree->{operands}[ $app[$i] ],
                        $vars, $varmap )
                      . ')';
                }
            }
            $code .= join '', @app;
        }
    }
    return $code;
}

sub _find_subname {
	my $package = shift;
	my $min_length = shift || 5;
	no strict 'refs';
	my $ref = \%{$package.'::'};
	use strict 'refs';
	my $name = 'A'x$min_length;
	while (exists $ref->{$name}) {
		$name++;
	}
	return $name;
}

1;
package Math::Symbolic::Custom::CCompiler::_Compiled;
sub compile {
	my $code = shift;
	Inline->bind(C => $code);
}



1;
__END__

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::CCompiler - Compile Math::Symbolic trees to C

=head1 SYNOPSIS

  use Math::Symbolic qw/:all/;
  use Math::Symbolic::Custom::CCompiler;
  
  my $function = parse_from_string(... some expression ...);
  # ... calculations ... see Math::Symbolic manpage

  my $c_code = $function->to_c();
  # $c_code now contains C code that does the same as the original
  # function.

  my $anon_subroutine = $function->to_compiled_c();
  # Generates and compiles C code. Uses Inline::C to dynamically
  # link the results. Returns an anonymous Perl subroutine that
  # does the same as the original function.
  # But in compiled C. (Ca. 1000x faster than the tree-walking
  # involved with the value() method.)

=head1 DESCRIPTION

This module extends the functionality of Math::Symbolic by offering
facilities to compile symbolic math trees (formulas) to C code. It
also uses Inline::C to compile and link the generated C code at
run-time, thus allowing the user to do symbolic calculations in Perl
with Math::Symbolic and then use the results in a fast numeric
environment.

This software generates code. Code generators are difficult to test, but the
first release of the module is now 1.5 years old and I haven't received any
bug reports, so I consider it somewhat stable now.

Please read the manpage of Math::Symbolic::Compiler which comes with
the Math::Symbolic distribution. Most of the gotchas involved with
compiling the functions to Perl subroutines also apply to this module
which compiles to C instead.

Alternatively, you can use the module not for faster calculations from your
Perl program, but to generate C code for you. I have used it to generate
an implementation for (many!) Zernike Polynomials for work in C.

The module adds two methods to all Math::Symbolic objects. These are:

=head2 $ms_tree->to_c()

This method returns the C code generated from the function. Please
note that the code is extremely difficult to read for humans because
variable and function names have been generated to not clash with any
reserved words. Feel free to do search/replace on the results of you
are bothered.

This code is not intended to be read by humans, but to be understood
by C compilers.

The method takes one optional argument: An array reference. The
referenced array is to contain some or all of the identifier names
that where in the original mathematical formula. You can use the
'signature()' method on a Math::Symbolic object to get at the
identifiers (variable names) that were used. The order of the
identifier names indicates the order in which the C function
parameters are to be mapped to the identifiers. Omitted identifiers
are appended to the list in alphabetic order. If no such array
reference is passed, the arguments are assumed to be in alphabetic
order altogether.

Since this behaviour is equivalent to that of the compilation methods
supplied by Math::Symbolic::Compiler, it is suggested that you
read the corresponding manual for more detailed instructions.

=head2 $ms_tree->to_compiled_c()

This method generates the same code that 'to_c()' generates and
compiles it using Inline::C and your local C compiler. The
binary is then dynamically linked to your instance of perl
through some scary magic in Inline::C. Go there and complain
if you don't understand that because I, for sure, don't.

Inline::C also generates an Perl wrapper for the compiled C
function. This is then referenced and returned.
(The original package sub is deleted to prevent memory leakage.)

=head1 AUTHOR

Please send feedback, bug reports, and support requests to one of the
contributors or the Math::Symbolic mailing list.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

L<Math::Symbolic>

L<Math::Symbolic::Compiler>

L<Math::Symbolic::Custom>,
L<Math::Symbolic::Custom::Base>,

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006, 2008, 2013 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

