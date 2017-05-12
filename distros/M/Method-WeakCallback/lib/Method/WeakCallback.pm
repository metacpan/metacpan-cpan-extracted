package Method::WeakCallback;

our $VERSION = '0.04';

use strict;
use warnings;
use Hash::Util::FieldHash qw(fieldhash);
use Scalar::Util qw(weaken);
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( weak_method_callback weak_method_callback_cached
                     weak_method_callback_static);

sub weak_method_callback {
    my ($object, $method, @args) = @_;
    croak 'Usage: weak_method_callback($object, $method, @args)'
        unless defined $method;
    weaken $object;
    sub { defined($object) ? $object->$method(@args, @_) : () };
}

fieldhash our %cached;
sub weak_method_callback_cached {
    my ($object, $method) = @_;
    croak 'Usage: weak_method_callback_cached($object, $method)'
        if @_ > 2 or !defined $method;

    $cached{$object}{$method} ||= do {
        weaken $object;
        sub { defined($object) ? $object->$method(@_) : () };
    };
}

fieldhash our %static;
sub weak_method_callback_static {
    my ($object, $method) = @_;
    croak 'Usage: weak_method_callback_static($object, $method)'
        if @_ > 2 or !defined $method;

    $static{$object}{$method} ||= do {
        weaken $object;
        my $sub = $object->can($method)
            or croak "object $object does not have method '$method'";
        sub { defined($object) ? $sub->($object, @_) : () };
    };
}

1;

=head1 NAME

Method::WeakCallback - Call back object methods through weak references.

=head1 SYNOPSIS

  package Foo::Bar;
  use Method::WeakCallback qw(weak_method_callback);

  use AE;

  sub new { ... }

  sub set_timer {
    my $obj = shift;
    $obj->{timer} = AE::timer(60, 60,
                        weak_method_callback($obj, 'on_timeout'));
  }

  sub on_timeout { say "Time out!" }


=head1 DESCRIPTION

When writing programs mixing event programming with OOP, it is very
common to employ callbacks that just call some method on some
object. I.e.:

  $w = AE::io($fh, 0, sub { $obj->data_available_for_reading });

Unfortunately, this style can result in the creation of cyclic data
structures that never get freed.

For instance consider the following code:

  $obj->{rw} = AE::io($fh, 0, sub { $obj->data_available_for_reading });

The callback is a closure that internally, keeps a reference to
C<$obj>. Then a reference to the callback is stored in the watcher
object which is itself stored in C<$obj> and so, the cycle is
complete.

Method::WeakCallback solves that problem generating callbacks that use
a weak reference for the object. Its usage is very simple:

  $obj->{rw} = AE::io($fh, 0,
                    weak_method_callback($obj, 'data_available_for_reading'));

If the callback is called after C<$obj> is destroyed it will just do
nothing.

Extra arguments to be passed to the method can also be given. I.e.

  weak_method_callback($obj, $method, @extra);

  # equivalent to:
  #   sub { $obj->$method(@extra, @_) };

The module also provides the subroutine C<weak_method_callback_cached>
which stores inside an internal cache the generated callbacks greatly
improving performance when the same callback (same object, same
method) is generated over and over.

Note that C<weak_method_callback_cached> does not accept extra
arguments.

=head2 EXPORT

None by default.

The subroutines C<weak_method_callback> and
C<weak_method_callback_cached> can be imported from this module.

=head1 SEE ALSO

L<curry>, L<AnyEvent>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
