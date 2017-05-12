#!/usr/bin/env perl
use inc::Module::Install;

name 'Gtk3-Ex-PdfViewer';
all_from 'lib/Gtk3/Ex/PdfViewer.pm';

requires 'File::Slurp';
requires 'Gtk3';
requires 'List::AllUtils';
requires 'Moose';
requires 'Poppler';

test_requires 'Test::More' => '0.42';

configure_requires 'Module::Install::AutoManifest';

auto_install;
auto_manifest;

WriteAll;
