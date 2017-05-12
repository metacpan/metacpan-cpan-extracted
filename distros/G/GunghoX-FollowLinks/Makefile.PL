use strict;
use inc::Module::Install;

name("GunghoX-FollowLinks");
all_from("lib/GunghoX/FollowLinks.pm");

requires('Gungho', '0.09005');
requires('HTML::Parser');
requires('HTML::Tagset');
requires('MIME::Types');
requires('Sub::Exporter');
requires('URI::Match');

build_requires('Test::More');
build_requires('URI');

tests('t/*.t t/*/*/*.t');
auto_install;
WriteAll;