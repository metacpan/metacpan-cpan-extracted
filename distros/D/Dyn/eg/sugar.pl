use strict;
use warnings;
use Data::Dump;
use lib '../lib', '../blib/arch', '../blib/lib';
use Dyn::Sugar;
use Dyn::Load qw[:all];
use Dyn::Call qw[:all];
use Dyn qw[call];
use Types::Standard qw[InstanceOf];
use Test::More 0.98;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use File::Spec;
$|++;
#

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
struct Containment {
	void * containment;
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
LIB_EXPORT Containment * contain ( void * _dcStruct ) {
    struct Containment * container = (Containment*) malloc(sizeof(Containment));
	return container;
}
typedef struct {
	double one;
	double two;
	double three;
	double four;
} SomeValues ;
LIB_EXPORT SomeValues * double_struct (SomeValues * _struct, double _double) {
	_struct->one = _double;
	return _struct;
}
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
    #
    $lib_file = File::Spec->rel2abs($lib_file);

	subtest 'struct builder' => sub {
		my $lib = dlLoadLibrary($lib_file);
        my $s = dcNewStruct( 4, DEFAULT_ALIGNMENT );
        dcStructField( $s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1 );
        dcStructField( $s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1 );
        dcStructField( $s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1 );
        dcStructField( $s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1 );
        dcCloseStruct($s);
		my $call = Dyn::load( $lib_file, 'sizeof_double', ')J' );
        is dcStructSize($s), ( 4 * call( $call ) ), 'dcStructSize( ... )';
		$call = Dyn::load( $lib_file, 'double_struct', 'Td)T' );
		Dyn::call($call, $s, 499);



#LIB_EXPORT SomeValues * double_struct (SomeValues * _struct, double _double) {

        dcFreeStruct($s);

		warn;
    };


    subtest 'class sugar' => sub {
		use Dyn::Load qw[:all];
        use Dyn::Sugar;
		my $lib = dlLoadLibrary($lib_file);

        #package Date::Range {
        #	sub new() { bless {}, shift }
        #};
        class Human {
            has $name : isa(Str);
            has $dob  : isa(Int);
            #has $period : isa( InstanceOf ['Date::Range'] );
        }
        my $dude = Human->new( name => 'John', dob => time ); # brand spankin' new!
        isa_ok $dude, 'Human';
		#isa_ok $dude, 'Dyn::pointer';
		my $ptr = dlFindSymbol( $lib, 'p2Z' );
		diag $ptr;
		my $cvm = dcNewCallVM(1024);
		diag $cvm;
		dcMode( $cvm, DC_CALL_C_DEFAULT );
		dcReset($cvm);
		dcArgStruct( $cvm, $dude->_to_c, $dude );
		warn;
		dcArgString( $cvm, 'Jack' );
		warn;
		diag dcCallString( $cvm, $ptr );
		is dcCallString( $cvm, $ptr ), 'John Smith', 'person->name == "John Smith"';



        if (1) {
            #my $var;
            dcFree($cvm);
        }

        #ddx Season::_elm();
        #ddx \%Season::;
        #my $summer = Season->new( rain => 3, name => 'Summer' );
        #isa_ok $summer, 'Season';
        #ddx $summer;
        #$summer->_set_name('Anti-Winter');
        #warn $summer->name;
        #diag $summer->_to_c;
    };
	my $lib;
    die;
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

    subtest 'Dyn sugar' => sub {
        is Dyn::call( $lib, 'add_i', 'ii)i', 2, 10 ), 12,
            q[Dyn::call( $lib, 'add_i', 'ii)i', 2, 10 ) == 12];
        is sprintf( '%.3f', Dyn::call( $lib, 'add_f', 'ff)f', 2.5, 10.3 ) ), '12.800',
            q[Dyn::call( $lib, 'add_f', 'ff)f', 2.5, 10.3 ) == 12.800];
    };
    subtest 'class sugar' => sub {
        use Dyn::Sugar;
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
