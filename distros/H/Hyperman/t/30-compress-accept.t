#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use Hyperman ();

# hz_accepts_gzip (hm_compress.h) as a table, through the author shim. This
# runs on every request when compression is on, so it is a scan of the raw
# header - no split, no hash, no SV - and the parsing rules are worth
# pinning before anything is wired to a response.

sub ok_ae   { my ($h, $why) = @_; ok  Hyperman::_accepts_gzip($h), $why }
sub no_ae   { my ($h, $why) = @_; ok !Hyperman::_accepts_gzip($h), $why }

ok_ae 'gzip',                  'the bare token';
ok_ae 'gzip, deflate',         'first of a list';
ok_ae 'deflate, gzip',         'last of a list';
ok_ae 'deflate, gzip, br',     'in the middle';
ok_ae ' gzip ',                'surrounding whitespace';
ok_ae "deflate,\tgzip",        'tab padding';
ok_ae 'GZIP',                  'case-insensitive';
ok_ae 'gzip;q=1',              'q=1';
ok_ae 'gzip;q=1.0',            'q=1.0';
ok_ae 'gzip;q=0.5',            'a middling q still accepts';
ok_ae 'gzip;q=0.001',          'a small but nonzero q accepts';
ok_ae 'gzip; q=0.9',           'space before the parameter';
ok_ae '*',                     'the wildcard';
ok_ae 'deflate, *',            'a wildcard alongside a named encoding';

# q=0 is an explicit refusal, not a weak preference. Getting this wrong
# means compressing for a client that asked us not to.
no_ae 'gzip;q=0',              'q=0 refuses';
no_ae 'gzip;q=0.0',            'q=0.0 refuses';
no_ae 'gzip;q=0.000',          'q=0.000 refuses';
no_ae 'gzip;q=0, deflate',     'a refusal inside a list';
no_ae '*;q=0',                 'a refused wildcard';

# A named token decides for itself and is not overridden by a wildcard,
# whichever order they appear in.
no_ae 'gzip;q=0, *',           'an explicit gzip refusal beats a later wildcard';
no_ae '*, gzip;q=0',           'and an earlier one';
ok_ae '*;q=0, gzip',           'an explicit gzip accept beats a refused wildcard';

no_ae 'deflate',               'another encoding alone';
no_ae 'identity',              'identity alone';
no_ae 'br',                    'br alone (we only emit gzip)';
no_ae '',                      'an empty header';
no_ae undef,                   'an absent header';
no_ae 'gzipp',                 'a longer token that merely starts with gzip';
no_ae 'xgzip',                 'a longer token that merely ends with it';
no_ae ',,,',                   'nothing but separators';

done_testing;
