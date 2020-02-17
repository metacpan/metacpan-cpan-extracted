use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny;
use PadWalker 'closed_over';
use Module::Runtime qw(use_module module_notional_filename);
use ExtUtils::MakeMaker;
use Test::Deep;
use Dist::Zilla::Plugin::DynamicPrereqs;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

# since we change directories during the build process, this must be absolute
use lib path('t/lib')->absolute->stringify;

my $sub_prereqs = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::register_prereqs)->{'%sub_prereqs'};
my %loaded_subs;

sub load_sub
{
    foreach my $sub (Dist::Zilla::Plugin::DynamicPrereqs->_all_required_subs_for(@_))
    {
        next if exists $loaded_subs{$sub};

        foreach my $prereq (keys %{$sub_prereqs->{$sub}})
        {
            note "loading $prereq $sub_prereqs->{$sub}{$prereq}";
            use_module($prereq, $sub_prereqs->{$sub}{$prereq});
        }

        my $filename = path(File::ShareDir::module_dir('Dist::Zilla::Plugin::DynamicPrereqs'), 'include_subs')->child($sub);
        note "loading $filename";
        do $filename;
        die $@ if $@;
        ++$loaded_subs{$sub};
    }
}

{
    load_sub('has_module');

    {
        # pick something we know is available, but not something we have loaded
        my $module = 'Inlined::Module';

        ok(!exists($INC{module_notional_filename($module)}), "$module has not already been loaded");
        my $got_version;
        ok($got_version = has_module($module), "$module is installed; returned something true ($got_version)");
        is(has_module($module, '0'), 1, "$module is installed at least version 0");
        ok(!exists($INC{module_notional_filename($module)}), "$module has not been loaded by has_module()");

        require Inlined::Module;
        is($got_version, MM->parse_version($INC{'Inlined/Module.pm'}), 'has_version returned $Inlined::Module::VERSION');
    }

    {
        my $module = 'Bloop::Blorp';
        ok(!exists($INC{module_notional_filename($module)}), "$module has not already been loaded");
        is(has_module($module), undef, "$module is not installed");
        ok(!exists($INC{module_notional_filename($module)}), "$module has not been loaded by has_module()");
    }

    {
        my $module = 'Dist::Zilla::Plugin::DynamicPrereqs';
        ok(exists($INC{module_notional_filename($module)}), "$module has already been loaded");
        is(has_module($module), $module->VERSION, "$module is installed; returned its version");
        is(has_module($module, '0'), 1, "$module is installed at least version 0");
        is(has_module($module, $module->VERSION), 1, "$module is installed at least version " . $module->VERSION);
    }
}

{
    load_sub('requires', 'build_requires', 'test_requires');

    our (%WriteMakefileArgs, %FallbackPrereqs);

    requires('Alpha', '1.0');
    runtime_requires('Beta', '2.0');
    build_requires('Gamma', '3.0');
    test_requires('Delta', '4.0');

    requires('Foo');
    runtime_requires('Bar');
    build_requires('Baz');
    test_requires('Qux');

    cmp_deeply(
        \%WriteMakefileArgs,
        {
            PREREQ_PM => {
                'Alpha' => '1.0',
                'Beta'  => '2.0',
                'Foo'   => '0',
                'Bar'   => '0',
            },
            BUILD_REQUIRES => {
                'Gamma' => '3.0',
                'Baz'   => '0',
            },
            TEST_REQUIRES => {
                'Delta' => '4.0',
                'Qux'   => '0',
            },
        },
        '%WriteMakefileArgs is correctly updated',
    );
    cmp_deeply(
        \%FallbackPrereqs,
        {
            'Alpha' => '1.0',
            'Beta'  => '2.0',
            'Gamma' => '3.0',
            'Delta' => '4.0',
            'Foo'   => '0',
            'Bar'   => '0',
            'Baz'   => '0',
            'Qux'   => '0',
        },
        '%FallbackPrereqs is correctly updated',
    );
}

done_testing;
