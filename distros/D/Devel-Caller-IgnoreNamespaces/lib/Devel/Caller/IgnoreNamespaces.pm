package Devel::Caller::IgnoreNamespaces;

use strict;
use warnings;

use vars qw(@NAMESPACES $VERSION);

$VERSION = '1.0';

sub register { push @NAMESPACES, @_; }

*CORE::GLOBAL::caller = sub (;$) {
  my ($height) = ($_[0]||0);
  my $i=1;
  my $name_cache;
  while (1) {
    my @caller = CORE::caller($i++) or return;
    $caller[3] = $name_cache if $name_cache;
    $name_cache = (grep { $caller[0] eq $_ } @NAMESPACES) # <-- !!!!
      ? $caller[3]
      : '';
    next if $name_cache || $height-- != 0;
    return wantarray ? @_ ? @caller : @caller[0..2] : $caller[0];
  }
};

1;

=head1 NAME

Devel::Caller::IgnoreNamespaces - make available a magic caller()
which can ignore namespaces that you tell it about

=head1 SYNOPSIS

    package Foo::Bar

    use Devel::Caller::IgnoreNamespaces;
    Devel::Caller::IgnoreNamespaces::register(__PACKAGE__);

=head1 DESCRIPTION

If your module should be ignored by caller(), just like Hook::LexWrap
is by its magic caller(), then call this module's register() subroutine
with its name.

=head1 SUBROUTINES

=head2 register('packagename', 'anotherpackage', ...)

Takes a list of packages that caller() will ignore in future.

=head1 BUGS and FEEDBACK

Please report any bugs using L<http://rt.cpan.org>.  The best bug
reports include a file with a test in it that fails with the current
code and will pass once the bug is fixed.

I welcome feedback, especially constructive criticism, by email.

Feature requests are more likely to be accepted if accompanied by a
patch and tests.

=head1 AUTHORS, COPYRIGHT and LICENCE

This module is maintained by David Cantrell E<lt>david@cantrell.org.ukE<gt>
and based almost entirely on code by Damian Conway.

Copyright 2001-2008 Damian Conway

Documentation and tests and some code copyright 2009 David Cantrell

You may use, modify and distribute this code under either the Artistic
Licence or the GNU GPL version 2.  See the ARTISTIC.txt or GPL2.txt files
for the full texts of the licences.

=cut
