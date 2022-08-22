package TestCommon;

use warnings;
use strict;

use Data::Dumper;
use File::KDBX::Constants qw(:magic :kdf);
use File::KDBX::Util qw(can_fork dumper);
use File::Spec;
use FindBin qw($Bin);
use Test::Fatal;
use Test::Deep;

BEGIN {
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Deparse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Quotekeys = 0;
    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Trailingcomma = 1;
    $Data::Dumper::Useqq = 1;
}

sub import {
    my $self = shift;
    my @args = @_;

    my $caller = caller;

    require Test::Warnings;
    my @warnings_flags;
    push @warnings_flags, ':no_end_test' if !$ENV{AUTHOR_TESTING} || grep { $_ eq ':no_warnings_test' } @args;
    Test::Warnings->import(@warnings_flags);

    # Just export a random assortment of things useful for testing.
    no strict 'refs';
    *{"${caller}::dumper"}      = \&File::KDBX::Util::dumper;

    *{"${caller}::exception"}   = \&Test::Fatal::exception;
    *{"${caller}::warning"}     = \&Test::Warnings::warning;
    *{"${caller}::warnings"}    = \&Test::Warnings::warnings;

    *{"${caller}::dump_test_deep_template"}  = \&dump_test_deep_template;
    *{"${caller}::ok_magic"}    = \&ok_magic;
    *{"${caller}::fast_kdf"}    = \&fast_kdf;
    *{"${caller}::can_fork"}    = \&can_fork;
    *{"${caller}::testfile"}    = \&testfile;
}

sub testfile {
    return File::Spec->catfile($Bin, 'files', @_);
}

sub dump_test_deep_template {
    my $struct = shift;

    my $str = Dumper $struct;
    # booleans: bless( do{\(my $o = 1)}, 'boolean' )
    $str =~ s/bless\( do\{\\\(my \$o = ([01])\)\}, 'boolean' \)/bool($1)/gs;
    # objects
    $str =~ s/bless\(.+?'([^']+)' \)/obj_isa('$1')/gs;
    # convert two to four space indentation
    $str =~ s/^( +)/' ' x (length($1) * 2)/gme;

    open(my $fh, '>>', 'TEST-DEEP-TEMPLATES.pl') or die "open failed: $!";
    print $fh $str, "\n";
}

sub ok_magic {
    my $kdbx = shift;
    my $vers = shift;
    my $note = shift;

    my $magic = [$kdbx->sig1, $kdbx->sig2, $kdbx->version];
    cmp_deeply $magic, [
        KDBX_SIG1,
        KDBX_SIG2_2,
        $vers,
    ], $note // 'KDBX magic numbers are correct';
}

# Returns parameters for a fast KDF so that running tests isn't pointlessly slow.
sub fast_kdf {
    my $uuid = shift // KDF_UUID_AES;
    my $params = {
        KDF_PARAM_UUID() => $uuid,
    };
    if ($uuid eq KDF_UUID_AES || $uuid eq KDF_UUID_AES_CHALLENGE_RESPONSE) {
        $params->{+KDF_PARAM_AES_ROUNDS} = 17;
        $params->{+KDF_PARAM_AES_SEED} = "\1" x 32;
    }
    else { # Argon2
        $params->{+KDF_PARAM_ARGON2_SALT} = "\1" x 32;
        $params->{+KDF_PARAM_ARGON2_PARALLELISM} = 1;
        $params->{+KDF_PARAM_ARGON2_MEMORY} = 1 << 13;
        $params->{+KDF_PARAM_ARGON2_ITERATIONS} = 2;
        $params->{+KDF_PARAM_ARGON2_VERSION} = 0x13;
    }
    return $params;
}

1;
