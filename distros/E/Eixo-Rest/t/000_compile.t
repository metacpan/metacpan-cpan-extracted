use t::test_base;

use_ok "Eixo::Rest";

# check dependencies
exists $INC{"JSON.pm"} || BAIL_OUT("JSON module can't be loaded");
exists $INC{"LWP/UserAgent.pm"} || BAIL_OUT("LWP::UserAgent can't be loaded");
exists $INC{"Eixo/Base/Clase.pm"} || BAIL_OUT("Eixo::Base::Clase can't be loaded");

done_testing;
