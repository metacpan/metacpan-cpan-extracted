#!/usr/bin/perl -w

# tag: test for coercion

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

use Test::More tests => 31;

use Net::Jabber qw(Client);
use JOAP;

can_ok(JOAP, 'coerce');

# idempotent coercions

{
    is(JOAP->coerce('i4', 10), 10, "Idempotent integer coercion works.");
    is(JOAP->coerce('int', 8), 8, "Idempotent integer 'int' coercion works.");
    is(JOAP->coerce('double', 0.1), 0.1, "Idempotent double coercion works.");
    is(JOAP->coerce('string', 'spock'), 'spock', "Idempotent string coercion works.");
    is(JOAP->coerce('boolean', 1), 1, "boolean coercion for positive value works.");
    is(JOAP->coerce('boolean', 0), 0, "boolean coercion for positive value works.");
    is(JOAP->coerce('dateTime.iso8601', '1968-10-14T07:32:00Z'), '1968-10-14T07:32:00Z',
       "Idempotent coercion of datetime works.");
    is_deeply(JOAP->coerce('array', [1, 2, 3]), [1, 2, 3], "Idempotent array coercion works.");
    is_deeply(JOAP->coerce('struct', {foo=>1, bar=>2}), {foo=>1, bar=>2}, "Idempotent struct coercion works.");
}

# undef coercions

{
    is(JOAP->coerce('i4', undef), 0, "Undef coercion to zero for integer 'i4'.");
    is(JOAP->coerce('int', undef), 0, "Undef coercion to zero for integer 'int'.");
    is(JOAP->coerce('double', undef), 0.0, "Undef coercion to 0.0 for double works.");
    is(JOAP->coerce('string', undef), '', "Undef coercion to empty string works.");
    is(JOAP->coerce('boolean', undef), 0, "Undef coercion to false for boolean works.");
    is(JOAP->coerce('dateTime.iso8601', undef), '0001-00-00T00:00:00Z', "Undef coercion of datetime works.");
    is_deeply(JOAP->coerce('array', undef), [], "Undef coercion of undef to empty array works.");
    is_deeply(JOAP->coerce('struct', undef), {}, "Undef coercion of undef to empty array works.");
}

# integer coercions

{
    is(JOAP->coerce('i4', 0.0), 0, "Int coercion to zero for double.");
    is(JOAP->coerce('i4', '12'), 12, "Int coercion for numeric string works.");
    is(JOAP->coerce('i4', 'spock'), 0, "Int coercion to zero for non-numeric string.");
    is(JOAP->coerce('i4', '12spock'), 12, "Int coercion for mixed string.");
}

# string coercions

{
    is(JOAP->coerce('string', 14), '14', "String coercion for integer.");
    is(JOAP->coerce('string', 0.4), '0.4', "String coercion for double.");
}

# boolean coercions

{
    is(JOAP->coerce('boolean', 14), 1, "Boolean coercion for integer.");
    is(JOAP->coerce('boolean', 'spock'), 1, "Boolean coercion for non-numeric string.");
    is(JOAP->coerce('boolean', '0'), 0, "Boolean coercion for string '0'.");
    is(JOAP->coerce('boolean', '0 but true'), 1, "Boolean coercion for string '0 but true'.");
    is(JOAP->coerce('boolean', ()), 0, "Boolean coercion for empty list.");
}

# datetime coercions

{
    is(JOAP->coerce('dateTime.iso8601', 0), '1970-01-01T00:00:00Z', "Coerce integer to datetime works.");
    is(JOAP->coerce('dateTime.iso8601', [gmtime(0)]), '1970-01-01T00:00:00Z', "Coerce list to datetime works.");
}
