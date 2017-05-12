#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;
use HTML::FormEngine::DBSQL;
use DBI;

my $form = HTML::FormEngine::DBSQL->new({},bless({},'DBI::db'));         # create an object
ok( defined $form, 'new() returned something' );                # check that we got something
ok( $form->isa('HTML::FormEngine::DBSQL'), 'it\'s the right class' );     # and it's the right class


