package Math::Calc::Units::Compute;
use base 'Exporter';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(compute
		plus minus mult divide power
		unit_mult unit_divide unit_power
                construct);
use strict;

use Math::Calc::Units::Convert qw(reduce);
use Math::Calc::Units::Rank qw(render_unit);
use Math::Calc::Units::Convert::Base;
require Math::Calc::Units::Grammar;

sub equivalent {
    my ($u, $v) = @_;
    return Math::Calc::Units::Convert::Base->same($u, $v);
}

sub is_unit {
    my ($x, $unit) = @_;
    return equivalent($x, { $unit => 1 });
}

# All these assume the values are in canonical units.
sub plus {
    my ($u, $v) = @_;
    $u = reduce($u);
    $v = reduce($v);

    if (equivalent($u->[1], $v->[1])) {
        return [ $u->[0] + $v->[0], $u->[1] ];
    } elsif (is_unit($u->[1], 'timestamp') && is_unit($v->[1], 'sec')) {
        return [ $u->[0] + $v->[0], $u->[1] ];
    } elsif (is_unit($u->[1], 'sec') && is_unit($v->[1], 'timestamp')) {
        return [ $u->[0] + $v->[0], $v->[1] ];
    }

    die "Unable to add incompatible units `".render_unit($u->[1])."' and `".render_unit($v->[1])."'";
}

sub minus {
    my ($u, $v) = @_;
    $u = reduce($u);
    $v = reduce($v);

    if (is_unit($u->[1], 'timestamp') && is_unit($v->[1], 'timestamp')) {
        return [ $u->[0] - $v->[0], { sec => 1 } ];
    } elsif (equivalent($u->[1], $v->[1])) {
        return [ $u->[0] - $v->[0], $u->[1] ];
    } elsif (is_unit($u->[1], 'timestamp') && is_unit($v->[1], 'sec')) {
        return [ $u->[0] - $v->[0], $u->[1] ];
    }

    die "Unable to subtract incompatible units `".render_unit($u->[1])."' and `".render_unit($v->[1])."'";
}

sub mult {
    my ($u, $v) = @_;
    return [ $u->[0] * $v->[0], unit_mult($u->[1], $v->[1]) ];
}

sub divide {
    my ($u, $v) = @_;
    return [ $u->[0] / $v->[0], unit_divide($u->[1], $v->[1]) ];
}

sub power {
    my ($u, $v) = @_;
    die "Can only raise to unit-less powers" if keys %{ $v->[1] };
    $u = reduce($u);
    if (keys %{ $u->[1] } != 0) {
	my $power = $v->[0];
	die "Can only raise a value with units to an integral power"
	    if abs($power - int($power)) > 1e-20;
	return [ $u->[0] ** $power, unit_power($u->[1], $power) ];
    }
    return [ $u->[0] ** $v->[0], {} ];
}

sub unit_mult {
    my ($u, $v, $mult) = @_;
    $mult ||= 1;
    while (my ($unit, $vp) = each %$v) {
	$u->{$unit} += $vp * $mult;
	delete $u->{$unit} if $u->{$unit} == 0;	# Keep zeroes out!
    }
    return $u;
}

sub unit_divide {
    my ($u, $v) = @_;
    return unit_mult($u, $v, -1);
}

sub unit_power {
    my ($u, $power) = @_;
    return {} if $power == 0;
    $u->{$_} *= $power foreach (keys %$u);
    return $u;
}

sub construct {
    my $s = shift;
    my ($constructor, $args) = $s =~ /^(\w+)\((.*)\)/;
    return Math::Calc::Units::Convert::construct($constructor, $args);
}

package Math::Calc::Units::Compute;

# Poor-man's tokenizer
sub tokenize {
    my $data = shift;
    my @tokens = $data =~ m{\s*
                           (
                             \w+\([^\(\)]*\) # constructed (eg date(2001...))
                            |[\d.]+       # Numbers
                            |\w+          # Words
                            |\*\*         # Exponentiation (**)
                            |[-+*/()@]    # Operators
                           )}xg;
    my @types = map {      /\w\(/ ? 'CONSTRUCT'
                      :(   /\d/   ? 'NUMBER'
                      :(   /\w/   ? 'WORD'
                      :(            $_))) } @tokens;
    return \@tokens, \@types;
}

# compute : string -> <value,unit>
#
# If the first character of the string is '#', this will attempt to avoid
# canonicalization as much as possible.
#
sub compute {
    my $expr = shift;
    my $canonicalize = $expr !~ /^\#/;
    my ($vals, $types) = tokenize($expr);
    my $lexer = sub {
#        print "TOK($vals->[0]) TYPE($types->[0])\n" if @$vals;
        return shift(@$types), shift(@$vals) if (@$types);
        return ('', undef);
    };

    my $parser = new Math::Calc::Units::Grammar;

    my $v = 
        $parser->YYParse(yylex => $lexer,
                         yyerror => sub {
                             my $parser = shift;
                             die "Error: expected ".join(" ", $parser->YYExpect)." got `".$parser->YYCurtok."', rest=".join(" ", @$types)."\nfrom ".join(" ", @$vals)."\n";
                         },
                         yydebug => 0); # 0x1f);
    return $canonicalize ? reduce($v) : $v;
};

1;
