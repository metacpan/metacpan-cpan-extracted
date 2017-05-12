#!/usr/bin/perl -w

use strict;
use warnings;
use List::Util qw/sum/;
use Test::More;
use Test::Warnings;
use Getopt::Alt;
use Data::Dumper qw/Dumper/;

my $opt = Getopt::Alt->new(
    {
        bundle => 1,
    },
    [
        'plain|p',
        'inc|i+',
        'negate|n!',
        'string|s=s',
        'integer|I=i',
        'float|f=f',
        'array|a=i@',
        'hash|h=s%',
        'null|N=i?',
        'value|v=[yes|auto|no]',
        'count|c++',
    ],
);

my @argv = argv();

for my $argv ( @argv ) {
    my $argv_str = join ' ', @{ $argv->[0] };
    eval { $opt->process( @{ $argv->[0] } ) };
    diag $@ if $@;
    ok !$@, "No errors for  $argv_str"
        or BAIL_OUT('Could not process the values: ' . join ', ', @{ $argv->[0] });

    for my $test ( keys %{ $argv->[1] } ) {
        if ( $test eq 'has' ) {
            ok exists $opt->opt->{$argv->[1]{$test}}, "$argv_str is set";
        }
        elsif ( ref $argv->[1]{$test} ) {
            is_deeply $opt->opt->{$test}, $argv->[1]{$test}, "$test $argv_str" or BAIL_OUT(2);
        }
        else {
            is $opt->opt->{$test}, $argv->[1]{$test}, "$test $argv_str" or BAIL_OUT(3);
        }
    }
}
done_testing();

sub argv {
    return (
        [ [ qw/--plain      / ] => { plain   => 1                    } ],
        [ [ qw/ -p          / ] => { plain   => 1                    } ],
        [ [ qw/ -pp         / ] => { plain   => 1                    } ],
        [ [ qw/--inc        / ] => { inc     => 1                    } ],
        [ [ qw/-i           / ] => { inc     => 1                    } ],
        [ [ qw/--inc --inc  / ] => { inc     => 2                    } ],
        [ [ qw/-ii          / ] => { inc     => 2                    } ],
        [ [ qw/--negate     / ] => { negate  => 1                    } ],
        [ [ qw/--no-negate  / ] => { negate  => 0                    } ],
        [ [ qw/-n           / ] => { negate  => 1                    } ],
        [ [ qw/--string=ab  / ] => { string  => 'ab'                 } ],
        [ [ qw/--string cd  / ] => { string  => 'cd'                 } ],
        [ [ qw/ -sef        / ] => { string  => 'ef'                 } ],
        [ [ qw/ -s gh       / ] => { string  => 'gh'                 } ],
        [ [ qw/ -s=ij       / ] => { string  => 'ij'                 } ],
        [ [ qw/ -s =k       / ] => { string  => '=k'                 } ],
        [ [ qw/--integer=10 / ] => { integer => 10                   } ],
        [ [ qw/--integer 9  / ] => { integer => 9                    } ],
        [ [ qw/ -I8         / ] => { integer => 8                    } ],
        [ [ qw/ -I 7        / ] => { integer => 7                    } ],
        [ [ qw/ -I=6        / ] => { integer => 6                    } ],
        [ [ qw/ -I-5        / ] => { integer => -5                   } ],
        [ [ qw/ -I -4       / ] => { integer => -4                   } ],
        [ [ qw/ -I=-3       / ] => { integer => -3                   } ],
        [ [ qw/--integer=-2 / ] => { integer => -2                   } ],
        [ [ qw/--integer -1 / ] => { integer => -1                   } ],
        [ [ qw/--float=9.1  / ] => { float   => 9.1                  } ],
        [ [ qw/--float 8.2  / ] => { float   => 8.2                  } ],
        [ [ qw/ -f7.3       / ] => { float   => 7.3                  } ],
        [ [ qw/ -f 6.4      / ] => { float   => 6.4                  } ],
        [ [ qw/ -f=5.5      / ] => { float   => 5.5                  } ],
        [ [ qw/ -f-4.6      / ] => { float   => -4.6                 } ],
        [ [ qw/ -f -3.7     / ] => { float   => -3.7                 } ],
        [ [ qw/ -f=-2.8     / ] => { float   => -2.8                 } ],
        [ [ qw/--float=-1.9 / ] => { float   => -1.9                 } ],
        [ [ qw/--float -0.10/ ] => { float   => '-0.10'              } ],
        [ [ qw/-a 1         / ] => { array   => [1]                  } ],
        [ [ qw/-a 1 -a 2    / ] => { array   => [1,2]                } ],
        [ [ qw/-a=3         / ] => { array   => [3]                  } ],
        [ [ qw/-h h=a       / ] => { hash    => {h=>'a'        }     } ],
        [ [ qw/-h h=b -h i=c/ ] => { hash    => {h=>'b', i=>'c'}     } ],
        [ [ qw/-h=a=b       / ] => { hash    => { a => 'b'     }     } ],
        [ [ qw/ -N          / ] => { null    => undef, has => 'null' } ],
        [ [ qw/ -N 7        / ] => { null    => 7                    } ],
        [ [ qw/ -N=6        / ] => { null    => 6                    } ],
        [ [ qw/ -N-5        / ] => { null    => -5                   } ],
        [ [ qw/ -N -4       / ] => { null    => -4                   } ],
        [ [ qw/ -N=-3       / ] => { null    => -3                   } ],
        [ [ qw/ --null      / ] => { null    => undef, has => 'null' } ],
        [ [ qw/ --null 3    / ] => { null    => 3                    } ],
        [ [ qw/ --null=2    / ] => { null    => 2                    } ],
        [ [ qw/ --null -6   / ] => { null    => -6                   } ],
        [ [ qw/ --null=-7   / ] => { null    => -7                   } ],
        [ [ qw/ --value=yes / ] => { value   => 'yes'                } ],
        [ [ qw/ --value=auto/ ] => { value   => 'auto'               } ],
        [ [ qw/ -v=no       / ] => { value   => 'no'                 } ],
        [ [ qw/ --count 1   / ] => { count   => 1                    } ],
        [ [ qw/--10         / ] => { count   => 10                   } ],
        [ [ qw/ -11         / ] => { count   => 11                   } ],
        [ [ qw/ -0          / ] => { count   => 0                    } ],
    );
}
