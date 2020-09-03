use Test::Most tests => 41;

use Hyperscan::Database;

# compile nonsense mode
dies_ok { Hyperscan::Database->compile( "pattern", 0, -1 ) };

# compile multi mismatched lengths
dies_ok {
    Hyperscan::Database->compile_multi( [], [0], [0], Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( ["pattern"], [], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( ["pattern"], [0], [],
        Hyperscan::HS_MODE_BLOCK )
};

# compile multi invalid types
dies_ok {
    Hyperscan::Database->compile_multi( [0], [0], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( "pattern", [0], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( ["pattern"], ["0"], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( ["pattern"], 0, [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( ["pattern"], [0], ["0"],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_multi( ["pattern"], [0], 0,
        Hyperscan::HS_MODE_BLOCK )
};

# compile multi nonsense mode
dies_ok { Hyperscan::Database->compile_multi( ["pattern"], [0], [0], -1 ) };

# compile multi ext mismatched lengths
dies_ok {
    Hyperscan::Database->compile_ext_multi( [], [0], [0], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [], [0], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0], [],
        Hyperscan::HS_MODE_BLOCK )
};

# compile multi ext unvalid types
dies_ok {
    Hyperscan::Database->compile_ext_multi( [0], [0], [0], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( "pattern", [0], [0], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], ["0"], [0], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], 0, [0], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], ["0"], [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], 0, [ {} ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0], {},
        Hyperscan::HS_MODE_BLOCK )
};

# invalid ext types
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0],
        [ { min_offset => "0" } ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0],
        [ { max_offset => "0" } ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0],
        [ { min_length => "0" } ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0],
        [ { edit_distance => "0" } ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0],
        [ { hamming_distance => "0" } ],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0],
        [ { invalid => 1 } ],
        Hyperscan::HS_MODE_BLOCK )
};

# compile multi ext nonsense mode
dies_ok {
    Hyperscan::Database->compile_ext_multi( ["pattern"], [0], [0], [ {} ], -1 )
};

# compile lit nonsense mode
dies_ok { Hyperscan::Database->compile_lit( "pattern", 0, -1 ) };

# compile lit multi mismatched lengths
dies_ok {
    Hyperscan::Database->compile_lit_multi( [], [0], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( ["pattern"], [], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( ["pattern"], [0], [],
        Hyperscan::HS_MODE_BLOCK )
};

# compile lit multi invalid types
dies_ok {
    Hyperscan::Database->compile_lit_multi( [0], [0], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( "pattern", [0], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( ["pattern"], ["0"], [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( ["pattern"], 0, [0],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( ["pattern"], [0], ["0"],
        Hyperscan::HS_MODE_BLOCK )
};
dies_ok {
    Hyperscan::Database->compile_lit_multi( ["pattern"], [0], 0,
        Hyperscan::HS_MODE_BLOCK )
};

# compile lit multi nonsense mode
dies_ok { Hyperscan::Database->compile_lit_multi( ["pattern"], [0], [0], -1 ) };
