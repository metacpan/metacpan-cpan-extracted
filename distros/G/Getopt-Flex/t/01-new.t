use Getopt::Flex;
use Test::More tests => 55;
use Test::Exception;

use warnings;
use strict;

my $recurse = 0;
my $size = 0;
my $file = 'foo.txt';
my $foo = '';
my %rels = ();
my @list = ();

#good
lives_ok { Getopt::Flex->new({spec => {'recurse|r' => {'var' => \$recurse, 'type' => 'Bool'}}}) } 'Should not die';

#good, trying all options
lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
            'desc' => 'Describing this switch',
            'required' => 0,
            'validator' => sub { $_[0] =~ m/foo/ },
            'callback' => sub { print "foo" },
            'default' => 'foobar',
        },
    }})
} 'Should not die';

#try defaults with all types
lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
            'default' => 'foobar',
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
            'default' => 1,
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
            'default' => 1e2,
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
            'default' => sub { [] },
        }
    }})
} 'Dies with default does not pass type constraint';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
            'default' => sub { {} },
        }
    }})
} 'Dies with default does not pass type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Int',
            'default' => 0,
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Int',
            'default' => 2.2,
        }
    }})
} 'Dies with default fails type constraint';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Int',
            'default' => 'b',
        }
    }})
} 'Dies with default fails type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Bool',
            'default' => 1,
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Bool',
            'default' => '1',
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Bool',
            'default' => 'a',
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Bool',
            'default' => 2e4,
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Num',
            'default' => 2e10,
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Num',
            'default' => 100,
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Num',
            'default' => 'baa',
        }
    }})
} 'Dies with default does not pass type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Str]',
            'default' => sub { {'foo' => 'bar'} },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Str]',
            'default' => sub { {'foo' => 1} },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Str]',
            'default' => sub { {'foo' => 1e3} },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Int]',
            'default' => sub { {'foo' => 0} },
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Int]',
            'default' => sub { {'foo' => 'bar'} },
        }
    }})
} 'Dies with default does not pass type constraint';

dies_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Int]',
            'default' => sub { {'foo' => 2.3} },
        }
    }})
} 'Dies with default does not pass type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Num]',
            'default' => sub { {'foo' => 2e3} },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Num]',
            'default' => sub { {'foo' => 2} },
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'bar|b' => {
            'var' => \%rels,
            'type' => 'HashRef[Num]',
            'default' => sub { {'foo' => 'bar'} },
        }
    }})
} 'Dies with default does not pass type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Str]',
            'default' => sub { ['foo', 'bar', 'baz'] },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Str]',
            'default' => sub { [1, 2, 3] },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Str]',
            'default' => sub { [1e1, 2e2, 3e3] },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Int]',
            'default' => sub { [1, 2, 3] },
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Int]',
            'default' => sub { [1.1, 2.2, 3.3] },
        }
    }})
} 'Dies with default does not pass type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Num]',
            'default' => sub { [1e2, 2e3, 3e4] },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Num]',
            'default' => sub { [1.2, 2.3, 3.4] },
        }
    }})
} 'Should not die';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Num]',
            'default' => sub { [1, 2, 3] },
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \@list,
            'type' => 'ArrayRef[Num]',
            'default' => sub { ['foo', 'bar', 'baz'] },
        }
    }})
} 'Dies with default does not pass type constraint';

lives_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Inc',
            'default' => 0,
        }
    }})
} 'Should not die';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Inc',
            'default' => 2.2,
        }
    }})
} 'Dies with default fails type constraint';

dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Inc',
            'default' => 'b',
        }
    }})
} 'Dies with default fails type constraint';

dies_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \$foo,
            'type' => 'Str',
            'default' => 'ss||asas',
            'validator' => sub { $_[0] !~ m/\|\|/ },
        }
    }})
} 'Dies with default does not pass supplied validation check';

dies_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \$foo,
            'type' => 'Num',
            'default' => -1,
            'validator' => sub { $_[0] > 0 },
        }
    }})
} 'Dies with default does not pass supplied validation check';

lives_ok { Getopt::Flex->new({spec => {
        'baz|b' => {
            'var' => \$foo,
            'type' => 'Num',
            'default' => 10,
            'validator' => sub { $_[0] > 0 },
        }
    }})
} 'Should not die';

#dies, duplicate aliases
dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Str',
        },
        'file|f' => {
            'var' => \$file,
            'type' => 'Str',
        }
    }})
} 'Dies with duplicate alias';

#dies, missing 'type'
dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
        }
    }})
} 'Dies with missing required argument \'type\'';

#dies, illegal type
dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \$foo,
            'type' => 'Foo',
        }
    }})
} 'Dies with illegal type';

#dies, wrong ref type
dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \%rels,
            'type' => 'Str',
        }
    }})
} 'Dies with illegal type of var';

#dies, wrong ref type
dies_ok { Getopt::Flex->new({spec => {
        'foo|f' => {
            'var' => \@list,
            'type' => 'Str',
        }
    }})
} 'Dies with illegal type of var';

#no spec
dies_ok { Getopt::Flex->new() } 'Dies with no spec';

#bad, invalid SwitchSpec
dies_ok { Getopt::Flex->new({spec => {'sda&' => {'var' => \$recurse, 'type' => 'Bool'}}}) } 'Dies with invalid SwitchSpec';

#bad, invalid SwitchSpec
dies_ok { Getopt::Flex->new({spec => {'sda|s||a' => {'var' => \$recurse, 'type' => 'Bool'}}}) } 'Dies with invalid SwitchSpec';

#bad, invalid switch option
dies_ok { Getopt::Flex->new({spec => {'recurse|r' => {'var' => \$recurse, 'type' => 'Bool', 'cut' => 1}}}) } 'Dies with invalid option';

#bad, not even a hash->hash->etc
dies_ok { Getopt::Flex->new({spec => qw(foo bar baz)}) } 'Dies with not a hash ref';

#bad, wrong kind of hash
dies_ok { Getopt::Flex->new({spec => {'foo' => 'bar'}}) } 'Dies with invalid hash';

#bad, var is of wrong type
dies_ok { Getopt::Flex->new({spec => {'recurse|r' => {'var' => \$file, 'type' => 'Int', 'default' => 'cats'}}}) } 'Dies with default fails type constraint';

#bad, invalid config
dies_ok { Getopt::Flex->new({spec => {'foo|f' => {'var' => \$foo, 'type' => 'Int'}}, config => {'foo' => 'bar'}}) } 'Dies with invalid config';

#bad, invalid config
dies_ok { Getopt::Flex->new({spec => {'foo|f' => {'var' => \$foo, 'type' => 'Int'}}, config => {'bundling' => 1, 'long_option_mode' => 'SINGLE_OR_DOUBLE'}}) } 'Dies with invalid config';
