use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use PadWalker 'closed_over';
use Module::CoreList 3.06;  # for is_core
use Dist::Zilla::Plugin::DynamicPrereqs;

# test that all prereqs are dual-life - that is, we do not ever add a
# configure_requires on unreasonable things

my $latest_release = (reverse sort keys %Module::CoreList::released)[0];

my $sub_prereqs = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::register_prereqs)->{'%sub_prereqs'};
foreach my $sub (keys %$sub_prereqs)
{
    foreach my $module (keys %{$sub_prereqs->{$sub}})
    {
        ok(
            Module::CoreList::is_core($module, $sub_prereqs->{$sub}{$module}, $latest_release),
            "$module $sub_prereqs->{$sub}{$module}, used by $sub, is a core module in the latest known release ($latest_release)",
        );
    }
}

done_testing;
