#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;
use HTML::FormEngine;

my $form = HTML::FormEngine->new;         # create an object
ok( defined $form, 'new() returned something' );                # check that we got something
ok( $form->isa('HTML::FormEngine'), 'it\'s the right class' );     # and it's the right class


