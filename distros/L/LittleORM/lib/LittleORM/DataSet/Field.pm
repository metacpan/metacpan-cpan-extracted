#!/usr/bin/perl

use strict;

package LittleORM::DataSet::Field;
use Moose;

has 'model' => ( is => 'rw', isa => 'Str' );
has 'dbfield' => ( is => 'rw', isa => 'Str' );
has 'value' => ( is => 'rw' );

__PACKAGE__ -> meta() -> make_immutable();

4243;
