# NAME

[ISAL::Crypto](https://metacpan.org/pod/ISAL%3A%3ACrypto) - Perl interface for Intel(R) Intelligent Storage
Acceleration Library Crypto Version - collection of optimized low-level
functions targeting storage applications.

# SYNOPSIS

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

# ABSTRACT

[ISAL::Crypto](https://metacpan.org/pod/ISAL%3A%3ACrypto) - allows to run multiple hash calculations at the same time
on one cpu using vector registers for much better throuput than usual single
registers calculations.

# SUBROUTINES/METHODS

## Detect CPU features methods

- ISAL::Crypto::CPU\_FEATURES

    Return hash reference with format `{"HAS_$FEATURE_NAME_UPPERCASE" => 1,}`.
    For example:
    `{
        HAS_SSE  => 1,
        HAS_AVX  => 1,
        HAS_AVX2 => 0,
        HAS_AVX512   => 0,
        HAS_AVX512F  => 0,
        HAS_AVX512VL => 0,
        HAS_AVX512BW => 0,
        HAS_AVX512CD => 0,
        HAS_AVX512DQ => 0,
    }`

- ISAL::Crypto::get\_cpu\_features

    Return list of available CPU features names in lowercase: ("sse", "avx").

## Mgr methods

#### init\_\*

- ISAL::Crypto::Mgr::SHA1->init\_sse()
- ISAL::Crypto::Mgr::SHA1->init\_avx()
- ISAL::Crypto::Mgr::SHA1->init\_avx2()
- ISAL::Crypto::Mgr::SHA1->init\_avx512()
- ISAL::Crypto::Mgr::SHA256->init\_sse()
- ISAL::Crypto::Mgr::SHA256->init\_avx()
- ISAL::Crypto::Mgr::SHA256->init\_avx2()
- ISAL::Crypto::Mgr::SHA256->init\_avx512()
- ISAL::Crypto::Mgr::SHA512->init\_sse()
- ISAL::Crypto::Mgr::SHA512->init\_avx()
- ISAL::Crypto::Mgr::SHA512->init\_avx2()
- ISAL::Crypto::Mgr::SHA512->init\_avx512()
- ISAL::Crypto::Mgr::MD5->init\_sse()
- ISAL::Crypto::Mgr::MD5->init\_avx()
- ISAL::Crypto::Mgr::MD5->init\_avx2()
- ISAL::Crypto::Mgr::MD5->init\_avx512()

    Init mgr taking in account CPU features.
    Return `"ISAL::Crypto::Mgr::$ALGO"` reference.

#### submit\_\*

- $mgr->submit\_sse($ctx, $str, $mask)
- $mgr->submit\_avx($ctx, $str, $mask)
- $mgr->submit\_avx2($ctx, $str, $mask)
- $mgr->submit\_avx512($ctx, $str, $mask)

    Submit `$ctx` taking in account CPU features with `$str` and mask with
    values: (0: UPDATE), (1: FIRST), (2: LAST), (3: ENTIRE).

    Return `$ctx` with the stampted error status if it is imposible to submit
    it now or if there were maximum submited contexts and manager flush them all.
    You can unsubmited job with `undef $ctx` - and it will be cleared from manager.

    `$str` **MUST TO BE IN SAFE** until `$mgr->flush_*` will be called.
    If `$str` has been freed then `$mgr->flush_*` (or later call
    of `$mgr->submit_*` with fully filled slots for contexts) behaviour
    IS UNDEFINED. It can lead to segmentation fault or incorrect digest
    value results.

#### flush\_\*

- $mgr->flush\_sse()
- $mgr->flush\_avx()
- $mgr->flush\_avx2()
- $mgr->flush\_avx512()

    Flush all submited context jobs taking in account CPU features.
    When the first job is finished its `$ctx` will be returned.

- $mgr->get\_num\_lanes\_inuse()

    Return the number of used manager's lanes.

## Ctx methods

- ISAL::Crypto::Ctx::SHA1->init()
- ISAL::Crypto::Ctx::SHA256->init()
- ISAL::Crypto::Ctx::SHA512->init()
- ISAL::Crypto::Ctx::MD5->init()

    Init ctx and return `"ISAL::Crypto::Ctx::$ALGO"` reference.

- $ctx->get\_digest()

    Returns the digest encoded as a binary string.

- $ctx->get\_digest\_hex()

    Returns the digest encoded as a hexadecimal string.

- $ctx->get\_status()

    Returns the number value of context status. Values: (0: CTX\_STS\_IDLE),
    (1: CTX\_STS\_PROCESSING), (2: CTX\_STS\_LAST), (4: CTX\_STS\_COMPLETE).

- $ctx->get\_error()

    Returns the number value of context error. Values: (0: CTX\_ERROR\_NONE),
    (-1: CTX\_ERROR\_INVALID\_FLAGS), (-2: CTX\_ERROR\_ALREADY\_PROCESSING),
    (-3: CTX\_ERROR\_ALREADY\_COMPLETED).

## EXPORT

Nothing is exported by default.

# Benchmarks

To start benchmark run `make bench` in console.

# Not Yet Implemented (NYI)

- Several cpu features usage (sha\_ni, sse3)
- Multi-hash
- Multi-hash + murmur
- AES - block ciphers (XTS, GCM, CBC)
- Rolling hash

# Prerequisites

- Assembler: nasm v2.11.01 or later (nasm v2.13 or better suggested for building in AVX512 support) or yasm version 1.2.0 or later.
- Compiler: gcc, clang or icc compiler.
- Make: GNU 'make'
- Optional: Building with autotools requires autoconf/automake packages.

# Resources

- [https://lists.01.org/hyperkitty/list/isal@lists.01.org/](https://lists.01.org/hyperkitty/list/isal@lists.01.org/) - isa-l\_crypto mailing list.

# AUTHOR

Sergey Kaplun, &lt;burii@cpan.org&lt;gt>,

# ACKNOWLEDGEMENTS

Mons Anderson - The rationale and motivation

# BUGS

Please report any bugs or feature requests in [https://github.com/Buristan/ISAL-Crypto/issues](https://github.com/Buristan/ISAL-Crypto/issues)

# COPYRIGHT AND LICENSE

Copyright (C) 2019 by Sergey Kaplun

This program is released under the following license: BSD 3-Clause
