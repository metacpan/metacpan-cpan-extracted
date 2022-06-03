# -*- Perl -*-
#
# most of the code, however, is over in Eforth.xs

package Language::Eforth;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load( 'Language::Eforth', $VERSION );

# more utility bloat
sub signed   { unpack s => pack s => $_[0] }
sub unsigned { unpack S => pack S => $_[0] }

# ( I complain about bloat here but then Chrome takes upwards of 10
# seconds to process a string much shorter than this sentence being
# pasted into the URL bar ... )

1;
__END__

=head1 NAME

Language::Eforth - a tiny embedded Forth interpreter

=head1 SYNOPSIS

  use Language::Eforth;
  my $f = Language::Eforth->new;

  $f->eval("2 2 + .s\n");
  print scalar $f->pop, "\n";

  $f->push(3, 7);
  print "depth: ", $f->depth, "\n";

  $f->eval("+\n");
  print scalar $f->pop, "\n";

  $f->reset;

  # there are, however, better ways to reverse a list of small
  # integers than this
  $f->eval("1 2 3 4\n");
  my @reverse = $f->drain;  # qw(4 3 2 1)

=head1 DESCRIPTION

This module embeds a tiny embeddable Forth interpreter.

L<https://github.com/howerj/embed>

The interpreter has a 16-bit cell size, does not support floating point
values, AND CONTRARY TO THE ans fORTH SPECIFICATION REQUIRES LOWER-CASE
WORDS. Consult C<embed.fth> for details on various "Error Codes" and
other documentation.

Memory usage while not zero should not be very significant; it mostly
depends on the C<EMBED_CORE_SIZE> count of 16-bit cells allocated. And
whatever Perl needs. Assertion failures are also possible, unless the
compile was somehow done with C<-DNDEBUG>.

=head1 METHODS

These may C<croak> should something be awry with the input, or if memory
allocation fails in the constructor.

=over 4

=item B<depth>

Returns the data stack depth as an unsigned integer.

=item B<drain>

Utility method to drain the data stack of all values as unsigned
integers, or returns the empty list otherwise. See also B<reset>.

Since version 0.02.

=item B<eval> I<expr>

Evaluates the string I<expr>. I<expr> MUST end with a newline. Output
from words such as C<.s> or C<.> or C<u.> is sent to standard output;
use L<Capture::Tiny> or similar to redirect this, if need be.

Input could be specified in a heredoc (see C<eg/shape> for an example)
or could be loaded into a string via a module like L<File::Slurper>.

No return value.

=item B<new>

Constructor. Returns a pointer to the interpreter used by the
other methods.

=item B<pop>

Pops an unsigned integer off of the data stack. In list context this
returns the value and the return code. If the code is non-zero something
went awry, probably a stack under- or overflow.

  my ( $value, $failed ) = $f->pop;
  if ( $failed ) { die "pop failed ($failed)\n" }

Otherwise, use the return value in scalar context, but then there is a
semipredicate problem where C<0> could mean the value zero, or that
there was a failure:

  my $v;
  $f->reset;              # empty the stack
  $f->eval("2 2 xor\n");  # calculate a value
  $v = scalar $f->pop;    # 0, the value
  $v = scalar $f->pop;    # 0, the semipredicate (underflow)

The value can be made 16-bit signed via:

  $f->push(54321);
  my $x = $f->pop;
  my $y = Language::Eforth::signed($x);
  say "$y $x";            # -11215 54321

See also B<drain>.

=item B<push> I<integer> [ I<integer> .. ]

Pushes I<integer>s onto the data stack. Values will be modulated to the
16-bit cell size:

  $f->push(-1); 
  $f->eval("u.\n");       # 65535

Returns the number of items pushed and the return code of the last item
pushed. The count may be fewer than the number of items supplied; if so,
the return code is likely some non-zero value.

  my ( $count, $status ) = $f->push(@long_list);
  if ( $count != @long_list ) { die "get a bigger box\n"; }

Note that B<embed_push> uses a C<cell_t> or C<uint16_t> so the integer
goes through both Perl's C<SvUV> and then C's C<uint16_t>. How the forth
treats the bit patterns in the stack depends on the word involved, e.g.
C<.> verses C<u.>.

  $f->push(-1); 
  $f->eval(" dup .  dup u. \n");

Since version 0.02 B<push> accepts multiple values.

=item B<reset>

Resets the state of the interpreter. Among other things this will clear
the data stack. See also B<drain>.

No return value.

=back

=head1 FUNCTIONS

These utility functions are not exported.

=over 4

=item B<signed> I<value>

The B<pop> and B<drain> methods tend to return unsigned short values
(C<uint16_t>); such values may need conversion on the Perl side to be
signed (C<int16_t>) for display or debugging needs. This function runs
the given value through an signed short conversion and returns the
result, after the fashion of Procrustes with his guests.

Since version 0.02.

=item B<unsigned> I<value>

Ensures that I<value> falls within the C<uint16_t> range. This will
probably happen automatically for values passed to B<push> as
B<embed_push> expects a C<uint16_t> argument.

Since version 0.02.

=back

=head1 SEE ALSO

L<https://github.com/howerj/embed>

"Starting FORTH". Leo Brodie. 1981.

=head1 COPYRIGHT & LICENSE

Copyright 2022 Jeremy Mates, All Rights Reserved.

This program is distributed under the (Revised) BSD License.

=cut
