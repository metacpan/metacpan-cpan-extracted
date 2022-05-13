package Perl::Critic::Policy::Mardem::ProhibitLargeSub;

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
        {   'name'            => 'statement_count_limit',
            'description'     => 'The maximum statement count allowed.',
            'default_string'  => '20',
            'behavior'        => 'integer',
            'integer_minimum' => 1,
        },
    );
}

sub violates
{
    my ( $self, $elem, undef ) = @_;

    my $s = $elem->find( 'PPI::Statement' );

    if ( !$s ) {
        return;
    }

    my $statement_count = @{ $s };
    if ( $statement_count <= $self->{ '_statement_count_limit' } ) {
        return;
    }

    my $desc;
    if ( my $name = $elem->name() ) {
        $desc = qq<Subroutine "$name" with high statement count ($statement_count)>;
    }
    else {
        # never the case becaus no PPI::Statement::Sub
        $desc = qq<Anonymous subroutine with high statement count ($statement_count)>;
    }

    return $self->violation( $desc, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Mardem::ProhibitLargeSub

=head1 DESCRIPTION

This Policy counts the statements within a sub
(more precise the PPI::Statement's)

=head1 CONFIGURATION

The maximum acceptable Statement-Count can be set with the C<statement_count_limit>
configuration item. Any sub with a count higher than this number will generate a
policy violation. The default is 20.

An example section for a F<.perlcriticrc>:

  [Mardem::ProhibitLargeSub]
  statement_count_limit = 1

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
