package Koha::QA::PerlSyntax;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::PerlSyntax - Centralized Perl syntax checking

=head1 SYNOPSIS

  use Koha::QA::PerlSyntax;

  # With a file
  my $checker = Koha::QA::PerlSyntax->new({file => $file_path});

  # Or with content directly
  my $checker = Koha::QA::PerlSyntax->new({content => $file_content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module provides centralized Perl syntax checking using C<perl -cw>.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::PerlSyntax->new({file => $file_path});

Creates a new Perl syntax checker instance.

=head2 check

  my $is_valid = $checker->check;

Checks a Perl file for syntax errors and warnings using C<perl -cw>.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: Type of error ('perl_syntax_compil_error', 'perl_syntax_compil_aborted' or 'perl_syntax_warning')
  - message: Human-friendly error message

=cut

use IPC::Run3;

sub check {
    my ($self) = @_;

    my $file = $self->file;

    my @exceptions = @{ $self->{exceptions} || [] };

    # Run perl -cw to check syntax
    my ( $stdout, $stderr );
    run3( [ 'perl', '-cw', $file ], undef, \$stdout, \$stderr );

    my $output = ( $stdout || '' ) . ( $stderr || '' );

    my @errors;

    if ( $output =~ m{^\Q$file\E syntax OK$} ) {
        $self->{_errors} = ();
        return 1;
    }

    if ( $output =~ m{had compilation errors} ) {
        my @messages      = grep { !/had compilation errors\.$/ } split /\n/, $output;
        my $message       = $messages[-1];
        my ($line_number) = $message =~ /\bline (\d+)\b/;
        my $guilty_line   = `sed -n '${line_number}p' $file`;
        chomp $guilty_line;
        push @errors, {
            error       => 'perl_syntax_compil_error',
            message     => $message,
            line_number => $line_number,
            line        => $guilty_line,
        };
    } elsif ( $output =~ m{had compilation errors} || $output =~ m{BEGIN failed--compilation aborted} ) {
        my @messages = grep { !/BEGIN failed--compilation aborted/ } split /\n/, $output;
        my $message  = $messages[-1];
        push @errors, {
            error   => 'perl_syntax_compil_aborted',
            message => $message,
        };
    } else {

        # If we got here, syntax is OK, but check for warnings
        # The output should end with "syntax OK" but may have warnings before it
        my @lines = split "\n", $output;
        chomp @lines;
    LINE: for my $line (@lines) {
            next if $line =~ /^\Q$file\E syntax OK$/;
            for my $re (@exceptions) {
                next LINE if $line =~ $re;
            }

            #next if $line =~ /^Subroutine .* redefined/;
            #next if $line =~ /^Constant subroutine .* redefined/;
            #next if $line =~ /^Name .* used only once/;
            if ( $line =~ /^(.*) at (\S+) line (\d+)\.?$/ ) {
                my $message     = $1;
                my $file_error  = $2;
                my $line_number = $3;
                my $line_error;
                if ( $file_error eq $file ) {

                    # If it's not the same file in the output, it's not relevant
                    my $guilty_line = `sed -n '${line_number}p' $file`;
                    chomp $guilty_line;
                    $line_error = $guilty_line;
                } else {
                    $message = $line;
                    undef $line_number;
                }
                push @errors, {
                    error       => 'perl_syntax_warning',
                    message     => $message,
                    line_number => $line_number,
                    line        => $line_error,
                };
            }
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
