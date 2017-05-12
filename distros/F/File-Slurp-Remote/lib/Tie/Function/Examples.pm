
package Tie::Function::Examples;

@ISA = qw(Tie::StdHash Exporter);
@EXPORT_OK = qw(%thoucomma %nothoucomma %addcents %q_shell %q_perl %round %sprintf %line_numbers);

require Tie::Hash;
require Exporter;
use Carp;
use strict;
use warnings;

our $VERSION = 0.44;

use strict;

tie our %q_perl, 'Tie::Function::Examples',
	sub {
		my ($string) = @_;
		$string =~ s/'/'."'".'/g;
		return "'$string'";
	};

tie our %q_shell, 'Tie::Function::Examples',
	sub {
		my ($file) = @_;
		return $file if $file =~ /^[-,_\.+=:\/0-9a-zA-Z]+$/;
		$file =~ s/'/'\\''/g;
		return "'$file'";
	};


tie our %sprintf, 'Tie::Function::Examples',
	sub {
		my ($format, @args) = split($; , $_[0]);
		return sprintf($format, @args);
	};

tie our %round, 'Tie::Function::Examples',
	sub {
		my ($amount, $scale) = split($; , $_[0]);
		require POSIX;
		$scale = 1 unless $scale;
		# scale = .01 for cents
		# scale = 1000 for thousands
		$amount /= $scale;
		$amount += .5;
		$amount = POSIX::floor($amount);
		$amount *= $scale;
		return $amount;
	};

tie my %decomma, 'Tie::Function::Examples',
	sub {
		my ($f) = @_;
		$f =~ s/,//g;
		return $f;
	};

tie our %nothoucomma, 'Tie::Function::Examples',
	sub {
		my ($number) = @_;
		$number =~ s/(\A|\D)(\d\d?\d?)(,\d\d\d)+(\D|\z)/$1$2$decomma{$3}$4/g;
		return $number;
	};

tie our %thoucomma, 'Tie::Function::Examples', 
	sub {
		my ($number) = @_;
		1 while ($number =~ s/(?<![\d.])(\d+)(\d\d\d)(?!\d)/$1,$2/g);
		return $number;
	};

tie our %addcents, 'Tie::Function::Examples',
	sub {
		my ($money) = @_;
		1 while ($money =~ s/(?<![\d.])(\d+)([^\d,.]|\z|,(?!\d))/$1.00$2/);
		1 while ($money =~ s/(?<![\d.])(\d+\.)([^\d,]|\z|,(?!\d))/${1}00$2/);
		1 while ($money =~ s/(?<![\d.])(\d+\.\d)([^\d,]|\z|,(?!\d))/${1}0$2/);
		$money =~ s/(\d+\.\d\d\d+)([^\d,]|\z|,(?!\d))/$sprintf{'%.2f', $1}$2/g;
		$money =~ s/(\d[\d,]+\.\d\d\d+)([^\d,]|\z|,(?!\d))/$thoucomma{$sprintf{'%.2f', $nothoucomma{$1}}}$2/g;
		return $money;
	};

tie our %line_numbers, 'Tie::Function::Examples',
	sub {
		my $text = shift;
		my @x = split(/\n/, $text);
		my $c = 0;
		return join("\n", map { sprintf("%-4d%s", $c++, $_) } @x);
	};

# 
#
#

sub TIEHASH
{
	my ($pkg, $func, @args) = @_;
	return bless [
		$func, 
		[@args],
		{},
	];
}

sub FETCH
{
	my ($self, $lookup) = @_;
	return &{$self->[0]}($lookup, $self->[2], @{$self->[1]});
}

sub STORE    { $_[0]->[2]{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]->[2]}; each %{$_[0]->[2]} }
sub NEXTKEY  { each %{$_[0]->[2]} }
sub EXISTS   { exists $_[0]->[2]{$_[1]} }
sub DELETE   { delete $_[0]->[2]{$_[1]} }
sub CLEAR    { %{$_[0]->[2]} = () }

1;

__END__

=head1 NAME

 Tie::Function::Examples - tie functions to the the read side of hashes

=head1 SYNOPSIS

 use Tie::Function::Examples;
 use Tie::Function::Examples qw(%thoucomma %nothoucomma %addcents %q_shell %round %sprintf);

 tie %array, 'Tie::Function::Examples', \&function;

=head1 EXAMPLES

	use Tie::Function::Examples;

	tie %double, 'Tie::Function::Examples', 
		sub {
			my ($key) = @_;
			return $key * 2 if $key != 0;
			return $key.$key;
		};

	print "2 * 2 is $double{2}\n";


	use Tie::Function::Examples qw(%thoucomma %addcents);

	tie %mymoney, 'Tie::Function::Examples',
		sub {
			my ($key, $underlying_array) = @_;
			return "\$$thoucomma{$addcents{$underlying_array->{$key}}";
		};

	$mymoney{joe} = 7000;
	print "$mymoney{joe}\n" # prints $7,000.00

=head1 DESCRIPTION

Tie::Function::Examples provides a simple method to tie a function to
a hash. 

The function is passed two arguments: the key used to access the
array and a reference to a hash that is used for all non-read accesses
to the array.

=head1 PREDEFINED BINDINGS

The following hashes are bound and can be imported from 
Tie::Function::Examples.

=over 4

=item %thoucomma

Adds commas to numbers.  "7000.32" becomes "7,000.32"

=item %nothoucomma

Removes commas from numbers.  "7,000.32" becomes "7000.32"

=item %addcents

Make sure that numbers end two places to the right of
the decimal.  "7000" becomes "7000.00" and "7000.149" 
becomes "7000.15".

=item %q_perl

Quote strings for use in perl I<eval>.

=item %q_shell

Quotes file names quoted for use on a command line with the
bash shell.  This will sometimes put 'single quotes' around
the file name and other times it will leave it bare.

=item %round

This will round a number to the nearest integer.  If you want
a different rounding-point, use a pseudo-two dimensional lookup
to provide a scale.  Use "0.01" to round to the nearest penny
and "1000" to round to the nearest thousand.  For
example: $round{38.7, 10} will round up to 40.

=item %sprintf

Use a comma to do a pseudo-multi-dimensional lookup to specify
both a format and arguments.  Obviously, none of the arguments
can have the ASCII character that is equal to the perl $; 
variable.   Example: $sprintf{"%07d", 82} will interpolate
to "0000082".

=item %line_numbers

Add line numbers to a block of text.

=back

=head1 LICENSE

Copyright (C) 2008-2007,2008-2010 David Sharnoff.
Copyright (C) 2007-2008 SearchMe Inc.
Copyright (C) 2011 Google Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

