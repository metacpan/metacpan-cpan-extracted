package Perl::Critic::Policy::Mardem::ProhibitLargeBlock;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };

use Mardem::RefactoringPerlCriticPolicies::Util qw( search_for_block_keyword );

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
    return 'PPI::Structure::Block';
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

    my $block_keyword = search_for_block_keyword( $elem );
    if ( !$block_keyword ) {
        $block_keyword = 'no-keyword-found';
    }

    if ( 'SUB' eq $block_keyword ) {
        return;    # no sub -> see SUB Perl::Critic::Policy::Mardem::ProhibitLargeSub !
    }

    my $desc = qq<"$block_keyword" code-block with high statement count ($statement_count)>;
    return $self->violation( $desc, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Mardem::ProhibitLargeBlock

=head1 DESCRIPTION

This Policy counts the statements within a code block { ... }
(more precise the PPI::Statement's)

=head1 CONFIGURATION

The maximum acceptable Statement-Count can be set with the
C<statement_count_limit> configuration item. Any block with a count higher
than this number will generate a policy violation. The default is 20.

An example section for a F<.perlcriticrc>:

  [Mardem::ProhibitLargeBlock]
  statement_count_limit = 10

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
