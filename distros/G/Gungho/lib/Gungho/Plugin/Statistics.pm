# $Id: /mirror/gungho/lib/Gungho/Plugin/Statistics.pm 4238 2007-10-29T15:08:17.605700Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endework.jp>
# All rights reserved.

package Gungho::Plugin::Statistics;
use strict;
use warnings;
use base qw(Gungho::Plugin);

__PACKAGE__->mk_accessors($_) for qw(storage dump_interval _next_update);

sub setup
{
    my ($self, $c) = @_;

#    $self->dump_interval( $self->config->{dump_interval} || 60 );

    # Create the storage
    $self->_setup_storage($c);

    $c->register_hook(
#        'engine.end_loop'        => sub { $self->dump_statistics(@_) },
        'engine.send_request'    => sub { $self->log_start_request(@_) },
        'engine.handle_response' => sub { $self->log_end_request(@_) },
    );
}

sub _setup_storage
{
    my ($self, $c) = @_;

    my $config = $self->config->{storage} || {};
    $config->{module} ||= 'SQLite';
    my $pkg = $c->load_gungho_module( $config->{module}, 'Plugin::Statistics::Storage');
    my $storage = $pkg->new(config => $self->config);
    $storage->setup($c);
    $self->storage($storage);
}

sub log_start_request
{
    my ($self, $c, $data) = @_;
    $self->storage->incr("active_requests");
    foreach my $name qw(active_requests finished_requests) {
        my $value = $self->storage->get($name);
        print STDERR $name, " = ", defined $value ? $value : '(undef)', "\n";
    }
}

sub log_end_request
{
    my ($self, $c, $data) = @_;
    $self->storage->decr("active_requests");
    $self->storage->incr("finished_requests");

    foreach my $name qw(active_requests finished_requests) {
        my $value = $self->storage->get($name);
        print STDERR $name, " = ", defined $value ? $value : '(undef)', "\n";
    }
}

# sub dump_statistics
# {
#     my ($self, $c) = @_;
#
#     if (time() <= ($self->_next_update || 0)) {
#         $c->log->debug("Dumping stats");
#         $self->_next_update(time() + $self->dump_interval);
#     }
# }

1;

__END__

=head1 NAME

Gungho::Plugin::Statistics - Gather Crawler Statistics 

=head1 SYNOPSIS

  plugins:
    - module: Statistics
      config:
        storage:
            module: SQLite

=head1 DESCRIPTION

This plugin collects statistics from gungho.

At this point it's still just a toy that doesn't do anything. 
If you have suggestions or patches, please let me know!

=head1 METHODS

=head2 setup

=head2 log_start_request

=head2 log_end_request

=cut

