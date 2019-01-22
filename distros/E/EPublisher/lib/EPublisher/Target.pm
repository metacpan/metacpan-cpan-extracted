package EPublisher::Target;

# ABSTRACT: Container for Target plugins

use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

sub new{
    my ($class,$args) = @_;
    my $self;
    
    my $plugin = 'EPublisher::Target::Plugin::' . $args->{type};
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

EPublisher::Target - Container for Target plugins

=head1 VERSION

version 1.23

=head1 SYNOPSIS

  my $target_options = { type => 'CPAN', 'pause_id' => 'reneeb', pause_pass => 'secret' };
  my $cpan_target    = EPublisher::Target->new( $target_options );
  $cpan_target->any_plugin_subroutine;

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
