#line 1
package UNIVERSAL::can;

use strict;
use warnings;

use vars qw( $VERSION $recursing );
$VERSION = '1.16';

use Scalar::Util 'blessed';
use warnings::register;

my $orig;
use vars '$always_warn';

BEGIN
{
    $orig = \&UNIVERSAL::can;

    no warnings 'redefine';
    *UNIVERSAL::can = \&can;
}

sub import
{
    my $class = shift;
    for my $import (@_)
    {
        $always_warn = 1 if $import eq '-always_warn';
        no strict 'refs';
        *{ caller() . '::can' } = \&can if $import eq 'can';
    }
}

sub can
{
    my $caller = caller();
    local $@;

    # don't get into a loop here
    goto &$orig if $recursing
                || (   defined $caller
                   &&  defined $_[0]
                   &&  eval { local $recursing = 1; $caller->isa($_[0]) } );

    # call an overridden can() if it exists
    my $can = eval { $_[0]->$orig('can') || 0 };

    # but only if it's a real class
    goto &$orig unless $can;

    # but not if it inherited this one
    goto &$orig if     $can == \&UNIVERSAL::can;

    # redirect to an overridden can, making sure not to recurse and warning
    local $recursing = 1;
    my    $invocant  = shift;

    _report_warning();
    return $invocant->can(@_);
}

sub _report_warning
{
    if ( $always_warn || warnings::enabled() )
    {
        my $calling_sub = ( caller(2) )[3] || '';
        warnings::warn("Called UNIVERSAL::can() as a function, not a method")
            if $calling_sub !~ /::can$/;
    }

    return;
}

1;
__END__

#line 154
