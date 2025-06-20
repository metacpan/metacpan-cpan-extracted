package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use 5.28.0;    # hash slices

use strict;
use warnings;

use experimental 'signatures', 'postderef';

our $VERSION = '0.19';

use Scalar::Util qw( refaddr );
use Ref::Util    qw( is_hashref );
use Exporter 'import';

our %REGISTRY;

our %ExhaustionActions;
our %RegistryKeys;
our %IterAttrs;
our %Methods;
our %IterStates;

BEGIN {
    %ExhaustionActions = ( map { $_ => lc $_ } qw[ THROW RETURN PASSTHROUGH ] );

    %RegistryKeys
      = ( map { $_ => lc $_ } qw[ INPUT_EXHAUSTION EXHAUSTION ERROR STATE ITERATOR GENERAL METHODS ] );

    %IterAttrs = (
        map { $_ => lc $_ }
          qw[ _SELF _DEPENDS _ROLES _NAME STATE CLASS
          NEXT PREV CURRENT REWIND RESET FREEZE METHODS ]
    );

    %Methods = ( map { $_ => lc $_ } qw[ IS_EXHAUSTED SET_EXHAUSTED  ] );

    %IterStates = (
        IterState_CLEAR     => 0,
        IterState_EXHAUSTED => 1,
        IterState_ERROR     => 2,
    );
}

use constant \%ExhaustionActions;
use constant \%RegistryKeys;
use constant \%IterAttrs;
use constant \%Methods;
use constant \%IterStates;

our @InterfaceParameters;
our @SignalParameters;

BEGIN {
    @InterfaceParameters = (
        +_NAME,  +_SELF, +_DEPENDS, +_ROLES,  +STATE,   +NEXT,
        +REWIND, +RESET, +PREV,     +CURRENT, +METHODS, +FREEZE
    );
    @SignalParameters = ( +INPUT_EXHAUSTION, +EXHAUSTION, +ERROR, );
}

use constant InterfaceParameters => @InterfaceParameters;
use constant SignalParameters    => @SignalParameters;
use constant GeneralParameters   => +InterfaceParameters, +SignalParameters;

our %SignalParameters    = {}->%{ +SignalParameters };
our %InterfaceParameters = {}->%{ +InterfaceParameters };

our %EXPORT_TAGS = (
    ExhaustionActions => [ keys %ExhaustionActions, ],
    RegistryKeys      => [ keys %RegistryKeys ],
    IterAttrs         => [ keys %IterAttrs ],
    IterStates        => [ keys %IterStates ],
    Methods           => [ keys %Methods ],
    GeneralParameters => [GeneralParameters],
    Functions         => [ qw(
          check_invalid_interface_parameters
          check_invalid_signal_parameters
          check_valid_interface_parameters
          check_valid_signal_parameters
          throw_failure
          parse_pars
        )
    ],
    default => [qw( %REGISTRY refaddr )],
);

our @EXPORT = @{ $EXPORT_TAGS{default} };

our @EXPORT_OK = ( map { @{$_} } values %EXPORT_TAGS, );


use Role::Tiny::With;
with 'Iterator::Flex::Role::Utils';

sub throw_failure ( $failure, $msg ) {
    require Iterator::Flex::Failure;
    my $type = join( '::', 'Iterator::Flex::Failure', $failure );
    $type->throw( { msg => $msg, trace => Iterator::Flex::Failure->croak_trace } );
}













sub parse_pars ( @args ) {

    my %pars = do {

        if ( @args == 1 ) {
            throw_failure( parameter => "expected a hashref " )
              unless is_hashref( $args[0] );
            $args[0]->%*;
        }

        else {
            throw_failure( parameter => "expected an even number of arguments for hash" )
              if @args % 2;
            @args;
        }
    };

    my %ipars = delete %pars{ check_valid_interface_parameters( [ keys %pars ] ) };
    my %spars = delete %pars{ check_valid_signal_parameters( [ keys %pars ] ) };

    return ( \%pars, \%ipars, \%spars );
}









sub check_invalid_interface_parameters ( $pars ) {
    return ( grep !exists $InterfaceParameters{$_}, $pars->@* );
}









sub check_valid_interface_parameters ( $pars ) {
    return ( grep exists $InterfaceParameters{$_}, $pars->@* );
}









sub check_invalid_signal_parameters ( $pars ) {
    return ( grep !exists $SignalParameters{$_}, $pars->@* );
}









sub check_valid_signal_parameters ( $pars ) {
    return ( grep exists $SignalParameters{$_}, $pars->@* );
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

version 0.19

=head1 SUBROUTINES

=head2 parse_pars

  ( $mpars, $ipars, $spars ) = parse_params( \%args  );

Returns the
L<model|Iterator::Flex::Manual::Overview/Model Parameters>
L<interface|Iterator::Flex::Manual::Overview/Interface Parameters>
L<signal|Iterator::Flex::Manual::Overview/Signal Parameters>
parameters from C<%args>.

=head2 check_invalid_interface_parameters

   @bad = check_invalid_interface_parameters( \@pars );

Returns invalid interface parameters;

=head2 check_valid_interface_parameters

   @bad = check_valid_interface_parameters( \@pars );

Returns valid interface parameters;

=head2 check_invalid_signal_parameters

   @bad = check_invalid_signal_parameters( \@pars );

Returns invalid signal parameters;

=head2 check_valid_signal_parameters

   @bad = check_valid_signal_parameters( \@pars );

Returns valid signal parameters;

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
