# JOAP/Proxy/Error.pm - base class for JOAP proxy errors
#
# Copyright (c) 2003, Evan Prodromou evan@prodromou.san-francisco.ca.us.
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

# tag: JOAP proxy error classes

package JOAP::Proxy::Error;

use 5.008;
use strict;
use warnings;
use Error;
use Exporter;
use JOAP;
use base qw/Error::Simple/;

our $VERSION = $JOAP::VERSION;

package JOAP::Proxy::Error::Local;

use 5.008;
use strict;
use warnings;
use JOAP;
use JOAP::Proxy::Error;
use base qw/JOAP::Proxy::Error/;

our $VERSION = $JOAP::VERSION;

package JOAP::Proxy::Error::Remote;

use 5.008;
use strict;
use warnings;
use JOAP;
use JOAP::Proxy::Error;
use base qw/JOAP::Proxy::Error/;

our $VERSION = $JOAP::VERSION;

package JOAP::Proxy::Error::Fault;

use 5.008;
use strict;
use warnings;
use JOAP;
use JOAP::Proxy::Error;
use base qw/JOAP::Proxy::Error/;

our $VERSION = $JOAP::VERSION;

1;

__END__

=head1 NAME

JOAP::Proxy::Error - Error classes for JOAP errors

=head1 SYNOPSIS

  use Error qw(:try);
  use JOAP::Proxy::Error;

  # Just want to distinguish JOAP errors from other errors

  try {

    $some_object->do_something_joapy();

  } catch JOAP::Proxy::Error with {

    my $err = shift;
    print STDERR "Something went kerblooie with JOAP: " . $err->value . ": " . $err->text;

  } otherwise {

    my $err = shift;
    print STDERR "Some other error happened.";

  };

  # Really care what kind of error we got.

  try {

    $some_object->do_something_joapy();

  } catch JOAP::Proxy::Error::Local with {

    my $err = shift;
    print STDERR "There was a client-side problem with JOAP: ",
      $err->text, "\n";

  } catch JOAP::Proxy::Error::Remote with {

    my $err = shift;
    print STDERR "There was a remote problem with JOAP: " .
      $err->value, ": ", $err->text, "\n";

  } catch JOAP::Proxy::Error::Fault with {

    my $err = shift;
    print STDERR "There was a XML-RPC fault with a JOAP method: ",
      $err->value, ": ", $err->text, "\n";

  } otherwise {

    my $err = shift;
    print STDERR "Some other error happened.\n";

  };

=head1 ABSTRACT

This module provides a simple hierarchy of error classes that can/may
happen when using JOAP proxies. OK, who am I kidding? You're going to
get errors. They will probably be in one of these classes.

=head1 DESCRIPTION

There are three classes in this module that represent different error
situations, and one superclass that rules them all and in the darkness
binds them. Or something.

Anyways, all three classes use the exact same interface as the
superclass, so I'll just describe it and you can interpolate from there.

The whole thing is mainly useful if you use the try mechanism in the
Error package. If you don't, then your Perl program will just die()
with the appropriate message.

=head2 JOAP::Proxy::Error

This is the superclass for all the other classes. None of the JOAP
proxy modules will throw an error of this type, but you can put it in
your catch blocks if you're interested in JOAP proxy errors in general
but not in their particulars.

The classes don't provide all the information that an Error object
normally does (file, line, etc.). They just have the following two
accessors:

=over

=item value

A coded value for the error. See below for details on what this value
is for each error type.

=item text

Descriptive text for the error. What went wrong, in plain English
(sorry, no i18n of error messages (yet). If you want, I can rewrite
all the embedded messages in Esperanto).

=back

=head2 JOAP::Proxy::Error::Remote

This class is for errors that were reported as part of the JOAP
protocol from the JOAP object server. Generally, they mean that
something has gone wrong in the communication between the proxy and
the object server, such as:

=over

=item *

The communications link in the Jabber network is broken down
somewhere. Either your server is down, or their server is down, or
they're not talking to each other, or they're not talking to you.

=item *

Some validation step failed on the server. This usually means that the
proxy library is broken somewhere, but it can also mean that there's
just some custom validation that happens on the server side that your
code messed up.

=back

The C<value> of a C<JOAP::Proxy::Error::Remote> object is always (OK,
usually), the numeric code of the Jabber IQ error that was
returned. Yeah, I know -- the whatsy-what-whatsit? -- but if you look
at the JOAP specification, you can figure out what the error codes
mean.

=head2 JOAP::Proxy::Error::Fault

This error is generated when an XML-RPC fault (a whatsy-what-whatsit?)
happens on the server side. What this means in JOAP terms is that
there wasn't any particular technical communications problem between
the proxy and the server, but that the application code on the other
side of the wire doesn't like something about the method you're
calling.

In other words, this differentiates between application-level errors
and JOAP-level errors. Usually.

The C<value> of the error is the XML-RPC C<faultCode> and the C<text>
of the error is the XML-RPC C<faultString>. This usually maps out to
"numeric value" and "descriptive text".

If you're using the Perl JOAP classes on the server side of the
conversation, the C<value> and C<text> should be more or less
identical to the C<value> and C<text> of the error that was thrown on
the server side. So it's almost like your server code threw an error
REAL REAL FAR (except class information is lost).

=head2 JOAP::Proxy::Error::Local

This type of error is thrown when the proxy library figures out you're
doing something wrong and it doesn't want to send the erroneous
request over the Jabber network and end up looking like an idiot by
association.

It also saves on network traffic if we save a round trip by just
telling you you're wrong right away. Performance improves!

Some common reasons that this error occurs:

=over

=item *

You're doing something on a JOAP class that you can only do to a JOAP
instance.

=item *

Vice versa.

=item *

You're calling a method with too many, or too few, arguments.

=item *

You're trying to set a value that's read-only.

=item *

You're calling one of the methods with named parameters, but your
named parameters don't exist.

=item *

You're trying to construct a JOAP Proxy object, but you didn't give
all the required parameters.

=back

In general, these are all programming errors and not runtime
errors. But not necessarily. But most likely.

The C<text> attribute of this kind of error is a friendly reminder to
RTFM. OK, not really: it'll tell you what the problem is.

The C<value> is usually nothing and should be ignored.

=head2 EXPORT

None by default.

=head1 SEE ALSO

If you have no idea what you're looking at, you should probably check
out L<JOAP>, L<JOAP::Proxy::Object>, and L<JOAP::Proxy::Class>. You
might also want to check out L<Error> for info on how Error stuff
works and how to C<try> to C<catch> them.

L<JOAP> also has information on contacting the author in case you
think there's a bug.

=head1 BUGS

There's 4 packages in one module. Some would call this a bug.

There's a logical inconsistency in the fact that some kinds of
validation errors on the server side will cause ::Remote errors, and
others will cause ::Fault errors. This is a problem with the JOAP
spec, though.

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
