use Test::More tests => 7;
BEGIN { use_ok('Math::GammaFunction') };

# I'm not going to test the R builtins.
# This is just to make sure the interfaces are there.

ok(Math::GammaFunction::log_gamma(5));
ok(Math::GammaFunction::gamma(5));
ok(Math::GammaFunction::faculty(4));
ok(Math::GammaFunction::psi(4));
ok(Math::GammaFunction::psi_derivative(4, 0));
ok(Math::GammaFunction::psi_derivative(4, 2));

