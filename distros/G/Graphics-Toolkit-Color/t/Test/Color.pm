
# GTC custom test functions

package Test::Color;
use v5.12;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_tuple);
use Test::Builder;
my $tb = Test::Builder->new;

sub is_tuple {
    my ($got, $expected, $axis, $name) = @_;
    my $pass = 0;
    my $diag = '';

    if    ( @_ < 4 )          { $diag = "'is_tuple' got not enough arguments" }
    elsif (not defined $name) { $diag = "got no test name" }
    else {
		$diag = "failed test: $name -";
		if    (not defined $got )       { $diag .= " got no values (need an ARRAY ref)" } 
	    elsif (not defined $expected)   { $diag .= " got no expected values (need an ARRAY ref)" } 
	    elsif (not defined $axis )      { $diag .= " got no axis names (need an ARRAY ref)" } 
		elsif (ref $got ne 'ARRAY')     { $diag .= " got values: '$got' that are not a tuple (ARRAY ref)" } 
	    elsif (ref $expected ne 'ARRAY'){ $diag .= " expected values: '$expected' are not a tuple (ARRAY ref)" } 
	    elsif (ref $axis ne 'ARRAY')    { $diag .= " axis names: '$axis' are not in a tuple (ARRAY ref)" } 
	    else {
			my $tuple_length = @$axis;
			if    ( @$got != $tuple_length)     { $diag .= " expected $tuple_length values (axis count) in tuple, but got ".(int @$got) }
			elsif ( @$expected != $tuple_length){ $diag .= " need $tuple_length values (axis count) to compare with (expect), but got ".(int @$expected) }
			else  {
				$pass = 1;
				for my $axis_number (0 .. $#$axis){
					my $axis_name = $axis->[$axis_number];
					if (not is_nr($got->[$axis_number])) {
						$pass = 0;
						$diag .= " $axis_name value I got is not a number,";
						next;
					}
					if ($got->[$axis_number] != $expected->[$axis_number] and $got->[$axis_number] ne $expected->[$axis_number]) {
						$pass = 0;
						$diag .= " expected $axis_name value of $expected->[$axis_number] but got $got->[$axis_number],";
					}
				}
				chop $diag;
			}
		}
	}
    $tb->diag( $diag ) unless $pass;
    $tb->ok($pass, $name);
}


my $number_re = qr/^\-?(?:\d+|(?:\d*\.\d+))(?:e-?\d+)?$/;
sub is_nr { $_[0] =~ $number_re }

1;
