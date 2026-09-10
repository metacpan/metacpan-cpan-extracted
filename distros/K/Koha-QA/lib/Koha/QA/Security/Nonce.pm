package Koha::QA::Security::Nonce;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::Security::Nonce - Check for missing nonce attributes in script/link tags

=head1 SYNOPSIS

  use Koha::QA::Security::Nonce;

  # With a file
  my $checker = Koha::QA::Security::Nonce->new({file => $file_path});

  # Or with content directly
  my $checker = Koha::QA::Security::Nonce->new({content => $template_content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module checks Template Toolkit files for script and link tags that are missing
nonce attributes.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Security::Nonce->new({file => $file_path});

Creates a new Nonce checker instance.

=head2 check

  my $is_valid = $checker->check;

Checks the file for missing nonce attributes.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each containing:
  - file: the file path
  - line: the line number
  - script: the script/link tag content
  - error: the error type (missing_nonce_attribute)

=cut

sub check {
    my ($self) = @_;
    my $content = $self->content;

    my @errors;
    my @lines = split /\n/, $content;
    return 1 unless grep { $_ =~ m[<(script|style)] } @lines;
    my $line_number = 0;
    for my $line (@lines) {
        $line_number++;
        my $found = 0;
        if ( $line =~ m{<script} && $line !~ m{<script nonce=} && $line !~ m{src="} ) {
            $found = 1;
        }
        if ( $line =~ m{<style} && $line !~ m{<style nonce=} ) {
            $found = 1;
        }
        if ($found) {
            push @errors, {
                line        => $line,
                line_number => $line_number,
                error       => 'missing_nonce',
                message     => "<script> or <style> tag does not have 'nonce' attribute (see bug 38365)",
            };
        }
    }
    $self->{_errors} = \@errors;
    return @errors ? 0 : 1;
}

1;

=head1 AUTHORS

Koha Development Team

=head1 COPYRIGHT

Copyright 2024-2026 Koha Development Team

=head1 LICENSE

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

=cut
