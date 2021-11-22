use strict;
use Test::More 0.98;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use Dyn qw[:all];
use File::Spec;
$|++;
#
my $lib;

# Build a library
use ExtUtils::CBuilder;
use File::Spec;
my ( $source_file, $object_file, $lib_file );
subtest 'ExtUtils::CBuilder' => sub {
    my $b = ExtUtils::CBuilder->new( quiet => 0 );
    ok $b, 'created EU::CB object';
    $source_file = File::Spec->catfile( ( -d 't' ? 't' : '.' ), 'libtest.cpp' );
    {
        open my $FH, '>', $source_file or die "Can't create $source_file: $!";
        print $FH <<'END'; close $FH;
#if defined(_WIN32) || defined(__WIN32__)
#  define LIB_EXPORT extern "C" __declspec(dllexport)
#else
#  define LIB_EXPORT extern "C"
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <float.h>
struct Human {
   char * name;
   int   dob;
};
LIB_EXPORT int          add  (int a, int b) { return a + b;   } // same as ii2i, honestly
LIB_EXPORT const char * b2Z  (bool tf)      { return tf       ? "true" : "false"; }
LIB_EXPORT const char * c2Z  (char a)       { return a == 'a' ? "!!!"  : "???"; }
LIB_EXPORT const char * s2Z  (short a)      { return a ==  91 ? "!!!"  : a == -32767 ? "floor": "???"; }
LIB_EXPORT const char * j2Z  (long a)       { return a ==   0 ? "Zero" : a == -2147483647 ? "floor": "???"; }
LIB_EXPORT const char * l2Z  (long long a)  { return a ==   0 ? "Zero" : a == -9223372036854775807 ? "floor": "???"; }
LIB_EXPORT const char * f2Z  (float a)      { return fabs(a - (float) 5.3) < FLT_EPSILON ? "Nice" : "???"; }
LIB_EXPORT const char * d2Z  (double a)     { return fabs(a - (double) 5.3) < DBL_EPSILON ? "Nice" : "???"; }
LIB_EXPORT int          ii2i (int a, int b) { return a + b;   } // same as add, honestly
LIB_EXPORT const char * Z2Z  (char * input) { return "Okay!"; }
LIB_EXPORT void         v2v  () { ; }
LIB_EXPORT Human *      v2p  () {
    struct Human * person = (Human*) malloc(sizeof(Human));
    if (person != NULL) {
        const char * name = "John Smith";
        person->name = (char *) malloc(strlen(name) + 1);
        strcpy(person->name, name);
        person->dob  = 954214635;
    }
    return person;
}
LIB_EXPORT char * p2Z ( Human * person ) { return person->name; }
LIB_EXPORT int    p2i ( Human * person ) { return person->dob;  }
LIB_EXPORT const char * cb  ( int (*f)(int) )  { return f(100) == 101 ? "Yes!" : "No..."; }
END
    }
    ok -e $source_file, "generated '$source_file'";

    # Compile
    eval { $object_file = $b->compile( source => $source_file, 'C++' => 1 ) };
    is $@, q{}, 'no exception from compilation';
    ok -e $object_file, 'found object file';

    # Link
SKIP: {
        plan skip_all => 'error compiling source' unless -e $object_file;
        my @temps;
        eval {
            #$b->prelink(  );
            ( $lib_file, @temps ) = $b->link(
                objects      => $object_file,
                module_name  => 't::hello',
                dl_func_list => [
                    qw[add
                        b2Z c2Z ii2i s2Z j2Z l2Z f2Z d2Z
                        Z2Z v2v v2p p2Z p2i
                        cb]
                ]
            );
        };
        is $@, q{}, 'no exception from linking';
        ok -e $lib_file, 'found library';

        #ok -x $lib_file, "executable file appears to be executable";
        if ( $^O eq 'os2' ) {    # Analogue of LDLOADPATH...

            # Actually, not needed now, since we do not link with the generated DLL
            my $old = OS2::extLibpath();    # [builtin function]
            $old = ";$old" if defined $old and length $old;

            # To pass the sanity check, components must have backslashes...
            OS2::extLibpath_set(".\\$old");
        }
    }
    #
    $lib_file = File::Spec->rel2abs($lib_file);
    subtest 'Dyn::Load' => sub {
        $lib = dlLoadLibrary($lib_file);
        ok $lib, 'dlLoadLibrary(...)';
        is dlGetLibraryPath( $lib, my $blah = '', length($lib_file) * 2 ), length($lib_file) + 1,
            'dlGetLibraryPath(...)';
        is $blah, $lib_file, '  $sOut is correct';
        diag $lib_file;
    SKIP: {
            plan skip_all => 'ExtUtils::CBuilder will only build bundles but I need a dynlib on OSX'
                if $^O eq 'darwin' && $lib_file =~ m[\.bundle$];
            my $dsyms = dlSymsInit($lib_file);
            ok $dsyms,                   'dlSymsInit(...)';
            ok dlSymsCount($dsyms) > 10, 'dlSymsCount(...) > 10';  # linker might export extra stuff
            for ( 1 .. dlSymsCount($dsyms) - 1 ) {
                diag '  -> ' . dlSymsName( $dsyms, $_ );
            }
            dlSymsCleanup($dsyms);
            is $dsyms, undef, 'dlSymsCleanup(...)';
        }

        #diag `nm $lib_file`;
        #diag dlSymsNameFromValue($dsyms, 0000000000001110);
    };
    subtest 'Dyn synopsis' => sub {
        use Dyn qw[:all];                                  # Exports nothing by default
        my $lib = dlLoadLibrary($lib_file);
        my $ptr = dlFindSymbol( $lib, 'add' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        dcArgInt( $cvm, 5 );
        dcArgInt( $cvm, 6 );
        is dcCallInt( $cvm, $ptr ), 11, 'Dyn synopsis';    #  '5 + 6 == 11';
    };
    subtest 'const char * b2Z(bool)' => sub {
        my $ptr = dlFindSymbol( $lib, 'b2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing a true value to arg stack';
        dcArgBool( $cvm, 1 );
        is dcCallString( $cvm, $ptr ), 'true', 'b2Z( 1 ) == "true"';
        diag 'reset for next call...';
        dcReset($cvm);
        diag 'pushing a false value to arg stack';
        dcArgBool( $cvm, 0 );
        is dcCallString( $cvm, $ptr ), 'false', 'b2Z( 0 ) == "false"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'const char * c2Z(char)' => sub {
        my $ptr = dlFindSymbol( $lib, 'c2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing a "a" to arg stack';
        dcArgChar( $cvm, 'a' );
        is dcCallString( $cvm, $ptr ), '!!!', 'c2Z( "a" ) == "!!!"';
        diag 'reset for next call...';
        dcReset($cvm);
        diag 'pushing a "b" to arg stack';
        dcArgChar( $cvm, 'b' );
        is dcCallString( $cvm, $ptr ), '???', 'c2Z( "b" ) == "???"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'const char * s2Z(short)' => sub {
        my $ptr = dlFindSymbol( $lib, 's2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing 91 to arg stack';
        dcArgShort( $cvm, 91 );
        is dcCallString( $cvm, $ptr ), '!!!', 's2Z( 91 ) == "!!!"';
        diag 'reset for next call...';
        dcReset($cvm);
        diag 'pushing 90 to arg stack';
        dcArgShort( $cvm, 90 );
        is dcCallString( $cvm, $ptr ), '???', 's2Z( 90 ) == "???"';
        diag 'reset for next call...';
        dcReset($cvm);
        diag 'pushing -32767 to arg stack';
        dcArgShort( $cvm, -32767 );
        is dcCallString( $cvm, $ptr ), 'floor', 's2Z( -32767 ) == "floor"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'int ii2i(int, int)' => sub {
        my $ptr = dlFindSymbol( $lib, 'ii2i' );
        isa_ok $ptr, 'Dyn::pointer';
        diag 'TODO: FindSymbol should return something other than Dyn::pointer';
        my $cvm = dcNewCallVM(1024);
        isa_ok $cvm, 'Dyn::Call';
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        #
        diag 'pushing 5 to arg stack';
        dcArgInt( $cvm, 5 );
        diag 'pushing 6 to arg stack';
        dcArgInt( $cvm, 6 );
        is dcCallInt( $cvm, $ptr ), 11, '5 + 6 == 11';
        #
        diag 'reset call VM...';
        dcReset($cvm);
        diag 'pushing 9 to arg stack';
        dcArgInt( $cvm, 9 );
        diag 'pushing 100 to arg stack';
        dcArgInt( $cvm, 100 );
        is dcCallInt( $cvm, $ptr ), 109, '9 + 100 == 109';
        #
        diag 'reset call VM...';
        dcReset($cvm);
        diag 'pushing -9 to arg stack';
        dcArgInt( $cvm, -9 );
        diag 'pushing 5 to arg stack';
        dcArgInt( $cvm, 5 );
        is dcCallInt( $cvm, $ptr ), -4, '-9 + 5 == -4';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'const char * j2Z(long)' => sub {
        my $ptr = dlFindSymbol( $lib, 'j2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing 0 to arg stack';
        dcArgLong( $cvm, 0 );
        is dcCallString( $cvm, $ptr ), 'Zero', 'j2Z( 0 ) == "Zero"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing −2147483647 to arg stack';
        dcArgLong( $cvm, -2147483647 );
        is dcCallString( $cvm, $ptr ), 'floor', 'j2Z( −2147483647 ) == "floor"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing 2147483647 to arg stack';
        dcArgLong( $cvm, 2147483647 );
        is dcCallString( $cvm, $ptr ), '???', 'j2Z( 2147483647 ) == "???"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'const char * l2Z(long long)' => sub {
        my $ptr = dlFindSymbol( $lib, 'l2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing 0 to arg stack';
        dcArgLongLong( $cvm, 0 );
        is dcCallString( $cvm, $ptr ), 'Zero', 'l2Z( 0 ) == "Zero"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing −9223372036854775807 to arg stack';
        dcArgLongLong( $cvm, -9223372036854775807 );
        is dcCallString( $cvm, $ptr ), 'floor', 'l2Z( −9223372036854775807 ) == "floor"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing 2147483647 to arg stack';
        dcArgLongLong( $cvm, 2147483647 );
        is dcCallString( $cvm, $ptr ), '???', 'l2Z( 2147483647 ) == "???"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'const char * f2Z(float)' => sub {
        my $ptr = dlFindSymbol( $lib, 'f2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing 5.3 to arg stack';
        dcArgFloat( $cvm, 5.3 );
        is dcCallString( $cvm, $ptr ), 'Nice', 'f2Z( 5.3 ) == "Nice"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing −1.2 to arg stack';
        dcArgFloat( $cvm, -1.2 );
        is dcCallString( $cvm, $ptr ), '???', 'f2Z( -1.2 ) == "???"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing 5.2 to arg stack';
        dcArgFloat( $cvm, 5.2 );
        is dcCallString( $cvm, $ptr ), '???', 'f2Z( 5.2 ) == "???"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'const char * d2Z(double)' => sub {
        my $ptr = dlFindSymbol( $lib, 'd2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing 5.3 to arg stack';
        dcArgDouble( $cvm, 5.3 );
        is dcCallString( $cvm, $ptr ), 'Nice', 'd2Z( 5.3 ) == "Nice"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing −1.2 to arg stack';
        dcArgDouble( $cvm, -1.2 );
        is dcCallString( $cvm, $ptr ), '???', 'd2Z( -1.2 ) == "???"';
        diag 'reset for next call';
        dcReset($cvm);
        diag 'pushing 5.2 to arg stack';
        dcArgDouble( $cvm, 5.2 );
        is dcCallString( $cvm, $ptr ), '???', 'd2Z( 5.2 ) == "???"';

        # Cleanup
        dcFree($cvm);
    };
    {
        my $person;
        subtest 'void * v2p()' => sub {
            my $ptr = dlFindSymbol( $lib, 'v2p' );
            my $cvm = dcNewCallVM(1024);
            dcMode( $cvm, DC_CALL_C_DEFAULT );
            dcReset($cvm);
            $person = dcCallPointer( $cvm, $ptr );
            isa_ok $person, 'Dyn::pointer';
            diag 'TODO: I need to handle classes';
            dcFree($cvm);
        };
        subtest 'const char * p2Z()' => sub {
            my $ptr = dlFindSymbol( $lib, 'p2Z' );
            my $cvm = dcNewCallVM(1024);
            dcMode( $cvm, DC_CALL_C_DEFAULT );
            dcReset($cvm);
            dcArgPointer( $cvm, $person );
            is dcCallString( $cvm, $ptr ), 'John Smith', 'person->name == "John Smith"';
            dcFree($cvm);
        };
        subtest 'int p2i()' => sub {
            my $ptr = dlFindSymbol( $lib, 'p2i' );
            my $cvm = dcNewCallVM(1024);
            dcMode( $cvm, DC_CALL_C_DEFAULT );
            dcReset($cvm);
            dcArgPointer( $cvm, $person );
            is dcCallInt( $cvm, $ptr ), 954214635, 'person->dob == 954214635';
            dcFree($cvm);
        };
    }
    subtest 'const char * Z2Z(char *)' => sub {
        my $ptr = dlFindSymbol( $lib, 'Z2Z' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        diag 'pushing "Hello!" to arg stack';
        dcArgString( $cvm, 'Hi!' );
        is dcCallString( $cvm, $ptr ), 'Okay!', 'Z2Z("Hi!") == "Okay!"';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'void v2v()' => sub {
        my $ptr = dlFindSymbol( $lib, 'v2v' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        is dcCallVoid( $cvm, $ptr ), undef, 'v2v() == undef';

        # Cleanup
        dcFree($cvm);
    };
    subtest 'Dyn sugar' => sub {
        is Dyn::call( $lib, 'add', 'dd)d', 2.0, 10.0 ), 2,
            q[Dyn::call( $lib, 'add', 'dd)d', 2.0, 10.0 ) == 2];
    };
    subtest 'Exported vars' => sub {
        is DC_ERROR_NONE,             0,  'DC_ERROR_NONE == 0';
        is DC_ERROR_UNSUPPORTED_MODE, -1, 'DC_ERROR_UNSUPPORTED_MODE == -1';
        can_ok __PACKAGE__, @{ $Dyn::Call::EXPORT_TAGS{vars} };

        # Testing known values
        is DC_CALL_C_DEFAULT,            0,   'DC_CALL_C_DEFAULT == 0';
        is DC_CALL_C_ELLIPSIS,           100, 'DC_CALL_C_ELLIPSIS == 100';
        is DC_CALL_C_ELLIPSIS_VARARGS,   101, 'DC_CALL_C_ELLIPSIS_VARARGS == 101';
        is DC_CALL_C_X86_CDECL,          1,   'DC_CALL_C_X86_CDECL == 1';
        is DC_CALL_C_X86_WIN32_STD,      2,   'DC_CALL_C_X86_WIN32_STD == 2';
        is DC_CALL_C_X86_WIN32_FAST_MS,  3,   'DC_CALL_C_X86_WIN32_FAST_MS == 3';
        is DC_CALL_C_X86_WIN32_FAST_GNU, 4,   'DC_CALL_C_X86_WIN32_FAST_GNU == 4';
        is DC_CALL_C_X86_WIN32_THIS_MS,  5,   'DC_CALL_C_X86_WIN32_THIS_MS == 5';
        is DC_CALL_C_X86_WIN32_THIS_GNU, 1,   'DC_CALL_C_X86_WIN32_THIS_GNU == 1';
        is DC_CALL_C_X64_WIN64,          7,   'DC_CALL_C_X64_WIN64 == 7';
        is DC_CALL_C_X64_SYSV,           8,   'DC_CALL_C_X64_SYSV == 8';
        is DC_CALL_C_PPC32_DARWIN,       9,   'DC_CALL_C_PPC32_DARWIN == 9';

        # Testing known aliases
        is DC_CALL_C_X86_WIN32_THIS_GNU, DC_CALL_C_X86_CDECL,  'DC_CALL_C_X86_WIN32_THIS_GNU alias';
        is DC_CALL_C_PPC64_LINUX,        DC_CALL_C_PPC64,      'DC_CALL_C_PPC64 alias';
        is DC_CALL_C_PPC32_LINUX,        DC_CALL_C_PPC32_SYSV, 'DC_CALL_C_PPC32_LINUX alias';
        is DC_CALL_C_MIPS32_PSPSDK, DC_CALL_C_MIPS32_EABI,
            'DC_CALL_C_MIPS32_PSPSDK deprecated alias';
        is DC_CALL_C_PPC32_OSX, DC_CALL_C_PPC32_DARWIN, 'DC_CALL_C_PPC32_OSX alias';
    };
    subtest 'Dyn::Callback' => sub {
        my $cb = dcbNewCallback(
            'i)i',
            sub {
                my ($in) = @_;
                if ( $in == 100 ) {
                    pass 'Args to callback: 100';
                    return 101;
                }
                elsif ( $in == 55 ) {
                    pass 'Args to callback: 55';
                    return 10;
                }
                fail 'Bad args to callback: ' . $in;
                return -1;
            },
            5
        );
        diag $cb;
        subtest 'const char * cb ( ... )' => sub {
            my $ptr = dlFindSymbol( $lib, 'cb' );
            my $cvm = dcNewCallVM(1024);
            dcMode( $cvm, DC_CALL_C_DEFAULT );
            dcReset($cvm);
            diag 'pushing callback to arg stack';
            dcArgPointer( $cvm, $cb );
            is dcCallString( $cvm, $ptr ), 'Yes!', 'cb( $callback ) == "Yes!"';

            # Cleanup
            dcFree($cvm);
        };
        #
        subtest 'call from perl' => sub {
            is $cb->call(100), 101, 'retval == 101';
            is $cb->call(55),  10,  'retval == 10';
            eval { $cb->call( 500, 'Hi!' ) };
            ok $@ =~ m[Too many], 'passing too many arguments is a fatal error';
            eval { $cb->call() };
            ok $@ =~ m[Not enough], 'not passing enough arguments is a fatal error';
            is $cb->call(100), 101, 'double check retval == 101';
        };

=fdsa
        #$cb->init();
        {
            my $cb = dcbNewCallback(
                'i)v',
                sub { warn 'Here!' }

                    #$coderef
                , 5
            );
            #
            warn $cb;
            #
            my $result = $cb->call(12);    # Don't make these an array ref

            #
            warn $result;
        }
        {
            my $cb = dcbNewCallback(
                'iZ)Z',
                sub {
                    my ( $int, $name, $userdata ) = @_;

                    #is $int, 100,    'int arg correct';
                    #is $name, 'John', 'string arg is correct';
                    ddx $userdata;
                    return 'Hello, ' . $name;
                },
                [5]
            );
            my $result = $cb->call( 10, 'Bob' );
            warn $result;
        }
=cut

    };
    subtest 'Dyn::Load Part II' => sub {
        dlFreeLibrary($lib);
        is $lib, undef;
    };
};
done_testing;

# Cleanup
END {
    for ( grep { defined && -e } $source_file, $object_file, $lib_file ) {
        tr/"'//d;
        1 while unlink;
    }
    if ( $^O eq 'VMS' ) {
        1 while unlink 'LINKT.LIS';
        1 while unlink 'LINKT.OPT';
    }
}
