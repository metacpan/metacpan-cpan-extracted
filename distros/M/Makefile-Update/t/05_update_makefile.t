use strict;
use warnings;
use autodie;
use Test::More;
use Test::LongString;

BEGIN { use_ok('Makefile::Update::Makefile'); }

my $vars = {
        VAR1 => [qw(file1.cpp file2.cpp fileNew.cpp)],
        VAR2 => [qw(file0.c file3.c file4.c file5.c fileCpp.cpp fileCppNew.cpp fileNew2.c)],
        prog => [qw(prog.cpp)],
        foo  => [qw(foo.cpp bar.cpp)],
    };

open my $out, '>', \my $outstr;
update_makefile(*DATA, $out, $vars);

note("Result: $outstr");

# VAR1 tests
lacks_string($outstr, 'fileToRemove.cpp', 'non-existing any more file was removed');
contains_string($outstr, 'file1.cpp', 'existing file was preserved');
like_string($outstr, qr/file2.cpp \\$/m, 'trailing backslash was added');
like_string($outstr, qr/fileNew.cpp$/m, 'new file was added without backslash');

# VAR2 tests
lacks_string($outstr, 'fileOld', 'old file was removed');
like_string($outstr, qr/fileNew2\.o \\$/m, 'another new file was added with backslash');
like_string($outstr, qr/file0\.o \\\s+file3\.o/s, 'new file added in correct order');
like_string($outstr, qr/file3\.o \\\s+file4\.o/s, 'existing files remain in correct order');

lacks_string($outstr, 'fileCppOld', 'old C++ file was removed');
contains_string($outstr, 'fileCpp.o', 'existing C++ file was preserved');
contains_string($outstr, 'fileCppNew.o', 'new C++ file was added with correct extension');

# The rest of them.
like_string($outstr, qr/bar\.\$\(OBJ\) \\\s+foo\.\$\(OBJ\)/, 'baz.$(OBJ) was removed from the file list');
contains_string($outstr, '$(extra_libs)', '$(extra_libs) was preserved');

# Test that different make variables (specified as first element of the array)
# are updated with the values of our variable with the given name (specified
# as the second element).
my @test_make_vars = (
        [qw(objects             sources     )],
        [qw(foo_objects         foo         )],
        [qw(foo_objects         foo_sources )],
        [qw(foo_sources         foo         )],
        [qw(foo_a_SOURCES       foo         )],
        [qw(foo_la_SOURCES      foo         )],
        [qw(libfoo_la_SOURCES   foo         )],
    );

# Return a makefile fragment defining the given variable with the given value.
sub make_fragment
{
    my ($makevar, $value) = @_;
    <<EOF
$makevar := \\
    $value

# end
EOF
}

for (@test_make_vars) {
    my ($makevar, $ourvar) = @$_;
    my $makefile = make_fragment($makevar, 'oldfile.c');

    open my $in, '<', \$makefile;
    open my $out, '>', \my $makefile_new;
    update_makefile($in, $out, { $ourvar => [qw(newfile.c)] });

    is($makefile_new, make_fragment($makevar, 'newfile.c'),
       qq{make variable "$makevar" updated with the value of "$ourvar"});
}

done_testing()

__DATA__
# Simplest case.
VAR1 = \
       fileToRemove.cpp \
       file1.cpp \
       file2.cpp

# More typical case, using object files.
VAR2_OBJECTS := \
    file3.o \
    file4.o \
    file5.o \
    fileCpp.o \
    fileCppOld.o \
    fileOld.o \

# Targets can be updated too and variables in them are preserved.
prog: \
    prog.o \
    $(extra_libs)

# Using variable for the extension should still work.
foo$(EXE): \
    bar.$(OBJ) \
    baz.$(OBJ) \
    foo.$(OBJ)
