package Koha::QA::Tidy::JS;

use Modern::Perl;
use base 'Koha::QA::Base';
use File::ShareDir qw(dist_file dist_dir);
use File::Spec;
use IPC::Run3;

=head1 NAME

Koha::QA::Tidy::JS - Centralized JavaScript/TypeScript tidiness checking using prettier

=head1 SYNOPSIS

  use Koha::QA::Tidy::JS;

  # With a file
  my $checker = Koha::QA::Tidy::JS->new({file => $file, prettierrc => $prettierrc});

  # Or with content directly
  my $checker = Koha::QA::Tidy::JS->new({content => $file_content, prettierrc => $prettierrc});

  my $is_tidy = $checker->check;
  my @errors = $checker->errors;

  # Return the tidy version
  my $success = $checker->fix;

=head1 DESCRIPTION

This module provides centralized JavaScript/TypeScript/Vue tidiness checking
and formatting using prettier.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Tidy::JS->new({file => $file, prettierrc => $prettierrc});

Creates a new Tidy::JS instance.

Arguments:
  - prettierrc: Optional path to .prettierrc.js file (default: .prettierrc.js)

=head2 check

  my $is_tidy = $checker->check;

Checks if a JavaScript file is tidy by comparing the original content with
the output from prettier.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (tidy_js, no_prettierrc, tidy_js_empty_output, tidy_js_prettier_failed)

=head2 fix

  my $output = $checker->fix;

Runs prettier on the file and returns the tidied content without modifying the file.

Returns:
  - String with tidied content on success
  - undef on failure

=cut

sub _prettier_cmd {
    my ( $self, $extra_args ) = @_;
    my $koha_qa_root = dist_dir('Koha-QA');
    my $prettier     = File::Spec->catfile( $koha_qa_root, 'node_modules', 'prettier', 'bin', 'prettier.cjs' );
    return [ 'node', $prettier, @$extra_args ];
}

sub check {
    my ($self)     = @_;
    my $file       = $self->file;
    my $prettierrc = $self->{prettierrc} // dist_file( 'Koha-QA', 'prettierrc.js' );

    # Check if prettier is available
    # FIXME Do we really need this additional prettier call per file?
    unless ( $self->_has_prettier() ) {
        $self->{_errors} = [ { error => 'prettier_not_installed', message => "prettier is not available" } ];
        return 0;
    }

    unless ( -f $prettierrc ) {
        $self->{_errors} = [
            {
                error   => 'no_prettierrc',
                message => "prettierrc file not found: $prettierrc",
            }
        ];
        return 0;
    }

    my $cmd = $self->_prettier_cmd( [ "--config=$prettierrc", $file ] );
    my ( $stdout, $stderr );
    run3( $cmd, undef, \$stdout, \$stderr );

    my $success = $? == 0;

    # FIXME raise exception if stderr is defined?
    warn $stderr if $stderr;

    unless ($success) {

        # prettier failed to process the file
        $self->{_errors} = [
            {
                error   => 'tidy_js_prettier_failed',
                message => 'prettier failed to process the file, the original content was kept',
            }
        ];
        return 0;
    }

    my $original    = $self->content;
    my $tidy_output = $stdout || '';

    if ( length($original) && !length($tidy_output) ) {

        # prettier produced nothing (e.g. invalid input or broken prettierrc), don't overwrite the file with that
        $self->{_errors} = [
            {
                error   => 'tidy_js_empty_output',
                message => 'prettier produced no output, the original content was kept'
            }
        ];
        return 0;
    }

    $self->{_fixed_content} = $tidy_output;

    if ( $original eq $tidy_output ) {
        $self->{_errors} = [];
        return 1;
    } else {
        $self->{_errors} = [ { error => 'tidy_js', message => "JavaScript file is not tidy" } ];
        return 0;
    }
}

sub fix {
    my ($self) = @_;

    # If we haven't checked yet, check first
    $self->check unless exists $self->{_fixed_content};
    return $self->{_fixed_content};
}

sub _has_prettier {
    my ($self) = @_;
    my $cmd = $self->_prettier_cmd( ['--version'] );
    my ( $stdout, $stderr );
    eval { run3( $cmd, undef, \$stdout, \$stderr ) };
    return 0 if $@;
    return $? == 0;
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
