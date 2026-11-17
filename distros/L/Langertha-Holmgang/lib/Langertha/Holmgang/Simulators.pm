package Langertha::Holmgang::Simulators;
# ABSTRACT: Registry of simulators by device type, and dispatch of calls to them

use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Module::Runtime qw( module_notional_filename use_module );
use Moose::Util qw( find_meta );

our $VERSION = '0.001';


my %BUILTIN = (
  linux    => 'Langertha::Holmgang::Sim::Linux',
  routeros => 'Langertha::Holmgang::Sim::RouterOS',
  ios      => 'Langertha::Holmgang::Sim::IOS',
  kueche   => 'Langertha::Holmgang::Sim::Kueche',
  sehen    => 'Langertha::Holmgang::Sim::Sehen',
  schichtfehler => 'Langertha::Holmgang::Sim::Schichtfehler',
  uebersetzung => 'Langertha::Holmgang::Sim::Uebersetzung',
  denken   => 'Langertha::Holmgang::Sim::Denken',
  roost    => 'Langertha::Holmgang::Sim::Roost',
);

has _classes => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { +{ %BUILTIN } },
);

has _instances => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);

has register_classes => (
  is      => 'ro',
  default => sub { [] },
);


sub BUILD {
  my ( $self ) = @_;
  $self->register($_) for @{ $self->register_classes };
}

sub register {
  my ( $self, $class ) = @_;
  croak __PACKAGE__.'->register needs a class name' unless defined $class && length $class && !ref $class;
  $self->_load($class);
  croak __PACKAGE__.'->register: '.$class.' composes neither Langertha::Holmgang::Role::Simulator nor Langertha::Holmgang::Role::AnswerWorld'
    unless $self->_is_simulator($class);
  my $type = $class->device_type;
  croak __PACKAGE__.'->register: '.$class.' has no device_type' unless defined $type && length $type;
  $self->_classes->{$type} = $class;
  delete $self->_instances->{$type};
  return $self;
}


# a class defined in a file already loaded (or inline, in a test) needs no require
sub _load {
  my ( $self, $class ) = @_;
  return if find_meta($class);
  use_module($class);
  return;
}

sub _is_simulator {
  my ( $self, $class ) = @_;
  return $class->can('does')
    && ( $class->does('Langertha::Holmgang::Role::Simulator') || $class->does('Langertha::Holmgang::Role::AnswerWorld') );
}

sub types {
  my ( $self ) = @_;
  return sort grep { $self->simulator($_) } keys %{ $self->_classes };
}


sub simulator {
  my ( $self, $type ) = @_;
  return unless defined $type && !ref $type;
  my $inst = $self->_instances;
  return $inst->{$type} if exists $inst->{$type};
  my $class = $self->_classes->{$type} or return;
  my $ok = eval { $self->_load($class); 1 };
  unless ( $ok ) {
    my $err = $@;
    my $file = module_notional_filename($class);
    return $inst->{$type} = undef if $err =~ /\ACan't locate \Q$file\E in \@INC/;
    croak __PACKAGE__.': simulator '.$class.' for type '.$type.' does not load: '.$err;
  }
  croak __PACKAGE__.': '.$class.' (type '.$type.') composes no simulator role' unless $self->_is_simulator($class);
  croak __PACKAGE__.': '.$class.' says device_type '.$class->device_type.', registered as '.$type
    unless $class->device_type eq $type;
  return $inst->{$type} = $class->new;
}


sub is_answer_world {
  my ( $self, $type ) = @_;
  my $sim = $self->simulator($type) or return 0;
  return $sim->does('Langertha::Holmgang::Role::AnswerWorld') ? 1 : 0;
}


sub _device {
  my ( $self, $state, $host ) = @_;
  return unless defined $host && !ref $host && ref $state eq 'HASH' && ref $state->{$host} eq 'HASH';
  return $state->{$host};
}

sub _unresolved {
  my ( $self, $host ) = @_;
  return ( 'ssh: Could not resolve hostname '.( $host // '' ).': Name or service not known', 0 );
}

sub prepare {
  my ( $self, $state ) = @_;
  for my $k ( sort keys %{ $state || {} } ) {
    my $dev = $state->{$k};
    next unless ref $dev eq 'HASH' && defined $dev->{type};
    my $sim = $self->simulator( $dev->{type} ) or next;
    $sim->prepare( $dev, { host => $k, state => $state } ) if $sim->can('prepare');
  }
  return;
}


sub run_command {
  my ( $self, $state, $host, $command ) = @_;
  my $dev = $self->_device( $state, $host ) or return $self->_unresolved($host);
  my $sim = $self->simulator( $dev->{type} );
  return ( 'ssh: connect to host '.$host.' port 22: Connection refused', 0 )
    unless $sim && $sim->can('run_command');
  return $sim->run_command( $dev, $command // '', { host => $host, state => $state } );
}


sub write_file {
  my ( $self, $state, $host, $path, $content ) = @_;
  my $dev = $self->_device( $state, $host ) or return $self->_unresolved($host);
  my $sim = $self->simulator( $dev->{type} );
  return ( 'scp: '.$host.': Datei schreiben auf diesem Gerät nicht möglich (nur Konsole über run_command)', 0 )
    unless $sim && $sim->can('write_file');
  return $sim->write_file( $dev, $path // '', $content // '', { host => $host, state => $state } );
}


sub world_tools {
  my ( $self, $type ) = @_;
  return unless $self->is_answer_world($type);
  return $self->simulator($type)->tools;
}


sub tool_call {
  my ( $self, $state, $type, $name, $args ) = @_;
  my ($key) = grep { ref $state->{$_} eq 'HASH' && ( $state->{$_}{type} // '' ) eq $type } sort keys %{ $state || {} };
  return ( 'Fehler: diese Umgebung hat keine '.$type.'.', 0 ) unless defined $key;
  return ( 'Fehler: unbekannte Welt '.$type.'.', 0 ) unless $self->is_answer_world($type);
  return $self->simulator($type)->tool( $state->{$key}, $name, $args || {}, { host => $key, state => $state } );
}


sub _for_rule {
  my ( $self, $dev, $method, $kind ) = @_;
  croak __PACKAGE__.': a '.$kind.' rule needs a device' unless ref $dev eq 'HASH';
  my $type = $dev->{type} // '';
  my $sim = $self->simulator($type);
  croak __PACKAGE__.': device type '.$type.' cannot answer a '.$kind.' rule (no '.$method.')'
    unless $sim && $sim->can($method);
  return $sim;
}

sub packet_verdict {
  my ( $self, $dev, $packet, $boot ) = @_;
  return $self->_for_rule( $dev, 'packet_verdict', 'packet' )->packet_verdict( $dev, $packet || {}, $boot );
}


sub login_check {
  my ( $self, $dev, $attempt, $host ) = @_;
  return $self->_for_rule( $dev, 'login_check', 'login' )->login_check( $dev, $attempt || {}, $host );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Simulators - Registry of simulators by device type, and dispatch of calls to them

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $sims = Langertha::Holmgang::Simulators->new;
  $sims->register('My::Sim::Switch');            # a simulator from outside the core

  $sims->prepare($state);                        # once, on the initial state

  my ( $out, $ok, $gap, $exit ) = $sims->run_command( $state, 'gw-a', 'ip route' );
  my ( $out, $ok, $gap )        = $sims->write_file( $state, 'gw-a', '/etc/dnsmasq.conf', $text );
  my ( $out, $ok, $gap )        = $sims->tool_call( $state, kueche => liste_lesen => {} );

  my $tools = $sims->world_tools('kueche');      # { tool => [ required params ] } or undef
  my ( $verdict, $why )         = $sims->packet_verdict( $state->{'gw-a'}, \%packet );
  my ( $allowed, $client, @log ) = $sims->login_check( $state->{'web-1'}, \%attempt, 'web-1' );

=head1 DESCRIPTION

The tools of a suite are general (C<run_command(host, command)>,
C<write_file(host, path, content)>, or the tools of an answer world); what a
call does is decided by the B<simulator of the device type> — the C<type> of
the device in the case's state. This class maps types to simulator classes,
loads them, and hands each call to the right one.

Built in are:

  linux     Langertha::Holmgang::Sim::Linux      shell (ip, nft, wg, systemctl, files …)
  routeros  Langertha::Holmgang::Sim::RouterOS   RouterOS console
  ios       Langertha::Holmgang::Sim::IOS        Cisco IOS CLI
  kueche    Langertha::Holmgang::Sim::Kueche     answer world: recipes, pantry, shopping list, week plan
  sehen     Langertha::Holmgang::Sim::Sehen      answer world: hand in what an image shows
  schichtfehler Langertha::Holmgang::Sim::Schichtfehler  answer world: a web application from recorded pages (sources, fetches, console, findings)
  uebersetzung Langertha::Holmgang::Sim::Uebersetzung  answer world: hand in segments, report ambiguity, glossary
  denken    Langertha::Holmgang::Sim::Denken     answer world: reasoning tasks, the answer handed in by tool, a checker per task
  roost     Langertha::Holmgang::Sim::Roost      answer world: an invented dragon roost (example suite demo-roost)

A built-in type whose class is not installed is not offered (L</types>) and
answers like a host without SSH. Further types come by L</register> with a
class name, so a simulator can ship outside this distribution; there is no
namespace scanning.

A simulator composes L<Langertha::Holmgang::Role::Simulator> (device with a
command line) or L<Langertha::Holmgang::Role::AnswerWorld> (world with its own
tools); the roles document the arguments and the result list.

Every dispatching method takes the B<whole state> and changes it in place
through the device's simulator: the caller passes a copy and keeps it.

=head2 register_classes

Optional. Class names to L</register> at construction.

  Langertha::Holmgang::Simulators->new( register_classes => [ 'My::Sim::Switch' ] );

=head2 register

  $sims->register('My::Sim::Switch');

Loads the class, checks that it composes one of the two roles, and makes it the
simulator of its L<Langertha::Holmgang::Role::Simulator/device_type> —
replacing a built-in of the same type. Croaks when the class does not load or
composes neither role. Returns the registry.

=head2 types

  my @types = $sims->types;   # sorted

The device types with an installed simulator.

=head2 simulator

  my $sim = $sims->simulator('linux');   # the instance, or undef

The simulator of a device type, constructed once. C<undef> for an unknown type
or a built-in whose class is not installed; croaks when the class is installed
but fails to compile or composes no simulator role.

=head2 is_answer_world

  $sims->is_answer_world('kueche');   # 1

True when the type's simulator is an answer world.

=head2 prepare

  $sims->prepare($state);

Calls C<prepare> of every device's simulator that has one, in host name order,
on the initial state. Dies when a simulator rejects its device state.

=head2 run_command

  my ( $output, $ok, $gap, $exit ) = $sims->run_command( $state, $host, $command );

Runs a command line on the device C<$host>. An unknown host answers like
C<ssh> (C<Could not resolve hostname>); a device without a simulator with a
command line refuses the connection. The result list is the simulator's (see
L<Langertha::Holmgang::Role::Simulator/RESULT>): C<$exit> is set only when it
is neither 0 nor 1.

=head2 write_file

  my ( $output, $ok, $gap ) = $sims->write_file( $state, $host, $path, $content );

Replaces a file on the device. Devices whose simulator has no C<write_file>
(RouterOS, IOS) refuse it.

=head2 world_tools

  my $tools = $sims->world_tools('kueche');   # { tool => [ required params ] }

The tools of an answer world; C<undef> for a type with a command line or
without a simulator.

=head2 tool_call

  my ( $output, $ok, $gap ) = $sims->tool_call( $state, 'kueche', 'auf_liste_setzen', { zutat => 'Mehl', menge => '250 g' } );

One call of an answer world's tool: goes to the first entry (by key) of the
state with this C<type>.

=head2 packet_verdict

  my ( $verdict, $why ) = $sims->packet_verdict( $dev, \%packet, $boot );

For the rule kind C<packet>: asks the simulator of C<$dev> (the device state
itself, not its host name) what its packet filter does with the packet. See
L<Langertha::Holmgang::Role::Simulator/packet_verdict>. Croaks when the
device's simulator cannot answer it.

=head2 login_check

  my ( $allowed, $client, @log ) = $sims->login_check( $dev, \%attempt, $host );

For the rule kind C<login>. See
L<Langertha::Holmgang::Role::Simulator/login_check>. Croaks when the device's
simulator cannot answer it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
