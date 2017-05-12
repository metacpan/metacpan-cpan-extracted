use strict;
use warnings;

use Test::Most;

use Getopt::Chain;

plan qw/no_plan/;

my (@arguments, $options, @path);

my $run = sub {
    my $context = shift;
    push @path, $context->command;
};

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
                my $context = shift;
                $context->run(qw/lime/);
            },
        },

        lime => sub {
            $run->(@_);
            cmp_deeply(scalar $_[0]->local_options, { qw/banana cherry/ });
        },
    },
);
cmp_deeply($options, { qw/apple 1 banana cherry/ });
cmp_deeply(\@path, [ undef, qw/grape lime/ ]);
