use Test::Effects;
use 5.014;

plan tests => 1;

use lib 'tlib';

{
    use SetterErrorModule;

    effects_ok { SetterErrorModule::dont_succeed() }
               { die => qr{\A \QCan't call ON_FAILURE after compilation at $SetterErrorModule::CROAK_LINE\E }xms }
               => 'runtime fail_width() sub';
};
