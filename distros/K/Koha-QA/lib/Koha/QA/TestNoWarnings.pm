package Koha::QA::TestNoWarnings;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::TestNoWarnings - Centralized Test::NoWarnings checking

=head1 SYNOPSIS

  use Koha::QA::TestNoWarnings;

  # With a file
  my $checker = Koha::QA::TestNoWarnings->new({file => $file});

  # Or with content directly
  my $checker = Koha::QA::TestNoWarnings->new({content => $file_content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module provides centralized Test::NoWarnings checking.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::TestNoWarnings->new({file => $file});

Creates a new TestNoWarnings instance.

=head2 check

  my $is_valid = $checker->check;

Checks if a single Perl test file contains 'use Test::NoWarnings'.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (test_no_warnings)

=cut

sub check {
    my ($self) = @_;
    my $content = $self->content;

    # Check if content contains '^use Test::NoWarnings'
    my $has_no_warnings = $content =~ m{^use Test::NoWarnings}m;

    my @errors;
    unless ($has_no_warnings) {
        push @errors, {
            error   => 'test_no_warnings',
            message => q{Test file does not use Test::NoWarning},
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
