#!/usr/bin/env perl

use lib 'lib';
use strict;
use warnings;

use MarpaX::Grammar::Parser::Filer;

# ------------------------------------------------

MarpaX::Grammar::Parser::Filer -> new -> generate_trees;
