#!/usr/bin/perl

use strict;

package LittleORM::Role;

use Moose::Role;
use Moose::Exporter;

use ORM ();

Moose::Exporter -> setup_import_methods( with_meta => [ 'has_field' ],
					 also      => 'Moose::Role' );

sub has_field { &LittleORM::__has_field_no_check( @_ ) }

no Moose::Exporter;
no Moose::Role;

-1;

