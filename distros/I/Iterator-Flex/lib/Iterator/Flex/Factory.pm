package Iterator::Flex::Factory;

# ABSTRACT: Create on-the-fly Iterator::Flex classes/objects

use 5.25.0;
use strict;
use warnings;

use experimental qw( signatures declared_refs refaliasing);

our $VERSION = '0.19';

use Ref::Util        ();
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime;


use Iterator::Flex::Base;
use Iterator::Flex::Utils qw[
  :ExhaustionActions
  :default
  :RegistryKeys
  :IterAttrs
  parse_pars
];

Role::Tiny::With::with 'Iterator::Flex::Role::Utils';










sub to_iterator ( $CLASS, $iterable = undef, $pars = {} ) {
    return defined $iterable
      ? $CLASS->construct_from_iterable( $iterable, $pars )
      : $CLASS->construct( {
            ( +NEXT ) => sub { }
        } );
}



############################################################################












sub construct ( $CLASS, $in_ipar = {}, $in_gpar = {} ) {

    $CLASS->_throw( parameter => "'iterator parameters' parameter must be a hashref" )
      unless Ref::Util::is_hashref( $in_ipar );

    $CLASS->_throw( parameter => "'general parameters' parameter must be a hashref" )
      unless Ref::Util::is_hashref( $in_gpar );

    my %ipar = $in_ipar->%*;
    my %ipar_k;
    @ipar_k{ keys %ipar } = ();
    my %gpar = $in_gpar->%*;
    my %gpar_k;
    @gpar_k{ keys %gpar } = ();

    my $par;
    my @roles;

    my $class = $ipar{ +CLASS } // 'Iterator::Flex::Base';
    delete $ipar_k{ +CLASS };

    $CLASS->_throw( parameter => "'class' parameter must be a string" )
      if Ref::Util::is_ref( $class );

    $CLASS->_throw( parameter => "can't load class $class" )
      if $class ne 'Iterator::Flex::Base'
      && !Module::Runtime::require_module( $class );

    delete $ipar_k{ +_NAME };
    $CLASS->_throw( parameter => "'@{[ _NAME ]}' parameter value must be a string\n" )
      if defined( $par = $ipar{ +_NAME } ) && Ref::Util::is_ref( $par );

    push @roles, 'State::Registry';

    delete $gpar_k{ +INPUT_EXHAUSTION };
    my $input_exhaustion = $gpar{ +INPUT_EXHAUSTION } // [ ( +RETURN ) => undef ];

    my @input_exhaustion
      = Ref::Util::is_arrayref( $input_exhaustion )
      ? ( $input_exhaustion->@* )
      : ( $input_exhaustion );

    delete $gpar_k{ +EXHAUSTION };
    my $has_output_exhaustion_policy = defined $gpar{ +EXHAUSTION };

    if ( $input_exhaustion[0] eq +RETURN ) {
        push @roles, 'Exhaustion::ImportedReturn', 'Wrap::Return';
        push $input_exhaustion->@*, undef if @input_exhaustion == 1;
        $gpar{ +INPUT_EXHAUSTION } = \@input_exhaustion;
        $gpar{ +EXHAUSTION }       = $gpar{ +INPUT_EXHAUSTION }
          unless $has_output_exhaustion_policy;
    }

    elsif ( $input_exhaustion[0] eq THROW ) {
        push @roles, 'Exhaustion::ImportedThrow', 'Wrap::Throw';
        $gpar{ +INPUT_EXHAUSTION } = \@input_exhaustion;
        $gpar{ +EXHAUSTION }       = [ ( +THROW ) => PASSTHROUGH ]
          unless $has_output_exhaustion_policy;
    }

    $CLASS->_throw( parameter => "missing or undefined 'next' parameter" )
      if !defined( $ipar{ +NEXT } );

    for my $method ( +NEXT, +REWIND, +RESET, +PREV, +CURRENT ) {

        delete $ipar_k{$method};
        next unless defined( my $code = $ipar{$method} );

        $CLASS->_throw( parameter => "'$method' parameter value must be a code reference\n" )
          unless Ref::Util::is_coderef( $code );

        # if $class can't perform the required method, add a role
        # which can.
        if ( $method eq +NEXT ) {
            # next is always a closure, but the caller may want to
            # keep track of $self
            push @roles, defined $ipar{ +_SELF } ? 'Next::ClosedSelf' : 'Next::Closure';
            delete $ipar_k{ +_SELF };
        }
        else {
            my $impl = $class->can( $method ) ? 'Method' : 'Closure';
            push @roles, ucfirst( $method ) . '::' . $impl;
        }
    }

    # these are dealt with in the iterator constructor.
    delete @ipar_k{ +METHODS, +FREEZE };

    if ( !!%ipar_k || !!%gpar_k ) {

        $CLASS->_throw( parameter => "unknown iterator parameters: @{[ join( ', ', keys %ipar_k ) ]}" )
          if %ipar_k;
        $CLASS->_throw( parameter => "unknown iterator parameters: @{[ join( ', ', keys %gpar_k ) ]}" )
          if %gpar_k;
    }

    $ipar{_roles} = \@roles;

    return $class->new_from_attrs( \%ipar, \%gpar );
}


































sub construct_from_iterable ( $CLASS, $obj, $pars = {} ) {

    my ( $mpars, $ipars, $spars ) = parse_pars( $pars );

    $CLASS->_throw( parameter =>
          "unknown parameters pased to construct_from_iterable: @{[ join ', ', keys $mpars->%* ]}" )
      if $mpars->%*;

    if ( Ref::Util::is_blessed_ref( $obj ) ) {
        return $CLASS->construct_from_object( $obj, $ipars, $spars );
    }

    elsif ( Ref::Util::is_arrayref( $obj ) ) {
        $CLASS->_throw(
            parameter => "unknown parameters pased to construct_from_iterable: @{[ join ', ', $ipars->%* ]}" )
          if $ipars->%*;
        return $CLASS->construct_from_array( $obj, $spars );
    }

    elsif ( Ref::Util::is_coderef( $obj ) ) {
        return $CLASS->construct( { $ipars->%*, next => $obj }, $spars );
    }

    elsif ( Ref::Util::is_globref( $obj ) ) {
        return $CLASS->construct( {
                $ipars->%*, next => sub { scalar <$obj> }
            },
            $spars
        );
    }

    $CLASS->_throw(
        parameter => sprintf "'%s' object is not iterable",
        ( ref( $obj ) || 'SCALAR' ) );
}







sub construct_from_array ( $, $obj, $pars = {} ) {
    require Iterator::Flex::Array;
    return Iterator::Flex::Array->new( $obj, $pars );
}























sub construct_from_object ( $CLASS, $obj, $ipar, $gpar ) {

    $CLASS->_throw( parameter => q['$object' parameter is not a real object] )
      unless Ref::Util::is_blessed_ref( $obj );

    return construct_from_iterator_flex( $CLASS, $obj, $ipar, $gpar )
      if $obj->isa( 'Iterator::Flex::Base' );

    my %ipar = $ipar->%*;
    my %gpar = $gpar->%*;

    $gpar{ +INPUT_EXHAUSTION } //= [ ( +RETURN ) => undef ];

    if ( !exists $ipar{ +NEXT } ) {
        my $code;
        if ( $code = $CLASS->_can_meth( $obj, 'iter' ) ) {
            $ipar{ +NEXT } = $code->( $obj );
        }
        elsif ( $code = $CLASS->_can_meth( $obj, 'next' )
            || overload::Method( $obj, '<>', undef, undef ) )
        {
            $ipar{ +NEXT } = sub { $code->( $obj ) };
        }

        elsif ( $code = overload::Method( $obj, '&{}', undef, undef ) ) {
            $ipar{ +NEXT } = $code->( $obj );
        }

        elsif ( $code = overload::Method( $obj, '@{}', undef, undef ) ) {
            return $CLASS->construct_from_array( $code->( $obj ), \%gpar );
        }

    }

    for my $method ( grep { !exists $ipar{$_} } +PREV, +CURRENT ) {
        my $code = $CLASS->_can_meth( $obj, $method );
        $ipar{$method} = sub { $code->( $obj ) }
          if $code;
    }

    return $CLASS->construct( \%ipar, \%gpar );
}


# create a proxy object for an Iterator::Flex object.  This is only
# required if an adaptor needs a different exhaustion signal than is
# provided by the object.

# Currently, proxy objects are not treated specially when de-serializing
# (e.g., they'll be run through to_iterator), but it *should* be a no-op.


sub construct_from_iterator_flex ( $CLASS, $obj, $, $gpar ) {

    my \%registry
      = exists $REGISTRY{ refaddr $obj }
      ? $REGISTRY{ refaddr $obj }{ +GENERAL }
      : $CLASS->_throw( internal => "non-registered Iterator::Flex iterator" );


    # if caller didn't specify an exhaustion, set it to return => undef
    my @want = do {
        my $exhaustion = $gpar->{ +EXHAUSTION } // [ ( +RETURN ) => undef ];
        Ref::Util::is_arrayref( $exhaustion )
          ? ( $exhaustion->@* )
          : ( $exhaustion );
    };


    # multiple different output exhaustion roles may have been
    # applied, so the object may claim to support both roles,
    # Exhaustion::Throw and Exhaustion::Return, although only the
    # latest one applied will work.  So, use what's in the registry to
    # figure out what it actually does.

    my \@have = $registry{ +EXHAUSTION } // $CLASS->_throw(
        internal => "registered Iterator::Flex iterator doesn't have a registered exhaustion" );

    # reuse the object if the requested and existing exhaustion signals are the same.
    return $obj
      if $want[0] eq $have[0]
      && ( ( defined $want[1] && defined $have[1] && $want[1] eq $have[1] )
        || ( !defined $want[1] && !defined $have[1] ) );

    # now we need a proxy object.
    my %gpars = (
        exhaustion       => [@want],
        input_exhaustion => [@have],
    );

    my %ipars;
    for my $method ( +NEXT, +PREV, +CURRENT, +REWIND, +RESET, +FREEZE ) {
        next unless defined( my $code = $CLASS->_can_meth( $obj, $method ) );
        $ipars{$method} = sub { $code->( $obj ) };
    }

    return $CLASS->construct( \%ipars, \%gpars );
}

sub construct_from_attr ( $CLASS, $in_ipar = {}, $in_gpar = {} ) {
    my %gpar = $in_gpar->%*;

    # this indicates that there should be no wrapping of 'next'
    $gpar{ +INPUT_EXHAUSTION } = +PASSTHROUGH;
    $CLASS->construct( $in_ipar, \%gpar );
}

1;

#
# This file is part of Iterator-Flex
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Iterator::Flex::Factory - Create on-the-fly Iterator::Flex classes/objects

=head1 VERSION

version 0.19

=head1 CLASS METHODS

=head2 to_iterator

  $iter = Iterator::Flex::Factory->to_iterator( $iterable, \%par );

Construct an iterator from an L<iterable thing|Iterator::Flex::Manual::Glossary/iterable thing>,
with optional L<general parameters|Iterator::Flex::Manual::Overview/Classes of Parameters>.

=head2 construct

  $iterator = Iterator::Flex::Factory->construct( \%interface_pars, \%signal_pars );

Construct an iterator object from the passed hash of
I<< L<interface parameters|Iterator::Flex::Manual::Overview/Interface Parameters> >>
and
I<< L<signal parameters|Iterator::Flex::Manual::Overview/Signal Parameters> >>

=head2 construct_from_iterable

  $iter = Iterator::Flex::Factory->construct_from_iterable( $iterable, \%pars );

Construct an iterator from an
L<Iterator::Flex::Manual::Glossary/iterable thing>.  The returned
iterator will return C<undef> upon exhaustion.

If C<$iterable> is:

=over

=item *

an object, the arguments are passed to L</construct_from_object>.

=item *

an array, the arguments are passed to L<Iterator::Flex::Array/new>.

=item *

a coderef, the arguments are passed to L</construct>.

=item *

a globref, the arguments are passed to L</construct>.

=back

=head2 construct_from_array

  $iter = Iterator::Flex::Factory->construct_from_array( $array_ref, ?\%pars );

=head2 construct_from_object

  $iter = Iterator::Flex::Factory->construct_from_object( $object, %parameters );

Construct an iterator from an L<Iterator::Flex::Manual::Glossary/iterable object>.
Normal use is to call L</to_iterator>, L</construct_from_iterable> or
simply use L<Iterator::Flex/iter>.

If the object has the following methods, they are used
by the constructed iterator:

=over

=item C<__prev__> or C<prev>

=item C<__current__> or C<current>

=back

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-iterator-flex@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex>

=head2 Source

Source is available at

  https://gitlab.com/djerius/iterator-flex

and may be cloned from

  https://gitlab.com/djerius/iterator-flex.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Iterator::Flex|Iterator::Flex>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
