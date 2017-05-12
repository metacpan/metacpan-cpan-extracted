#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::AST' ) || print "Bail out!\n";
}
use MarpaX::Languages::C::AST::Expected;

my $cSourceCode = do { local $/; <DATA> };
my $cAst = MarpaX::Languages::C::AST->new();
my $valuep = $cAst->parse(\$cSourceCode)->value();
ok(defined($valuep), 'Output from parse()->value() is ok');

__DATA__
// ----------
// alloc_text
// ----------
__pragma( alloc_text( "textsection" ))
__pragma( alloc_text( "textsection", function1 ))
__pragma( alloc_text( "textsection", function1 , function2 ))

// -----------
// auto_inline
// -----------
__pragma( auto_inline())
__pragma( auto_inline(on))
__pragma( auto_inline(off))

// -------
// warning
// -------
__pragma( warning( disable : 4507 34; once : 4385; error : 164 ))
__pragma( warning( disable : 4507 34 ))
__pragma( warning( once : 4385 ))
__pragma( warning( error : 164 ))
__pragma( warning(disable:4700))
__pragma( warning( push ))
__pragma( warning( disable : 4705 ))
__pragma( warning( disable : 4706 ))
__pragma( warning( disable : 4707 ))
__pragma( warning( pop ) )
__pragma( warning( push, 3 ))
__pragma( warning( pop ) )

// -------
// bss_seg
// -------
__pragma( bss_seg(".my_data1") )
__pragma( bss_seg(push, stack1, ".my_data2")   )
__pragma( bss_seg(pop, stack1) )

// -------
// code_seg
// -------
__pragma( code_seg(".my_data1") )
__pragma( code_seg(push, stack1, ".my_data2")   )
__pragma( code_seg(pop, stack1) )

// ---------
// const_seg
// ---------
__pragma( const_seg(".my_data1") )
__pragma( const_seg(push, stack1, ".my_data2")   )
__pragma( const_seg(pop, stack1) )

// --------
// data_seg
// --------
__pragma( data_seg(".my_data1") )
__pragma( data_seg(push, stack1, ".my_data2")   )
__pragma( data_seg(pop, stack1) )

// -----------
// check_stack
// -----------
__pragma( check_stack( ))
__pragma( check_stack (on))
__pragma( check_stack (off))
__pragma( check_stack (+))
__pragma( check_stack (-))

// -------
// comment
// -------
__pragma( comment(linker, "/include:__mySymbol"))
__pragma( comment( lib, "emapi" ) )
__pragma( comment( compiler ))
__pragma( comment( user, "Compiled on " "Some date" " at " "Some hour" ) )

// ---------
// component
// ---------
__pragma( component(browser, off))
__pragma( component(browser, off, references))
__pragma( component(browser, off, references, DWORD))
__pragma( component(browser, on, references, DWORD))
__pragma( component(browser, off, references, "NULL"))
__pragma( component( minrebuild, on ) )
__pragma( component( minrebuild, off ) )
__pragma( component( mintypeinfo, on ) )
__pragma( component( mintypeinfo, off ) )

// -------
// conform
// -------
__pragma( conform(forScope, show))
__pragma( conform(forScope, push, x, on))
__pragma( conform(forScope, push, x1, off))
__pragma( conform(forScope, push, x2, off))
__pragma( conform(forScope, push, x3, off))
__pragma( conform(forScope, show))
__pragma( conform(forScope, pop, x1))
__pragma( conform(forScope, show))

// ----------
// deprecated
// ----------
__pragma( deprecated(func1))
__pragma( deprecated(func1, func2))

// ---------------
// detect_mismatch
// ---------------
__pragma( detect_mismatch("myLib_version", "9"))

// -----------
// fenv_access
// -----------
__pragma( fenv_access)
__pragma( fenv_access(  ))
__pragma( fenv_access(on))
__pragma( fenv_access(ON))
__pragma( fenv_access(off))
__pragma( fenv_access(OFF))

// -------------
// float_control
// -------------
__pragma( float_control(except, off) )
__pragma( float_control(except, off push) )
__pragma( float_control(precise, off) )
__pragma( float_control(precise, off push) )
__pragma( float_control(precise, on) )
__pragma( float_control(precise, on push) )
__pragma( float_control(except, on) )
__pragma( float_control(except, on push) )
__pragma( float_control(push) )
__pragma( float_control(pop) )

// -----------
// fp_contract
// -----------
__pragma( fp_contract)
__pragma( fp_contract(  ))
__pragma( fp_contract(on))
__pragma( fp_contract(ON))
__pragma( fp_contract(off))
__pragma( fp_contract(OFF))

// --------
// function
// --------
__pragma( function(func1))
__pragma( function(func1, func2))

// -------
// hdrstop
// -------
__pragma( hdrstop )
__pragma( hdrstop ("c:\\projects\\include\\myinc.pch") )

// -------------
// include_alias
// -------------
__pragma( include_alias("mymath.h", "math.h"))
__pragma( include_alias( <stdio.h>, <newstdio.h> ))

// ------------
// inline_depth
// ------------
__pragma( inline_depth ())
__pragma( inline_depth ( 255 ))

// ----------------
// inline_recursion
// ----------------
__pragma( inline_recursion ())
__pragma( inline_recursion ( on ))
__pragma( inline_recursion ( off ))

// --------
// intrinsic
// --------
__pragma( intrinsic(func1))
__pragma( intrinsic(func1, func2))

// ----
// loop
// ----
__pragma( loop(hint_parallel(3)))
__pragma( loop(no_vector))
__pragma( loop(ivdep))

// -----------
// make_public
// -----------
__pragma( make_public(Native_Struct_1))

// -------
// managed
// -------
__pragma( managed)
__pragma( managed())
__pragma( managed(push, off))
__pragma( managed(pop))

// ---------
// unmanaged
// ---------
__pragma( unmanaged)
__pragma( unmanaged())

// -------
// message
// -------
__pragma( message("_M_IX86 >= 500"))

// ---------
// once
// ---------
__pragma( once)
__pragma( once())

// ---------
// optimize
// ---------
__pragma( optimize( "ts", on ))
__pragma( optimize( "", off ))
__pragma( optimize( "", on ))

// ----
// pack
// ----
__pragma(pack(2))
__pragma(pack())   // n defaults to 8; equivalent to /Zp8
__pragma(pack(show))   // C4810
__pragma(pack(4))   // n = 4
__pragma(pack(show))   // C4810
__pragma(pack(push, r1, 16))   // n = 16, pushed to stack
__pragma(pack(push, 16))   // n = 16, pushed to stack
__pragma(pack(show))   // C4810
__pragma(pack(pop, r1, 2))   // n = 2 , stack popped
__pragma(pack(pop, 2))   // n = 2 , stack popped
__pragma(pack(show))   // C4810

// -------------------
// pointers_to_members
// -------------------
__pragma( pointers_to_members( full_generality, single_inheritance ))

// --------------------
// pop_macro/push_macro
// --------------------
   __pragma(push_macro("Y"))
   __pragma(push_macro("X"))
   __pragma(pop_macro("X"))
   __pragma(pop_macro("Y"))

// ----------------
// region/endregion
// ----------------
__pragma(region)
__pragma(region())
__pragma(region(ThisRegion))
__pragma(endregion)
__pragma(endregion())
__pragma(endregion(ThisRegion))

// --------------
// runtime_checks
// --------------
__pragma(runtime_checks( "sc", restore ))
__pragma(runtime_checks( "", off ))
__pragma(runtime_checks( "", restore ))

// -------
// section
// -------
__pragma(section("mysec"))
__pragma(section("mysec",read))
__pragma(section("mysec",read, write))

// ---------
// setlocale
// ---------
__pragma( setlocale("dutch"))

// ---------------
// strict_gs_check
// ---------------
__pragma( strict_gs_check(push, on))
__pragma( strict_gs_check(on))
__pragma( strict_gs_check(push, off))
__pragma( strict_gs_check(off))
__pragma( strict_gs_check(pop))

// --------
// vtordisp
// --------
__pragma( vtordisp(2))
__pragma( vtordisp(on))
__pragma( vtordisp(off))
__pragma( vtordisp(push, 2))
__pragma( vtordisp(push, on))
__pragma( vtordisp(push, off))
__pragma( vtordisp(pop))
__pragma( vtordisp())
__pragma( vtordisp)

int f();
