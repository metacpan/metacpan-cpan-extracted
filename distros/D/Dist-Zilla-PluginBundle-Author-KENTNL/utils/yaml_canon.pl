#!/usr/bin/env perl
# FILENAME: yaml_canon.pl
# CREATED: 01/02/15 12:13:58 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Canonicalise a YAML file

use strict;
use warnings;
use utf8;

use YAML;
my $content = YAML::LoadFile( $ARGV[0] );
YAML::DumpFile( $ARGV[0], $content );
