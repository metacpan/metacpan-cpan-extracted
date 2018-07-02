#!perl

use strict;
use warnings;

use Test::More;

# Prereqs-testing for File::ShareDir

TODO:
{
    local $TODO = "Just diagnostics ...";
    use_ok("CPAN::Meta") or plan skip_all => "Need CPAN::Meta for this test";
}

my $meta = CPAN::Meta->load_file(-d "xt" ? "MYMETA.json" : "META.json");

my $prereqs = $meta->effective_prereqs;
my %dups;
my %report;
my %len = (
    module => length("module"),
    want   => length("wanted"),
    have   => length("missing")
);

foreach my $phase (qw/configure build runtime test/, (-d "xt" ? "develop" : ()))
{
    foreach my $severity (qw/requires recommends suggests/)
    {
        my $reqs = $prereqs->requirements_for($phase, $severity);
        my @modules = sort $reqs->required_modules;
        @modules or next;

        $len{module} < length(" $phase / $severity ") and $len{module} = length(" $phase / $severity ");

        for my $module (@modules)
        {
            my $want = $reqs->{requirements}->{$module}->{minimum}->{original};
            defined $dups{$module} and $dups{$module} >= $want and next;

            $len{module} < length($module) and $len{module} = length($module);

            $dups{$module} = $want;
            $len{want} < length($want) and $len{want} = length($want);

            local $TODO = $severity eq "requires" ? undef : $severity;

            if (eval { require_ok($module) unless $module eq 'perl'; 1 })
            {
                my $version = $module eq 'perl' ? $] : $module->VERSION;
                $len{have} < length($version) and $len{have} = length($version);
                my $ok = ok($reqs->accepts_module($module, $version), "$module matches required $version");
                my $status = $ok ? "ok" : "not ok";
                $report{$phase}{$severity}{$module} = {
                    want   => $want,
                    have   => $version,
                    status => $status
                };
            }
            else
            {
                $report{$phase}{$severity}{$module} = {
                    want   => $want,
                    have   => "undef",
                    status => "missing"
                };
            }
        }
    }
}

diag sprintf("Requirements for %s version %s", $meta->name, $meta->version);

my $fmt_str = " %$len{module}s | %$len{have}s | %$len{want}s | %s";
my $sep_str = "-%$len{module}s-+-%$len{have}s-+-%$len{want}s-+---------";
diag(sprintf($fmt_str, qw(module version wanted status)));
foreach my $phase (qw/configure build runtime test/, (-d "xt" ? "develop" : ()))
{
    foreach my $severity (qw/requires recommends suggests/)
    {
        scalar keys %{$report{$phase}{$severity}} or next;
        my $cap = " $phase / $severity ";
        $cap .= "-" x ($len{module} - length($cap));
        diag(sprintf($sep_str, $cap, "-" x $len{have}, "-" x $len{want}));
        foreach my $module (sort keys %{$report{$phase}{$severity}})
        {
            my ($have, $want, $status) = @{$report{$phase}{$severity}{$module}}{qw(have want status)};
            diag(sprintf($fmt_str, $module, $have, $want, $status));
        }
    }
}
diag(sprintf($sep_str, "-" x $len{module}, "-" x $len{have}, "-" x $len{want}));

done_testing;
