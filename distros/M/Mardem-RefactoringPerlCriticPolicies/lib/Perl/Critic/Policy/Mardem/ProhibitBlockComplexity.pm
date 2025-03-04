package Perl::Critic::Policy::Mardem::ProhibitBlockComplexity;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion :classification };
use Perl::Critic::Utils::McCabe qw{ calculate_mccabe_of_main };

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
        {   'name'            => 'max_mccabe',
            'description'     => 'The maximum complexity score allowed.',
            'default_string'  => '10',
            'behavior'        => 'integer',
            'integer_minimum' => 1,
        },
    );
}

sub violates
{
    my ( $self, $elem, undef ) = @_;

    my $score = calculate_mccabe_of_main( $elem );
    if ( $score <= $self->{ '_max_mccabe' } ) {
        return;
    }

    my $block_keyword = search_for_block_keyword( $elem );
    if ( !$block_keyword ) {
        $block_keyword = 'no-keyword-found';
    }

    if ( 'SUB' eq $block_keyword ) {
        return;    # no sub -> see SUB Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity !
    }

    my $desc = qq<"$block_keyword" code-block has a high complexity score ($score)>;
    return $self->violation( $desc, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Mardem::ProhibitBlockComplexity

=head1 DESCRIPTION

This Policy approximates the McCabe score within a code block "eg if() {...}".

See L<http://en.wikipedia.org/wiki/Cyclomatic_complexity>

It should help to find complex code block, which should be extracted
into subs, to be more testable.

eg. from

  if( $a ) {
    ...
    ...
    ...
  }

to

  if( $a ) {
    do_something();
  }

=head1 CONFIGURATION

The maximum acceptable McCabe can be set with the C<max_mccabe>
configuration item. Any block with a McCabe score higher than
this number will generate a policy violation. The default is 10.

An example section for a F<.perlcriticrc>:

  [Mardem::ProhibitBlockComplexity]
  max_mccabe = 1

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
