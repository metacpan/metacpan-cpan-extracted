# JOAP::Proxy::Package -- Classes that use JOAP
#
# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

# tag: JOAP package base class

package JOAP::Proxy::Package;
use Class::Data::Inheritable;
use base qw/Exporter Class::Data::Inheritable/;

use 5.008;
use strict;
use warnings;
use JOAP::Proxy::Error;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = $JOAP::VERSION;
our $AUTOLOAD;

JOAP::Proxy::Package->mk_classdata('Attributes');
JOAP::Proxy::Package->mk_classdata('Methods');
JOAP::Proxy::Package->mk_classdata('Timestamp');
JOAP::Proxy::Package->mk_classdata('Description');

JOAP::Proxy::Package->Methods({});
JOAP::Proxy::Package->Attributes({});
JOAP::Proxy::Package->Timestamp(undef);
JOAP::Proxy::Package->Description('');

# when describe stuff happens, we want to store it in the package
# rather than in the instance.

sub attributes {
    my $self = shift;
    return $self->Attributes(@_);
}

sub methods {
    my $self = shift;
    return $self->Methods(@_);
}

sub timestamp {
    my $self = shift;
    return $self->Timestamp(@_);
}

sub _set_timestamp {
    my $self = shift;
    return $self->Timestamp(@_);
}

sub description {
    my $self = shift;
    return $self->Description(@_);
}

sub _set_description {
    my $self = shift;
    return $self->Description(@_);
}

# when we autoload, we want to cache the results in the package
# namespace.

sub AUTOLOAD {

    my ($self) = $_[0];
    my ($sub) = $AUTOLOAD;

    my ($pkg,$name) = ($sub =~ /(.*)::([^:]+)$/);
    my ($func) = $self->can($name);

    if ($func) {
        no strict 'refs';
        *$sub = $func;
        goto &$sub;
    } else {
        throw JOAP::Proxy::Error::Local("No attribute or method '$name'");
    }
}

1;
__END__

=head1 NAME

JOAP::Proxy::Package - Mixin for proxies that store metadata in the package

=head1 SYNOPSIS

    use JOAP::Proxy::Package;
    use base qw(JOAP::Proxy::Package JOAP::Proxy::Object);

=head1 ABSTRACT

This module provides a mixin class for storing JOAP::Proxy::Object
metadata in the package of a class rather than in each instance. It
also caches AUTOLOAD'd methods in the package namespace so they can be
accessed by standard lookup the next time around.

=head1 DESCRIPTION

First of all, this modules isn't really of use unless you're really
messing around inside the JOAP proxy internals. If you aren't, well,
just forget that you saw this package.

The module does two things:

=over

=item *

It has class data accessors for the metadata (attribute and method
descriptors, timestamps, and descriptions) for a class of JOAP
objects. It also overloads the per-instance accessors so that they
pass through to the class accessors. Because JOAP::Proxy and friends
use those per-instance accessors, this means that the behavior of
instances of a package will all be the same (more or less).

=item *

It provides an AUTOLOAD method like the one in JOAP::Proxy. This one,
however, will cache the resultant proxy method or accessor in the
package namespace, so that the method doesn't have to be AUTOLOAD'd
the next time around.

=back

This package should be the first in an @ISA or 'use base' statement,
since it overloads some of the basic stuff in JOAP::Proxy. It is not a
subclass of JOAP::Proxy -- this prevents the 'diamond problem', since
Perl inheritance is depth-first.

If that doesn't make any sense, just remember: this package first.

=head2 Class Methods

The package defines the following four class methods for storing JOAP metadata:

=over

=item Attributes

This is for storing a reference to a hashtable of attribute
descriptors. See L<JOAP::Proxy> for how these work.

=item Methods

This is for storing a reference to a hashtable of method descriptors
(again, fully documented in L<JOAP::Proxy>).

=item Description

A text description of the interface.

=item Timestamp

The most recent time the interface was checked with the server. It's a
string in ISO 8601 format; see L<JOAP> for a full description of that
format.

=back

=head2 Instance Methods

The package also whomps ('overloads' is the wrong word, since it's not
a subclass) the following methods in JOAP::Proxy:

=over

=item attributes

=item methods

=item timestamp

=item description

=item _set_timestamp

=item _set_description

=back

For compatibility with the JOAP::Proxy interface, it's probably better
to call the lowercase interface for application code, and reserve the
uppercase interface for class declarations.

=head1 EXPORT

None by default.

=head1 SEE ALSO

If you have no idea what you're looking at, you should probably check
out L<JOAP> and L<JOAP::Proxy> first.

L<JOAP> also has information on contacting the author in case you
think there's a bug.

This package uses L<Class::Data::Inheritable>. You should look at that
module's info if you're bent on messing around with it.

=head1 BUGS

The package doesn't keep you from instantiating it directly, or from
instantiating one of its immediate subclasses. You probably shouldn't,
though.

It clouds up your namespace something awful. It should probably be
reduced to a single Metadata object or something. But not right now.

The whole thing is kind of sneaky and underhanded.

The AUTOLOAD caching is kind of a problem for programs that use
inheritance in their JOAP proxy classes. If class A is a superclass of
class B, and they both have an attribute 'c', then calling:

    B->c

...won't cache the accessor in package A. A later call to:

    A->c

...will require a new AUTOLOAD, compile, and cache. Inefficient!

Worse, if the structure of attribute 'c' is changed for some reason in
B (which is probably a bad idea), then calling:

    A->c

...will cache A's version, and when you call:

    B->c

...A's version will be called (by standard lookup), and will probably
fail, or at least cause weird errors.

=head1 AUTHOR

Evan Prodromou, E<lt>evan@prodromou.san-francisco.ca.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, Evan Prodromou E<lt>evan@prodromou.san-francisco.ca.usE<gt>.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut
