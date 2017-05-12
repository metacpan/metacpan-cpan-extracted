package Devel::Valgrind::Client;
use strict;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Devel::Valgrind::Client', $VERSION);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(is_in_memcheck count_leaks do_leak_check do_quick_leak_check leak_check);

sub leak_check(&) {
  my $code = shift;

  do_quick_leak_check();
  my $start = count_leaks();

  $code->();

  do_quick_leak_check();
  my $end = count_leaks();

  @$end{keys %$end} = map { $end->{$_} - $start->{$_} } keys %$end;
  return $end;
}

1;

__END__

=head1 NAME

Devel::Valgrind::Client - Make valgrind memcheck client requests

=head1 SYNOPSIS

  # Run the following code under Valgrind

  use Devel::Valgrind::Client qw(leak_check);

  my $result = leak_check {
    # Code to check here.

    # The following two lines are deliberately leaky:
    my $x = "a" x 1_000;
    Internals::SvREFCNT($x, 2); # Don't do this in real code, please
  };

  # Should print just over 1000 (i.e. SvLEN + sizeof(SVPV))
  warn "Lost $result->{leaked} bytes";

=head1 DESCRIPTION

Valgrind provides the ability for a program that is running under Valgrind's
memcheck tool ("being valgrinded") to make requests to the Valgrind VM through
macros defined in C<<valgrind/memcheck.h>>.

This module provides a way to access some of these calls from Perl, such as to
find out if a program is running under memcheck, to force a leak check
operation and retrieve statistics of the check.

The reason this module was created was to test XS code does not leak, however
note that for many cases L<Test::Valgrind> will be a better choice. The
difference compared to L<Test::Valgrind> is this runs within the same process;
it is your responsibility to arrange for the program to run under Valgrind.

(Potentially it can also be used to count how many bytes are allocated -- by
deliberately leaking memory -- although there are other choices for that, such
as L<Devel::Mallinfo>)

To compile this module you will need Valgrind installed, as it uses a header
file Valgrind provides.

=head1 EXPORTS

Nothing by default. The following are available by request:

=over 4

=item * leak_check($coderef)

A high level interface.

The steps performed are as follows:

=over 4

=item *

Request memcheck to run a leak check and record the statistics.

=item *

Run the code reference given as an argument.

=item *

Request memcheck to perform a leak check again and take the values that were
reported previously from the leak statistics.

=back

The return value is as per C</count_leaks>, with the statistics adjusted
appropriately.

=item * is_in_memcheck

Returns true if perl is running under memcheck, false otherwise.

=item * count_leaks

Returns a hash reference:
  leaked
  dubious
  reachable
  suppressed

=item * count_leaks_blocks

=item * do_leak_check

=item * do_leak_check_quick

=back

=head1 LICENSE

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2, as
published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING or
L<Software::License::WTFPL_2> for more details.

=head1 AUTHOR

David Leadbeater E<lt>L<dgl@dgl.cx>E<gt>, 2010

=cut

