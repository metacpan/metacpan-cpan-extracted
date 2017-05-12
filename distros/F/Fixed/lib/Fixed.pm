package Fixed;

use 5.012;
use strict;
use warnings;

BEGIN {
	$Fixed::AUTHORITY = 'cpan:TOBYINK';
	$Fixed::VERSION   = '0.003';
}

use Readonly;
use Text::Balanced;

BEGIN {
	package Fixed::Scalar;
	sub TIESCALAR {
		my $class = shift;
		bless \@_, $class;
	}
	sub FETCH {
		$_[0][0];
	}
	sub STORE {
		my $self = shift;
		Readonly::croak $Readonly::MODIFY if @$self;
		push @$self, $_[0];
	}
};

my $KEYWORD  = 'fix';
my $CLASS    = __PACKAGE__;

my $PERLSVAR = qr{\$[^\W0-9]\w*};
my $SPACE    = qr{(?:\s|\#.*?\n)*}s;

sub import
{
	require Keyword::Simple;
	Keyword::Simple::define($KEYWORD, sub
	{
		my $ref = shift;
		$$ref =~ s/^$SPACE//;

		# set $foo = 1;
		if (my ($vname, $assignment, $rest) = ($$ref =~ /^($PERLSVAR)($SPACE=)(.*)$/s))
		{
			$$ref = "$CLASS\::Scalar my $vname => $rest";
		}

		# set ($foo) = 1;
		elsif (my ($vname4, $assignment4, $rest4) = ($$ref =~ /^\($SPACE($PERLSVAR)$SPACE\)($SPACE=)(.*)$/s))
		{
			$$ref = "$CLASS\::Scalar my $vname4 => $rest4";
		}

		# set $foo;
		elsif (my ($vname2, $rest2) = ($$ref =~ /^($PERLSVAR)$SPACE;(.*)$/s))
		{
			$$ref = "$CLASS\::Scalar my $vname2; $rest2";
		}
		
		# set ($foo, $bar)
		# set ($foo, $bar) = (1, 2);
		elsif ($$ref =~ /^$SPACE\(/s)
		{
			my $extracted = Text::Balanced::extract_bracketed($$ref)
				or Readonly::croak "usage: $KEYWORD (\$scalar, ...);";
			$extracted =~ s/(^\(|\)$)//gs;
			my @E = split /$SPACE,$SPACE/, $extracted;
			for (@E)
			{
				Readonly::croak "$KEYWORD used for non scalar variable '$_'"
					unless /^$PERLSVAR$/;
			}
			# If declaration includes an assignent, then ensure we have something to assign to!
			my $extra = ''; $extra = "($extracted)" if $$ref =~ /^$SPACE=/;
			$$ref = "$CLASS\::Scalar(\$_) for my ($extracted); $extra $$ref";
		}
		
		elsif (
			my ($vname3) = ($$ref =~ /^$SPACE([\@\%\*][^\W0-9]\w*)/s)
		) {
			Readonly::croak "$KEYWORD used with non scalar variable '$vname3'";
		}
		
		else {
			Readonly::croak "usage: $KEYWORD \$variable = \$value;";
		}
	});
}

sub unimport
{
	require Keyword::Simple;
	Keyword::Simple::undefine($KEYWORD);
}

sub Scalar
{
	if (@_ > 1 and $Readonly::XSokay) {
		$_[0] = $_[1];
		Readonly::make_sv_readonly($_[0]);
		return;
	}
	elsif (@_ > 1) {
		my $value = $_[1];
		tie $_[0], "$CLASS\::Scalar", $value;
	}
	else {
		tie $_[0], "$CLASS\::Scalar";
	}
}

1;

__END__

=head1 NAME

Fixed - a readonly variable that you can assign to

=head1 SYNOPSIS

   use 5.012;
   use strict;
   use warnings;
   use Fixed;
   
   fix $x = 42;
   $x++;  # croaks

=head1 DESCRIPTION

C<Fixed> is a little like L<Readonly>; the main difference is that you can
assign to fixed variables.

B<< What?! Then how are they fixed? >>

Because you can only assign to them once!

   use 5.012;
   use strict;
   use warnings;
   use Fixed;
   
   fix $x;  # declared but not initialized
   
   given ($author) {
      when ("Adams")   { $x = 42    }  # ok
      when ("Heller")  { $x = 22    }  # ok
      default          { $x = undef }  # ok
   }
   
   $x = 99; # croaks, even when $x is undef

Note that Fixed differentiates between a variable which has no value, and
a variable explicitly set to undef.

C<Fixed> does not currently support arrays and hashes. (See "Internals"
below for the reason.) You can of course assign an arrayref or hashref to
a fixed variable, but this does not fix the contents of the array or hash.
Use L<Readonly> if you want readonly arrays and hashes.

=head2 Syntax

Fixed allows variables to be declared as fixed in several ways:

   fix $variable = $value;
   fix $variable;
   
   fix ($var1, $var2, ...) = ($val1, $val2, ...);
   fix ($var1, $var2, ...);

When a single variable is declared and initialized in the same statement
(i.e. the first syntax), Fixed is able to use some optimizations, so this
form should be preferred when possible.

Note that declaration of a variable with C<fix> must be a statement on its
own; C<fix> cannot be slipped into the middle of an expression.

   if (fix $result = $search->get_result) {  # no!
      ...;
   }

This is a limitation inherited from L<Keyword::Simple>.

=head2 Internals

=begin trustme

=item Scalar

=end trustme

The C<fix> keyword is defined using L<Keyword::Simple> and is parsed as
if you'd witten:

   Fixed::Scalar(my $variable, $value);  # ... or ...
   Fixed::Scalar(my $variable);

If given a value, the C<Fixed::Scalar> method will attempt to discover
if L<Readonly>'s XS support is available, and if so will define the variable
and use XS to set the scalar's C<SvREADONLY> flag.

If XS is not available, or no initial value is provided, C<Fixed::Scalar>
will fall back to Perl's C<tie> mechanism.

Arrays and Hashes do not have a C<SvREADONLY> flag, plus the tie mechanism
doesn't really have any way to differentiate between the initial list
assignment to an uninitialized array or hash, and subsequent assignments.
This is why C<Fixed> does not support arrays or hashes.

=head2 Fixed without the Syntax Hacks

If you'd rather not enable the C<fix> keyword and would prefer to just
define fixed variables using C<< Fixed::Scalar(my $variable => $value) >>,
then that's OK. Just include some empty parentheses when loading C<Fixed>:

   use Fixed ();

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Fixed>.

=head1 SEE ALSO

L<Readonly>,
L<Readonly::XS>,
L<MooseX::SetOnce>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

