use strict;
use warnings;

#use Test::Trap;
use Test::Most;
plan qw/no_plan/;

use Getopt::Chain;

my (@arguments, $options, @path);

my $run = sub {
    my $context = shift;
    push @path, $context->command;
};

undef @path;
@arguments = qw/--apple/;
$options = Getopt::Chain->process(\@arguments, 
    options => [ qw/apple/ ],
);
cmp_deeply($options, { qw/apple 1/ });

undef @path;
@arguments = qw/--apple --banana cherry/;
$options = Getopt::Chain->process(\@arguments, 
    options => [ qw/apple banana:s/ ],
);
cmp_deeply($options, { qw/apple 1 banana cherry/ });

undef @path;
@arguments = qw/--apple grape --banana cherry/;
$options = Getopt::Chain->process(\@arguments, 
    options => [ qw/apple/ ],
    run => $run,
    commands => {
        grape => {
            options => [ qw/banana:s/ ],
            run => sub {
                $run->(@_);
                cmp_deeply(scalar $_[0]->local_options, { qw/banana cherry/ });
            },
        },
    },
);
cmp_deeply($options, { qw/apple 1 banana cherry/ });
cmp_deeply(\@path, [ undef, qw/grape/ ]);

undef @path;
@arguments = qw/--apple grape --banana cherry lime mango berry --orange/;
$options = Getopt::Chain->process(\@arguments, 
    options => [ qw/apple/ ],
    run => $run,
    commands => {
        grape => {
            options => [ qw/banana:s/ ],
            run => sub {
                $run->(@_);
                cmp_deeply(scalar $_[0]->local_options, { qw/banana cherry/ });
            },
            commands => {
                lime => {
                    run => $run,
                    commands => {
                        mango => {
                            run => $run,
                            commands => {
                                berry => {
                                    options => [ qw/orange/ ],
                                    run => sub {
                                        $run->(@_);
                                        cmp_deeply(scalar $_[0]->local_options, { qw/orange 1 / });
                                    },
                                },
                            },
                        },

                        herring => {},
                    },
                },
            },
        },
    },
);
cmp_deeply($options, { qw/apple 1 banana cherry orange 1/ });
cmp_deeply(\@path, [ undef, qw/grape lime mango berry/ ]);

#trap {
#    Getopt::Chain->process([],
#        run => sub {
#            shift->abort("Abort test");
#        },
#    );
#};
#is($trap->exit, -1);

@arguments = qw/--apple grape 1 2 3 4 5/;
$options = Getopt::Chain->process(\@arguments, 
    options => [ qw/apple/ ],
    run => $run,
    commands => {
        grape => {
            options => [ qw/banana:s/ ],
            run => sub {
                my $context = shift;
                cmp_deeply(\@_, [qw/1 2 3 4 5/]);
            },
        },
    },
);
