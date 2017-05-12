
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.053

use Test::More;

plan tests => 32;

my @module_files = (
    'Fey/Hash/ColumnsKey.pm',
    'Fey/Meta/Attribute/FromColumn.pm',
    'Fey/Meta/Attribute/FromInflator.pm',
    'Fey/Meta/Attribute/FromSelect.pm',
    'Fey/Meta/Class/Schema.pm',
    'Fey/Meta/Class/Table.pm',
    'Fey/Meta/HasMany/ViaFK.pm',
    'Fey/Meta/HasMany/ViaSelect.pm',
    'Fey/Meta/HasOne/ViaFK.pm',
    'Fey/Meta/HasOne/ViaSelect.pm',
    'Fey/Meta/Method/Constructor.pm',
    'Fey/Meta/Method/FromSelect.pm',
    'Fey/Meta/Role/FromSelect.pm',
    'Fey/Meta/Role/Relationship.pm',
    'Fey/Meta/Role/Relationship/HasMany.pm',
    'Fey/Meta/Role/Relationship/HasOne.pm',
    'Fey/Meta/Role/Relationship/ViaFK.pm',
    'Fey/ORM.pm',
    'Fey/ORM/Exceptions.pm',
    'Fey/ORM/Policy.pm',
    'Fey/ORM/Role/Iterator.pm',
    'Fey/ORM/Schema.pm',
    'Fey/ORM/Table.pm',
    'Fey/ORM/Types.pm',
    'Fey/ORM/Types/Internal.pm',
    'Fey/Object/Iterator/FromArray.pm',
    'Fey/Object/Iterator/FromSelect.pm',
    'Fey/Object/Iterator/FromSelect/Caching.pm',
    'Fey/Object/Policy.pm',
    'Fey/Object/Schema.pm',
    'Fey/Object/Table.pm'
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
        and not eval { blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


