#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Future::AsyncAwait;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

require Future;

=head1 NAME

C<Future::AsyncAwait> - deferred subroutine syntax for futures

=head1 SYNOPSIS

 use Future::AsyncAwait;

 async sub do_a_thing
 {
    my $first = await do_first_thing();

    my $second = await do_second_thing();

    return combine_things( $first, $second );
 }

 do_a_thing()->get;

This module provides syntax for deferring and resuming subroutines while
waiting for L<Future>s to complete.

B<WARNING>: The actual semantics in this module are in a very early state of
implementation. A few things work but most do not. Don't expect to be able to
use this module in any real code yet.

That said, the syntax parsing and semantics for immediate futures are already
defined and working. So it is already very slightly useful for writing simple
functions that return immediate futures.

Instead of writing

 sub foo
 {
    ...
    return Future->done( @result );
 }

you can now simply write

 async sub foo
 {
    ...
    return @result;
 }

with the added side-benefit that any exceptions thrown by the elided code will
be turned into an immediate-failed C<Future> rather than making the call
itself propagate the exception, which is usually what you wanted when dealing
with futures.

In addition, code such as the following simple case may work even on
non-immediate futures:

 async sub bar
 {
    my ( $f ) = @_;

    return 1 + await( $f ) + 3;
 }

For a more complete list of what is still unimplemented, see L</TODO>.

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my ( $caller, @syms ) = @_;

   my %syms = map { $_ => 1 } @syms;
   $^H{"Future::AsyncAwait/async"}++ if delete $syms{async};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 TODO

=over 4

=item *

Save and resume the PAD of the calling function, so that local variables are
preserved:

 async sub with_pad
 {
    my $x = func();

    await $F;

    print "I still have X: $x\n";
 }

=item *

Suspend and resume over other interesting types of context, such as BLOCK and
various LOOPs:

 async sub with_loop
 {
    while(1) {
       my $result = await func();
       return if $result;
    }
 }

=item *

Suspend and resume with some consideration for the savestack; i.e. the area
used to implement C<local> and similar:

 our $VAR;

 async sub with_local
 {
    local $VAR = "preserved";

    await $F;

    print "I still have VAR: $VAR\n";
 }

=item *

Clean up the implementation; check for and fix memory leaks.

=back

=head1 ACKNOWLEDGEMENTS

With thanks to C<Zefram>, C<ilmari> and others from C<irc.perl.org/#p5p> for
assisting with trickier bits of XS logic. Thanks to C<genio> for project
management and actually reminding me to write some code.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
