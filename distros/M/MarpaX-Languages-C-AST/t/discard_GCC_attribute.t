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
__attribute__ ((weak, alias ("__f")))
__attribute__((alloc_size(1,2)))
__attribute__((alloc_size(2)))
__attribute__ ((deprecated))
__attribute__ ((dllexport))
__attribute__ ((format (printf, 2, 3)))
__attribute__ ((format_arg (2)))
__attribute__((function_vector(0x18)))
__attribute__ ((ifunc ("resolve_memcpy")))
__attribute__ ((interrupt ("IRQ")))
__attribute__ ((interrupt ("dma0, dma1")))
__attribute__ ((interrupt))
__attribute__ ((interrupt ("dma1")))
__attribute__ ((interrupt ("dma0, dma1")))
__attribute__ ((interrupt ("timer0"), disinterrupt))
__attribute__ ((interrupt ("dma0, dma1"), forwarder_section ("tramp")))
__attribute__ ((interrupt))
__attribute__ ((interrupt, use_shadow_register_set))
__attribute__ ((interrupt, keep_interrupts_masked))
__attribute__ ((interrupt, use_debug_exception_return))
__attribute__ ((interrupt, use_shadow_register_set,
                               keep_interrupts_masked))
__attribute__ ((interrupt, use_shadow_register_set,
                               use_debug_exception_return))
__attribute__ ((interrupt, keep_interrupts_masked,
                               use_debug_exception_return))
__attribute__ ((interrupt, use_shadow_register_set,
                               keep_interrupts_masked,
                               use_debug_exception_return))
__attribute__((nonnull (1, 2)))
__attribute__((nonnull))
__attribute__ ((noreturn))
__attribute__((pcs("aapcs")))
__attribute__ ((pure))
__attribute__ ((section ("bar")))
__attribute__ ((sentinel))
__attribute__ ((sentinel(0)))
__attribute__ ((interrupt_handler,
                                    sp_switch ("alt_stack")))
__attribute__ ((__target__ ("arch=core2")))
__attribute__ ((__target__ ("sse3")))
__attribute__((version_id ("20040821")))
__attribute__ ((visibility ("protected")))
__attribute__ ((visibility ("hidden")))
__attribute__ ((warn_unused_result))
__attribute__ ((weakref ("y")))
__attribute__ ((weak, weakref, alias ("y")))
__attribute__ ((weakref))
__attribute__ ((alias ("y")))
__attribute__ ((aligned (16)))
__attribute__ ((aligned (8)))
__attribute__ ((deprecated))
__attribute__ ((packed))
__attribute__ ((section ("DUART_A")))
__attribute__ ((section ("DUART_B")))
__attribute__ ((section ("STACK")))
__attribute__ ((section ("INITDATA")))
__attribute__((section ("shared"), shared))
__attribute__ ((vector_size (16)))
__attribute__((io(0x123)))
__attribute__((cb(0x123)))
__attribute__ ((aligned (8)))
__attribute__ ((aligned))
__attribute__ ((__packed__))
__attribute__ ((__transparent_union__))
__attribute__((__may_alias__))
   __attribute__((altivec(vector__)))
     __attribute__((altivec(pixel__))) unsigned short
     __attribute__((altivec(bool__))) unsigned

int f();
