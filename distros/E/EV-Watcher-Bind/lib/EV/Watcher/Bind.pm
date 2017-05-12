# $Id: /mirror/perl/EV-Watcher-Bind/trunk/lib/EV/Watcher/Bind.pm 9173 2007-11-15T11:33:58.291707Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package EV::Watcher::Bind;
use strict;
use warnings;
use EV;
our $VERSION = '0.00001';

BEGIN
{
    my $mk_wrapper = sub {
        my ($original) = @_;
        return sub {
            # the EV API always ends with a callback. pop that callback, and
            # take the rest of the arguments as the binding arguments
            my @binds;
            my $x;
            do {
                $x = pop @_;
                unshift @binds, $x;
            } while (@_ && ref $x ne 'CODE');

            my $callback = shift @binds;
            my $w;
            $w = $original->(@_, sub { $callback->(@binds, $w) });
        };
    };

    my @names = qw(io timer periodic signal child idle prepare check);
    my @suffix = ('', '_ns');
    foreach my $name (@names) {
        foreach my $suffix (@suffix) {
            no strict 'refs';
            my $fullname = "EV::${name}${suffix}";
            my $bindname = "${fullname}_bind";
            my $original = *{ $fullname }{CODE};
            *{ $bindname } = $mk_wrapper->($original);
        }
    }
}


1;

__END__

=head1 NAME

EV::Bind - Easier Interface To EV's Callbacks

=head1 SYNOPSIS

  use EV;
  use EV::Watcher::Bind;

  EV::io_bind($fh, $mask, $callback, @args);

=head1 DESCRIPTION

Highly experimental. You've been warned.

EV::Watcher::Bind provides a simple interface to EV.pm's watcher methods
that allows you to bind arguments as well as the watcher being created
to the callback being registerd.

If you have, for example, an object that you want to use as your callback,
you always need to do

  my $obj = ...;
  my @args = (1, 2, 3);
  my $io = EV::io($fh, $mask, sub { $obj->foo(@args) });

With EV::Watcher::Bind, you can do

  my $io = EV::io_bind($fh, $mask, \&foo, $obj, @args);

The functions provided by EV::Watcher::Bind also has the advantage of
passing you the EV::Watcher object that caused your callback to execute
as the last argument in your callback. In the above example, foo() could
have be implemented like so:

  sub foo {
    my ($self, $arg1, $arg2, $arg3, $w) = @_;
    $w->stop;
  }

=head1 METHODS

EV::Watcher::Bind provides the following functions:

=head2 EV::io_bind

=head2 EV::io_ns_bind

=head2 EV::timer_bind

=head2 EV::timer_ns_bind

=head2 EV::periodic_bind

=head2 EV::periodic_ns_bind

=head2 EV::signal_bind

=head2 EV::signal_ns_bind

=head2 EV::child_bind

=head2 EV::child_ns_bind

=head2 EV::idle_bind

=head2 EV::idle_ns_bind

=head2 EV::prepare_bind

=head2 EV::prepare_ns_bind

=head2 EV::check_bind

=head2 EV::check_ns_bind

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut