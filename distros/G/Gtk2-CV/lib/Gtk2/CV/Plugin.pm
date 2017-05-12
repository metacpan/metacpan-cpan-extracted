=head1 NAME

Gtk2::CV::Plugin - plugin superclass and nonexistent documentation

=head1 SYNOPSIS

 # in ~/.cvrc:
 # require "/path/to/plugin/class";

 # in the plugin file:
 package myplugin;
 use Gtk2::CV::Plugin; # registers the current class as plugin

 # see eg/plugin-skeleton for a starting point

=head1 DESCRIPTION

=over 4

=cut

package Gtk2::CV::Plugin;

use common::sense;

my %registry;

sub import {
   my ($self) = @_;

   return unless $self eq Gtk2::CV::Plugin::;

   my $caller = caller;
   $registry{$caller}++;
   push @{"$caller\::ISA"}, __PACKAGE__;
}

sub call_accum {
   my ($self, $accum, $method, @args) = @_;

   my $state = { };

   for my $plugin (keys %registry) {
      $accum->($state, $plugin->$method (@args))
         or last;
   }

   $state->{accum}
}

sub call {
   my ($self, $method, @args) = @_;

   $self->call_accum (sub { 1 }, $method, @args)
}

=item $plugin->new_imagewindow ($imagewindow)

=cut

sub new_imagewindow {
}

=item $plugin->new_schnauzer ($schnauzer)

=cut

sub new_schnauzer {
}

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

