# $Id: /mirror/gungho/lib/Gungho/Provider/Inline.pm 31310 2007-11-29T13:19:42.807767Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# Copyright (c) 2007 Kazuho Oku
# All rights reserved.

package Gungho::Provider::Inline;
use strict;
use base qw(Gungho::Provider);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(requests callback);

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->has_requests(1);
    $self->requests([]);
    $self;
}

sub setup {
    my $self = shift;
    my $callback = $self->config->{callback};
    die "``callback'' not supplied\n" unless ref $callback eq 'CODE';
    $self->callback($callback);
    $self->next::method(@_);
}

sub add_request {
    my ($self, $req) = @_;
    push @{$self->requests}, $req;
    $self->has_requests(1);
}

sub pushback_request {
    my ($self, $c, $req) = @_;
    $c->log->debug( "[PROVIDER]: Pushback request " . $req->uri );
    $self->add_request($req);
}

sub dispatch {
    my ($self, $c) = @_;
    
    if ($self->callback) {
        my @args = (
            Class::Inspector->loaded('Gungho::Inline') &&
                &Gungho::Inline::OLD_PARAMETER_LIST ?
            ($c, $self) :
            ($self, $c)
        );
        unless ($self->callback->(@args)) {
            $self->callback(undef);
        }
    }
    
    if (! $self->callback && @{$self->requests} == 0) {
        $self->has_requests(0);
        $c->is_running(0);
    }
}

1;

__END__

=head1 NAME 

Gungho::Provider::Inline - Inline Provider 

=head1 DESCRIPTION

Sometimes you don't need the full power of an independent Gungho Provider
and or Handler. In those cases, Gungho::Provider::Inline saves you from 
creating a separate package for a Provider.

You can simply pass a code reference as the the provider config:

  Gungho->run(
    {
       provider => sub { ... }
    }
  );

And it will be called via Gungho::Provider::Inline.

The code reference you specified will be called as if it were a method
in the Gungho::Provider::Inline package.

=head1 METHODS

=head2 new

=head2 setup

=head2 add_request

=head2 dispatch

=head2 pushback_request

=cut