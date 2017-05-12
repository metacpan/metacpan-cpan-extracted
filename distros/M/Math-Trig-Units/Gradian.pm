package Math::Trig::Gradian;

use vars qw( @ISA @EXPORT_OK $VERSION $AUTOLOAD );
use Math::Trig::Units;
$VERSION = '0.02';
@ISA=qw(Exporter);
@EXPORT_OK=qw(
    dsin    asin
    dcos    acos
    tan     atan
    sec     asec
    csc     acsc
    cot     acot
    sinh    asinh
    cosh    acosh
    tanh    atanh
    sech    asech
    csch    acsch
    coth    acoth
    deg_to_rad  rad_to_deg
    grad_to_rad rad_to_grad
    deg_to_grad grad_to_deg
    );

BEGIN { Math::Trig::Units::units('gradians') };

sub AUTOLOAD {     no strict 'refs'; my ($pkg,$func) = ($AUTOLOAD =~ /(.*)::([^:]+)$/); &{"Math::Trig::Units::$func"} }

1;

__END__

=head1 NAME

    Math::Trig::Gradian - Inverse and hyperbolic trigonemetric Functions
                           in gradians

=head1 SYNOPSIS

    use Math::Trig::Gradian qw(dsin dcos tan sec csc cot asin acos atan asec acsc acot sinh cosh tanh sech csch coth asinh acosh atanh asech acsch acoth);
    $v = dsin($x);
    $v = dcos($x);
    $v = tan($x);
    $v = sec($x);
    $v = csc($x);
    $v = cot($x);
    $v = asin($x);
    $v = acos($x);
    $v = atan($x);
    $v = asec($x);
    $v = acsc($x);
    $v = acot($x);
    $v = sinh($x);
    $v = cosh($x);
    $v = tanh($x);
    $v = sech($x);
    $v = csch($x);
    $v = coth($x);
    $v = asinh($x);
    $v = acosh($x);
    $v = atanh($x);
    $v = asech($x);
    $v = acsch($x);
    $v = acoth($x);

=head1 DESCRIPTION

This module exports the missing inverse and hyperbolic trigonometric
functions of real numbers.  The inverse functions return values
cooresponding to the principal values.  Specifying an argument outside
of the domain of the function where an illegal divion by zero would occur
will cause infinity to be returned. Infinity is Perl's version of this.

This module is a sub-class of Math::Trig::Units and operates in gradians. For
full documentation see the Math::Trig::Units module.

=head1 AUTHOR

Initial Version John A.R. Williams <J.A.R.Williams@aston.ac.uk>
Bug fixes and many additonal functions Jason Smith <smithj4@rpi.edu>
This version James Freeman <james.freeman@id3.org.uk>

=cut




