use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 19;

my @module_files = (
    'MetaCPAN/Client.pm',
    'MetaCPAN/Client/Author.pm',
    'MetaCPAN/Client/Distribution.pm',
    'MetaCPAN/Client/DownloadURL.pm',
    'MetaCPAN/Client/Favorite.pm',
    'MetaCPAN/Client/File.pm',
    'MetaCPAN/Client/Mirror.pm',
    'MetaCPAN/Client/Module.pm',
    'MetaCPAN/Client/Permission.pm',
    'MetaCPAN/Client/Pod.pm',
    'MetaCPAN/Client/Rating.pm',
    'MetaCPAN/Client/Release.pm',
    'MetaCPAN/Client/Request.pm',
    'MetaCPAN/Client/ResultSet.pm',
    'MetaCPAN/Client/Role/Entity.pm',
    'MetaCPAN/Client/Role/HasUA.pm',
    'MetaCPAN/Client/Scroll.pm',
    'MetaCPAN/Client/Types.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
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


