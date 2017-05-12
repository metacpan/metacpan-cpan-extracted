# $Id: /mirror/gungho/lib/Gungho/Handler/Inline.pm 8911 2007-11-12T01:12:09.994728Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# Copyright (c) 2007 Kazuho Oku
# All rights reserved.

package Gungho::Handler::Inline;
use strict;
use warnings;
use base qw(Gungho::Handler);
use Gungho::Request;
    
__PACKAGE__->mk_accessors($_) for qw(callback);
    
    
sub setup {
    my $self = shift;
    my $callback = $self->config->{callback};
    die "``callback'' not supplied\n" unless ref $callback eq 'CODE';
    $self->callback($callback);
    $self->next::method(@_);
}   
    
sub handle_response {
    my ($self, $c, $req, $res) = @_;
    
    my @args = (
        Class::Inspector->loaded('Gungho::Inline') &&
            &Gungho::Inline::OLD_PARAMETER_LIST ?
        ($req, $res, $c, $self) :
        ($self, $c, $req, $res)
    );
    $self->callback->(@args);
}

1;

__END__

=head1 NAME 

Gungho::Handler::Inline - Inline Handler 

=head1 DESCRIPTION

Sometimes you don't need the full power of an independent Gungho Handler
and or Handler. In those cases, Gungho::Handler::Inline saves you from 
creating a separate package for a Handler.

You can simply pass a code reference as the the provider config:

  Gungho->run(
    {
       handler => sub { ... }
    }
  );

And it will be called via Gungho::Handler::Inline.

The code reference you specified will be called as if it were a method
in the Gungho::Handler::Inline package.

=head1 METHODS

=head2 setup

=head2 handle_response

=cut