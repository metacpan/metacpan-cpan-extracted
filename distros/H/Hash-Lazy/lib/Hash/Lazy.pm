package Hash::Lazy;

use strict;
use warnings;
our $VERSION = '0.02';

use Sub::Exporter -setup => {
    exports => [ qw(Hash) ],
    groups => { default => [ qw(Hash) ] }
};

use Hash::Lazy::Tie;
sub Hash(&) {
    my $cb = shift;
    my %h = ();
    tie %h, 'Hash::Lazy::Tie', $cb, \%h;
    return \%h;
}

1;

__END__

=head1 NAME

Hash::Lazy - A Hash implementation with lazy evaluation feature

=head1 SYNOPSIS

Here's a fibonacci number calucator, recursively defined, memoized:

  use Hash::Lazy;
  my $fib = Hash { my ($h, $k)= @_; return $h->{$k-1} + $h->{$k-2} };
  $fib->{0} = 0;
  $fib->{1} = 1;

  say $fib->{10}; # 55

=head1 DESCRIPTION

Hash::Lazy is a way to have a lazy evaluated hash in your
program. Unlike other C<Hash::*> modules, it doesn't work on real hash
variables (those with % sigil). Read on to see how it works.

This module exports a keyword C<Hash> by default. If you cannot import
this keyword in your current namespace for any reasons, you can
re-named to 'lazy_hash' (or any other names or your choice) by saying:

    use Hash::Lazy Hash => { -as => 'lazy_hash' };

This C<Hash> keyword construct and returns an object that acts exactly
like a normal hash reference. It requies a code block as its only
argument. The block will be the builder to build the value of the
wanted key. Therefore, the current hash object and the key will be the
block arguments. This block need to either returns the value, or sets
it back to C<$hash>.

    # returns it
    $next = Hash {
        my ($hash, $key) = @_;
        return $key + 1;
    };

    # or assign it
    $next = Hash {
        my ($hash, $key) = @_;
        $hash->{$key} = $key + 1;
    };

The later takes advantages of the former if you do both.

The returned object is just like a hash reference, therefore it's safe to assign values to it, or clear it:

    # Clear all previously calculated values, and resets the seed.
    %$fib = ();
    $fib->{0} = 1;
    $fib->{1} = 1;

Notice that it's not ok to copy it to a hash:

    %fib = %$fib;

This basically freeze the magic-ness and the resulting %fib becomes
static. The builder will not be called through any access to the
%fib hash. Please be aware of this if you intend to do so.

The example code of fibonacci number above are also available at
examples/fib.pl in the distribution tarball.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

Other lazy evaluation modules on CPAN, like L<Scalar::Lazy>,
L<Tie::Array::Lazy>, L<Variable::Lazy>, L<Data::Lazy>, L<Data::Thunk>,
L<Scalar::Defer>, L<Object::Lazy>.

The Ruby Hash class constructor L<http://www.ruby-doc.org/core/classes/Hash.html>.

The Perl 6 version of fibonacciy number calculation is really awesome,
L<http://en.wikibooks.org/wiki/Fibonacci_number_program#Perl_6>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2019, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
