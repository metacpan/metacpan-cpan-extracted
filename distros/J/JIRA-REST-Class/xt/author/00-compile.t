use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 28;

my @module_files = (
    'JIRA/REST/Class.pm',
    'JIRA/REST/Class/Abstract.pm',
    'JIRA/REST/Class/Factory.pm',
    'JIRA/REST/Class/FactoryTypes.pm',
    'JIRA/REST/Class/Issue.pm',
    'JIRA/REST/Class/Issue/Changelog.pm',
    'JIRA/REST/Class/Issue/Changelog/Change.pm',
    'JIRA/REST/Class/Issue/Changelog/Change/Item.pm',
    'JIRA/REST/Class/Issue/Comment.pm',
    'JIRA/REST/Class/Issue/LinkType.pm',
    'JIRA/REST/Class/Issue/Status.pm',
    'JIRA/REST/Class/Issue/Status/Category.pm',
    'JIRA/REST/Class/Issue/TimeTracking.pm',
    'JIRA/REST/Class/Issue/Transitions.pm',
    'JIRA/REST/Class/Issue/Transitions/Transition.pm',
    'JIRA/REST/Class/Issue/Type.pm',
    'JIRA/REST/Class/Issue/Worklog.pm',
    'JIRA/REST/Class/Issue/Worklog/Item.pm',
    'JIRA/REST/Class/Iterator.pm',
    'JIRA/REST/Class/Mixins.pm',
    'JIRA/REST/Class/Project.pm',
    'JIRA/REST/Class/Project/Category.pm',
    'JIRA/REST/Class/Project/Component.pm',
    'JIRA/REST/Class/Project/Version.pm',
    'JIRA/REST/Class/Query.pm',
    'JIRA/REST/Class/Sprint.pm',
    'JIRA/REST/Class/User.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


