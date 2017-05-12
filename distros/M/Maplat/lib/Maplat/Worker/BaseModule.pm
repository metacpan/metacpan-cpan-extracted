# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::BaseModule;
use strict;
use warnings;

our $VERSION = 0.995;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = bless \%config, $class;
    
    return $self;
}

sub register {
    confess("Required method 'register' not implemented!");
}

sub reload {
    confess("Required method 'reload' not implemented!");
}

sub register_worker {
    my ($self, $funcname) = @_;
    
    $self->{server}->add_worker($self, $funcname);
    return;
}

sub register_cleanup {
    my ($self, $funcname) = @_;
    
    $self->{server}->add_cleanup($self, $funcname);
    return;
}

1;
__END__

=head1 NAME

Maplat::Worker::BaseModule - base module for worker modules

=head1 SYNOPSIS

This module is the base module any worker module should use.

=head1 DESCRIPTION

When writing a new worker module, use this module as a base:

  use Maplat::Worker::BaseModule;
  @ISA = ('Maplat::Worker::BaseModule');

=head2 new

This creates a new instance of this module. Do not call this function directly, use the "configure" call in
Maplat::Worker.

=head2 register

This function needs to be overloaded in every worker module. This function is run during startup
once some time after new(). Within this function (and ONLY within this function) you can call
register_worker() to register cyclic functions.

=head2 reload

This function is called some time after register() and may be called again while the worker is running. Everytime
reload() is called, you should empty all cached data in this worker and reload it from the sources (if applicable).

=head2 register_worker

This function registers a function of its own module as a cyclic worker function. It takes
one argument, the name of the cyclic function, for example:

  ...
  sub register {
    $self->register_worker("doWork");
  }
  ...
  sub doWork {
    # update file $bar with @foo
    ...
  }

It is possible to register multiple cyclic functions within the same worker module.

=head2 register_cleanup

Register a callback for "cleanup" operations after a workcycle has been completed. This might for example be a function in a
database module that makes sure there are no open transactions.

=head1 Configuration

This module is not used directly and doesn't need configuration.

=head1 Dependencies

This module does not depend on other worker modules

=head1 SEE ALSO

Maplat::Worker

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
