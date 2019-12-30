package ISAL::Crypto;

use strict;
use warnings;

require Exporter;

use constant {
	UPDATE => 0x00,
	FIRST => 0x01,
	LAST => 0x02,
	ENTIRE => 0x03,
	
	CTX_STS_IDLE => 0x00,
	CTX_STS_PROCESSING => 0x01,
	CTX_STS_LAST => 0x02,
	CTX_STS_COMPLETE => 0x04,
	
	CTX_ERROR_NONE => 0,
	CTX_ERROR_INVALID_FLAGS => -1,
	CTX_ERROR_ALREADY_PROCESSING => -2,
	CTX_ERROR_ALREADY_COMPLETED => -3,
	
	SHA1_MAX_LANES => 16,
	SHA1_MIN_LANES => 4,
	
	SHA256_MAX_LANES => 16,
	SHA256_MIN_LANES => 4,
	
	SHA512_MAX_LANES => 8,
	SHA512_MIN_LANES => 2,
	
	MD5_MAX_LANES => 32,
	MD5_MIN_LANES => 8,
};

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use ISAL::Crypto ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	UPDATE
	FIRST
	LAST
	ENTIRE
	CTX_STS_IDLE
	CTX_STS_PROCESSING
	CTX_STS_LAST
	CTX_STS_COMPLETE
	CTX_ERROR_NONE
	CTX_ERROR_INVALID_FLAGS
	CTX_ERROR_ALREADY_PROCESSING
	CTX_ERROR_ALREADY_COMPLETED
	
	SHA1_MAX_LANES
	SHA1_MIN_LANES
	
	SHA256_MAX_LANES
	SHA256_MIN_LANES
	
	SHA512_MAX_LANES
	SHA512_MIN_LANES
	
	MD5_MAX_LANES
	MD5_MIN_LANES
	
	CPU_FEATURES
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = 0.01;

require XSLoader;
XSLoader::load('ISAL::Crypto', $VERSION);

sub get_cpu_features {
	my $features = ISAL::Crypto::CPU_FEATURES();
	return grep !/\A\z/, map {
		lc s/\AHAS_(.+)\z/$1/r if $features->{$_}
	} grep /\AHAS_(?:SSE|AVX|AVX2|AVX512)\z/, keys %{$features};
}

1;
__END__

=head1 NAME

L<ISAL::Crypto> - Perl interface for Intel(R) Intelligent Storage
Acceleration Library Crypto Version - collection of optimized low-level
functions targeting storage applications.

=cut

=head1 SYNOPSIS

    use ISAL::Crypto qw(:all);
    my $feature = "avx512";

    my $init = "init_$feature";
    my $mgr = ISAL::Crypto::Mgr::SHA256->$init();

    my $ctx1 = ISAL::Crypto::Ctx::SHA256->init();
    my $ctx2 = ISAL::Crypto::Ctx::SHA256->init();

    my $submit = "submit_$feature";
    $mgr->$submit($ctx1, $str1, ENTIRE);

    $mgr->$submit($ctx2, $str2, FIRST);
    $mgr->$submit($ctx2, $str3, UPDATE);
    $mgr->$submit($ctx2, $str4, UPDATE);
    $mgr->$submit($ctx2, $str5, LAST);

    my $flush = "flush_$feature";
    while ($mgr->$flush()){};

    my $result_digest1 = $ctx1->get_digest();
    my $result_digest2 = $ctx2->get_digest();

=head1 ABSTRACT

L<ISAL::Crypto> - allows to run multiple hash calculations at the same time
on one cpu using vector registers for much better throuput than usual single
registers calculations.

=head1 SUBROUTINES/METHODS

=head2 Detect CPU features methods

=over 4

=item ISAL::Crypto::CPU_FEATURES

Return hash reference with format C<< {"HAS_$FEATURE_NAME_UPPERCASE" => 1,} >>.
For example:
C<< {
    HAS_SSE  => 1,
    HAS_AVX  => 1,
    HAS_AVX2 => 0,
    HAS_AVX512   => 0,
    HAS_AVX512F  => 0,
    HAS_AVX512VL => 0,
    HAS_AVX512BW => 0,
    HAS_AVX512CD => 0,
    HAS_AVX512DQ => 0,
} >>

=item ISAL::Crypto::get_cpu_features

Return list of available CPU features names in lowercase: ("sse", "avx").

=back

=head2 Mgr methods

=head4 init_*

=over 4

=item ISAL::Crypto::Mgr::SHA1->init_sse()

=item ISAL::Crypto::Mgr::SHA1->init_avx()

=item ISAL::Crypto::Mgr::SHA1->init_avx2()

=item ISAL::Crypto::Mgr::SHA1->init_avx512()

=item ISAL::Crypto::Mgr::SHA256->init_sse()

=item ISAL::Crypto::Mgr::SHA256->init_avx()

=item ISAL::Crypto::Mgr::SHA256->init_avx2()

=item ISAL::Crypto::Mgr::SHA256->init_avx512()

=item ISAL::Crypto::Mgr::SHA512->init_sse()

=item ISAL::Crypto::Mgr::SHA512->init_avx()

=item ISAL::Crypto::Mgr::SHA512->init_avx2()

=item ISAL::Crypto::Mgr::SHA512->init_avx512()

=item ISAL::Crypto::Mgr::MD5->init_sse()

=item ISAL::Crypto::Mgr::MD5->init_avx()

=item ISAL::Crypto::Mgr::MD5->init_avx2()

=item ISAL::Crypto::Mgr::MD5->init_avx512()

Init mgr taking in account CPU features.
Return C<"ISAL::Crypto::Mgr::$ALGO"> reference.

=back

=head4 submit_*

=over 4

=item $mgr->submit_sse($ctx, $str, $mask)

=item $mgr->submit_avx($ctx, $str, $mask)

=item $mgr->submit_avx2($ctx, $str, $mask)

=item $mgr->submit_avx512($ctx, $str, $mask)

Submit C<$ctx> taking in account CPU features with C<$str> and mask with
values: (0: UPDATE), (1: FIRST), (2: LAST), (3: ENTIRE).

Return C<$ctx> with the stampted error status if it is imposible to submit
it now or if there were maximum submited contexts and manager flush them all.
You can unsubmited job with C<undef $ctx> - and it will be cleared from manager.

C<$str> B<MUST TO BE IN SAFE> until C<< $mgr->flush_* >> will be called.
If C<$str> has been freed then C<< $mgr->flush_* >> (or later call
of C<< $mgr->submit_* >> with fully filled slots for contexts) behaviour
IS UNDEFINED. It can lead to segmentation fault or incorrect digest
value results.

=back

=head4 flush_*

=over 4

=item $mgr->flush_sse()

=item $mgr->flush_avx()

=item $mgr->flush_avx2()

=item $mgr->flush_avx512()

Flush all submited context jobs taking in account CPU features.
When the first job is finished its C<$ctx> will be returned.

=item $mgr->get_num_lanes_inuse()

Return the number of used manager's lanes.

=back

=head2 Ctx methods

=over 4

=item ISAL::Crypto::Ctx::SHA1->init()

=item ISAL::Crypto::Ctx::SHA256->init()

=item ISAL::Crypto::Ctx::SHA512->init()

=item ISAL::Crypto::Ctx::MD5->init()

Init ctx and return C<"ISAL::Crypto::Ctx::$ALGO"> reference.

=item $ctx->get_digest()

Returns the digest encoded as a binary string.

=item $ctx->get_digest_hex()

Returns the digest encoded as a hexadecimal string.

=item $ctx->get_status()

Returns the number value of context status. Values: (0: CTX_STS_IDLE),
(1: CTX_STS_PROCESSING), (2: CTX_STS_LAST), (4: CTX_STS_COMPLETE).

=item $ctx->get_error()

Returns the number value of context error. Values: (0: CTX_ERROR_NONE),
(-1: CTX_ERROR_INVALID_FLAGS), (-2: CTX_ERROR_ALREADY_PROCESSING),
(-3: CTX_ERROR_ALREADY_COMPLETED).

=back

=cut

=head2 EXPORT

Nothing is exported by default.

=cut

=head1 Benchmarks

To start benchmark run C<make bench> in console.

=cut

=head1 Not Yet Implemented (NYI)

=over 4

=item Several cpu features usage (sha_ni, sse3)

=item Multi-hash

=item Multi-hash + murmur

=item AES - block ciphers (XTS, GCM, CBC)

=item Rolling hash

=back

=cut

=head1 Prerequisites

=over 4

=item Assembler: nasm v2.11.01 or later (nasm v2.13 or better suggested for building in AVX512 support) or yasm version 1.2.0 or later.

=item Compiler: gcc, clang or icc compiler.

=item Make: GNU 'make'

=item Optional: Building with autotools requires autoconf/automake packages.

=back

=cut

=head1 Resources

=over 4

=item L<https://lists.01.org/hyperkitty/list/isal@lists.01.org/> - isa-l_crypto mailing list.

=back

=cut

=head1 AUTHOR

Sergey Kaplun, E<lt>burii@cpan.org<gt>,

=head1 ACKNOWLEDGEMENTS

Mons Anderson - The rationale and motivation

=head1 BUGS

Please report any bugs or feature requests in L<https://github.com/Buristan/ISAL-Crypto/issues>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Sergey Kaplun

This program is released under the following license: BSD 3-Clause

=cut
