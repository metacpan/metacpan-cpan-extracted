package EPublisher::Utils::PPI;

# ABSTRACT: PPI utility for EPublisher

use strict;
use warnings;

use Exporter;
use PPI;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    extract_package
    extract_pod
    extract_pod_from_code
);

our $VERSION = 0.5;

sub extract_package {
    my ($file, $config) = @_;
    
    return if !$file || ! -f $file;
    
    my $content;
 
    if ( open my $fh, '<', $file ) {
 
        if ( $config->{encoding} ) {
            binmode $fh, ':encoding(' . $config->{encoding} . ')';
        }
 
        local $/;
        $content = <$fh>;
    } 
    
    return if !$content;
    
    my $parser    = PPI::Document->new( \$content );
    
    return if !$parser;
    
    my $stmt = $parser->find_first('PPI::Statement::Package');
    
    return if !$stmt;
    
    my $package = $stmt->namespace;
    
    return $package;
}

sub extract_pod {
    my ($file, $config) = @_;
    
    return if !$file || ! -f $file;
    
    my $content;
 
    if ( open my $fh, '<', $file ) {
 
        if ( $config->{encoding} ) {
            binmode $fh, ':encoding(' . $config->{encoding} . ')';
        }
 
        local $/;
        $content = <$fh>;
    } 

    return extract_pod_from_code( $content );
}

sub extract_pod_from_code {
    my ($code) = @_;
    
    return if !$code;
    
    my $parser    = PPI::Document->new( \$code );
    
    return if !$parser;
    
    my $pod_nodes = $parser->find(
        sub {
             $_[1]->isa( 'PPI::Token::Pod' );
        },
    );
    
    my $merged = PPI::Token::Pod->merge( @{$pod_nodes || []} );
    
    return '' if !$merged;
    return $merged->content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Utils::PPI - PPI utility for EPublisher

=head1 VERSION

version 1.22

=head1 SYNOPSIS

  use EPublisher::Utils::PPI qw(extract_pod extract_pod_from_code);
  
  my $file = '/usr/local/share/perl/5.12.1/CGI.pm';
  my $pod  = extract_pod( $file );
  
  my $code = <<PERL;
  sub test {
  }

  =head1 METHODS

  =head2 test

  Docs for subroutine "test"
  PERL
  
  my $pod_from_code = extract_pod_from_code( $code );

=head1 DESCRIPTION

This module provides some functions to retrieve information about
modules and/or perl files. It uses L<PPI> to analyze those
files.

=head1 METHODS

=head2 extract_pod

Get Pod documentation from file.

=head2 extract_pod_from_code

Get the documentation of a piece of code...

=head2 extract_package

Get the namespace name of a package

=head1 COPYRIGHT & LICENSE

Copyright 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
