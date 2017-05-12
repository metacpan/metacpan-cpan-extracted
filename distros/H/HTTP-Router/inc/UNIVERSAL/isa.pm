#line 1
package UNIVERSAL::isa;

use strict;
use vars qw( $VERSION $recursing );

use UNIVERSAL ();

use Scalar::Util 'blessed';
use warnings::register;

$VERSION = '1.03';

my ( $orig, $verbose_warning );

BEGIN { $orig = \&UNIVERSAL::isa }

no warnings 'redefine';

sub import
{
    my $class = shift;
    no strict 'refs';

    for my $arg (@_)
    {
        *{ caller() . '::isa' } = \&UNIVERSAL::isa if $arg eq 'isa';
        $verbose_warning = 1 if $arg eq 'verbose';
    }
}

sub UNIVERSAL::isa
{
    goto &$orig if $recursing;
    my $type = invocant_type(@_);
    $type->(@_);
}

sub invocant_type
{
    my $invocant = shift;
    return \&nonsense unless defined($invocant);
    return \&object_or_class if blessed($invocant);
    return \&reference       if ref($invocant);
    return \&nonsense unless $invocant;
    return \&object_or_class;
}

sub nonsense
{
    report_warning('on invalid invocant') if $verbose_warning;
    return;
}

sub object_or_class
{

    local $@;
    local $recursing = 1;

    if ( my $override = eval { $_[0]->can('isa') } )
    {
        unless ( $override == \&UNIVERSAL::isa )
        {
            report_warning();
            my $obj = shift;
            return $obj->$override(@_);
        }
    }

    report_warning() if $verbose_warning;
    goto &$orig;
}

sub reference
{
    report_warning('Did you mean to use Scalar::Util::reftype() instead?')
        if $verbose_warning;
    goto &$orig;
}

sub report_warning
{
    my $extra = shift;
    $extra = $extra ? " ($extra)" : '';

    if ( warnings::enabled() )
    {
        my $calling_sub = ( caller(3) )[3] || '';
        return if $calling_sub =~ /::isa$/;
        warnings::warn(
            "Called UNIVERSAL::isa() as a function, not a method$extra" );
    }
}

__PACKAGE__;

__END__

#line 174
