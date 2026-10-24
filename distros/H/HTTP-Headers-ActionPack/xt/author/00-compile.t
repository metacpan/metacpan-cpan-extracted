use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More;

plan tests => 22;

my @module_files = (
    'HTTP/Headers/ActionPack.pm',
    'HTTP/Headers/ActionPack/AcceptCharset.pm',
    'HTTP/Headers/ActionPack/AcceptLanguage.pm',
    'HTTP/Headers/ActionPack/AuthenticationInfo.pm',
    'HTTP/Headers/ActionPack/Authorization.pm',
    'HTTP/Headers/ActionPack/Authorization/Basic.pm',
    'HTTP/Headers/ActionPack/Authorization/Digest.pm',
    'HTTP/Headers/ActionPack/ContentNegotiation.pm',
    'HTTP/Headers/ActionPack/Core/Base.pm',
    'HTTP/Headers/ActionPack/Core/BaseAuthHeader.pm',
    'HTTP/Headers/ActionPack/Core/BaseHeaderList.pm',
    'HTTP/Headers/ActionPack/Core/BaseHeaderType.pm',
    'HTTP/Headers/ActionPack/Core/BaseHeaderWithParams.pm',
    'HTTP/Headers/ActionPack/DateHeader.pm',
    'HTTP/Headers/ActionPack/LinkHeader.pm',
    'HTTP/Headers/ActionPack/LinkList.pm',
    'HTTP/Headers/ActionPack/MediaType.pm',
    'HTTP/Headers/ActionPack/MediaTypeList.pm',
    'HTTP/Headers/ActionPack/PriorityList.pm',
    'HTTP/Headers/ActionPack/Util.pm',
    'HTTP/Headers/ActionPack/WWWAuthenticate.pm'
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


