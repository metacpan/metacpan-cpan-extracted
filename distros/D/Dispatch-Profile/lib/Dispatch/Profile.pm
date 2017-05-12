package Dispatch::Profile;
#-------------------------------------------------------------------------------
#   Module  : Dispatch::Profile
#
#   Purpose : Code dispatch framework
#-------------------------------------------------------------------------------
use Moose;
our $VERSION = '0.001';
extends 'Dispatch::Profile::CodeStore', 'Dispatch::Profile::Dispatcher', 'Dispatch::Profile::Forwarder';

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Dispatch::Profile code dispatch framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Dispatch::Profile - Dispatch::Profile code dispatch framework

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Dispatch::Profile;
  
  sub print_received {
     print "print_received: @_\n";
  }
  
  my $target = Dispatch::Profile->new(
     profile => {
        target => 'print_received',
     },
  );

  $target->dispatch('hello', 'world');

=head1 DESCRIPTION

Dispatch::Profile provides a means of simplyifying message flow between
entities within an application.  The Dispatch::Profile object utilises a simple
profile format that allows dispatch to a variety of targets including
methods within the main namespace, class methods both exported and non
exported and object instantiated methods.

The class can also be used to extend an existing class through the
inheritance of the dispatch and the Moose BUILD methods, allowing where 
required the message flow to be chained across multiple targets.

=head1 RATIONALE

I created this package to provide a simple means of dispatching data
to different targets within an application with a minimum of changes
to the underline code.  When used with a standardised payload, 
it makes it very easy to switch or dispatch to multiple targets.

=head1 EXAMPLES

=head2 Example 1

=head3 Overview

The following depicts the creation of a caretaker object with a target method
of print_received.  All data sent through the object via the dispatch
mechanism will be processed accordingly by the target method handler.

=head3 Code

  use Dispatch::Profile;
  
  sub print_received {
     print "print_received: @_\n";
  }
  
  my $target = Dispatch::Profile->new(
     profile => {
        target => 'print_received',
     },
  );

  $target->dispatch('hello', 'world');

=head3 Output

  print_received: hello world

=head2 Example 2

=head3 Overview

The Dispatch::Profile object can facilitate multiple targets by specifying the profile configuration
as an array of hashes.  When the dispatch method is called, all targets
are processed sequentially with the same payload.

=head3 Code

  use Dispatch::Profile;

  sub print_received {
     print "print_received: @_\n";
  }
  
  sub print_received_uc {
     my @uc = map( uc, @_ );
     print "print_received_uc: @uc\n";
  }
  
  my $target = Dispatch::Profile->new(
     profile => [
        {
           target => 'print_received',
        },
        {
           target => 'print_received_uc',
        },
     ]
  );

  $target->dispatch('hello', 'world');

=head3 Output

  print_received: hello world
  print_received_uc: HELLO WORLD

=head2 Example 3

=head3 Overview

Targets that are provided through a specific class can be specified with the class keyword.

=head3 Code

  use Dispatch::Profile;
  
  package class1;
  sub print_received {
     print "print_received: @_\n";
  }
  
  package class2;
  sub print_received_uc {
     my @uc = map( uc, @_ );
     print "print_received_uc: @uc\n";
  }
  
  package main;
  my $target = Dispatch::Profile->new(
     profile => [
        {
           class  => 'class1',
           target => 'print_received',
        },
        {
           class  => 'class2',
           target => 'print_received_uc',
        },
     ]
  );
  
  $target->dispatch( 'hello', 'world' );

=head3 Output

  print_received: hello world
  print_received_uc: HELLO WORLD

=head2 Example 4

=head3 Overview

Targets can be initialised as objects through the object hashref option.
The initialisation process expects the class to provide a 'new' method
for object creation.  Key/Values within the hashref are
passed through to the object during initialisation.

=head3 Code

  use Dispatch::Profile;

  package class1;
  use Data::Dumper;
  sub new {
     my $package = shift;
     my %options = @_;
     print "Object of $package initialising with the following parameters:\n",Dumper(\%options),"\n";
     bless {@_};
  }

  sub print_received {
     my $self = shift;
     print "print_received: @_\n";
  }

  package class2;
  use Data::Dumper;
  sub new {
     my $package = shift;
     my %options = @_;
     print "Object of $package initialising with the following parameters:\n",Dumper(\%options),"\n";
     bless {@_};
  }

  sub print_received_uc {
     my $self = shift;
     my @uc = map( uc, @_ );
     print "print_received_uc: @uc\n";
  }

  package main;
  my $target = Dispatch::Profile->new(
     profile => [
        {
           class  => 'class1',
           target => 'print_received',
           object => { param1 => 'value1' },
        },
        {
           class  => 'class2',
           target => 'print_received_uc',
           object => { param2 => 'value2' },
        },
     ]
  );

  $target->dispatch( 'hello', 'world' );

=head3 Output

  Object of class1 initialising with the following parameters:
  $VAR1 = {
            'param1' => 'value1'
          };
  
  Object of class2 initialising with the following parameters:
  $VAR1 = {
            'param2' => 'value2'
          };
  
  print_received: hello world
  print_received_uc: HELLO WORLD

=head2 Example 5

=head3 Overview

The target object can continue the dispatch chain as an invoker of the 
Dispatch::Profile class.  This functionality is enabled through the keyword 
forwarder.  The package utilises the Moose Object Constructor method BUILD
for initialisation allowing the calling object to facilitate it's own
constructor.

=head3 Code

  use Dispatch::Profile;
  
  package class1;
  use Moose;
  extends 'Dispatch::Profile';
  
  sub print_received {
     my $self = shift;
     print "print_received: @_\n";
  }

  package class2;
  use Moose;
  extends 'Dispatch::Profile';

  sub print_received_uc {
     my $self = shift;
     my @uc = map( uc, @_ );
     print "print_received_uc: @uc\n";
  
     # Dispatch data to the next target
     $self->dispatch(@uc);
  }
  
  package class3;
  use Moose;
  extends 'Dispatch::Profile';
  
  sub print_received_reverse {
     my $self = shift;
     my @reverse = reverse @_;
     print "print_received_reverse: @reverse\n";
  }
  
  package main;
  my $forwarder_target = Dispatch::Profile->new(
     profile => {
        class  => 'class3',
        target => 'print_received_reverse',
        object => { param3 => 'value3' },
     },
  );
  
  my $target = Dispatch::Profile->new(
     profile => [
        {
           class  => 'class1',
           target => 'print_received',
           object => {},
        },
        {
           class  => 'class2',
           target => 'print_received_uc',
           object => { forwarder => $forwarder_target },
        },
     ]
  );

  $target->dispatch( 'hello', 'world' );

=head3 Output

  print_received: hello world
  print_received_uc: HELLO WORLD
  print_received_reverse: WORLD HELLO

=head1 AUTHOR

James Spurin <james@spurin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by James Spurin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
