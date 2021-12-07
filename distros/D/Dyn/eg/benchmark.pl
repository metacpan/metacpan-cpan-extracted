use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use Dyn qw[:sugar];
use FFI::Platypus 1.00;
use Config;
use Benchmark qw[cmpthese timethese];
use Test::More;

# arbitrary benchmarks
$|++;
our $libfile
    = $^O eq 'MSWin32'        ? 'msvcrt.dll' :
    $^O eq 'darwin'           ? '/usr/lib/libm.dylib' :
    $^O eq 'bsd'              ? '/usr/lib/libm.so' :
    $Config{archname} =~ /64/ ? '/lib64/libm.so.6' :
    '/lib/libm.so.6';
#
sub sin_ : Dyn(${libfile}, '(d)d',   'sin');
sub sin_var : Dyn(${libfile}, '(_:d)d', 'sin');
sub sin_ell : Dyn(${libfile}, '(_.d)d', 'sin');
sub sin_cdecl : Dyn(${libfile}, '(_cd)d', 'sin');
sub sin_std : Dyn(${libfile}, '(_sd)d', 'sin');
sub sin_fc : Dyn(${libfile}, '(_fd)d', 'sin');
sub sin_tc : Dyn(${libfile}, '(_#d)d', 'sin');
#
my $sin_default  = Dyn::load( $libfile, 'sin', 'd)d' );
my $sin_vararg   = Dyn::load( $libfile, 'sin', '_:d)d' );
my $sin_ellipsis = Dyn::load( $libfile, 'sin', '_.d)d' );
my $sin_cdecl    = Dyn::load( $libfile, 'sin', '_cd)d' );
my $sin_stdcall  = Dyn::load( $libfile, 'sin', '_sd)d' );
my $sin_fastcall = Dyn::load( $libfile, 'sin', '_fd)d' );
my $sin_thiscall = Dyn::load( $libfile, 'sin', '_#d)d' );
#
my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib($libfile);
my $ffi_func = $ffi->function( sin => ['double'] => 'double' );
$ffi->attach( [ sin => 'ffi_sin' ] => ['double'] => 'double' );
my $depth = 1000000;
cmpthese(
    timethese(
        -5,
        {   perl => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin($x); $x++ }
            },
            sin_ => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_($x); $x++ }
            },
            sin_var => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_var($x); $x++ }
            },
            sin_ell => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_ell($x); $x++ }
            },
            sin_cdecl => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_cdecl($x); $x++ }
            },
            sin_std => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_std($x); $x++ }
            },
            sin_fc => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_fc($x); $x++ }
            },
            sin_tc => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin_tc($x); $x++ }
            },
            call_default => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_default->call($x); $x++ }
            },
            call_vararg => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_vararg->call($x); $x++ }
            },
            call_ellipsis => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_ellipsis->call($x); $x++ }
            },
            call_cdecl => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_cdecl->call($x); $x++ }
            },
            call_stdcall => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_stdcall->call($x); $x++ }
            },
            call_fastcall => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_fastcall->call($x); $x++ }
            },
            call_thiscall => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_thiscall->call($x); $x++ }
            },
            ffi_attach => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = ffi_sin($x); $x++ }
            },
            ffi_function => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $ffi_func->call($x); $x++ }
            }
        }
    )
);
