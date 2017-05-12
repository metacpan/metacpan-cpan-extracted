#!/usr/bin/perl -w
#
# $Id$
#

#
# Glib::Error
#

use strict;
use Test::More tests => 36;
use Glib;


# this is obviously invalid and should result in an exception.
eval { Glib::filename_from_uri 'foo://bar'; };

ok ($@, "\$@ is defined");
isa_ok ($@, "Glib::Error", "it's a Glib exception object");
isa_ok ($@, "Glib::Convert::Error", "specifically, it's a conversion error");
is ($@->code, 4, "numeric code");
is ($@->value, 'bad-uri', "code's nickname");
is ($@->domain, 'g_convert_error', 'error domain (implies class)');
ok ($@->message, "should have an error message, may be translated");
ok ($@->location, "should have an error location, may be translated");
is ($@, $@->message.$@->location, "stringification operator is overloaded");

#
# create a new exception class...
#
Glib::Type->register_enum ('Test::ErrorCode',
                           qw(frobbed fragged fubar b0rked help-me-please));
Glib::Error::register ('Test::Error', 'Test::ErrorCode');
is_deeply (\@Test::Error::ISA, ['Glib::Error'], 'register sets up ISA');

#
# create a new instance, something we can pass to croak.
#
my $error = Test::Error->new ('fubar', "I'm fscked up beyond repair");
ok ($error, '$error should be defined');
isa_ok ($error, 'Glib::Error', "it's an exception object");
isa_ok ($error, 'Test::Error', "it's one our new exception objects");
is ($error->code, 3, 'numeric code');
is ($error->value, 'fubar', "code's nickname");
is ($error->domain, 'test-error', "domain should be mangled from package");
is ($error->message, "I'm fscked up beyond repair", "message should be unaltered");
ok ($error->location, 'should have error location');
is ($error, $error->message.$error->location, "stringification operator is overloaded");

#
# now try to throw one of those with the Glib::Error syntax.
#
eval { Test::Error->throw ('fragged', "Here is a message"); };
ok ($@, '$@ should be defined');
isa_ok ($@, 'Glib::Error', "it's an exception object");
isa_ok ($@, 'Test::Error', "it's one our new exception objects");
is ($@->code, 2, 'numeric code');
is ($@->value, 'fragged', "code's nickname");
is ($@->domain, 'test-error', "domain should be mangled from package");
is ($@->message, "Here is a message", "message should be unaltered");
ok ($@->location, 'should have error location');
is ($@, $@->message.$@->location, "stringification operator is overloaded");

# various good tests for the matches function
ok (Glib::Error::matches ($@, 'Test::Error', 'fragged'), "is");
ok (!Glib::Error::matches (undef, 'Test::Error', 'fragged'), "isn't");
ok (!Glib::Error::matches ($@, 'Test::Error', 'b0rked'), "isn't");
ok (!Glib::Error::matches ($@, 'Glib::File::Error', 'noent'), "isn't");
ok (Glib::Error::matches ($@, 'test-error', 2), "is");
my $raw = {
	domain => 'test-error',
	code => 2,
	message => 'dummy',
};
ok (Glib::Error::matches ($raw, 'Test::Error', 'fragged'), "unblessed hash");
ok (Glib::Error::matches (bless ($raw, 'Glib::Error'),
                          'Test::Error', 'fragged'),
    "from Glib::Error, but with domain");
ok (!Glib::Error::matches (bless ($raw, 'Glib::Error'),
                           'Glib::File::Error', 'isdir'),
    "from Glib::Error, but with domain");


__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
