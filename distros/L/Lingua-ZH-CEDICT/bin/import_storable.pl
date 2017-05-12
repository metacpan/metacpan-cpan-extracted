#!/usr/bin/perl -w

# Copyright (c) 2002 Christian Renz <crenz@web42.com>
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

# $Id: import_storable.pl,v 1.4 2002/08/13 21:38:13 crenz Exp $

use lib './lib';

use strict;
use warnings;
use Lingua::ZH::CEDICT;

my $dict = Lingua::ZH::CEDICT->new(source        => 'Textfile',
                                   filename      => './data/cedict_ts.u8',
				   targetCharset => "");

print "Reading CEDICT...\n";
$dict->init();

print "Converting to simplified characters...\n";
$dict->addSimpChar();

print "Storing dictionary data...\n";
my $store = Lingua::ZH::CEDICT->new(source   => 'Storable',
                                    filename => './lib/Lingua/ZH/CEDICT/CEDICT.store');

$store->importData($dict);

# eof ***********************************************************************
