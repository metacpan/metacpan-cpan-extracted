package Koha::QA::PodChecker;

use Modern::Perl;
use base 'Koha::QA::Base';

use Pod::Checker;

=head1 NAME

Koha::QA::PodChecker - Centralized POD checking

=head1 SYNOPSIS

  use Koha::QA::PodChecker;

  # With a file
  my $checker = Koha::QA::PodChecker->new({file => $file});

  # Or with content directly
  my $checker = Koha::QA::PodChecker->new({content => $content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module provides centralized POD checking using Pod::Checker.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::PodChecker->new({file => $file});

Creates a new PodChecker instance.

=head2 check

  my $is_valid = $checker->check;

Checks a Perl file for POD errors and warnings using Pod::Checker.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (pod_checker_error, pod_checker_warning)

=cut

sub check {
    my ($self) = @_;
    my $file = $self->file;

    my $checker = Pod::Checker->new();

    my $report = '';
    open my $out, '>', \$report or die $!;

    $checker->parse_from_file( $file, $out );

    my @errors;
    while ( $report =~ /^\*\*\*\s+(ERROR|WARNING):\s+(.*?)\s+at\s+line\s+(\d+)\b/gm ) {
        my ( $severity, $message, $line_number ) = ( $1, $2, $3 );

        my $guilty_line = $line_number ? `sed -n '${line_number}p' $file` : undef;
        chomp $guilty_line if defined $guilty_line;
        push @errors,
            {
            error => ( $severity eq 'ERROR' ? 'pod_checker_error' : 'pod_checker_warning' ), message => $message,
            ( $line_number ? ( line => $guilty_line, line_number => $line_number ) : () )
            };
    }

    $self->{_errors} = \@errors;
    return @errors ? 0 : 1;
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
