package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use 5.28.0;    # hash slices

use strict;
use warnings;

use experimental 'signatures', 'postderef';

our $VERSION = '0.25';

use Scalar::Util qw( refaddr );
use Ref::Util    qw( is_hashref );
use Exporter 'import';
use experimental 'declared_refs';

our %REGISTRY;

sub mk_indices {
    my $idx = 0;
    return { map { $_ => $idx++ } @_ };
}

sub mk_lc {
    return { map { $_ => lc $_ } @_ };
}

use constant ITER_ATTRS => qw(
  CLASS CURRENT FREEZE METHODS NEXT PREV RESET REWIND STATE _DEPENDS _NAME _ROLES _SELF
);
use constant mk_lc ITER_ATTRS;
use constant REGISTRY_ITERATION_INDICES => map { 'REG_ITER_' . $_ } ITER_ATTRS, 'MAY_METHOD';
use constant mk_indices REGISTRY_ITERATION_INDICES;
our \%RegIterationIndexMap = mk_indices map { lc } ITER_ATTRS;

use constant EXHAUSTED_METHODS => qw( IS_EXHAUSTED SET_EXHAUSTED  );
use constant mk_lc EXHAUSTED_METHODS;

use constant ITER_STATES => qw( IterState_CLEAR IterState_EXHAUSTED IterState_ERROR );
use constant mk_indices ITER_STATES;

use constant REGISTRY_INDICES => qw( REG_ITERATOR REG_GENERAL REG_METHODS );
use constant mk_indices REGISTRY_INDICES;

use constant EXHAUSTION_ACTIONS => qw[ THROW RETURN PASSTHROUGH ];
use constant mk_lc EXHAUSTION_ACTIONS;

# these duplicate ITER_ATTRS. combine?
use constant INTERFACE_PARAMETERS =>
  qw( CURRENT FREEZE METHODS NEXT PREV RESET REWIND STATE _DEPENDS _NAME _ROLES _SELF );
use constant INTERFACE_PARAMETER_VALUES => map { lc $_ } INTERFACE_PARAMETERS;
use constant mk_lc INTERFACE_PARAMETERS;


use constant SIGNAL_PARAMETERS       => qw( INPUT_EXHAUSTION EXHAUSTION ERROR );
use constant SIGNAL_PARAMETER_VALUES => map { lc $_ } SIGNAL_PARAMETERS;
use constant mk_lc SIGNAL_PARAMETERS;

use constant GENERAL_PARAMETERS      => ( INTERFACE_PARAMETERS, SIGNAL_PARAMETERS );
use constant REGISTRY_GENPAR_INDICES => map { 'REG_GP_' . $_ } GENERAL_PARAMETERS;
use constant mk_indices REGISTRY_GENPAR_INDICES;

our \%RegGeneralParameterIndexMap = mk_indices map { lc } GENERAL_PARAMETERS;

our %EXPORT_TAGS = (
    ExhaustionActions => [EXHAUSTION_ACTIONS],
    ExhaustedMethods  => [EXHAUSTED_METHODS],
    RegistryIndices   => [
        REGISTRY_INDICES,        REGISTRY_ITERATION_INDICES,
        '%RegIterationIndexMap', REGISTRY_GENPAR_INDICES,
        '%RegGeneralParameterIndexMap'
    ],
    IterAttrs           => [ITER_ATTRS],
    IterStates          => [ITER_STATES],
    SignalParameters    => [ SIGNAL_PARAMETERS,    'SIGNAL_PARAMETER_VALUES' ],
    InterfaceParameters => [ INTERFACE_PARAMETERS, 'INTERFACE_PARAMETER_VALUES' ],
    GeneralParameters   => [ GENERAL_PARAMETERS, ],
    Functions           => [ qw(
          throw_failure
          parse_pars
        )
    ],
    default => [qw( %REGISTRY refaddr )],
);

## no critic ( AutomaticExportation )
our @EXPORT = @{ $EXPORT_TAGS{default} };    # ??? is this needed?

our @EXPORT_OK = ( map { @{$_} } values %EXPORT_TAGS, );


use Role::Tiny::With;
with 'Iterator::Flex::Role::Utils';

sub throw_failure ( $failure, $msg ) {
    require Iterator::Flex::Failure;
    my $type = join( q{::}, 'Iterator::Flex::Failure', $failure );
    $type->throw( { msg => $msg, trace => Iterator::Flex::Failure->croak_trace } );
}













sub parse_pars ( @args ) {

    my %pars = do {

        if ( @args == 1 ) {
            is_hashref( $args[0] )
              or throw_failure( parameter => 'expected a hashref' );
            $args[0]->%*;
        }

        else {
            @args % 2
              and throw_failure( parameter => 'expected an even number of arguments for hash' );
            @args;
        }
    };

    my %ipars = delete %pars{ grep exists $pars{$_}, INTERFACE_PARAMETER_VALUES };
    my %spars = delete %pars{ grep exists $pars{$_}, SIGNAL_PARAMETER_VALUES };

    return ( \%pars, \%ipars, \%spars );
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

Iterator::Flex::Utils - Internal utilities

=head1 VERSION

version 0.25

=head1 SUBROUTINES

=head2 parse_pars

  ( $mpars, $ipars, $spars ) = parse_params( \%args  );

Returns the
L<model|Iterator::Flex::Manual::Overview/Model Parameters>
L<interface|Iterator::Flex::Manual::Overview/Interface Parameters>
L<signal|Iterator::Flex::Manual::Overview/Signal Parameters>
parameters from C<%args>.

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
