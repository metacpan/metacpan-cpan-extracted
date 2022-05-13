package Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };

use base 'Perl::Critic::Policy';

Readonly::Scalar my $EXPL => q{Consider refactoring};

sub default_severity
{
    return $SEVERITY_MEDIUM;
}

sub default_themes
{
    return qw(complexity maintenance);
}

sub applies_to
{
    return 'PPI::Statement::Sub';
}

sub supported_parameters
{
    return (
        {   'name'            => 'condition_count_limit',
            'description'     => 'The maximum condition count allowed.',
            'default_string'  => '3',
            'behavior'        => 'integer',
            'integer_minimum' => 1,
        },
    );
}

sub violates
{
    my ( $self, $elem, undef ) = @_;

    my $s = $elem->find(
        sub
        {
            my ( undef, $element ) = @_;

            my $interesting =
                   $element->isa( 'PPI::Structure::Condition' )
                || $element->isa( 'PPI::Structure::For' )
                || $element->isa( 'PPI::Structure::Given' );

            return $interesting;
        }
    );

    if ( !$s ) {
        return;
    }

    my $condition_count = @{ $s };
    if ( $condition_count <= $self->{ '_condition_count_limit' } ) {
        return;
    }

    my $desc;
    if ( my $name = $elem->name() ) {
        $desc = qq<Subroutine "$name" with high condition count ($condition_count)>;
    }
    else {
        # never the case becaus no PPI::Statement::Sub
        $desc = qq<Anonymous subroutine with high condition count ($condition_count)>;
    }

    return $self->violation( $desc, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub

=head1 DESCRIPTION

This Policy counts the conditions within a sub.
(more precise the PPI::Structure::Condition's,
PPI::Structure::For's and PPI::Structure::Given's)

=head1 CONFIGURATION

The maximum acceptable Condition-Count can be set with the
C<condition_count_limit> configuration item. Any sub with a count higher than
this number will generate a policy violation. The default is 3.

An example section for a F<.perlcriticrc>:

  [Mardem::ProhibitManyConditionsInSub]
  condition_count_limit = 1

=head1 AFFILIATION

This policy is part of L<Mardem::RefactoringPerlCriticPolicies>.

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

=cut
