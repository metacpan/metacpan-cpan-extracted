#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 20;

use_ok('LCFG::Build::Utils');

use_ok('LCFG::Build::Utils::Debian');

use_ok('LCFG::Build::Utils::RPM');

use_ok('LCFG::Build::Utils::OSXPkg');

use_ok('LCFG::Build::Tool');

use_ok('LCFG::Build::Tool::CheckMacros');

use_ok('LCFG::Build::Tool::DevDebianPkg');

use_ok('LCFG::Build::Tool::DebianPkg');

use_ok('LCFG::Build::Tool::DevOSXPkg');

use_ok('LCFG::Build::Tool::DevPack');

use_ok('LCFG::Build::Tool::DevRPM');

use_ok('LCFG::Build::Tool::GenDeb');

use_ok('LCFG::Build::Tool::MicroVersion');

use_ok('LCFG::Build::Tool::MajorVersion');

use_ok('LCFG::Build::Tool::MinorVersion');

use_ok('LCFG::Build::Tool::OSXPkg');

use_ok('LCFG::Build::Tool::Pack');

use_ok('LCFG::Build::Tool::RPM');

use_ok('LCFG::Build::Tool::SRPM');

use_ok('LCFG::Build::Tools');
