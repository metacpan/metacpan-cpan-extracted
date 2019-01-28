package EPublisher::Target::Base;

# ABSTRACT: Base class for Target plugins

use strict;
use warnings;
use Carp;

our $VERSION = 0.0101;

sub new{
    my ($class,$args,%params) = @_;
    
    my $self = bless {}, $class;
    $self->publisher( delete $params{publisher} );
    $self->_config( $args );
    
    return $self;
}

sub publisher {
    my ($self,$object) = @_;
    
    return $self->{__publisher} if @_ != 2;
    
    $self->{__publisher} = $object;
}

sub _config{
    my ($self,$args) = @_;
    
    $self->{__config} = $args if defined $args;
    return $self->{__config};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Target::Base - Base class for Target plugins

=head1 VERSION

version 1.27

=head1 SYNOPSIS

  package EPublisher::Target::Plugin::AnyTarget;
  use  EPublisher::Target::Base;
  
  our @ISA = qw(EPublisher::Target::Base);
  
  # ... more code ...

=head1 METHODS

=head2 new

=head2 publisher

=head2 _config

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
