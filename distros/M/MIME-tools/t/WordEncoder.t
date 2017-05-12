use strict;
use warnings;
use Test::More tests => 8;
use MIME::Words qw(:all);

is(encode_mimeword('wookie', 'Q', 'ISO-8859-1'),
    '=?ISO-8859-1?Q?wookie?=');
is(encode_mimeword('François', 'Q', 'ISO-8859-1'),
    '=?ISO-8859-1?Q?Fran=E7ois?=');
is(encode_mimewords('Me and François'), 'Me and =?ISO-8859-1?Q?Fran=E7ois?=');
is(decode_mimewords('Me and =?ISO-8859-1?Q?Fran=E7ois?='),
   'Me and François');

is(encode_mimewords('Me and François and François    and François       and François               and François                      and François'),
   'Me and =?ISO-8859-1?Q?Fran=E7ois=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois?=');


is(decode_mimewords('Me and =?ISO-8859-1?Q?Fran=E7ois=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois?='),
   'Me and François and François    and François       and François               and François                      and François');


is(encode_mimewords('Me and François and François    and François       and François               and François                      and François and wookie and wookie and wookie and wookie and wookie and wookie'),
   'Me and =?ISO-8859-1?Q?Fran=E7ois=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20?=and wookie and wookie and wookie and wookie and wookie and wookie');

is(decode_mimewords('Me and =?ISO-8859-1?Q?Fran=E7ois=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20=20?=and =?ISO-8859-1?Q?Fran=E7ois=20?=and wookie and wookie and wookie and wookie and wookie and wookie'),
   'Me and François and François    and François       and François               and François                      and François and wookie and wookie and wookie and wookie and wookie and wookie');
