use strict;
use warnings;
use Test::More;
use File::Basename qw//;
use File::Spec;
use YAML qw//;
use List::Util qw/shuffle/;

use Duadua;

MAIN: {
    test_yaml(@{$_}) for shuffle get_yaml_list(@ARGV);
}

sub test_yaml {
    my ($dir, $test_yaml) = @_;

    note 'Load YAML: ' . $test_yaml;

    my $tests = YAML::LoadFile(File::Spec->catfile($dir, $test_yaml));

    for my $t (shuffle @{$tests}) {
        for my $k (keys %{$t}) {
            next unless $k =~ m!^is_!;
            $t->{$k} = $t->{$k} eq 'true' ? 1 : 0;
        }

        subtest $test_yaml => sub {
            test_ua($t);
        };
    }
}

sub test_ua {
    my ($t) = @_;

    my $d = Duadua->new($t->{ua});

    is $t->{ua}, $d->ua, $t->{ua};

    for my $i (qw/
        name
        is_bot
        is_ios
        is_android
        is_linux
        is_windows
        is_chromeos
    /) {
        is $d->$i, $t->{$i}, "$i, expect:$t->{$i}";
    }

    if (exists $t->{version}) {
        my $dv = Duadua->new($t->{ua}, { version => 1 });
        is $dv->version, $t->{version}, "version, expect:$t->{version}";
    }
}

sub get_yaml_list {
    my @args = @_;

    my $root_dir = File::Spec->catfile(
        File::Basename::dirname(__FILE__),
        'testset',
    );

    opendir my $rdh, $root_dir or die "Could not open $root_dir, $!";

    my @yaml_list;

    while (my $d = readdir $rdh) {
        next if $d =~ m!\.+!;
        my $test_dir = File::Spec->catfile(
            File::Basename::dirname(__FILE__),
            'testset',
            $d,
        );
        opendir my $tdh, $test_dir or die "Could not open $test_dir, $!";
        while (my $test_yaml = readdir $tdh) {
            next unless $test_yaml =~ m!.+\.yaml$!;
            next if scalar(@args) > 0 && !(grep { $test_yaml =~ m!\Q$_!i } @args);
            push @yaml_list, [$test_dir, $test_yaml];
        }
        closedir $tdh;
    }

    closedir $rdh;

    return @yaml_list;
}

done_testing;