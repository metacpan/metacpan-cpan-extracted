package EPublisher::Source::Plugin::File;

# ABSTRACT: File source plugin

use strict;
use warnings;

use File::Basename;

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.04;

sub load_source{
    my ($self) = @_;
    
    my $options = $self->_config;
    
    my $file = $options->{path};
    
    unless( $file && -f $file ) {
        $self->publisher->debug( "400: $file -> " . ( -f $file or 0 ) );
        return '';
    }
    
    my $pod      = extract_pod( $file, $self->_config );
    my $filename = basename $file;
    my $title    = $filename;

    if ( $options->{title} and $options->{title} eq 'pod' ) {
        ($title) = $pod =~ m{ =head1 \s+ (.*) }x;
        $title = '' if !defined $title;
    }
    elsif ( $options->{title} and $options->{title} ne 'pod' ) {
        $title = $options->{title};
    }

    return { pod => $pod, filename => $filename, title => $title };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Source::Plugin::File - File source plugin

=head1 VERSION

version 1.21

=head1 SYNOPSIS

  my $source_options = { type => 'File', path => '/var/lib/CGI.pm' };
  my $file_source    = EPublisher::Source->new( $source_options );
  my $info           = $File_source->load_source;

  my $options = { type => 'File', path => '/path.pod', title => 'pod' };
  my $file_source = EPublisher::Source->new( $options );
  my $info = $file_source->load_source;

=head1 METHODS

=head2 load_source

  my $pod = $file_source->load_source;

reads the File and returns a hashreference with several information
about the document.

  {
    pod      => $pod_document,
    filename => $file,
    title    => $title,
  }

C<$pod_document> is the complete pod documentation that was found in the file.
C<$file> is the name of the file (without path) and C<$title> is the title of
the pod documentation. By default it is the filename, but you can say "title => 'pod'"
in the configuration. The title is the first value for I<=head1> in the pod.

=head1 COPYRIGHT & LICENSE

Copyright 2010 - 2012 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
