package Math::BigSimple;
require Exporter;
use Math::BigInt;
@ISA = qw(Exporter);
@EXPORT = qw(new);
@EXPORT_OK = qw(is_simple make_simple);
$VERSION = "1.1a";
$_DEFAULT_CHECKS = 4;
$_DEFAULT_RAND = sub { rand() };
sub new
{
	my $class = shift;
	my($LENGTH, $CHECKS, $RAND);
	my %param = @_ if(@_ % 2 == 0);
	if(exists $param{Length}) # Compability mode (with 1.0 version).
	{
		$CHECKS = $param{'Checks'};
		$LENGTH = $param{'Length'};
		$RAND = $param{'Random'};
	}
	else
	{
		($LENGTH, $CHECKS, $RAND) = @_;
	}
	if((!$LENGTH) || (int($LENGTH) != $LENGTH))
	{
		die "[error] " . __PACKAGE__ . " $VERSION : number length not specified.";
	}
	$CHECKS = $Math::BigSimple::_DEFAULT_CHECKS if((!$CHECKS) || (int($CHECKS) != $CHECKS));
	$RAND = $Math::BigSimple::_DEFAULT_RAND if((!$RAND) || (ref($RAND) != 'CODE'));

	my $ref = [$LENGTH, $CHECKS, $RAND]; # [$CHECKS, $LENGTH, $RAND] in 1.0.
	bless $ref, $class;
	return $ref;
}
sub make
{
	my $ref = shift;
	my($LENGTH, $CHECKS, $RAND) = @$ref;
	while(1)
	{
		my $p = &$RAND();
		if(int($p * 10) == 0)
		{
			my $repl = 0;
			while(!$repl)
			{
				$repl = int(rand() * 10);
			}
			$p += $repl / 10;
		}
		$p = int($p * (10 ** $LENGTH));

		return $p if(Math::BigSimple::is_simple($p) == 1);
	}
}
sub is_simple
{
	my($number, $CHECKS) = @_;
	return -1 if((!$number) || (int($number) != $number));
	$CHECKS = $Math::BigSimple::_DEFAULT_CHECKS if(!$CHECKS);

	my $_2 = Math::BigInt->new(2);
	my $coof = $number << 4;
	my $simple = 1;
	my $_p = Math::BigInt->new($number);
	my $_i1 = Math::BigInt->new($number-1);
	my $_i2 = $_i1->bdiv($_2);

	for(my $count = 0; $count < $CHECKS; $count++)
	{
		$simple = 0;
		last if($number % 2 == 0);
		my $x = Math::BigInt->new(int(&$Math::BigSimple::_DEFAULT_RAND() * $coof) % $number);
		next if($x->is_zero());

		my $func = $x->bmodpow($_i1, $_p);
		$func = $func->bstr();
		last if(($func != 1) && ($func != $number-1));

		$simple = 1;
	}
	if($simple == 1)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}
sub make_simple
{
	my $g = Math::BigSimple->new(shift);
	return $g->make();
}
__END__

=head1 NAME

Math::BigSimple

=head1 VERSION

Version number is 1.1a.
Looks stable.

This is 1.1 version with improved test 3, written 13.06.2005.

=head1 DESCRIPTION

The Math::BigSimple module can generate big simple numbers; it's very usefull for cryptographic programs which follow the
open key principles(like RSA, IDEA, PGP and others). It's interface is VERY easy to use and it works enough fast even for the real-time applications.

=head1 SYNTAX

 # OOP interface
 use Math::BigSimple;
 $bs = Math::BigSimple->new(8);  # Constructor
 $bs = Math::BigSimple->new(Length => 8, Checks => 5); # Old style
 $simple = $bs->make(); # Generation

 # Procedure interface.
 use Math::BigSimple qw(is_simple make_simple);
 print "SIMPLE!!!" if(is_simple(84637238096) == 1); # Test number
 $simple_number = make_simple($length); # Easy generation

=head1 FUNCTIONS

=head2 OOP interface

=head3 new(@params)

$generator = Math::BigSimple->new(@options);

Initializes number generator; first parameter is required number length
and optional second is number of validation checks (default 4).
Also supported old format of params(1.0) - the hash with 'Length' and
'Checks' elements (don't use it).

=head3 make

$simple_number = $generator->make();

Returns number as specified in $generator.

=head2 Procedure interface

=head3 is_simple($number)

$if_is_simple = is_simple($number);

Returns 1 if $number is simple. Don't use with small numbers.

=head3 make_simple

$simple_number = make_simple($length);

Returns a simple number of specified length. This is really the
easiest way to get it.

=head1 LIMITATIONS

Generation of number with 15 or more digits is slow.

Number 2 won't be recognized as simple.

Some small numbers (for example, 3 and 7) not always pass the test.

=head1 AUTHOR

 Edward Chernenko <edwardspec@yahoo.com>.
 Perl programmer & Linux system administrator.

=head1 COPYRIGHT

Copyright (C)Edward Chernenko.
This program is protected by Artistic License
and can be used and/or distributed by the same
rules as perl interpreter.
All right reserved.

=head1 LOOK ALSO

Math::BigInt
