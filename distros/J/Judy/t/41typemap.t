#!perl
use strict;
use warnings;
use vars '@MAGIC';
use Test::More tests => 29;
use Test::Deep;
use Judy::Mem qw( String2Ptr Ptr2String Ptr2String2 Free );

# Build the library in t/MAGIC
BEGIN {
    require Cwd;
    require File::Basename;
    require File::Spec;
    my $cwd = Cwd::getcwd();
    my $test_dir = File::Basename::dirname( $0 );
    my $magic_dir = File::Spec->catdir(
        $test_dir,
        'MAGIC',
    );
    chdir $magic_dir
        or die "Can't chdir(t): $!";
    system $^X, 'Build.PL';
    system $^X, 'Build';
    require blib;
    blib->import;
    require MAGIC;
    chdir $cwd
        or die "Can't chdir($cwd): $!";
}

tie my($magic), 'MAGIC';
@MAGIC = ();

$|=1;
use Data::Dumper;
sub X { print Dumper([\@MAGIC,${tied($magic)}]); @MAGIC = () }
sub RunTest (&) {
    local @MAGIC;
    &{$_[0]};
}    

# Pvoid_t #####################################################################
RunTest {
    $magic = MAGIC::set_Pvoid_t1();
    is_deeply( \@MAGIC, [['STORE',undef,3]], 'Set Pvoid_t via RETVAL' );
    is( ${tied $magic}, 3, 'Set Pvoid_t via RETVAL' );
};

RunTest {
    MAGIC::get_Pvoid_t( $magic );
    is_deeply( \@MAGIC, [['FETCH',3]], 'Fetch Pvoid_t' );
    is( ${tied $magic}, 3, 'Fetch Pvoid_t' );
};

RunTest {
    MAGIC::set_Pvoid_t2( $magic );
    is_deeply( \@MAGIC,[['FETCH',3],
			['STORE',3,4]], 'Set Pvoid_t via OUTPUT:' );
    is( ${tied $magic}, 4, 'Set Pvoid_t via OUTPUT:' );
};

# IWord_t #####################################################################
${ tied $magic } = 5;
RunTest {
    MAGIC::get_IWord_t( $magic );
    cmp_deeply(
        \@MAGIC,
        array_each(all(['FETCH',5])),
        'Fetch Word_t'
    );
    is( ${tied $magic}, 5, 'Fetch Word_t' );
};

RunTest {
    $magic = MAGIC::set_IWord_t1();
    @MAGIC =
        grep { $_->[0] ne 'FETCH' }
        @MAGIC;
    is_deeply( \@MAGIC,[['STORE',5,6]], 'Set Word_t via RETVAL' )
	or diag( Dumper( \ @MAGIC ) );
    is( ${tied $magic}, 6, 'Set Word_t via RETVAL' );
};
RunTest {
    MAGIC::set_IWord_t2( $magic );
    @MAGIC =
        grep { $_->[0] ne 'FETCH' }
        @MAGIC;
    is_deeply( \@MAGIC,[['STORE',6,7]], 'Set Word_t via OUTPUT:' );
    is( ${tied $magic}, 7, 'Set Word_t via OUTPUT:' );
};

# UWord_t #####################################################################
${ tied $magic } = 5;
RunTest {
    MAGIC::get_UWord_t( $magic );
    cmp_deeply(
        \@MAGIC,
        array_each(all(['FETCH',5])),
        'Fetch Word_t'
    );
    is( ${tied $magic}, 5, 'Fetch Word_t' );
};

RunTest {
    $magic = MAGIC::set_UWord_t1();
    @MAGIC =
        grep { $_->[0] ne 'FETCH' }
        @MAGIC;
    is_deeply( \@MAGIC,[['STORE',5,6]], 'Set Word_t via RETVAL' )
	or diag( Dumper( \ @MAGIC ) );
    is( ${tied $magic}, 6, 'Set Word_t via RETVAL' );
};
RunTest {
    MAGIC::set_UWord_t2( $magic );
    @MAGIC =
        grep { $_->[0] ne 'FETCH' }
        @MAGIC;
    is_deeply( \@MAGIC,[['STORE',6,7]], 'Set Word_t via OUTPUT:' );
    is( ${tied $magic}, 7, 'Set Word_t via OUTPUT:' );
};

# PWord_t ######################################################################
${ tied $magic } = 8;
RunTest {
    MAGIC::get_PWord_t( $magic );
    is_deeply( \@MAGIC, [['FETCH',8]], 'Fetch PWord_t' );
    is( ${tied $magic}, 8, 'Fetch PWord_t' );
};

RunTest {
    $magic = MAGIC::set_PWord_t1();
    is_deeply( \@MAGIC,[['STORE',8,9]], 'Set PWord_t via RETVAL' )
	or diag( Dumper( \ @MAGIC ) );
    is( ${tied $magic}, 9, 'Set PWord_t via RETVAL' );
};

RunTest {
    MAGIC::set_PWord_t2( $magic );
    is_deeply( \@MAGIC,[['FETCH',9],
    			['STORE',9,10]], 'Set PWord_t via OUTPUT:' );
    is( ${tied $magic}, 10, 'Set PWord_t via OUTPUT:' );
};

# Str #####################################################################
RunTest {
    ${tied $magic} = "aa\0bb";
    MAGIC::get_Str( $magic );
    is_deeply( \@MAGIC, [['FETCH',"aa\0bb"]], 'Fetch Str' );
};

RunTest {
    $magic = MAGIC::set_Str1();
    is_deeply( \@MAGIC, [['STORE',"aa\0bb","bb\0cc"]], 'Set Str via RETVAL' );
};

RunTest {
    MAGIC::set_Str2( $magic );
    is_deeply( \@MAGIC, [['FETCH',"bb\0cc"],
			 ['STORE',"bb\0cc","cc\0dd"]], 'Set Str via OUTPUT' );
};

RunTest {
    $magic = MAGIC::set_Str3();
    is_deeply( \@MAGIC, [['STORE',"cc\0dd",'ee']], 'Set Str via RETVAL w/ implicit length' );
};

RunTest {
    MAGIC::set_Str4( $magic );
    is_deeply( \@MAGIC, [['FETCH','ee'],
			 ['STORE','ee','ff']], 'Set Str via OUTPUT w/ implict length' );
};

######################################################################
# RunTest {
#     ${ tied $magic } = 'hi';
#     Free( String2Ptr( $magic ) );
#     is_deeply( \@MAGIC,[['FETCH','hi']],'String2Ptr GET');
# };
# 
# ${ tied $magic } = undef;
# RunTest {
#     $magic = String2Ptr( 'hi' );
#     like( ${tied $magic}, qr/^[1-9]\d+\z/, 'String2Ptr SET RETVAL' );
#     is_deeply( \@MAGIC, [['STORE',undef,${tied $magic}]], 'String2PTR SET RETVAL' );
#     Free( ${ tied $magic } );
# };
# 
# RunTest {
#     ${tied $magic} = String2Ptr( 'bye' );
#     Ptr2String( $magic );
#     like( ${tied $magic}, qr/^[1-9]\d+\z/, 'Ptr2String );
#     is_deeply( \@MAGIC, [['FETCH',${tied $magic}]] );
#     Free( ${ tied $magic } );
# };
