#!/usr/bin/perl
use Test::Spec;

use Karel::Parser;
use Karel::Robot;

describe 'Karel::Parser' => sub {

    it 'instantiates' => sub {
        my $p = 'Karel::Parser'->new;
        isa_ok $p, 'Karel::Parser';
    };
};

describe 'Karel::Robot with Karel::Robot' => sub {

    my $WHILE_LOOP = << '__EOF__';
command test
while not facing West
    left
done
end
__EOF__

    my $NESTED_IF = << '__EOF__';
command to-north
    repeat 3 x
        if not facing North
            right
        else
            stop
        done
    done
end
__EOF__

    my ($r, $p);
    before each => sub {
        $r = 'Karel::Robot'->new;
        $p = 'Karel::Parser'->new;
        $r->set_grid('Karel::Grid'->new(x => 5, y => 4), 3, 1, 'S');
    };

    describe 'privately' => sub {

        my $command;

        shared_examples_for 'learned' => sub {
            before each => sub {
                my ($parsed) = $p->parse($command);
                $r->_learn(%$parsed, $command);
            };

            it 'learns the command' => sub {
                ok $r->knows('test');
            };

            it 'runs the command' => sub {
                $r->_run([ ['c', 'test'] ]);
                $r->step while $r->is_running;
                is $r->direction, 'W';
            };
        };

        describe 'simple commands' => sub {
            before all => sub {
                $command = 'command test left left left end';
            };
            it_should_behave_like 'learned';
        };

        describe 'repeat loop' => sub {
            before all => sub {
                $command = 'command test repeat 3 times left done end';
            };
            it_should_behave_like 'learned';
        };

        describe 'while loop' => sub {
            before all => sub {
                $command = $WHILE_LOOP;
            };
            it_should_behave_like 'learned';
        };
    };

    describe 'unknown' => sub {
        it 'is propagated' => sub {
            my $command = 'command test while not facing West right done end';
            my ($parsed, $unknown) = $p->parse($command);
            cmp_deeply $unknown, { right => 1 };

            $r->_learn(%$parsed, $command);
        };
    };

    describe 'negation' => sub {
        it 'runs' => sub {
            my ($to_wall)= $p->parse( my $command
                = "command to-wall while there isn't a wall forward done end");

            $r->_learn(%$to_wall, $command);
            $r->_run([ ['c', 'to-wall'] ]);
            $r->step while $r->is_running;

            cmp_methods $r, [ y => 4,
                              facing => 'W',
                            ];
        };
    };

    describe 'nested if with unknown' => sub {
        it 'runs' => sub {
            my $command = 'command right repeat 3 x left done end';
            $r->_learn(%{ ($p->parse($command))[0] }, $command);
            my ($parse, $unknown) = $p->parse($NESTED_IF);

            my ($command_name, $command_def) = %$parse;
            $r->_learn($command_name, $command_def, $command);
            cmp_deeply $unknown, { right => 1 };
            cmp_methods $r, [ map { [ 'knows', $_ ] => bool(1) }
                              qw( right to-north )];

            $r->_run([ ['c', 'to-north'] ]);
            $r->step while $r->is_running;
            is $r->direction, 'N';
        };
    };

    describe 'dropping' => sub {

        it 'runs' => sub {
            $r->set_grid('Karel::Grid'->new( x => 1, y => 1 ), 1, 1, 'N');
            my $command = << '__EOF__';
command safe-step
    if there's no wall
        forward
    done
end
command drop9
    repeat 4 times
        repeat 2 times
            drop-mark
        done
    done
    pick-mark
    repeat 2 x
        drop-mark
    done
end
__EOF__

            my ($d9_ss, $unknown) =  $p->parse($command);
            for my $name (keys %$d9_ss) {
                $r->_learn($name, $d9_ss->{$name}, $command);
            }

            cmp_deeply $unknown, {};

            $r->_run([ ['c', 'drop9' ] ]);
            $r->step while $r->is_running;
            is $r->cover, 9;

            $r->run('left');
            $r->step while $r->is_running;
            is $r->direction, 'W';
        };

    };

    describe 'core' => sub {
        it 'runs directly' => sub {
            $r->set_grid('Karel::Grid'->new( x => 1, y => 1 ), 1, 1, 'N');
            $r->run('left');
            $r->step while $r->is_running;
            is $r->direction, 'W';
        };
    };

    describe 'comments' => sub {
        they 'are ignored' => sub {
            my $code = << '__EOF__';
command run
# testing comment 'blah'
    while there's no # wait for it!
                     wall
        forward
    done
end
__EOF__

            my ($with_comment)    = $p->parse($code);
            my ($without_comment) = $p->parse(do {
                (my $code2 = $code) =~ s/#.*\n?//g;
                $code2
            });

            # Different position in the input string.
            $_ = ignore for $without_comment->{run}[0][0][2][0][1],
                            $without_comment->{run}[0][0][3],
                            @{ $without_comment->{run} }[ 1, 2 ];

            cmp_deeply $with_comment, $without_comment;
        };
    };
};

describe 'failures' => sub {

    my @valid = do { no warnings 'qw';
                     qw( alpha left forward drop-mark pick-mark stop
                         repeat while if # space )
                 };

    my ($E, $command, $expected_exception);
    shared_examples_for 'failure' => sub {
        it fails => sub {
            my $p = 'Karel::Parser'->new;
            trap { $p->parse($command) };
            $E = $trap->die;
            isa_ok $E, 'Karel::Parser::Exception';
            $expected_exception->{pos} //= [ 1, 1 + length $command ];
            cmp_deeply $E, noclass($expected_exception);
        };
    };

    describe 'unfinished body' => sub {
        before all => sub {
            $command = << '__EOF__';
command wrong
while there's a wall
  forward
__EOF__

            $expected_exception = { last_completed => 'forward',
                                    expected => bag(@valid, 'done'),
                                    pos => [ 3, 11 ],
                                };
        };
        it_should_behave_like 'failure';
    };

    describe 'missing end' => sub {
        before all => sub {
            $command = "command wrong while there's a wall forward done\n";
            $expected_exception = { last_completed => re(qr/while .* done/xs),
                                    expected => bag(@valid, 'end'),
                                };
        };
        it_should_behave_like 'failure';
    };

    describe 'missing times' => sub {
        before all => sub {
            $command = 'command wrong repeat 3 ';
            $expected_exception = {
                expected => bag(do {
                    no warnings 'qw';
                    qw( times x space # )
                }),
            };
        };
        it_should_behave_like 'failure';
    };

    describe 'missing condition' => sub {
        before all => sub {
            $command = 'command wrong while ';
            $expected_exception = {
                expected => bag(do {
                    no warnings 'qw';
                    qw( facing not there space # )
                }),
            };
        };
        it_should_behave_like 'failure';
    };

    describe 'missing verb' => sub {
        before all => sub {
            $command = 'command wrong if there';
            $expected_exception = {
                expected => bag(do {
                    no warnings 'qw';
                    qw( quote space # )
                }),
            };
        };
        it_should_behave_like 'failure';
    };

    describe 'missing verb' => sub {
        before all => sub {
            $command = 'command wrong if there ';
            $expected_exception = {
                expected => bag(do {
                    no warnings 'qw';
                    qw( is isn space # )
                }),
            };
        };
        it_should_behave_like 'failure';
    };


};

runtests();
