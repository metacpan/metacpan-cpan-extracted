package Language::FormulaEngine::Error;
use Moo;
my @subclasses;
BEGIN {
	@subclasses= qw( ErrInval ErrNA ErrREF ErrNUM ErrNAME );
	# For each subclass name, export a function which can be used as the package
	# name or as the package constructor.
	for (@subclasses) {
		my $pkg= __PACKAGE__.'::'.$_;
		no strict 'refs';
		*$_= sub { @_? $pkg->new(@_) : $pkg }
	}
}
use Exporter 'import';
our @EXPORT_OK= ( @subclasses, qw( auto_wrap_error ) );
our %EXPORT_TAGS= ( all => \@EXPORT_OK );

# ABSTRACT: Exception objects for formula functions
our $VERSION = '0.05'; # VERSION


has message => ( is => 'rw', required => 1 );

sub mine {
	return Language::FormulaEngine::ErrorMine->new($_[0]);
}

sub BUILDARGS {
	my $pkg= shift;
	return $_[0] if @_ == 1 && ref $_[0] eq 'HASH';
	# If odd number of arguments, and first is a scalar, then treat it as the message
	unshift @_, 'message' if @_ & 1 and !ref $_[0];
	return { @_ };
}

our %err_patterns= (
	ErrNA    => qr/uninitialized|undefined/,
	ErrNUM   => qr/numeric/,
);
sub auto_wrap_error {
	# allow to be called as package method, or not
	shift if @_ && !ref $_[0] && $_[0]->isa(__PACKAGE__);
	my $msg= shift;
	# return things which are already Error objects (or mines)
	if (ref $msg) {
		return $msg->disarm if ref($msg)->can('disarm');
		return $msg if ref($msg)->can('message');
	}
	# Match message against patterns that Perl might have generated
	if (defined $msg) {
		$msg =~ s/ at \(eval.*//; # isn't useful
		for (keys %err_patterns) {
			return (__PACKAGE__.'::'.$_)->new(message => $msg)
				if $msg =~ $err_patterns{$_};
		}
	} else {
		$msg= '<undef>';
	}
	return __PACKAGE__->new(message => $msg);
}

sub _fake_inc {
	(my $pkg= caller) =~ s,::,/,g;
	$INC{$pkg.'.pm'}= $INC{'Language/FormulaEngine/Error.pm'};
}

sub _stringify {
	my $self= shift;
	my $cls= ref $self;
	$cls =~ s/^Language::FormulaEngine::Error:://;
	$cls . ': ' . $self->message;
}

use overload '""' => \&_stringify;

package Language::FormulaEngine::ErrorMine;
Language::FormulaEngine::Error::_fake_inc();
use overload # SOMEONE SET US UP THE BOMB!
	'0+' => sub { die ${$_[0]} },
	'""' => sub { die ${$_[0]} },
	bool => sub { die ${$_[0]} };

sub new { bless $_[0], shift }
sub disarm { ${$_[0]} }

package Language::FormulaEngine::Error::ErrInval;
Language::FormulaEngine::Error::_fake_inc();
use Moo;
extends 'Language::FormulaEngine::Error';

package Language::FormulaEngine::Error::ErrNA;
Language::FormulaEngine::Error::_fake_inc();
use Moo;
extends 'Language::FormulaEngine::Error';

package Language::FormulaEngine::Error::ErrREF;
Language::FormulaEngine::Error::_fake_inc();
use Moo;
extends 'Language::FormulaEngine::Error';

package Language::FormulaEngine::Error::ErrNUM;
Language::FormulaEngine::Error::_fake_inc();
use Moo;
extends 'Language::FormulaEngine::Error::ErrInval';

package Language::FormulaEngine::Error::ErrNAME;
Language::FormulaEngine::Error::_fake_inc();
use Moo;
extends 'Language::FormulaEngine::Error';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Error - Exception objects for formula functions

=head1 VERSION

version 0.05

=head1 DESCRIPTION

In keeping with the theme of spreadsheet formulas, this module collection provides exception
objects that can be used for similar exception handling.  These objects are intended to be
thrown using "die", but they can also be wrapped with a "trap" object so that they don't die
until used.  For example, in a spreadsheet the error is I<returned> from a function, but
anything that uses that value needs to generate a similar error.  That would require a lot of
argument checking and prevent using native Perl operations, but by returning an error wrapped
in a trap, any perl operation that attempts to use the trap will instead throw the exception
object.

=head1 ATTRIBUTES

All error objects have:

=head2 message

A text description of the error

=head1 METHODS

=head2 mine

  return $error->mine;

This wraps the error in a "landmine".  Any perl code that attempts to operate on the value of
the object will instead die with C<$error>.  Call C<disarm> on the mine to return the original
C<$error> reference.

=head1 EXPORTABLE FUNCTIONS

Each of the sub-classes of error has a constructor function which you can export from this
module.  You can also take a perl-generated exception and automatically wrap it with an
appropriate Error object using L</auto_wrap_error>.

=head2 ErrInval

The formula was given invalid inputs

=head2 ErrNA

The function encountered a condition where no value could be returned.  i.e. the function is
not defined for the supplied parameters, such as accessing elements beyond the end of an array.

=head2 ErrREF

The formula referenced a non-existent or nonsensical variable.

=head2 ErrNUM

The function expected a number (or specific range of number, like positive, integer, etc) but
was given something it couldn't convert.

=head2 ErrNAME

The formula uses an unknown function name.  This is thrown during compilation, or during
evaluation if the compile step is omitted.

=head2 auto_wrap_error

  my $err_obj= auto_wrap_error( $perl_error_text );

Look at the perl error to see if it is a known type of error, and wrap it with the appropriate
type of error object.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
