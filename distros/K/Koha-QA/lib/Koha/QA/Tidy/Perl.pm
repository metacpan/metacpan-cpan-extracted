package Koha::QA::Tidy::Perl;

use Modern::Perl;
use base 'Koha::QA::Base';
use File::ShareDir qw(dist_file);

=head1 NAME

Koha::QA::Tidy::Perl - Centralized Perl tidiness checking using perltidy

=head1 SYNOPSIS

  use Koha::QA::Tidy::Perl;

  # With a file
  my $checker = Koha::QA::Tidy::Perl->new({file => $file, perltidyrc => $perltidyrc});

  # Or with content directly
  my $checker = Koha::QA::Tidy::Perl->new({content => $file_content, perltidyrc => $perltidyrc});

  my $is_tidy = $checker->check;
  my @errors = $checker->errors;

  # Return the tidy version
  my $success = $checker->fix;

=head1 DESCRIPTION

This module provides centralized Perl tidiness checking using perltidy.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Tidy::Perl->new({file => $file, perltidyrc => $perltidyrc});

Creates a new Tidy::Perl instance.

Arguments:
  - perltidyrc: Optional path to .perltidyrc file (default: .perltidyrc)

=head2 check

  my $is_tidy = $checker->check;

Checks if a Perl file is tidy by comparing the original content with
the output from perltidy.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (tidy_perl, no_perltidyrc)

=head2 fix

  my $output = $checker->fix;

Runs perltidy on the file and returns the tidied content without modifying the file.

Returns:
  - String with tidied content on success
  - undef on failure

=cut

use IPC::Run3;

sub check {
    my ($self)     = @_;
    my $file       = $self->file;
    my $perltidyrc = $self->{perltidyrc} // dist_file( 'Koha-QA', 'perltidyrc' );

    unless ( -f $perltidyrc ) {
        $self->{_errors} = [
            {
                error   => 'no_perltidyrc',
                message => "perltidyrc file not found: $perltidyrc",
            }
        ];
        return 0;
    }

    my $cmd = [ 'perltidy', '--standard-output', "-pro=$perltidyrc", $file ];
    my ( $stdout, $stderr );
    run3( $cmd, undef, \$stdout, \$stderr );

    # FIXME raise exception if stderr is defined?
    warn $stderr if $stderr;

    my $original    = $self->content;
    my $tidy_output = $stdout || '';

    $self->{_fixed_content} = $tidy_output;

    if ( $original eq $tidy_output ) {
        $self->{_errors} = [];
        return 1;
    } else {
        $self->{_errors} = [ { error => 'tidy_perl', message => "Perl file is not tidy" } ];
        return 0;
    }
}

sub fix {
    my ($self) = @_;

    # If we haven't checked yet, check first
    $self->check unless exists $self->{_fixed_content};
    return $self->{_fixed_content};
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
