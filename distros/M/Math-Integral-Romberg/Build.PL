#!/usr/bin/env perl

use Module::Build;
Module::Build->new(
                   module_name => 'Math::Integral::Romberg',
                   license     => 'perl',
         )->create_build_script;
