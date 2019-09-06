package List::Util::MaybeXS;
use strict;
use warnings;
use Exporter (); BEGIN { *import = \&Exporter::import }

our $VERSION = '1.500004';
$VERSION =~ tr/_//d;

our @EXPORT_OK;
BEGIN {
  @EXPORT_OK = qw(
    all any first min max minstr maxstr none notall
    product reduce sum sum0
    shuffle uniq uniqnum uniqstr
    pairs unpairs pairkeys pairvalues pairmap pairgrep pairfirst
    head tail
  );
}

BEGIN {
  my %need;
  @need{@EXPORT_OK} = ();
  local $@;
  if (eval { require List::Util; 1 }) {
    my @import = grep defined &{"List::Util::$_"}, keys %need;
    if ( ! eval { List::Util->VERSION(1.45) } ) {
      @import = grep !/^uniq/, @import;
    }
    List::Util->import(@import);
    delete @need{@import};
  }
  if (keys %need) {
    require List::Util::PP;
    List::Util::PP->import(keys %need);
  }
}

1;
__END__

=head1 NAME

List::Util::MaybeXS - L<List::Util> but with Pure Perl fallback

=head1 SYNOPSIS

  use List::Util::MaybeXS qw(
    any all
  );

=head1 DESCRIPTION

This module provides the same functions as L<List::Util>, but falls back to
pure perl implementations if the installed L<List::Util> is too old to provide
them.

Picking between L<List::Util>'s XS accellerated functions and the PP versions is
done on a per-sub basis, so using this module should never result in a slowdown
over using L<List::Util> directly.

=head1 FUNCTIONS

=over

=item L<all|List::Util/all>

=item L<any|List::Util/any>

=item L<first|List::Util/first>

=item L<min|List::Util/min>

=item L<max|List::Util/max>

=item L<minstr|List::Util/minstr>

=item L<maxstr|List::Util/maxstr>

=item L<none|List::Util/none>

=item L<notall|List::Util/notall>

=item L<product|List::Util/product>

=item L<reduce|List::Util/reduce>

=item L<sum|List::Util/sum>

=item L<sum0|List::Util/sum0>

=item L<shuffle|List::Util/shuffle>

=item L<uniq|List::Util/uniq>

=item L<uniqnum|List::Util/uniqnum>

=item L<uniqstr|List::Util/uniqstr>

=item L<pairs|List::Util/pairs>

=item L<unpairs|List::Util/unpairs>

=item L<pairkeys|List::Util/pairkeys>

=item L<pairvalues|List::Util/pairvalues>

=item L<pairmap|List::Util/pairmap>

=item L<pairgrep|List::Util/pairgrep>

=item L<pairfirst|List::Util/pairfirst>

=item L<head|List::Util/head>

=item L<tail|List::Util/tail>

=back

=head1 DIFFERENCES FROM List::Util

As the subs provided are implemented in perl, there are some minor differences
with the interface.

=over 4

=item C<@_> in blocks

Inside a callback block (such as C<any { }>), C<@_> will be empty when using the
pure perl implementation.  With the XS implementation, the outer C<@_> will be
visible.  Under the perl debugger, the XS implementation will also not be able
to see the outer C<@_>.

=back

=head1 AUTHORS

Graham Knop <haarg@haarg.org>

Paul Evans <leonerd@leonerd.org.uk>

Graham Barr <gbarr@pobox.com>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2017 the List::Util::MaybeXS L</AUTHORS> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
