# -*- mode: perl; coding: utf-8 -*-

requires perl => '>= 5.010';

requires 'rlib'; # XXX:

requires 'JSON::MaybeXS';

recommends 'Module::Runtime';
recommends 'YAML::Syck';
recommends 'Cpanel::JSON::XS', '>= 4.05';

recommends 'File::AddInc';

on configure => sub {
  requires 'rlib';
  requires 'Module::Build';
  requires 'Module::Build::Pluggable';
  requires 'Module::CPANfile';
};

on build => sub {
  requires 'rlib'; # XXX:
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
