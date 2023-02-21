#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::Hooks 0.02;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Future::AsyncAwait::Hooks> - scoped hook blocks that run extra code around C<await> expressions

=head1 SYNOPSIS

   use Future::AsyncAwait;
   use Future::AsyncAwait::Hooks;

   async sub do_work
   {
      suspend { say "do_work is pausing here" }
      resume  { say "do_Work has woken up again" }

      my $result = (await inner_1()) + (await inner_2());
      return $result;
   }

=head1 DESCRIPTION

This module provides two extra syntax keywords for inserting code that can
observe the suspend and resume behaviour of C<await> expressions within an
C<async sub>.

These two keywords are lexically scoped. They affect C<await> expressions
later within their own scope, or scopes nested within it. They do not affect
any C<await> expressions in scopes outside of those in which they appear.

=cut

=head1 KEYWORDS

=head2 suspend

   async sub {
      suspend { BLOCK }
   }

Inserts a block of code to run every time a subsequent C<await> expression
at this block level pauses execution of the C<async sub>.

=head2 resume

   async sub {
      resume { BLOCK }
   }

Inserts a block of code to run every time a subsequent C<await> expression
at this block level resumes execution of the C<async sub> after a pause.

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

   @syms or @syms = qw( suspend resume );

   my %syms = map { $_ => 1 } @syms;

   foreach (qw( suspend resume )) {
      $^H{"Future::AsyncAwait::Hooks/$_"}++ if delete $syms{$_};
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 TODO

=over 4

=item *

Maybe work out why it doesn't appear to work on perls older than 5.24. Or
maybe nobody will be writing new code and needs it back that old?

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
