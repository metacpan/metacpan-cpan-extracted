use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 144 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'KiokuDB.pm',
    'KiokuDB/Backend.pm',
    'KiokuDB/Backend/Hash.pm',
    'KiokuDB/Backend/Role/BinarySafe.pm',
    'KiokuDB/Backend/Role/Broken.pm',
    'KiokuDB/Backend/Role/Clear.pm',
    'KiokuDB/Backend/Role/Concurrency/POSIX.pm',
    'KiokuDB/Backend/Role/GC.pm',
    'KiokuDB/Backend/Role/Prefetch.pm',
    'KiokuDB/Backend/Role/Query.pm',
    'KiokuDB/Backend/Role/Query/GIN.pm',
    'KiokuDB/Backend/Role/Query/Simple.pm',
    'KiokuDB/Backend/Role/Query/Simple/Linear.pm',
    'KiokuDB/Backend/Role/Scan.pm',
    'KiokuDB/Backend/Role/TXN.pm',
    'KiokuDB/Backend/Role/TXN/Memory.pm',
    'KiokuDB/Backend/Role/TXN/Memory/Scan.pm',
    'KiokuDB/Backend/Role/TXN/Nested.pm',
    'KiokuDB/Backend/Role/UnicodeSafe.pm',
    'KiokuDB/Backend/Serialize.pm',
    'KiokuDB/Backend/Serialize/Delegate.pm',
    'KiokuDB/Backend/Serialize/JSON.pm',
    'KiokuDB/Backend/Serialize/JSPON.pm',
    'KiokuDB/Backend/Serialize/JSPON/Collapser.pm',
    'KiokuDB/Backend/Serialize/JSPON/Converter.pm',
    'KiokuDB/Backend/Serialize/JSPON/Expander.pm',
    'KiokuDB/Backend/Serialize/Memory.pm',
    'KiokuDB/Backend/Serialize/Null.pm',
    'KiokuDB/Backend/Serialize/Storable.pm',
    'KiokuDB/Backend/Serialize/YAML.pm',
    'KiokuDB/Backend/TypeMap/Default.pm',
    'KiokuDB/Backend/TypeMap/Default/JSON.pm',
    'KiokuDB/Backend/TypeMap/Default/Storable.pm',
    'KiokuDB/Class.pm',
    'KiokuDB/Collapser.pm',
    'KiokuDB/Collapser/Buffer.pm',
    'KiokuDB/Entry.pm',
    'KiokuDB/Entry/Skip.pm',
    'KiokuDB/Error.pm',
    'KiokuDB/Error/MissingObjects.pm',
    'KiokuDB/Error/UnknownObjects.pm',
    'KiokuDB/GC/Naive.pm',
    'KiokuDB/GC/Naive/Mark.pm',
    'KiokuDB/GC/Naive/Sweep.pm',
    'KiokuDB/GIN.pm',
    'KiokuDB/LinkChecker.pm',
    'KiokuDB/LinkChecker/Results.pm',
    'KiokuDB/Linker.pm',
    'KiokuDB/LiveObjects.pm',
    'KiokuDB/LiveObjects/Guard.pm',
    'KiokuDB/LiveObjects/Scope.pm',
    'KiokuDB/LiveObjects/TXNScope.pm',
    'KiokuDB/Meta/Attribute/DoNotSerialize.pm',
    'KiokuDB/Meta/Attribute/Lazy.pm',
    'KiokuDB/Meta/Instance.pm',
    'KiokuDB/Reference.pm',
    'KiokuDB/Role/API.pm',
    'KiokuDB/Role/Cacheable.pm',
    'KiokuDB/Role/ID.pm',
    'KiokuDB/Role/ID/Content.pm',
    'KiokuDB/Role/ID/Digest.pm',
    'KiokuDB/Role/Immutable.pm',
    'KiokuDB/Role/Immutable/Transitive.pm',
    'KiokuDB/Role/Intrinsic.pm',
    'KiokuDB/Role/Scan.pm',
    'KiokuDB/Role/TypeMap.pm',
    'KiokuDB/Role/UUIDs.pm',
    'KiokuDB/Role/UUIDs/DataUUID.pm',
    'KiokuDB/Role/UUIDs/SerialIDs.pm',
    'KiokuDB/Role/Upgrade/Data.pm',
    'KiokuDB/Role/Upgrade/Handlers.pm',
    'KiokuDB/Role/Upgrade/Handlers/Table.pm',
    'KiokuDB/Role/Verbosity.pm',
    'KiokuDB/Role/WithDigest.pm',
    'KiokuDB/Serializer.pm',
    'KiokuDB/Serializer/JSON.pm',
    'KiokuDB/Serializer/Memory.pm',
    'KiokuDB/Serializer/Storable.pm',
    'KiokuDB/Serializer/YAML.pm',
    'KiokuDB/Set.pm',
    'KiokuDB/Set/Base.pm',
    'KiokuDB/Set/Deferred.pm',
    'KiokuDB/Set/Loaded.pm',
    'KiokuDB/Set/Storage.pm',
    'KiokuDB/Set/Stored.pm',
    'KiokuDB/Set/Transient.pm',
    'KiokuDB/Stream/Objects.pm',
    'KiokuDB/Test.pm',
    'KiokuDB/Test/Company.pm',
    'KiokuDB/Test/Digested.pm',
    'KiokuDB/Test/Employee.pm',
    'KiokuDB/Test/Fixture.pm',
    'KiokuDB/Test/Fixture/Binary.pm',
    'KiokuDB/Test/Fixture/CAS.pm',
    'KiokuDB/Test/Fixture/Clear.pm',
    'KiokuDB/Test/Fixture/Concurrency.pm',
    'KiokuDB/Test/Fixture/GIN/Class.pm',
    'KiokuDB/Test/Fixture/MassInsert.pm',
    'KiokuDB/Test/Fixture/ObjectGraph.pm',
    'KiokuDB/Test/Fixture/Overwrite.pm',
    'KiokuDB/Test/Fixture/Refresh.pm',
    'KiokuDB/Test/Fixture/RootSet.pm',
    'KiokuDB/Test/Fixture/Scan.pm',
    'KiokuDB/Test/Fixture/Sets.pm',
    'KiokuDB/Test/Fixture/SimpleSearch.pm',
    'KiokuDB/Test/Fixture/Small.pm',
    'KiokuDB/Test/Fixture/TXN.pm',
    'KiokuDB/Test/Fixture/TXN/Nested.pm',
    'KiokuDB/Test/Fixture/TXN/Scan.pm',
    'KiokuDB/Test/Fixture/TypeMap/Default.pm',
    'KiokuDB/Test/Fixture/Unicode.pm',
    'KiokuDB/Test/Person.pm',
    'KiokuDB/Thunk.pm',
    'KiokuDB/TypeMap.pm',
    'KiokuDB/TypeMap/ClassBuilders.pm',
    'KiokuDB/TypeMap/Composite.pm',
    'KiokuDB/TypeMap/Default.pm',
    'KiokuDB/TypeMap/Default/Canonical.pm',
    'KiokuDB/TypeMap/Default/JSON.pm',
    'KiokuDB/TypeMap/Default/Passthrough.pm',
    'KiokuDB/TypeMap/Default/Storable.pm',
    'KiokuDB/TypeMap/Entry.pm',
    'KiokuDB/TypeMap/Entry/Alias.pm',
    'KiokuDB/TypeMap/Entry/Callback.pm',
    'KiokuDB/TypeMap/Entry/Closure.pm',
    'KiokuDB/TypeMap/Entry/Compiled.pm',
    'KiokuDB/TypeMap/Entry/JSON/Scalar.pm',
    'KiokuDB/TypeMap/Entry/MOP.pm',
    'KiokuDB/TypeMap/Entry/Naive.pm',
    'KiokuDB/TypeMap/Entry/Passthrough.pm',
    'KiokuDB/TypeMap/Entry/Ref.pm',
    'KiokuDB/TypeMap/Entry/Set.pm',
    'KiokuDB/TypeMap/Entry/Std.pm',
    'KiokuDB/TypeMap/Entry/Std/Compile.pm',
    'KiokuDB/TypeMap/Entry/Std/Expand.pm',
    'KiokuDB/TypeMap/Entry/Std/ID.pm',
    'KiokuDB/TypeMap/Entry/Std/Intrinsic.pm',
    'KiokuDB/TypeMap/Entry/StorableHook.pm',
    'KiokuDB/TypeMap/Resolver.pm',
    'KiokuDB/TypeMap/Shadow.pm',
    'KiokuDB/Util.pm',
    'Moose/Meta/Attribute/Custom/Trait/KiokuDB/DoNotSerialize.pm',
    'Moose/Meta/Attribute/Custom/Trait/KiokuDB/Lazy.pm'
);

my @scripts = (
    'bin/kioku'
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

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;
    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!.*?\bperl\b\s*(.*)$/;

    my @flags = $1 ? split(/\s+/, $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

   # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


