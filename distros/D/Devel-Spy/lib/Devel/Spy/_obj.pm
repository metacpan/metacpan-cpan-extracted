package Devel::Spy::_obj;
use strict;
use warnings;

## WARNING!!!! HEY!! Read this!

# This package should be as spotless as possible. Don't define or
# import any functions here because then they'll shadow that if it's
# also defined in the objects that are being wrapped.

# Seriously. Make recursion fatal. I hit this alot when writing this
# kind of code and it helps to have a backstop.
use warnings FATAL => 'all';

use overload ();
use Sub::Name ();
use UNIVERSAL::ref;
use Devel::Spy::Util ();
use Devel::Spy::_constants;
use Devel::Spy::_overload;

# Called by UNIVERSAL::ref.
#
# TODO: what if my called object also would like ->ref invoked as a method?
sub ref {
    return CORE::ref( $_[Devel::Spy::SELF][Devel::Spy::UNTIED_PAYLOAD] );
}
        
# Do all the proxy work for methods (other than isa and can) here.
#
# TODO: what if my wrapped object needs an AUTOLOAD too?
use vars '$AUTOLOAD';

sub AUTOLOAD {
    my $method = $AUTOLOAD;
    $method =~ s/^Devel::Spy::_obj:://;

    my $self  = shift @_;
    my $class = Scalar::Util::blessed( $self->[Devel::Spy::UNTIED_PAYLOAD] );

    # Redispatch and log, maintaining context.
    if (wantarray) {

        # Log before.
        my $followup = $self->[Devel::Spy::CODE]->( " \@->$method("
                . join( ',', map overload::StrVal($_), @_ )
                . ')' );

        # Redispatch.
        my @results = $self->[Devel::Spy::UNTIED_PAYLOAD]->$method(@_);

        # Log after.
        $followup = $followup->(
            ' ->(' . join( ',', map overload::StrVal($_), @results ) . ')' );

        return @results;
    }
    elsif ( defined wantarray ) {

        # Log before.
        my $followup = $self->[Devel::Spy::CODE]->( " \$->$method("
                . join( ',', map overload::StrVal($_), @_ )
                . ')' );

        # Redispatch.
        my $result = $self->[Devel::Spy::UNTIED_PAYLOAD]->$method(@_);

        # Log after.
        $followup = $followup->( ' ->' . overload::StrVal($result) );

        return Devel::Spy->new( $result, $followup );
    }
    else {

        # Log before.
        my $followup = $self->[Devel::Spy::CODE]->( " V->$method("
                . join( ',', map overload::StrVal($_), @_ )
                . ')' );

        # Redispatch.
        $self->[Devel::Spy::UNTIED_PAYLOAD]->$method(@_);

        # Log after?

        return;
    }
}

# TODO: what if my called object should accept this DESTROY call?
sub DESTROY { }

1;

__END__

=head1 NAME

Devel::Spy::_obj - Devel::Spy implementation

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::Util>, L<Devel::Spy::TieHash>,
L<Devel::Spy::TieArray>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>
