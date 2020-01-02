use lib 't/lib';
use JTTest;
use JSON::Transform::Grammar;
use XML::Invisible qw(make_parser);

*parse = make_parser(JSON::Transform::Grammar->new);

is_deeply_snapshot parse(<<'EOF'), 'array to hashes';
  "" <@ { "/$K/id":$V#`id` }
EOF

is_deeply_snapshot parse(<<'EOF'), 'hashes to array';
  "" <% [ $V@`id`:$K ]
EOF

is_deeply_snapshot parse(<<'EOF'), 'array identity non-implicit';
  "" <- "" <@ [ $V ]
EOF

is_deeply_snapshot parse(<<'EOF'), 'array identity';
  "" <@ [ $V ]
EOF

is_deeply_snapshot parse(<<'EOF'), 'hash identity';
  "" <% { $K:$V }
EOF

is_deeply_snapshot parse(<<'EOF'), 'hash move';
  "/destination" << "/source"
EOF

is_deeply_snapshot parse(<<'EOF'), 'hash copy';
  "/destination" <- "/source"
EOF

is_deeply_snapshot parse(<<'EOF'), 'hash copy with transform';
  "/destination" <- "/source" <@ [ $V@`order`:$K ]
EOF

is_deeply_snapshot parse(<<'EOF'), 'variable bind then replace';
  $defs <- "/definitions"
  "" <- $defs
EOF

done_testing;
