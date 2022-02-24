#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Feature::Compat::Defer 0.02;

use v5.14;
use warnings;
use feature ();

use constant HAVE_FEATURE_DEFER => defined $feature::feature{defer};

=head1 NAME

C<Feature::Compat::Defer> - make C<defer> syntax available

=head1 SYNOPSIS

   use Feature::Compat::Defer;

   {
      my $dbh = DBI->connect( ... ) or die "Cannot connect";
      defer { $dbh->disconnect; }

      my $sth = $dbh->prepare( ... ) or die "Cannot prepare";
      defer { $sth->finish; }

      ...
   }

=head1 DESCRIPTION

This module provides a new syntax keyword, C<defer>, in a forward-compatible
way.

The latest perl development source provides a C<defer> block syntax, under
the C<defer> named feature. If all goes well, this will become available at
development version 5.35.4, and included in the 5.36 release. On such perls,
this module simply enables that feature.

On older versions of perl before such syntax is available. this module will
instead depend on and use L<Syntax::Keyword::Defer> to provide it.

=cut

=head1 KEYWORDS

=head2 defer

   defer {
      STATEMENTS...
   }

The C<defer> keyword introduces a block which runs its code body at the time
that its immediately surrounding code block finishes.

When the C<defer> statement is encountered, the body of the code block is
pushed to a queue of pending operations, which is then flushed when the
surrounding block finishes for any reason - either by implicit fallthrough,
or explicit termination by C<return>, C<die> or any of the loop control
statements C<next>, C<last> or C<redo>.

For more information, see additionally the documentation in
L<Syntax::Keyword::Defer/defer> and, on a recent enough perl,
L<perlsyn/"defer blocks">.

=cut

sub import
{
   if( HAVE_FEATURE_DEFER ) {
      feature->import(qw( defer ));
      require warnings;
      warnings->unimport(qw( experimental::defer ));
   }
   else {
      require Syntax::Keyword::Defer;
      Syntax::Keyword::Defer->VERSION( '0.06' );
      Syntax::Keyword::Defer->import(qw( defer ));
   }
}

=head1 COMPATIBILITY NOTES

This module may use either L<Syntax::Keyword::Defer> or the perl core C<defer>
feature to implement its syntax. While the two behave very similarly, and both
conform to the description given above, the following differences should be
noted.

=over 4

=item * Double Exceptions

Because C<defer> blocks will run during stack unwind because of exception
propagation it is possible to encounter a second exception within the block,
thus having two "in flight" at once. Neither C<Syntax::Keyword::Defer> nor
core's C<defer> feature currently guarantees what exception will be seen by
the caller in such a situation, other than that some kind of exception will
definitely happen.

In particular, you should not rely on definitely receiving either the first,
or the final exception, in this situation.

=item * Fragile Against Erroneous Control Flow

The core C<defer> feature tries hard to forbid various kinds of problematic
control that jumps into or out of C<defer> blocks. In particular, things like
using C<last> to jump out of a control loop that is outside the C<defer> block
are banned.

By comparison, there is less that C<Syntax::Keyword::Defer> can do about this
situation because it does not have access to as many parser and compiler
tricks as the core implementation. Therefore, there are some situations that
the core feature can prohibit statically, that C<Syntax::Keyword::Defer> can
only detect at runtime - if at all. There may be odd cases where prohibited
behaviour performs differently between the two implementations.

As long as you don't do anything "weird" like using loop controls or C<goto>
to abuse the flow of control into or out of a C<defer> block, this should not
cause a problem.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
