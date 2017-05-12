package DZPA::Main;
# ABSTRACT: dumb module to test DZPA

# perl minimum version
use 5.008;

# core modules
use strict;
use warnings;

# modern core module, which only exists in
# Perl 5.10.1 and above
use mro 1.01;

# modern core "dual-life" module, which only exists in
# Perl 5.10.0 and above, so would be removed because of
# the above mro -> Perl elevation
use Module::Load 0.12;

# modern core "dual-life" module that is too high a version
# to be removed
use Module::Metadata;

# core deprecated module
# (or removed; same result either way)
use Shell;

# Modules that exist in CPAN with a similar namespace,
# but are separate distributions
use Acme::Prereq::A;
use Acme::Prereq::B;
use Acme::Prereq::None;

# Modules that exist in CPAN with a similar namespace,
# and they are on the same distribution
use Acme::Prereq::BigDistro::Deeper::A 0.01;
use Acme::Prereq::BigDistro::Deeper::B;
use Acme::Prereq::BigDistro::B;

# Modules that exist in CPAN with a different namespace,
# and they are on the same distribution as above
use Acme::Prereq::AnotherNS::Deeper::C;
use Acme::Prereq::AnotherNS::Deeper::B;
use Acme::Prereq::AnotherNS::B;
use Acme::Prereq::AnotherNS::C;

# This only exists in 0.02
use Acme::Prereq::AnotherNS;

# imaginary DZPA module, not in CPAN
use DZPA::NotInDist;

# DZPA::Skip should be trimmed
use DZPA::Skip::Blah;

42;
