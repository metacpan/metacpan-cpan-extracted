package Devel::Spy::Util;
use strict;
use warnings;

use overload     ();
use Scalar::Util ();
use Carp         ();
use Symbol       ();

sub Y {    ## no critic (Prototype)
           # The Y combinator.
    my ( undef, $curried_rec ) = @_;
    my $p = sub {
        my $f = shift @_;
        return $curried_rec->( sub { $f->($f)->(@_) } );
    };
    return $p->($p);
}

sub compile_this {

    # Accepts some source code and expects to return a true
    # value. Devel::Spy::_obj uses this to compile a bunch of subs but
    # without having to repeat the "eval or croak" stuff all over the
    # place.
    #
    # Example:
    #   my $sub = Devel::Spy::Util::compile_this( <<"SRC" );
    #       sub ... {
    #           ...
    #       };
    #       1;
    #   SRC
    my ( undef, $src ) = @_;
    my ( $package, $filename, $line ) = caller;

    # Add some sugar to make the code appear in the proper location.
    $src = <<"CODE";
#line @{[$line]} "@{[$filename]}"
package $package;
$src
CODE

    ## no critic (Eval)
    my $result = eval $src
        or Carp::confess "$@ while compiling:\n$src";
    return $result;
}

my %class_rx_cache;

sub comes_from {
    my $class    = shift @_;
    my $class_rx = $class_rx_cache{$class} ||= qr/\A\Q$class\E(?:\z|::)/;

    # Returns a string showing the location of the non-Devel::Spy code
    # that's higher in the call stack.
    my $cx = 1;
    while ( my ( $pkg, undef, $line ) = caller $cx++ ) {

        # Find !Devel::Spy
        unless ( $pkg =~ $class_rx ) {
            return "($pkg:$line)";
        }
    }

    # Huh? I suppose this only occurs if Devel::Spy is the *only*
    # thing in the call stack and I'm not even sure how that happens.
    return;
}

sub wrap_thing {
    my ( $class, $thing, $code ) = @_;

    # Use a tied proxy to $thing instead of $thing directly. But only
    # if $thing is a reference.
    my $reftype = Scalar::Util::reftype $thing;
    return $thing unless defined $reftype;

    # This may be a really bad idea.
    $class =~ s/::Util\z//;

    # Return a tied wrapper over $thing.
    if ( 'HASH' eq $reftype ) {
        tie my %pretend_self, "$class\::TieHash", $thing, $code;
        return \%pretend_self;
    }
    elsif ( 'ARRAY' eq $reftype ) {
        tie my @pretend_self, "$class\::TieArray", $thing, $code;
        return \@pretend_self;
    }
    elsif ( $reftype =~ /^(?:SCALAR|REF|CODE|LVALUE|REGEXP|VSTRING|BIND)\z/ ) {
        tie my $pretend_self, "$class\::TieScalar", $thing, $code;
        return \$pretend_self;
    }
    elsif ( $reftype =~ /^(?:GLOB|FORMAT|IO)\z/ ) {
        my $pretend_self = Symbol::gensym();
        tie *$pretend_self, "$class\::TieHandle", $thing, $code;
        return $pretend_self;
    }

    # Missing implementations?
    Carp::croak "Unsupported reftype: $reftype on "
        . overload::StrVal($thing);
}

1;

__END__

=head1 NAME

Devel::Spy::Util - Utility functions for Devel::Spy

=head1 PRIVATE METHODS

=over

=item C<< FUNCTION = Devel::Spy::Util->Y( FUNCTION ) >>

The Y combinator. See http://use.perl.org/~Aristotle/journal/30896 for
the scoop. Devel::Spy uses it to make functions that support the
following snippet.

  while ( ... ) {
      $logger = $logger->();
  }

=item C<< VALUE = Devel::Spy::Util->compile_this( SOURCE CODE ) >>

Compiles SOURCE CODE and returns it. It throws an exception if the
result is false.

=item C<< LOCATION = Devel::Spy::Util->comes_from >>

Returns a string showing the file and line number that called into
Devel::Spy.

=item C<< WRAPPED OBJECT = Devel::Spy::Util->wrap_thing( OBJECT, CODE ) >>

=item C<< WRAPPED OBJECT = Devel::Spy::Util->wrap_thing( REFERENCE, CODE ) >>

=item C<< VALUE = Devel::Spy::Util->wrap_thing( VALUE, CODE ) >>

If the "thing" passed in as the first parameter is any kind of
reference or object it is returned in a Devel::Spy::Tie* wrapper.

This is how Devel::Spy tracks accesses to hashes and other references.

=item SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::TieHash>,
L<Devel::Spy::TieArray>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>

=back
