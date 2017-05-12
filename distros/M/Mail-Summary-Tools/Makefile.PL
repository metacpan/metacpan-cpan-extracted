#!/usr/bin/perl -w

use strict;

use inc::Module::Install;

name 'Mail-Summary-Tools';

perl_version '5.008'; # unicode

requires 'Moose'                       => '0.11';
requires 'App::Cmd'                    => '0.005';
requires 'Class::Autouse'              => 0;
requires 'Date::Range'                 => 0;
requires 'Date::Manip'                 => 0;
requires 'DateTime'                    => 0;
requires 'DateTime::Format::DateManip' => 0;
requires 'DateTime::Format::Mail'      => 0;
requires 'File::Save::Home'            => 0;
requires 'File::Slurp'                 => '9999.12'; # less warnings
requires 'File::Temp'                  => 0;
requires 'FindBin'                     => 0;
requires 'HTML::Entities'              => 0;
requires 'List::MoreUtils'             => 0;
requires 'Mail::Box'                   => 0;
requires 'Mail::ListDetector'          => 0;
requires 'Net::NNTP'                   => 0;
requires 'Path::Class'                 => 0;
requires 'Proc::InvokeEditor'          => 0;
requires 'Sub::Exporter'               => 0;
requires 'Template'                    => 0;
requires 'Text::Wrap'                  => 0;
requires 'Text::Markdown'              => 0;
requires 'URI::Escape'                 => 0;
requires 'URI::QueryParam'             => 0;
requires 'YAML::Syck'                  => '0.67';
requires 'WWW::Mechanize'              => 0;
requires 'WWW::Shorten'                => 0;

build_requires 'Test::More'    => 0;
build_requires 'Test::use::ok' => 0;
build_requires 'File::Temp'    => 0;

recommends 'YAML' => '0.62';

install_script 'script/mailsum';

license "MIT";

all_from 'lib/Mail/Summary/Tools.pm';

sign;

WriteAll;



