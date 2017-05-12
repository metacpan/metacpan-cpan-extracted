#!/usr/bin/env perl -w
# CAVEAT EMPTOR: This file is UTF8 encoded (BOM-less)
# Burak Gürsoy <burak[at]cpan[dot]org>
use strict;
use warnings;
use utf8;
use constant TEST_NUM => 42;
use Test::More qw( no_plan );
use Lingua::Any::Numbers qw( :std +locale );

ok( to_string(  TEST_NUM ), 'We got a string from global locale' );
ok( to_ordinal( TEST_NUM ), 'We got an ordinal from global locale' );

ok( to_string(  TEST_NUM, 'locale' ), 'We got a string from param locale' );
ok( to_ordinal( TEST_NUM, 'locale' ), 'We got an ordinal from param locale' );
