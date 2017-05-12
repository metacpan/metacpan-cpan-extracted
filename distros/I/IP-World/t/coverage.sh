#!/bin/sh

cover -delete
perl Build.PL --extra-compiler-flags "-O0 --coverage" --extra-linker-flags "--coverage"
HARNESS_PERL_SWITCHES=-MDevel::Cover ./Build test
cover -ignore_re \(Builder\|/CORE/\\w+\\\.h$\)
