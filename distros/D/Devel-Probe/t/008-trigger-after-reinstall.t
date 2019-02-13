use strict;
use warnings;
use Test::More;
use Devel::Probe;
my %probes = (
    fire_before_reinstall => [ 28, 29 ],
    skip_because_uninstalled => [ 31 ],
    fire_after_reinstall => [ 35, 36 ],
);

my @triggered;
sub probe {
    my ($file, $line) = @_;
    push @triggered, $line;
}

Devel::Probe::trigger(\&probe);

my $actions = [
    { action => "enable" },
    { action => "define", "file" => __FILE__, lines => $probes{fire_before_reinstall} },
    { action => "define", "file" => __FILE__, lines => $probes{skip_beacuse_uninstalled} },
    { action => "define", "file" => __FILE__, lines => $probes{fire_after_reinstall} },
];

Devel::Probe::config({actions => $actions});

my $x = 1; # probe 1
my $y = 2; # probe 2
Devel::Probe::remove();
my $z = $x + $y; # probe defined, but not fired -- Devel::Probe not active
Devel::Probe::install();
Devel::Probe::trigger(\&probe);
Devel::Probe::config({actions => $actions});
my $bar = $z * 42; # probe 3. should fire, but might not if we can't gracefully re-install
my $baz = $bar * 11; # probe 4. should fire, but might not if we can't gracefully re-install

is_deeply(
    \@triggered,
    [ @{$probes{fire_before_reinstall}}, @{$probes{fire_after_reinstall}} ],
    "exactly expected probes fired"
);

done_testing;
