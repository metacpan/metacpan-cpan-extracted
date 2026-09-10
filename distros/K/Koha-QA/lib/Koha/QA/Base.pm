package Koha::QA::Base;

use Modern::Perl;
use File::Slurp qw(read_file);
use File::Temp  qw(tempfile);

=head1 NAME

Koha::QA::Base - Base class for Koha QA modules

=head1 SYNOPSIS

  use base 'Koha::QA::Base';

  sub new {
      my ($class, $params) = @_;
      my $self = $class->SUPER::new($params);
      # ... child class initialization
      return $self;
  }

=head1 DESCRIPTION

This is the base class for Koha QA modules. It provides common functionality
for file/content handling and error management.

=head1 METHODS

=head2 new

  my $checker = $class->SUPER::new({file => $file_path});
  my $checker = $class->SUPER::new({content => $template_content});

Creates a new QA checker instance.
Accepts either a 'file' parameter (path to a file to read) or a 'content' parameter (string content).

=head2 content

  my $content = $checker->content;

Returns the content being checked.

=head2 file

  my $file_path = $checker->file;

Returns the file path being checked. If the object was created with content
instead of a file, this method will generate a temporary file with the content.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs.

=cut

sub new {
    my ( $class, $params ) = @_;

    my $content =
          exists $params->{content} ? $params->{content}
        : exists $params->{file}    ? read_file( $params->{file} )
        :                             die "Must provide either 'file' or 'content' parameter";

    my $self = bless { %$params, content => $content }, $class;

    # Track if we were given a file or content
    $self->{_has_original_file} = exists $params->{file};

    return $self;
}

sub content {
    my ($self) = @_;
    return $self->{content};
}

sub file {
    my ($self) = @_;

    # If we have an original file, return it
    return $self->{file} if $self->{_has_original_file};

    # Otherwise, create a temporary file with the content
    unless ( $self->{_temp_file} ) {
        my $suffix;
        if ( ref($self) =~ m{Tidy::JS$} ) {
            $suffix = '.js';
        } elsif ( ref($self) =~ m{Tidy::TT$} ) {
            $suffix = '.tt';
        }
        my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, ( $suffix ? ( SUFFIX => $suffix ) : () ) );
        print $fh $self->content;
        close $fh;
        $self->{_temp_file} = $filename;
    }

    return $self->{_temp_file};
}

sub errors {
    my ($self) = @_;
    return @{ $self->{_errors} || [] };
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
