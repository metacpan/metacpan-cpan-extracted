package Digest::SipHash;

use 5.008001;
use strict;
use warnings;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.21 $ =~ /(\d+)/g;
require XSLoader;
XSLoader::load( 'Digest::SipHash', $VERSION );

use base 'Exporter';
our @EXPORT_OK = qw/siphash siphash32/;

use constant BIG_ENDIAN => pack( "L", 1 ) eq pack( "N", 1 );
use constant USE64BITINT => eval { pack 'Q', 1 };

push @EXPORT_OK, 'siphash64' if USE64BITINT;
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
our $DEFAULT_SEED = pack 'C16', map { int( rand(256) ) } ( 0 .. 0xF );

sub siphash {
    my $str = shift;
    my $seed = shift || $DEFAULT_SEED;
    unless (@_) {
        utf8::downgrade($str,1);
        utf8::downgrade($seed,1);
    }
    use bytes;
    $seed .= substr( $DEFAULT_SEED, length($seed) ) if length($seed) < 16;
    my $lohi = _xs_siphash_av( $str, $seed );
    return wantarray ? @$lohi : $lohi->[0];
}

*siphash32 = \&siphash;

if (USE64BITINT) {
    *siphash64 = sub {
        my $str = shift;
        my $seed = shift || $DEFAULT_SEED;
        unless (@_) {
            utf8::downgrade($str,1);
            utf8::downgrade($seed,1);
        }
        use bytes;
        $seed .= substr( $DEFAULT_SEED, length($seed) ) if length($seed) < 16;
        return _xs_siphash64( $str, $seed );
    };
}

1;

=head1 NAME

Digest::SipHash - Perl XS interface to the SipHash algorithm

=head1 VERSION

$Id: SipHash.pm,v 0.21 2020/12/11 18:05:44 dankogai Exp $

=head1 SYNOPSIS

  use Digest::SipHash qw/siphash/;
  my $seed = pack 'C16', 0 .. 0xF;    # 16 chars long
  my $str = "hello world!";
  my ( $lo, $hi ) = siphash( $str, $seed );
  #  $lo = 0x10cf32e0, $hi == 0x7da9cd17
  my $u32 = siphash( $str, $seed )
  #  $u32 = 0x10cf32e0

  use Config;
  if ( $Config{use64bitint} ) {
    use Digest::SipHash qw/siphash64/;
    my $uint64 = siphash64( $str, $seed );    # scalar context;
    # $uint64 == 0x7da9cd1710cf32e0
  }

=head1 DESCRIPTION

SipHash is the default perl hash function for 64 bit builds now.

L<http://perl5.git.perl.org/perl.git/commit/3db6cbfca39da94d152d3e860e2aa79b9c6bb161>

L<https://131002.net/siphash/>

This module does only one thing - culculates the SipHash value of the
given string.

=head1 EXPORT

C<siphash()>, C<siphash32()> and C<siphash64()> on demand.

C<:all> to all of above

=head1 SUBROUTINES/METHODS

=head2 siphash

  my ($hi, $lo) = siphash($str [, $seed][, $no_downgrade]);
  my $uint32    = siphash($str [, $seed][, $no_downgrade]);

Calculates the SipHash value of C<$src> with $<$seed>.

If C<$seed> is omitted, it defaults to C<$Digest:::SipHash::DEFAULT_SEED>,
which is set randomly upon initialization of this module.

If C<$seed> is set but less than 16 bytes long, it is padded with C<$DEFAULT_SEED>.

To be compatible with 32-bit perl, It returns a pair of 32-bit
integers instead of a 64-bit integer.  Since C<Hash::Util::hash_value()>
always returns the lower 32-bit first so that:

  use Hash::Util qw/hash_seed hash_value/;
  use Digest::SipHash qw/siphash/;
  hash_value($str) == siphash($str, hash_seed()); # scalar context

always holds true when PERL_HASH_FUN_SIPHASH is in effect.

=head2 About Unicode

By default this module follows the same rules as Perl does regarding
hashing, utf8 strings are passed to utf8::downgrade() with the $fail_ok
flag set to true. This means that if the complete string can be downgraded
to non-utf8 prior to hashing it will be, otherwise it will be left in
utf8 form. This means that all strings which are string equivalent
hash equivalently, and may not be what you want. In which case you can
pass a third argument to the hash functions, which when true disables
the downgrade behavior.

=head2 siphash32

just an alias of C<siphash>.

=head2 siphash64

  my $uint64 = siphash64($str [, $seed]);

Calculates the SipHash value of C<$src> with C<$seed> in 64-bit.
Available on 64-bit platforms only.

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-digest-siphash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Digest-SipHash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::SipHash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Digest-SipHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-SipHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-SipHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-SipHash/>

=back

=head1 SEE ALSO

L<Hash::Util>, L<https://131002.net/siphash/>

=head1 ACKNOWLEDGEMENTS

B<SipHash: a fast short-input PRF>

by Jean-Philippe Aumasson & Daniel J. Bernstein

L<https://131002.net/siphash/>

=head1 LICENSE AND COPYRIGHT

=head2 csiphash.c

Copyright (c) 2013  Marek Majkowski

MIT License L<http://opensource.org/licenses/MIT>

L<https://github.com/majek/csiphash>

=head2 The rest of this module

Copyright 2013 Dan Kogai.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Digest::SipHash
