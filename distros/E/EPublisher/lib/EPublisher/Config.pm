package EPublisher::Config;

# ABSTRACT: Config module for EPublisher
use strict;
use warnings;
use Carp;
use YAML::Tiny;

our $VERSION = 0.01;

sub get_config{
    my ($class,$file) = @_;
    
    croak "No (existant) config file given!" unless defined $file and -e $file;
    my $config = YAML::Tiny->read( $file )->[0];
    
    return $config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Config - Config module for EPublisher

=head1 VERSION

version 1.22

=head1 SYNOPSIS

  my $file   = 'test.yml';
  my $config = EPublisher::Config->get_config( $file );

=head1 METHODS

All methods available for EPublisher are described in the subsequent sections

=head2 get_config

  my $config = EPublisher::Config->get_config( $file );

Returns the hashref build by YAML::Tiny.

=head1 SEE ALSO

L<EPublisher>

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
