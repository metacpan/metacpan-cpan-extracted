#ifndef DEVEL_STACKBLECH
#define DEVEL_STACKBLECH

/*
 * Dump all levels of the interpreter's runloop stacks.
 *
 * This is the backend, reuseable implementation for the perl function C<dumpStacks()>.
 */
void dsb_dumpStacks();

/*
 * Dump all contexts in this runloop level.
 */
void dsb_dumpFrames( PERL_SI *si );

/*
 * Dump a context.
 */
void dsb_dumpFrame( const PERL_CONTEXT *const cx );

#endif
