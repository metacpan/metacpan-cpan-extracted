# -*- mode: perl; coding: utf-8 -*-

requires perl => '>= 5.010';

requires 'JSON::MaybeXS';

requires 'Sub::Util', '>= 1.40'; # For subname

recommends 'Module::Runtime';
recommends 'YAML::Syck';
recommends 'Cpanel::JSON::XS', '>= 4.05';

recommends 'File::AddInc';

recommends 'Data::Dumper', '>= 2.160';

on configure => sub {
  requires 'rlib';
};

on build => sub {
  requires 'rlib';
  requires 'Module::Build', '>= 0.42';
  requires 'Module::Build::Pluggable::CPANfile';
  requires 'JSON::PP', '>= 2.273';
};

on test => sub {
  requires 'Test::More', '>= 1.3021';
  requires 'Test::Kantan';
  requires 'Capture::Tiny';
  requires 'Test::Output';
  requires 'Test::Exit';
  requires 'YAML::Syck';
  requires 'Cpanel::JSON::XS', '>= 4.05';
};
