#!/usr/bin/perl -w

use Test::More 'no_plan';

BEGIN { use_ok 'Gravatar::URL';
        use_ok 'Libravatar::URL'; }

my %interfaces = (
    libravatar => {
        func => \&libravatar_url,
        base => 'http://cdn.libravatar.org/avatar',
        https_base => 'https://seccdn.libravatar.org/avatar',
    },
    gravatar => {
        func => \&gravatar_url,
        base => 'http://www.gravatar.com/avatar',
        https_base => 'https://secure.gravatar.com/avatar',
    },
);

for my $interface_name (keys %interfaces) {
    my $interface = $interfaces{$interface_name};
    my $base = $interface->{base};
    my $https_base = $interface->{https_base};
    my $func = $interface->{func};

    my $id = 'a60fc0828e808b9a6a9d50f1792240c8';
    my $email = 'whatever@wherever.whichever';

    my @tests = (
        [{ email => $email },
         "$base/$id",
        ],
        
        [{ id => $id },
         "$base/$id",
        ],
        
        [{ email => $email,
           https => 1
         },
         "$https_base/$id",
        ],

        [{ email => $email,
           https => 0
         },
         "$base/$id",
        ],

        [{ email => $email,
           base  => 'http://example.com/gravatar'
         },
         "http://example.com/gravatar/$id",
        ],

        [{ email => $email,
           base  => 'http://example.com/gravatar',
           https => 1
         },
         "http://example.com/gravatar/$id",
        ],

        # Make sure we don't get a double slash after the base.
        [{ email => $email,
           base  => 'http://example.com/gravatar/'
         },
         "http://example.com/gravatar/$id",
        ],
        
        [{ default => "/local.png",
           email   => $email
         },
         "$base/$id?d=%2Flocal.png",
        ],
        
        [{ default => "/local.png",
           rating  => 'X',
           email   => $email,
         },
         "$base/$id?r=x&d=%2Flocal.png",
        ],
        
        [{ default  => "/local.png",
           email    => $email,
           rating   => 'R',
           size     => 80
         },
         "$base/$id?r=r&s=80&d=%2Flocal.png"
        ],

        [{ default => "/local.png",
           rating  => 'PG',
           size    => 45,
           email   => $email,
         },
         "$base/$id?r=pg&s=45&d=%2Flocal.png"
        ],

        [{ default => "/local.png",
           rating  => 'PG',
           size    => 45,
           email   => $email,
         },
         "$base/$id?r=pg&s=45&d=%2Flocal.png"
        ],

        [{ default => "/local.png",
           rating  => 'PG',
           size    => 45,
           email   => $email,
           short_keys => 1,
         },
         "$base/$id?r=pg&s=45&d=%2Flocal.png"
        ],
        [{ default => "/local.png",
           rating  => 'PG',
           size    => 45,
           email   => $email,
           short_keys => 0,
         },
         "$base/$id?rating=pg&size=45&default=%2Flocal.png"
        ],
    );

    # Add tests for the special defaults.
    for my $special ("identicon", "mm", "monsterid", "retro", "wavatar") {
        my $test = [{ default => $special,
                      email   => $email,
                    },
                    "$base/$id?d=$special",
                   ];
        push @tests, $test;
    }

    for my $test (@tests) {
        my($args, $url) = @$test;
        is &$func( %$args ), $url, join ", ", keys %$args;
    }
}
