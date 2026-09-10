package Koha::QA::Security::CSRF;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::Security::CSRF - Check for missing CSRF tokens and op parameters in forms

=head1 SYNOPSIS

  use Koha::QA::Security::CSRF;

  # With a file
  my $checker = Koha::QA::Security::CSRF->new({file => $file_path});

  # Or with content directly
  my $checker = Koha::QA::Security::CSRF->new({content => $template_content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module checks Template Toolkit files for forms that are missing CSRF tokens
or have missing/improper op parameters.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Security::CSRF->new({file => $file_path});

Creates a new CSRF checker instance.

=head2 check

  my $is_valid = $checker->check;

Checks the file for missing CSRF tokens and op parameters.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each containing:
  - line: the form tag content
  - line_number: the line number
  - error: the error type (missing_csrf_token, missing_op, invalid_op_value)

=cut

sub check {
    my ($self) = @_;
    my $content = $self->content;

    my @errors;
    my @lines = split /\n/, $content;
    return 1 unless grep { $_ =~ m|<form| } @lines;

    my ( $in_form, $form_start_line, $form_line_content, $found_csrf, $has_op, $op_value );
    my $line_number = 0;
    for my $line (@lines) {
        $line_number++;
        if ( $line =~ m{<form.*method=('|")post('|")}i ) {
            $in_form           = 1;
            $form_start_line   = $line_number;
            $form_line_content = $line;
            $found_csrf        = 0;
            $has_op            = 0;
            $op_value          = undef;
        }
        if ( $in_form && !$found_csrf ) {
            $found_csrf++
                if $line =~ m{csrf-token\.inc}
                || $line =~ m{<input type="hidden" name="csrf_token" value="\$\{csrf_token\}" />};
        }
        if ( $in_form && ( $line =~ m{name=('|")op('|")} || $line =~ m{name=('|")login_op('|")} ) ) {
            $has_op = 1;
            if ( $line =~ m{value=('|")([^'"]*)('|")} ) {
                $op_value = $2;
            }
        }
        if ( $in_form && $line =~ m{</form} ) {

            # Check for CSRF token
            unless ($found_csrf) {
                push @errors, {
                    line        => $form_line_content,
                    line_number => $form_start_line,
                    error       => 'missing_csrf_token',
                    message     => 'Some forms with POST method are missing CSRF token (bug 22990)',
                };
            }

            # Check for op parameter
            unless ($has_op) {
                push @errors, {
                    line        => $form_line_content,
                    line_number => $form_start_line,
                    error       => 'missing_op',
                    message     => 'Form with POST method is missing op parameter (see bug 34478)',
                };
            } elsif ( $op_value && $op_value !~ m{^cud-} && $op_value !~ m{^\[%} ) {
                push @errors, {
                    line        => $form_line_content,
                    line_number => $form_start_line,
                    error       => 'invalid_op_value',
                    message     => 'op parameter value should start with "cud-" or be a TT variable (see bug 34478)',
                    op_value    => $op_value,
                };
            }
            $in_form = 0;
        }
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
