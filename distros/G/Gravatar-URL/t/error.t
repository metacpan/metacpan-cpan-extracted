#!/usr/bin/perl -w

# Test argument error handling.

use strict;

use Test::More 'no_plan';

BEGIN { use_ok 'Gravatar::URL' }

my @tests = (
    [ {},
      "Cannot generate a Gravatar URI without an email address or gravatar id"
    ],

    [ { email => 'foo@bar.com', id => '12345' },
      "Both an id and an email were given.  gravatar_url() only takes one"
    ],

    [ { email => 'foo@bar.com', rating => 'Q' },
      "Gravatar rating can only be g, pg, r, or x"
    ],

    [ { email => 'foo@bar.com', size => 0 },
      "Gravatar size must be 1 .. 512"
    ],

    [ { email => 'foo@bar.com', size => 1 } ],
    [ { email => 'foo@bar.com', size => 512 } ],

    [ { email => 'foo@bar.com', size => 513 },
      "Gravatar size must be 1 .. 512"
    ],
);

for my $test (@tests) {
    my($args, $want) = @$test;
    
    eval { gravatar_url( %$args ) };

    my $error = $@;
    $error =~ s/\.\n/\n/;
    $want  = !$want ? ""
                    : sprintf "%s at %s line %d\n", $want, $0, __LINE__ - 5;

    my $name = join ", ", map { "$_ => '$args->{$_}'" } keys %$args;
    is $error, $want, "gravatar_url($name)";
}
