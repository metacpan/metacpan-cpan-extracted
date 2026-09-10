package Koha::QA::FilePermissions;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::FilePermissions - Centralized file permissions checking

=head1 SYNOPSIS

  use Koha::QA::FilePermissions;

  # With a file
  my $checker = Koha::QA::FilePermissions->new({file => $file});

  # Or with content directly
  my $checker = Koha::QA::FilePermissions->new({content => $content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module provides centralized file permissions checking.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::FilePermissions->new({file => $file_path});

Creates a new FilePermissions instance.

=head2 check

  my $is_valid = $checker->check;

Checks if a file has correct executable permissions.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (missing_x_flag, extra_x_flag)

Rules:
  - Files in svc/, xt/ and .t files: must have exec flag
  - .pl and .sh files: must have exec flag
  - .pm files: must NOT have exec flag

=cut

use File::Basename;

sub check {
    my ($self) = @_;
    my $file = $self->file;

    my @errors;

    # Ignore files in .git, blib and node_modules
    return 1 if $file =~ m[^\./(.git|blib|node_modules)];

    # Check for files that must have exec flag
    if ( ( $file =~ m[^(svc|xt)/] || $file =~ m[\.t$] ) && !-x $file ) {
        push @errors, { error => 'missing_x_flag', message => 'File must have the exec flag' };
    }

    # Check for .pl and .sh files
    if ( $file =~ m[\.(pl|sh)$] && !-x $file ) {
        push @errors, { error => 'missing_x_flag', message => 'File must have the exec flag' };
    }

    # Check for .pm files (must NOT have exec flag)
    if ( $file =~ m[\.pm$] && -x $file ) {
        push @errors, { error => 'extra_x_flag', message => 'File must not have the exec flag' };
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
