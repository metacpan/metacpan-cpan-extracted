use strict;
use warnings;
use Test::More 0.98;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use Dyn qw[:all];
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

typedef void (*fun_ptr)(int);

LIB_EXPORT int set_callback (fun_ptr * ptr ) {
    return 1;
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
        skip 'error compiling source', 4 unless -e $object_file;
        my @temps;
        eval {
            #$b->prelink(  );
            ( $lib_file, @temps ) = $b->link(
                objects      => $object_file,
                module_name  => 't::callback',
                dl_func_list => [qw[set_callback]]
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
};
#
$lib_file = File::Spec->rel2abs($lib_file);
diag $lib_file;
diag -s $lib_file;
my $lib = dlLoadLibrary($lib_file);
diag $lib;

#diag -s $lib;
#
subtest 'int cb( int )' => sub {
    my $cb = dcbNewCallback( 'i)i', sub { is shift, 100, 'int arg correct'; return 55 }, 5 );
    isa_ok $cb , 'Dyn::Callback';
    is $cb->call(100), 55, 'int return == 55';
};
subtest 'void cb( int )' => sub {
    my $cb = dcbNewCallback( 'i)v', sub { is shift, 100, 'int arg correct'; }, 5 );
    isa_ok $cb , 'Dyn::Callback';
    is $cb->call(100), undef, 'void return == undef';
};
subtest 'const char * cb( int, const char * )' => sub {
    my $cb = dcbNewCallback(
        'iZ)Z',
        sub {
            my ( $int, $name ) = @_;
            is $int,  100,    'int arg correct';
            is $name, 'John', 'string arg is correct';
            return 'Hello, ' . $name;
        },
        5
    );
    isa_ok $cb , 'Dyn::Callback';
    is $cb->call( 100, 'John' ), 'Hello, John', 'string return == "Hello, John"';
};
subtest 'void cb( )' => sub {
    my $called = 0;
    my $cb;
    $cb = dcbNewCallback(
        'v)v',
        sub {
            my $userdata = dcbGetUserData($cb);
            if ( !$called++ ) {
                is_deeply $userdata, [ 5, 'time', { anon => 'hash' } ], 'userdata array is correct';
                diag 'inc value in userdata...';
                $userdata->[0]++;
            }
            else {
                is_deeply $userdata, [ 6, 'time', { anon => 'hash' } ],
                    'updated userdata is correct';
            }
        },
        [ 5, 'time', { anon => 'hash' } ]
    );
    is_deeply dcbGetUserData($cb), [ 5, 'time', { anon => 'hash' } ],
        'userdata is correct before all calls';
    isa_ok $cb , 'Dyn::Callback';
    $cb->call();    # original userdata
    $cb->call();    # modified userdata
    is_deeply dcbGetUserData($cb), [ 6, 'time', { anon => 'hash' } ],
        'userdata is correct after all calls';
};

=pod

subtest 'int add(int, int)' => sub {
    my $ptr = Dyn::Load::FindSymbol( $lib, 'add' );
    diag $ptr;
    my $cvm = Dyn::Call::NewCallVM(1024);
    Dyn::Call::Mode( $cvm, 0 );
    Dyn::Call::Reset($cvm);
    #
    diag 'pushing 5 to arg stack';
    Dyn::Call::ArgInt( $cvm, 5 );
    diag 'pushing 6 to arg stack';
    Dyn::Call::ArgInt( $cvm, 6 );
    is Dyn::Call::CallInt( $cvm, $ptr ), 11, '5 + 6 == 11';
    #
    diag 'reset call VM...';
    Dyn::Call::Reset($cvm);
    diag 'pushing 9 to arg stack';
    Dyn::Call::ArgInt( $cvm, 9 );
    diag 'pushing 100 to arg stack';
    Dyn::Call::ArgInt( $cvm, 100 );
    is Dyn::Call::CallInt( $cvm, $ptr ), 109, '9 + 100 == 109';
    #
    diag 'reset call VM...';
    Dyn::Call::Reset($cvm);
    diag 'pushing -9 to arg stack';
    Dyn::Call::ArgInt( $cvm, -9 );
    diag 'pushing 5 to arg stack';
    Dyn::Call::ArgInt( $cvm, 5 );
    is Dyn::Call::CallInt( $cvm, $ptr ), -4, '-9 + 5 == -4';

    # Cleanup
    Dyn::Call::Free($cvm);
};
subtest 'const char * hi( char * input )' => sub {
    my $ptr = Dyn::Load::FindSymbol( $lib, 'to_lower' );
    diag $ptr;
    my $cvm = Dyn::Call::NewCallVM(1024);
    Dyn::Call::Mode( $cvm, 0 );
    Dyn::Call::Reset($cvm);
    #
    diag 'pushing "Hello!" to arg stack';

    #my $hello = 'Hello';
    #my $ref = \$hello;
    Dyn::Call::ArgString( $cvm, 'Hi!' );
    is Dyn::Call::CallString( $cvm, $ptr ), 'Okay!', 'to_lower("Hi!") == "Okay!"';
    #
    #diag 'reset call VM...';
    #Dyn::Call::Reset($cvm);
    #diag 'pushing 9 to arg stack';
    #Dyn::Call::ArgInt( $cvm, 9 );
    #diag 'pushing 100 to arg stack';
    #Dyn::Call::ArgInt( $cvm, 100 );
    #is Dyn::Call::CallInt( $cvm, $ptr ), 109, '9 + 100 == 109';
    #
    #diag 'reset call VM...';
    #Dyn::Call::Reset($cvm);
    #diag 'pushing -9 to arg stack';
    #Dyn::Call::ArgInt( $cvm, -9 );
    #diag 'pushing 5 to arg stack';
    #Dyn::Call::ArgInt( $cvm, 5 );
    #is Dyn::Call::CallInt( $cvm, $ptr ), -4, '-9 + 5 == -4';
    # Cleanup
    Dyn::Call::Free($cvm);
};
=cut

# Cleanup
END {
    dlFreeLibrary($lib) if defined $lib;
    for ( $source_file, $object_file, $lib_file ) {
        tr/"'//d;
        1 while unlink;
    }
    if ( $^O eq 'VMS' ) {
        1 while unlink 'LINKT.LIS';
        1 while unlink 'LINKT.OPT';
    }
}
done_testing;
