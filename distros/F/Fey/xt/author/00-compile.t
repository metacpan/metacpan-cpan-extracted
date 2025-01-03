use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 52;

my @module_files = (
    'Fey.pm',
    'Fey/Column.pm',
    'Fey/Column/Alias.pm',
    'Fey/Exceptions.pm',
    'Fey/FK.pm',
    'Fey/FakeDBI.pm',
    'Fey/Literal.pm',
    'Fey/Literal/Function.pm',
    'Fey/Literal/Null.pm',
    'Fey/Literal/Number.pm',
    'Fey/Literal/String.pm',
    'Fey/Literal/Term.pm',
    'Fey/NamedObjectSet.pm',
    'Fey/Placeholder.pm',
    'Fey/Role/ColumnLike.pm',
    'Fey/Role/Comparable.pm',
    'Fey/Role/Groupable.pm',
    'Fey/Role/HasAliasName.pm',
    'Fey/Role/IsLiteral.pm',
    'Fey/Role/Joinable.pm',
    'Fey/Role/MakesAliasObjects.pm',
    'Fey/Role/Named.pm',
    'Fey/Role/Orderable.pm',
    'Fey/Role/SQL/Cloneable.pm',
    'Fey/Role/SQL/HasBindParams.pm',
    'Fey/Role/SQL/HasLimitClause.pm',
    'Fey/Role/SQL/HasOrderByClause.pm',
    'Fey/Role/SQL/HasWhereClause.pm',
    'Fey/Role/SQL/ReturnsData.pm',
    'Fey/Role/Selectable.pm',
    'Fey/Role/SetOperation.pm',
    'Fey/Role/TableLike.pm',
    'Fey/SQL.pm',
    'Fey/SQL/Delete.pm',
    'Fey/SQL/Except.pm',
    'Fey/SQL/Fragment/Join.pm',
    'Fey/SQL/Fragment/Where/Boolean.pm',
    'Fey/SQL/Fragment/Where/Comparison.pm',
    'Fey/SQL/Fragment/Where/SubgroupEnd.pm',
    'Fey/SQL/Fragment/Where/SubgroupStart.pm',
    'Fey/SQL/Insert.pm',
    'Fey/SQL/Intersect.pm',
    'Fey/SQL/Select.pm',
    'Fey/SQL/Union.pm',
    'Fey/SQL/Update.pm',
    'Fey/SQL/Where.pm',
    'Fey/Schema.pm',
    'Fey/Table.pm',
    'Fey/Table/Alias.pm',
    'Fey/Types.pm',
    'Fey/Types/Internal.pm'
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

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
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



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


