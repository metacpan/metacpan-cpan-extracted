use strict;
use warnings;

use Test2::Tools::Tiny;

use ok 'H';

{

    package my_t;

    sub scal { 'x' }
    sub udef { undef }
    sub list { qw/a b c d/ }
    sub arra { @{[qw/a b c d/]} }
    sub none { () }
}

my $x = bless {}, 'my_t';

tests H => sub {
    is_deeply({$x->H::scal}, {scal => 'x'},   "H scalar");
    is_deeply({$x->H::udef}, {udef => undef}, "H undef");
    is_deeply({$x->H::list}, {list => 'd'},   "H list");
    is_deeply({$x->H::arra}, {arra => 4},     "H array");
    is_deeply({$x->H::none}, {none => undef}, "H none");

    is_deeply({$x->h::scal}, {scal => 'x'},   "h scalar");
    is_deeply({$x->h::udef}, {udef => undef}, "h undef");
    is_deeply({$x->h::list}, {list => 'd'},   "h list");
    is_deeply({$x->h::arra}, {arra => 4},     "h array");
    is_deeply({$x->h::none}, {none => undef}, "h none");
};

tests HS => sub {
    is_deeply({$x->HS::scal}, {scal => 'x'},   "HS scalar");
    is_deeply({$x->HS::udef}, {udef => undef}, "HS undef");
    is_deeply({$x->HS::list}, {list => 'd'},   "HS list");
    is_deeply({$x->HS::arra}, {arra => 4},     "HS array");
    is_deeply({$x->HS::none}, {none => undef}, "HS none");

    is_deeply({$x->hs::scal}, {scal => 'x'},   "hs scalar");
    is_deeply({$x->hs::udef}, {udef => undef}, "hs undef");
    is_deeply({$x->hs::list}, {list => 'd'},   "hs list");
    is_deeply({$x->hs::arra}, {arra => 4},     "hs array");
    is_deeply({$x->hs::none}, {none => undef}, "hs none");
};

tests HD => sub {
    is_deeply({$x->HD::scal}, {scal => 'x'}, "HD scalar");
    is_deeply({$x->HD::list}, {list => 'd'}, "HD list");
    is_deeply({$x->HD::arra}, {arra => 4},   "HD array");
    is_deeply({$x->HD::udef}, {}, "HD undef");
    is_deeply({$x->HD::none}, {}, "HD none");

    is_deeply({$x->hd::scal}, {scal => 'x'}, "hd scalar");
    is_deeply({$x->hd::list}, {list => 'd'}, "hd list");
    is_deeply({$x->hd::arra}, {arra => 4},   "hd array");
    is_deeply({$x->hd::udef}, {}, "hd undef");
    is_deeply({$x->hd::none}, {}, "hd none");
};

tests HF => sub {
    is_deeply({$x->HF::scal}, {scal => 'x'},   "HF scalar");
    is_deeply({$x->HF::udef}, {udef => undef}, "HF undef");
    is_deeply({$x->HF::list}, {list => 'a'},   "HF list");
    is_deeply({$x->HF::arra}, {arra => 'a'},   "HF array");
    is_deeply({$x->HF::none}, {}, "HF none");

    is_deeply({$x->hf::scal}, {scal => 'x'},   "hf scalar");
    is_deeply({$x->hf::udef}, {udef => undef}, "hf undef");
    is_deeply({$x->hf::list}, {list => 'a'},   "hf list");
    is_deeply({$x->hf::arra}, {arra => 'a'},   "hf array");
    is_deeply({$x->hf::none}, {}, "hf none");
};

tests HL => sub {
    is_deeply({$x->HL::scal}, {scal => 'x'},   "HL scalar");
    is_deeply({$x->HL::udef}, {udef => undef}, "HL undef");
    is_deeply({$x->HL::list}, {list => 'd'},   "HL list");
    is_deeply({$x->HL::arra}, {arra => 'd'},   "HL array");
    is_deeply({$x->HL::none}, {}, "HL none");

    is_deeply({$x->hl::scal}, {scal => 'x'},   "hl scalar");
    is_deeply({$x->hl::udef}, {udef => undef}, "hl undef");
    is_deeply({$x->hl::list}, {list => 'd'},   "hl list");
    is_deeply({$x->hl::arra}, {arra => 'd'},   "hl array");
    is_deeply({$x->hl::none}, {}, "hl none");
};

tests HA => sub {
    is_deeply({$x->HA::scal}, {scal => ['x']},         "HA scalar");
    is_deeply({$x->HA::udef}, {udef => [undef]},       "HA undef");
    is_deeply({$x->HA::list}, {list => [qw/a b c d/]}, "HA list");
    is_deeply({$x->HA::arra}, {arra => [qw/a b c d/]}, "HA array");
    is_deeply({$x->HA::none}, {none => []},            "HA none");

    is_deeply({$x->ha::scal}, {scal => ['x']},         "ha scalar");
    is_deeply({$x->ha::udef}, {udef => [undef]},       "ha undef");
    is_deeply({$x->ha::list}, {list => [qw/a b c d/]}, "ha list");
    is_deeply({$x->ha::arra}, {arra => [qw/a b c d/]}, "ha array");
    is_deeply({$x->ha::none}, {none => []},            "ha none");
};

tests HH => sub {
    # This is to hide the warnings for {undef, undef} in this file, it
    # intentionally does nothing about the warnings in HH.pm.
    no warnings 'uninitialized';

    my $line;
    my $warnings = warnings {
        $line = __LINE__ + 1;
        is_deeply({$x->HH::scal}, {scal => {'x' => undef}}, "HH scalar");
    };
    is_deeply(
        $warnings,
        ["Odd number of elements in hash assignment at t/test.t (Via HH::scal()) line $line.\n"],
        "Got the expected warning"
    );

    $warnings = warnings {
        $line = __LINE__ + 1;
        is_deeply({$x->HH::udef}, {udef => {undef, undef}}, "HH undef");
    };
    is_deeply(
        $warnings,
        [
            "Odd number of elements in hash assignment at t/test.t (Via HH::udef()) line $line.\n",
            "Use of uninitialized value in list assignment at t/test.t (Via HH::udef()) line $line.\n"
        ],
        "Got the expected warnings"
    );

    is_deeply({$x->HH::list}, {list => {qw/a b c d/}}, "HH list");
    is_deeply({$x->HH::arra}, {arra => {qw/a b c d/}}, "HH array");
    is_deeply({$x->HH::none}, {none => {}},            "HH none");

    $warnings = warnings {
        $line = __LINE__ + 1;
        is_deeply({$x->hh::scal}, {scal => {'x' => undef}}, "hh scalar");
    };
    is_deeply(
        $warnings,
        ["Odd number of elements in hash assignment at t/test.t (Via hh::scal()) line $line.\n"],
        "Got the expected warning"
    );

    $warnings = warnings {
        $line = __LINE__ + 1;
        is_deeply({$x->hh::udef}, {udef => {undef, undef}}, "hh undef");
    };
    is_deeply(
        $warnings,
        [
            "Odd number of elements in hash assignment at t/test.t (Via hh::udef()) line $line.\n",
            "Use of uninitialized value in list assignment at t/test.t (Via hh::udef()) line $line.\n"
        ],
        "Got the expected warnings"
    );

    is_deeply({$x->hh::list}, {list => {qw/a b c d/}}, "hh list");
    is_deeply({$x->hh::arra}, {arra => {qw/a b c d/}}, "hh array");
    is_deeply({$x->hh::none}, {none => {}},            "hh none");
};

done_testing;
