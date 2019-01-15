use strict;
use warnings;

use Data::Dumper;

use Path::Tiny ();
use JSON::XS   ();
use Test::More;
use Test::Output;

use Devel::Probe (check_config_file => 0);

my @expected_lines = qw/ 34 36 /;
my @triggered;

exit main();

sub main {
    my $config = get_probe_config();
    Devel::Probe::set_config_name($config);

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        push @triggered, [ $file, $line ];
    });

    my $stderr = stderr_from {
        Devel::Probe::check_config_file();
    };
    foreach my $line (@expected_lines) {
        like($stderr, qr/dump line \[$line\]/, "probe dump contains line $line");
    }

    my $x = 1;          # probe #1
    my $y = 2;
    my $z = $x + $y;    # probe #2

    my @got_lines = map { $_->[1] } @triggered;
    is_deeply(\@got_lines, \@expected_lines, "probe triggered in all expected lines and nowhere else");

    done_testing;
    return 0;
}

sub get_probe_config {
    my $config = {
        actions => [
            { action => 'disable' },
            { action => 'clear' },
            {
                action => 'define',
                file => 't/007-trigger.t',  # this file
                lines => \@expected_lines,
            },
            { action => 'dump' },
            { action => 'enable' },
        ],
    };
    my $tmp = Path::Tiny->tempfile();
    $tmp->spew(JSON::XS->new->utf8->encode($config));
    return $tmp;
}
