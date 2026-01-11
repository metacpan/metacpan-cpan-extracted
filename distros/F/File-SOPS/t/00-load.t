#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('File::SOPS');
use_ok('File::SOPS::Encrypted');
use_ok('File::SOPS::Metadata');
use_ok('File::SOPS::Backend::Age');
use_ok('File::SOPS::Format::YAML');
use_ok('File::SOPS::Format::JSON');

done_testing;
