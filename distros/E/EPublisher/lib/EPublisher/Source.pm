package EPublisher::Source;

# ABSTRACT:  Container for Source plugins

use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

sub new{
    my ($class,$args) = @_;
    my $self;
    
    my $plugin = 'EPublisher::Source::Plugin::' . $args->{type};
    eval{
        (my $file = $plugin) =~ s!::!/!g;
        $file .= '.pm';
        
        require $file;
        $self = $plugin->new( $args );
    };
    
    croak "Problems with $plugin: $@" if $@;
    
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Source - Container for Source plugins

=head1 VERSION

version 1.22

=head1 SYNOPSIS

  my $source_options = { type => 'File', 'path' => '/repo' };
  my $svn_source     = EPublisher::Source->new( $source_options );
  $svn_source->load_source;

=head1 METHODS

=head2 new

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
