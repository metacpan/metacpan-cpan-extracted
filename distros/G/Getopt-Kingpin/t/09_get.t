use strict;
use Test::More 0.98;
use Test::Exception;
use Getopt::Kingpin;


subtest 'get' => sub {
    local @ARGV;
    push @ARGV, qw(--name=kingpin);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->flag('name', 'set name')->string();

    $kingpin->parse;

    my $name = $kingpin->flags->get('name');
    is ref $name, 'Getopt::Kingpin::Flag';
    is $name, 'kingpin';
};

subtest 'args get' => sub {
    local @ARGV;
    push @ARGV, qw(kingpin);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->arg('name', 'set name')->string();

    $kingpin->parse;

    my $name = $kingpin->args->get_by_index(0);
    is ref $name, 'Getopt::Kingpin::Arg';
    is $name, 'kingpin';

    my $name2 = $kingpin->args->get("name");
    is ref $name2, 'Getopt::Kingpin::Arg';
    is $name2, 'kingpin';

    ok not defined $kingpin->args->get_by_index(1);

    throws_ok {
        $kingpin->args->get("xyz");
    } qr/failed/;
};

done_testing;

