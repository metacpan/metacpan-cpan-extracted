package EPublisher::Source::Plugin::Dir;

# ABSTRACT: Dir source plugin

use strict;
use warnings;

use File::Find::Rule;
use File::Basename;
use List::Util qw(first);

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod extract_package);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 1.0;

sub load_source{
    my ($self) = @_;
    
    my $options = $self->_config;
    
    my $path = $options->{path};
    
    my @paths = ref $path eq 'ARRAY' ? @{$path} : ($path);
    my @paths_to_use;
    
    for my $path_to_check ( @paths ) {
        unless( $path_to_check && -d $path_to_check ) {
            $self->publisher->debug( "400: $path_to_check -> " . ( -d $path_to_check or 0 ) );
            next;
        }
        
        push @paths_to_use, $path_to_check;
    }
    
    return '' if !@paths_to_use;
    
    my @files = sort File::Find::Rule->file->name( qr/\.p(?:m|od|l)\z/ )->in( @paths_to_use );
    my @pods;
    
    FILE:
    for my $file ( @files ) {
        
        if ( $options->{exclude} ) {
            my @excludes = ref $options->{exclude} eq 'ARRAY' ? @{ $options->{exclude} } : ($options->{exclude});
            
            next FILE if first{ $file =~ m{\A \Q$_\E }xms }@excludes;
        }
        
        my $pod = extract_pod( $file, $self->_config );
        
        next FILE if !$pod;

        my $filename = basename $file;
        my $title    = $filename;

        if ( $options->{title} and $options->{title} eq 'pod' ) {
            ($title) = $pod =~ m{ =head1 \s+ (.*) }x;
            $title = '' if !defined $title;
        }
        elsif ( $options->{title} and $options->{title} eq 'package' ) {
            my $package = extract_package( $file, $self->_config );
            $title = $package if $package;
        }
        elsif ( $options->{title} and $options->{title} ne 'pod' ) {
            $title = $options->{title};
        }
        
        push @pods, { pod => $pod, title => $title, filename => $filename };
    }
    
    return @pods;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Source::Plugin::Dir - Dir source plugin

=head1 VERSION

version 1.23

=head1 SYNOPSIS

  my $source_options = { type => 'Dir', path => '/var/lib/' };
  my $file_source    = EPublisher::Source->new( $source_options );
  my $pod            = $File_source->load_source;

=head1 METHODS

=head2 load_source

  my $pod = $file_source->load_source;

checks all pod/pm/pl files in the given directory (and its subdirectories)
and returns information about those files:

  (
      {
          pod      => $pod_document,
          filename => $file,
          title    => $title,
      },
  )

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
