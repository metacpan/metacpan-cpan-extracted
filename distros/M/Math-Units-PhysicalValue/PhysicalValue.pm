
package Math::Units::PhysicalValue;

use strict;
use Math::Units::PhysicalValue::AutoUnit;

use Carp;
use base qw(Exporter); 
use Math::Units qw(convert);
use Number::Format;
use Math::BigFloat;
use overload 
    '+'    => \&pv_add,
    '*'    => \&pv_mul,
    '**'   => \&pv_mulmul,
    'sqrt' => \&pv_sqrt,
    '-'    => \&pv_sub,
    '/'    => \&pv_div,
    '++'   => \&pv_inc,
    '--'   => \&pv_dec,
    '=='   => \&pv_num_eq,
    '<'    => \&pv_num_lt,
    '>'    => \&pv_num_gt,
    '<='   => \&pv_num_lte,
    '>='   => \&pv_num_gte,
    'eq'   => \&pv_str_eq,
    'ne'   => \&pv_str_ne,
    '""'   => \&pv_print,
    '<=>'  => \&pv_ncmp,
    'cmp'  => \&pv_scmp,
    'bool' => \&pv_bool;

our $VERSION = 1.0009;

our $StrictTypes    = 0; # throws errors on unknown units
our $PrintPrecision = 2; 
our $fmt;
    $fmt = new Number::Format if not defined $fmt;

our @EXPORT_OK = qw(pv PV G);
our @AUTO_PLURALS = ();

# NOTE:  AUTO_PLURALS and G are not documented because they are still experimental

1;

sub G { Math::Units::PhysicalValue->new( "6.672e-11 N m^2 / kg^2" ) }

# PV {{{
sub PV {
    my $v = shift;

    return Math::Units::PhysicalValue->new( $v );
}
*pv = *PV;
# }}}

# new {{{
sub new {
    my $class = shift;
    my $value = shift;
    my $this  = bless [], $class;

    $value = 0 unless defined $value;

    if( $value =~ m/^\s*([\-\,\.\de]+)\s*([\s\w\^\d\.\/\*]*)$/ ) {
        my ($v, $u) = ($1, $2);

        $v =~ s/\,//g;
        $u =~ s/\^/**/g;
        $u =~ s/(\w+(?:\*\*\d+)?)\s+(\w+(?:\*\*\d+)?)/$1*$2/g;
        $u =~ s/\s//g;

        if ( $StrictTypes ) {
            eval { convert(3.1415926, $u, '') };
            if( $@ =~ /unknown unit/ ) {
                my $e = $@;
                $e =~ s/ at .*PhysicalValue.*//s;
                croak $e;
            }
        }

        $u =~ s/\b$_->[1]\b/$_->[0]/sg for @AUTO_PLURALS;

        $this->[0] = Math::BigFloat->new($v);
        $this->[1] = new Math::Units::PhysicalValue::AutoUnit $u;

    } else {
        croak "value passed to PhysicalValue->new(\"$value\") was not understood";
    }

    return $this;
}
# }}}
# deunit {{{
sub deunit {
    my $this = shift;

    return $this->[0];
}
# }}}

# pv_add {{{
sub pv_add {
    my ($lhs, $rhs) = @_; 
    
    $rhs = ref($lhs)->new($rhs eq "0" ? "0 $lhs->[1]" : $rhs) unless ref $rhs eq ref $lhs;

    my $v; 
    eval {
        $v = convert(@$lhs, $rhs->[1]);
    };

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    $v += $rhs->[0];

    return bless [ $v, $rhs->[1] ], ref $lhs;
}
# }}}
# pv_mul {{{
sub pv_mul {
    my ($lhs, $rhs) = @_; 

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;

    my ($v, $u) = (@$lhs);

    $v *= $rhs->[0];
    $u *= $rhs->[1];

    return bless [ $v, $u ], ref $lhs;
}
# }}}
# pv_mulmul {{{
sub pv_mulmul {
    my ($lhs, $rhs) = @_; 

    croak "right hand side must be a scalar (ie no units)" if ref($rhs);

    my ($v, $u) = (@$lhs);

    $v = $v ** $rhs;
    $u = $u ** $rhs;

    return bless [ $v, $u ], ref $lhs;
}
# }}}
# pv_sqrt {{{
sub pv_sqrt {
    my ($lhs) = @_; 

    my ($v, $u) = (@$lhs);

    $v = sqrt( $v );
    $u = sqrt( $u );

    return bless [ $v, $u ], ref $lhs;
}
# }}}
# pv_div {{{
sub pv_div {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs / $lhs if $assbackwards;

    my ($v, $u) = (@$lhs);

    $v /= $rhs->[0];
    $u /= $rhs->[1];

    return bless [ $v, $u ], ref $lhs;
}
# }}}

# pv_sub {{{
sub pv_sub {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs eq "0" ? "0 $lhs->[1]" : $rhs) unless ref $rhs eq ref $lhs;
    return ($rhs - $lhs) if $assbackwards;

    return $lhs->pv_add( $rhs->pv_mul(-1) );
}
# }}}

# pv_inc {{{
sub pv_inc {
    my $this = shift;

    $this->[0] ++;
    
    return $this;
}
# }}}
# pv_dec {{{
sub pv_dec {
    my $this = shift;

    $this->[0] --;
    
    return $this;
}
# }}}

# pv_str_eq {{{
sub pv_str_eq {
    my ($lhs, $rhs) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    $rhs->[0] = $v;
    $rhs->[1] = $lhs->[1];

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return "$lhs" eq "$rhs";
}
# }}}
# pv_str_ne {{{
sub pv_str_ne {
    my ($lhs, $rhs) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    $rhs->[0] = $v;
    $rhs->[1] = $lhs->[1];

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return "$lhs" ne "$rhs";
}
# }}}
# pv_num_eq {{{
sub pv_num_eq {
    my ($lhs, $rhs) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return $lhs->[0] == $v;
}
# }}}
# pv_num_lt {{{
sub pv_num_lt {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs < $lhs if $assbackwards;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return $lhs->[0] < $v;
}
# }}}
# pv_num_gt {{{
sub pv_num_gt {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs > $lhs if $assbackwards;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return $lhs->[0] > $v;
}
# }}}
# pv_num_lte {{{
sub pv_num_lte {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs <= $lhs if $assbackwards;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return $lhs->[0] <= $v;
}
# }}}
# pv_num_gte {{{
sub pv_num_gte {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs >= $lhs if $assbackwards;

    my $v;
    eval {
        $v = convert(@$rhs, $lhs->[1]);
    };

    if( $@ ) {
        my $e = $@;
        $e =~ s/'1'/''/;
        $e =~ s/ at .*PhysicalValue.*//s;
        croak $e;
    }

    return $lhs->[0] >= $v;
}
# }}}

# pv_print {{{
sub pv_print {
    my $this = shift;
    my ($v, $u) = @$this;

    if( $u->{unit} == 1 ) {
        $u = "";

    } else {
        $u = " $u";

        # XXX: evil hack
        # Attempt to impose alphabetical ordering 
        # on kg*m/s vs m*kg/s
        # (this will only catch simple cases)
        my @to_fix;
        while($u =~ m/\b(\w+\*\w+)\b/g) {
            my $orig = $1;
            my @s = split m/\*/, $orig;
            my $fixed = join('*', sort @s);
            push @to_fix, [quotemeta($orig) => $fixed] if $orig ne $fixed;
        }

        $u =~ s/$_->[0]/$_->[1]/ for @to_fix;

        if( $v != 1 ) {
            $u =~ s/\b$_->[0]\b/$_->[1]/sg for @AUTO_PLURALS;
        }
    }

    return $v . $u if $PrintPrecision < 0;

    # temprary fix until I hear back from the Number::Format guy

    # $v->bstr; returns a string number
    # $v->bsstr; returns a string in scinoti
    # we can maybe use sstr later?

    $v = $v->bstr;

    my $f = join('', $fmt->format_number( $v, $PrintPrecision ), $u);
    if( $f =~ m/^\S*e/ ) {
        $f = $v . $u;
        $f =~ s/e\+(\d+)/e$1/g;
        $f =~ s/^([\.\-\d]+)(?=e)/$fmt->format_number( $1, $PrintPrecision )/e if $PrintPrecision >= 0;
    }
    return $f;

    # original numbers

=cut
    return "$v $u" if $PrintPrecision < 0;
    return join(" ", $fmt->format_number( $v, $PrintPrecision ), $u);
=cut

}
# }}}
# pv_bool {{{
sub pv_bool {
    my $this = shift;
    my ($v, $u) = @$this;

    return $v;
}
# }}}
# pv_ncmp {{{
sub pv_ncmp {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs <=> $lhs if $assbackwards;

    return -1 if $lhs < $rhs;
    return  1 if $lhs > $rhs;
    return 0;
}
# }}}
# pv_scmp {{{
sub pv_scmp {
    my ($lhs, $rhs, $assbackwards) = @_;

    $rhs = ref($lhs)->new($rhs) unless ref $rhs eq ref $lhs;
    return $rhs cmp $lhs if $assbackwards;

    return -1 if "$lhs" lt "$rhs";
    return  1 if "$lhs" gt "$rhs";
    return 0;
}
# }}}
# sci {{{
sub sci {
    my $this   = shift;
    my $digits = shift;
    my ($v, $u) = @$this;
    my $e = 0;
       $e = int( log($v) / log(10) ) unless $v == 0;

    if( $u->{unit} == 1 ) {
        $u = "";
    } else {
        $u = " $u";
    }

    croak "please use 0 or more sigfigs..." if $digits < 0;

    # $v->bstr; returns a string number
    # $v->bsstr; returns a string in scinoti
    # we can maybe use sstr later?

    $v /= (10 ** $e);
    $v  = $v->bstr;

    $v = $fmt->format_number($v, $digits-1) . "e$e";

    return $v . $u;
}
# }}}
