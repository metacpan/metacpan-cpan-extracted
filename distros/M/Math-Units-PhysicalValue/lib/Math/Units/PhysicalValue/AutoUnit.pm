package Math::Units::PhysicalValue::AutoUnit;

use strict;
use Carp;
use Math::Algebra::Symbols;
use overload
    '+'  => \&au_add,
    '-'  => \&au_sub,
    '/'  => \&au_div,
    '*'  => \&au_mul,
    '**' => \&au_mulmul,
  'sqrt' => \&au_sqrt,
    'eq' => \&au_eq,
    '""' => \&au_print;

our $VERSION = 1.0005; # PV::AU diverges from PV here

# new {{{
sub new {
    my $class = shift;
    my $unit  = shift;
    my $this  = bless {unit=>1}, $class;

    if( $unit =~ m/[^a-zA-Z]/i ) {
        my %unities = ();

        while( $unit =~ m/([a-zA-Z]+)/g ) {
            my $xxu = "xx$1";
            unless( $unities{$xxu} ) {
                $unities{$xxu} = symbols($xxu);
            }
        }

        my $obj;

        $unit =~ s/([a-zA-Z]+)/\$unities{"xx$1"}/g;
        $unit = "\$obj = $unit";

        eval $unit;
        die $@ if $@;

        # use Data::Dumper;
        # warn "$obj";
        # die Dumper( \%unities, $unit, $obj );

        $this->{unit} = $obj;

    } elsif( $unit =~ m/[a-zA-Z]/ ) {
        $this->{unit} = symbols("xx$unit");

    }

    return $this;
}
# }}}
# au_mul {{{
sub au_mul {
    my ($lhs, $rhs) = @_;

    return bless { unit=>($lhs->{unit} * $rhs->{unit}) }, ref $lhs;
}
# }}}
# au_mulmul {{{
sub au_mulmul {
    my ($lhs, $rhs) = @_;

    croak "right hand side must be a scalar" if ref($rhs);

    return bless { unit=>($lhs->{unit} ** $rhs) }, ref $lhs;
}
# }}}
# au_sqrt {{{
sub au_sqrt {
    my ($lhs) = @_;

    return bless { unit=>sqrt($lhs->{unit}) }, ref $lhs;
}
# }}}
# au_div {{{
sub au_div {
    my ($lhs, $rhs) = @_;

    return bless { unit=>($lhs->{unit} / $rhs->{unit}) }, ref $lhs;
}
# }}}
# au_print {{{
sub au_print {
    my $this = shift;
    my $a = $this->{unit};
       $a =~ s/\$xx//g;
       $a =~ s/\*\*/\^/g;

    return $a;
}
# }}}
# au_eq {{{
sub au_eq {
    my ($lhs, $rhs) = @_;

    return $lhs->au_print eq $rhs->au_print;
}
# }}}

"this file is true"
