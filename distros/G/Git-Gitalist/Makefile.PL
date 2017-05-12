#!perl

use strict;
use warnings;
use inc::Module::Install 0.91;

name     'Git-Gitalist';
all_from 'lib/Git/Gitalist.pm';
author   'Dan Brook <dan@broquaint.com>';
abstract 'An interface to git influenced by Gitalist';
license  'perl';

resources repository => 'git://github.com/broquaint/Git-Gitalist.git';

# Standard deps
requires 'aliased'              => '0';
requires 'DateTime'             => '0';
requires 'File::Which'          => '0';
requires 'Git::PurePerl'        => '0.50';
requires 'IPC::Run'             => '0';
requires 'List::MoreUtils'      => '0';
requires 'namespace::autoclean' => '0';
requires 'Path::Class'          => '0';
requires 'Scalar::Util'         => '0';

# Syntax sugar
requires 'Method::Signatures' => '0';

# Moosery
requires 'Moose'                         => '0';
requires 'MooseX::Storage'               => '0';
requires 'MooseX::Types'                 => '0';
requires 'MooseX::Types::Common::String' => '0';
requires 'MooseX::Types::DateTime'       => '0';
requires 'MooseX::Types::Moose'          => '0';
requires 'MooseX::Types::Path::Class'    => '0';

# Testing
test_requires 'Test::More' => '0.88';

requires_external_bin 'git';

auto_install;

WriteAll;
