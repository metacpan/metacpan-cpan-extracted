use Test::More tests => 10;

use HEP::Names::LaTeX 'particle_to_latex';

# real test would be to use all outputs of HEP::MCNS and compare
# but then, the expected output has to be formated manually
# at least this will probably fail if the func is changed in the wrong way

# 'normal' particle
is( particle_to_latex( "B+" ), '$B^{+}$', 'B+' );

# 'norma' anti-particle
is( particle_to_latex( "anti-B0" ), '$\bar{B}^{0}$', 'anti-B0' );

# with index
is( particle_to_latex( 'anti-B_10' ), '$\bar{B}_{1}^{0}$', 'anti-B_10' );

# with index and star + charge
is( particle_to_latex( 'anti-B_s0*0' ), '$\bar{B}_{s0}^{*0}$', 'anti-B_s0*0' );

# without charge, index, etc
is( particle_to_latex( 'X(3940)' ), '$X(3940)$', 'X(3940)' );

# with only '
is( particle_to_latex( "eta'" ), q($\eta^{'}$), "eta'" );

# with ' and charge and subscript
is( particle_to_latex( "anti-K'_10" ), q($\bar{K}_{1}^{'0}$), "anti-K'_10" );

# with 2 ' and charge
is( particle_to_latex( "K''*0" ), q($K^{''*0}$), "K''*0" );

# subscript escape
is( particle_to_latex( "nu_mu" ), q($\nu_{\mu}$), 'subscript escape' );

# array return
is_deeply [ particle_to_latex( 'B-', 'e+', 'rho-' ) ], [ q($B^{-}$), q($e^{+}$), q($\rho^{-}$) ], 'list-context';
