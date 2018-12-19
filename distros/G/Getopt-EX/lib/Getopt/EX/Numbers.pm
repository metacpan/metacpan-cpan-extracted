=head1 NAME

Getopt::EX::Numbers - module to handle number parameters

=head1 SYNOPSIS

use Getopt::EX::Numbers;

my $obj = Getopt::EX::Numbers->new(max => 100);

$obj->parse("start:end:step:length");
$obj->range;

$obj->parse("start:end:step:length")->sequence;

Getopt::EX::Numbers->new->parse("1:10:2")->sequence;

=head1 FORMAT

Number format is composed by for elements: C<start>, C<end>, C<step>
and C<length>.  All elements are optional.

    1		1
    1:3		1,2,3
    1:20:5	1,     6,     11,       16
    1:20:5:3	1,2,3, 6,7,8, 11,12,13, 16,17,18

When C<start> is omitted, minimum value is used, which is zero by
default.  If the object is initialized with C<max> value, C<end>
element can be omitted.

    ::		all
    ::2		even numbers
    1::2	odd numbers

If C<start> and C<end> number is negative, they are subtracted from
the maximum number.  If the C<end> number is prefixed by plus (`+')
sign, it is summed to C<start> number.  Next examples produce top and
last 10 numbers.

    :+9		top 10 numbers
    -9:		last 10 numbers

=head1 METHOD

=over 4

=item B<new> ( [ B<min> => n ] , [ B<max> => m ] )

Create object with optional parameter B<min> and B<max>.

=item B<parse>(I<spec>)

Accept number description and parse it.
Return object itself.

=item B<range>

Return number range list:

    ( [ n0, m0 ], [ n1, m1 ], ... )

=item sequence

Return number sequence:

    ( n0 .. m0, n1 .. m1, ... )

=back

=cut

package Getopt::EX::Numbers;

use strict;
use warnings;

use Carp;
use List::Util qw();
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Exporter qw(import);
our @EXPORT_OK = qw();

use Moo;

has [ qw(min max start end step length _spec) ] => ( is => 'rw' ) ;

has '+min' => ( default => 0 ) ;

sub parse {
    my $obj = shift;
    local $_ = shift;
    if (m{
	^
	(?<start> -\d+ | \d* )
	(?:
	  (?: \.\. | : ) (?<end> [-+]\d+ | \d* )
	  (?:
	    : (?<step> \d* )
	      (?:
	        : (?<length> \d* )
	      )?
	  )?
	)?
	$
	}x) {
	$obj->start  ($+{start});
	$obj->end    ($+{end});
	$obj->step   ($+{step});
	$obj->length ($+{length});
    }
    else {
	carp "$_: format error";
	return undef;
    }
    $obj->_spec($_);
    $obj;
}

sub range {
    my $obj = shift;
    my $max = $obj->max;
    my $min = $obj->min;

    my $start  = $obj->start;
    my $end    = $obj->end;
    my $step   = $obj->step;
    my $length = $obj->length;

    if (not defined $max) {
	if ($start =~ /^-\d+$/ or
	    (defined $end and $end =~ /^-\d+$/)) {
	    carp "$_: max required";	    
	    return ();
	}
    }

    if ($start =~ /\d/ and defined $max and $start > $max) {
	return ();
    }
    if ($start eq '') {
	$start = $min;
    }
    elsif ($start =~ /^-\d+$/) {
	$start = List::Util::max($min, $start + $max);
    }

    if (not defined $end) {
	$end = $start;
    }
    elsif ($end eq '') {
	$end = defined $max ? $max : $start;
    }
    elsif ($end =~ /^-/) {
	$end = List::Util::max(0, $end + $max);
    }
    elsif ($end =~ s/^\+//) {
	$end += $start;
    }
    $end = $max if defined $max and $end > $max;

    $length ||= 1;
    $step ||= $length;

    my @l;
    if ($step == 1) {
	@l = ( [$start, $end] );
    } else {
	for (my $from = $start; $from <= $end; $from += $step) {
	    my $to = $from + $length - 1;
	    $to = List::Util::min($max, $to) if defined $max;
	    push @l, [$from, $to ];
	}
    }

    return @l;
}

sub sequence {
    my $obj = shift;
    map { ref $_ eq 'ARRAY' ? ($_->[0] .. $_->[1]) : $_ } $obj->range;
}

1;
