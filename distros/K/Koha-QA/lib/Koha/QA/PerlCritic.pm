package Koha::QA::PerlCritic;

use Modern::Perl;
use base 'Koha::QA::Base';
use File::ShareDir qw(dist_file);

=head1 NAME

Koha::QA::PerlCritic - Centralized Perl criticism checking using Perl::Critic

=head1 SYNOPSIS

  use Koha::QA::Critic::Perl;

  # With a file
  my $checker = Koha::QA::PerlCritic->new({file => $file, perlcriticrc => $perlcriticrc});

  # Or with content directly
  my $checker = Koha::QA::PerlCritic->new({content => $file_content, perlcriticrc => $perlcriticrc});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module provides centralized Perl criticism checking using Perl::Critic.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Critic::Perl->new({file => $file, perlcriticrc => $perlcriticrc});

Creates a new PerlCritic instance.

Arguments:
  - perlcriticrc: Optional path to .perlcriticrc file

=head2 check

  my $is_valid = $checker->check;

Checks a Perl file for Perl::Critic violations.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (perlcritic, no_perlcriticrc)

=cut

use Perl::Critic;

sub check {
    my ($self)       = @_;
    my $file         = $self->file;
    my $perlcriticrc = $self->{perlcriticrc} // dist_file( 'Koha-QA', 'perlcriticrc' );

    unless ( -f $perlcriticrc ) {
        $self->{_errors} = [
            {
                error   => 'no_perlcriticrc',
                message => "perlcriticrc file not found: $perlcriticrc",
            }
        ];
        return 0;
    }

    my @issues;
    my $critique;

    my $critic     = Perl::Critic->new( -profile => $perlcriticrc );
    my @violations = $critic->critique($file);
    for my $violation (@violations) {
        my $message = $violation->to_string;
        chomp $message;
        push @issues, {
            line        => $violation->source,
            line_number => $violation->line_number,
            error       => 'perlcritic',
            message     => $message,
        };
    }

    $self->{_errors} = \@issues;
    return @issues ? 0 : 1;
}

1;

=head1 AUTHORS

Jonathan Druart <jonathan.druart@bugs.koha-community.org>

=head1 COPYRIGHT

Copyright 2026 Koha Development Team

=head1 LICENSE

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

=cut
