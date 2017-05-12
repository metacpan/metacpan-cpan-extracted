# $Id: /mirror/gungho/lib/Gungho/Inline.pm 39015 2008-01-16T15:58:40.917983Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# Copyright (c) 2007 Kazuho Oku
# All rights reserved.

package Gungho::Inline;
use strict;
use warnings;
use base qw(Gungho);
use Gungho::Request;

BEGIN
{
    if (! __PACKAGE__->can('OLD_PARAMETER_LIST')) {
        my $old_parameter_list = $ENV{GUNGHO_INLINE_OLD_PARAMETER_LIST} || 0;
        eval "sub OLD_PARAMETER_LIST() { $old_parameter_list } ";
        die if $@;
    }
}

sub bootstrap
{
    my $class = shift;
    if (&OLD_PARAMETER_LIST) {
        $class->_setup_old_parameters(@_);
    } else {
        my $config = $class->load_config(shift);
        my $opts   = shift || {};

        foreach my $k qw(provider handler) {
            if ($opts->{$k} && ref $opts->{$k} eq 'CODE') {
                $config->{$k} = {
                    module => qw(Inline),
                    config => {
                        callback => $opts->{$k},
                    },
                };
            }
        }
        @_ = ($config);
    }

    $class->next::method(@_);
}

sub _setup_old_parameters
{
    my $class = shift;
    my $config = shift;
    
    foreach my $k qw(provider handler) {
        if ($config->{$k} && ref $config->{$k} eq 'CODE') {
            $config->{$k} = {
                module => qw(Inline),
                config => {
                    callback => $config->{$k},
                },
            };
        }
    }
}

1;

__END__

=head1 NAME

Gungho::Inline - Inline Your Providers And Handlers (Deprecated)

=head1 SYNOPSIS

  use Gungho::Inline;
  use IO::Select;
  
  Gungho::Inline->run(
     $config,
     {
        provider => sub {
           my ($provider, $c) = @_;
           while (IO::Select->new(STDIN)->can_read(0)) {
              return if STDIN->eof;
              my $url = STDIN->getline;
              chomp $url;
              $provider->add_request($c->prepare_request(Gungho::Request->new(GET => $url)));
            }
        },
        handler => sub {
           my ($handler, $c, $req, $res) = @_;
           print $res->code, ' ', $req->uri, "\n";
        }
    }
  );

=head1 DESCRIPTION

Sometimes you don't need the full power of an independent Gungho Provider
and or Handler. In those cases, Gungho::Inline saves you from creating 
separate packages

This module is a thin wrapper around Gungho that allows you to specify
subroutine references instead of a full config.

As of Gungho 0.09003, inlined handlers and providers are supported natively.
The only reason to use this module is for you to use the old parameter list.

=head1 BACKWARDS COMPATIBILITY WITH VERSIONS < 0.08

From version 0.08 of Gungho::Inline, the parameter list passed to the
handler and providers, as well as the run method has been changed. You
can enable the old behavior if you do

   env GUNGHO_INLINE_OLD_PARAMETER_LIST=1 gungho 

or, somewhere in your code, create a subroutine constant:

   BEGIN
   {
       sub Gungho::Inline::OLD_PARAMETER_LIST { 1 };
   }
   use Gungho::Inline;

=head1 CONSTANTS

=head2 OLD_PARAMETER_LIST

If true, uses the old-style parameter list

=head1 METHODS

=head2 setup({ provider => $callback, handler => $callback, %args })

Sets up Gungho::Inline with this set of providers

=head1 AUTHOR

Original code by Kazuho Oku. 
  
=cut