#!/usr/bin/env perl -T

use strict;

use Time::HiRes 'sleep';
use Term::ANSIColor;
use Test::More tests => 2;

# For debugging only
# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '2.02';
    use_ok('Graphics::Framebuffer');
}

diag("\r ");
diag("\r" . colored(['blue'], q{   #####\    })  );
diag("\r" . colored(['blue'], q{  ##  __##\  })  );
diag("\r" . colored(['blue'], q{  ## /  \__| })  );
diag("\r" . colored(['blue'], q{  ## |####\  })  );
diag("\r" . colored(['blue'], q{  ## |\_## | })  );
diag("\r" . colored(['blue'], q{  ## |  ## | })  );
diag("\r" . colored(['blue'], q{  \######  | })  );
diag("\r" . colored(['blue'], q{   \______/  })  );
sleep .3;
diag("\r \e[8A\e[11C" . colored(['green'], q{ ########\  }));
diag("\r \e[11C"      . colored(['green'], q{  ##  ____\ }));
diag("\r \e[11C"      . colored(['green'], q{  ## |      }));
diag("\r \e[11C"      . colored(['green'], q{  #####\    }));
diag("\r \e[11C"      . colored(['green'], q{  ##  __|   }));
diag("\r \e[11C"      . colored(['green'], q{  ## |      }));
diag("\r \e[11C"      . colored(['green'], q{  ## |      }));
diag("\r \e[11C"      . colored(['green'], q{  \__|      }));
sleep .3;
diag("\r \e[8A\e[22C" . colored(['red'], q{ #######\   }));
diag("\r \e[22C"      . colored(['red'], q{ ##  __##\  }));
diag("\r \e[22C"      . colored(['red'], q{ ## |  ## | }));
diag("\r \e[22C"      . colored(['red'], q{ #######\ | }));
diag("\r \e[22C"      . colored(['red'], q{ ##  __##\  }));
diag("\r \e[22C"      . colored(['red'], q{ ## |  ## | }));
diag("\r \e[22C"      . colored(['red'], q{ #######  | }));
diag("\r \e[22C"      . colored(['red'], q{ \_______/  }));
sleep .3;

diag("\r" . colored(['cyan on_black'],                                     q{  _______        _   _              }));
diag("\r" . colored(['cyan on_black'],                                     q{ |__   __|      | | (_)             }));
diag("\r" . colored(['cyan on_black'],                                     q{    | | ___  ___| |_ _ _ __   __ _  }));
diag("\r" . colored(['cyan on_black'],                                     q{    | |/ _ \/ __| __| | '_ \ / _` | }));
diag("\r" . colored(['cyan on_black'],                                     q{    | |  __/\__ \ |_| | | | | (_| | }));
diag("\r" . colored(['cyan on_black'],                                     q{    |_|\___||___/\__|_|_| |_|\__, | }));
diag("\r" . colored(['cyan on_black'],                                     q{                              __/ | }));
diag("\r" . colored(['yellow on_black'], q{   Graphics::Framebuffer }) . colored(['cyan on_black'], q{    |___/  }));
diag("\r ");

our $F = Graphics::Framebuffer->new('RESET' => 0, 'SPLASH' => 0);
isa_ok($F,'Graphics::Framebuffer');

$F->acceleration(0);
$F->splash(2);

$F->acceleration(1);
$F->splash(2);
exit(0);
