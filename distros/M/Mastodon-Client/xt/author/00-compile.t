use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More;

plan tests => 20;

my @module_files = (
    'Mastodon/Client.pm',
    'Mastodon/Entity/Account.pm',
    'Mastodon/Entity/Application.pm',
    'Mastodon/Entity/Attachment.pm',
    'Mastodon/Entity/Card.pm',
    'Mastodon/Entity/Context.pm',
    'Mastodon/Entity/Error.pm',
    'Mastodon/Entity/Instance.pm',
    'Mastodon/Entity/Mention.pm',
    'Mastodon/Entity/Notification.pm',
    'Mastodon/Entity/Relationship.pm',
    'Mastodon/Entity/Report.pm',
    'Mastodon/Entity/Results.pm',
    'Mastodon/Entity/Status.pm',
    'Mastodon/Entity/Tag.pm',
    'Mastodon/Listener.pm',
    'Mastodon/Role/Entity.pm',
    'Mastodon/Role/UserAgent.pm',
    'Mastodon/Types.pm'
);



# no fake home requested

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

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'}.$str.q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


