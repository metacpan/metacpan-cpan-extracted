use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
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
LIB_EXPORT int          add_i(int a,     int b) { return a + b; } // same as ii2i, honestly
LIB_EXPORT float        add_f(float a, float b) { return a + b; }
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
LIB_EXPORT unsigned long sizeof_double() { return sizeof(double); }

typedef struct { unsigned char a; } U8;
LIB_EXPORT U8            A2A (U8 in)            { in.a++;                      return in;   }
LIB_EXPORT unsigned char A2C (U8 in)            { in.a++;                      return in.a; }
LIB_EXPORT U8            C2A (unsigned char in) { U8 out; out.a = in; out.a++; return out;  }

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
                    qw[add_i add_f
                        b2Z c2Z ii2i s2Z j2Z l2Z f2Z d2Z
                        Z2Z v2v v2p p2Z p2i
                        cb
                        A2A A2C C2A
                        sizeof_double]
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
    subtest 'Dyn::Load' => sub {
        $lib = dlLoadLibrary($lib_file);
        ok $lib, 'dlLoadLibrary(...)';
    TODO: {
            local $TODO = 'Some platforms do rel2abs and some do not';
            my $___lib = ' ' x 1024;
            my $_abs_  = File::Spec->rel2abs($lib_file);
            is dlGetLibraryPath( $lib, $___lib, length $___lib ), length($_abs_) + 1,
                'dlGetLibraryPath(...)';
            is $___lib, $_abs_, '  $sOut is correct';
        }
        diag $lib_file;
    SKIP: {
            plan skip_all => 'ExtUtils::CBuilder will only build bundles but I need a dynlib on OSX'
                if $^O eq 'darwin' && $lib_file =~ m[\.bundle$];
            my $dsyms = dlSymsInit($lib_file);
            ok $dsyms,                   'dlSymsInit(...)';
            ok dlSymsCount($dsyms) > 10, 'dlSymsCount(...) > 10';  # linker might export extra stuff

            #for ( 1 .. dlSymsCount($dsyms) - 1 ) {
            #    diag '  -> ' . dlSymsName( $dsyms, $_ );
            #}
            dlSymsCleanup($dsyms);
            is $dsyms, undef, 'dlSymsCleanup(...)';
        }

        #diag `nm $lib_file`;
        #diag dlSymsNameFromValue($dsyms, 0000000000001110);
    };
    subtest 'aggregate builder [api]' => sub {
        use Dyn qw[:all];    # Exports nothing by default
        my $lib = dlLoadLibrary($lib_file);
        my $ptr = dlFindSymbol( $lib, 'C2A' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        my $s = dcNewAggr( 1, 1 );
        isa_ok $s, 'Dyn::Call::Aggregate';
        dcAggrField( $s, DC_SIGCHAR_UCHAR, 0, 1 );
        dcCloseAggr($s);
        my @fields = $s->fields;
        subtest 'Dyn::Call::Field [0]' => sub {
            isa_ok $fields[0], 'Dyn::Call::Field';
            is $fields[0]->offset,    0,                'field->offset == 0';
            is $fields[0]->size,      1,                'field->size == sizeof(DCchar)';
            is $fields[0]->alignment, 1,                'field->alignment == 1';
            is $fields[0]->array_len, 1,                'field->array_len == 1';
            is $fields[0]->type,      DC_SIGCHAR_UCHAR, 'field->type == DC_SIGCHAR_UCHAR';
            is $fields[0]->sub_aggr,  undef,            'field->sub_aggr == undef';
        };
        dcFreeAggr($s);
        pass 'remove';
    };
    subtest 'aggregate builder [struct arg]' => sub {
        use Dyn qw[:all];    # Exports nothing by default
        my $lib = dlLoadLibrary($lib_file);
        my $ptr = dlFindSymbol( $lib, 'A2C' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        my $s = dcNewAggr( 1, 1 );
        isa_ok $s, 'Dyn::Call::Aggregate';
        dcAggrField( $s, DC_SIGCHAR_UCHAR, 0, 1 );
        dcCloseAggr($s);
        dcReset($cvm);
        my $mem = malloc(1);
        memcpy( $mem, 'Y', 1 );
        dcArgAggr( $cvm, $s, $mem );
        is dcCallChar( $cvm, $ptr ), 'Z', 'struct.a++ == Z';
        dcFreeAggr($s);
        free($mem);
    };
    subtest 'aggregate builder [struct return [raw]]' => sub {
        use Dyn qw[:all];    # Exports nothing by default
        my $lib = dlLoadLibrary($lib_file);
        my $ptr = dlFindSymbol( $lib, 'C2A' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        my $s = dcNewAggr( 1, 1 );
        isa_ok $s, 'Dyn::Call::Aggregate';
        diag DC_SIGCHAR_UCHAR;
        dcAggrField( $s, DC_SIGCHAR_UCHAR, 0, 1 );
        dcCloseAggr($s);
        dcReset($cvm);
        dcBeginCallAggr( $cvm, $s );
        dcArgChar( $cvm, 'm' );
        my $ret = malloc(1);
        isa_ok dcCallAggr( $cvm, $ptr, $s, $ret ), 'Dyn::Call::Pointer';
        is $ret->raw(1), 'n', 'struct.a++ == n';
        dcFreeAggr($s);
    };
    subtest 'aggregate builder [struct return [obj]]' => sub {
        use Dyn qw[:all];    # Exports nothing by default
        my $lib = dlLoadLibrary($lib_file);
        my $ptr = dlFindSymbol( $lib, 'C2A' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        my $s = dcNewAggr( 1, 1 );
        isa_ok $s, 'Dyn::Call::Aggregate';
        dcAggrField( $s, DC_SIGCHAR_UCHAR, 0, 1 );
        dcCloseAggr($s);
        dcReset($cvm);
        dcArgChar( $cvm, 'm' );
        my $obj = malloc(1);
        my $ret = dcCallAggr( $cvm, $ptr, $s, $obj );
        isa_ok $ret, 'Dyn::Call::Pointer', '$ret';
        my $struct = unpack 'C', $obj;
        is_deeply $struct, ord 'n', 'struct unpacked to perl vars';
        dcFreeAggr($s);
        free($ret);
    };
    subtest 'aggregate builder [struct arg and return]' => sub {
        use Dyn qw[:all];    # Exports nothing by default
        my $lib = dlLoadLibrary($lib_file);
        my $ptr = dlFindSymbol( $lib, 'A2A' );
        my $cvm = dcNewCallVM(1024);
        dcMode( $cvm, DC_CALL_C_DEFAULT );
        dcReset($cvm);
        my $s = dcNewAggr( 1, 1 );
        isa_ok $s, 'Dyn::Call::Aggregate';
        dcAggrField( $s, DC_SIGCHAR_UCHAR, 0, 1 );
        dcCloseAggr($s);
        dcReset($cvm);
        dcBeginCallAggr( $cvm, $s );
        dcArgChar( $cvm, 'Y' );
        my $obj    = malloc(1);
        my $ret    = dcCallAggr( $cvm, $ptr, $s, $obj );
        my $struct = unpack 'C', $obj;
        is_deeply $struct, ord 'Z', 'struct unpacked to perl vars';
        dcFreeAggr($s);
        free($obj);
    };
    #
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
