######################################################################
#
# not_JIS78.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/78-vs-83-1.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/78-vs-83-2.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/78-vs-83-3.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/78-vs-83-4.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/83-vs-90-1.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/83-vs-90-2.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/TJ2.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/TJ3.sjs
# https://resources.oreilly.com/examples/9781565922242/tree/master/AppQ/TJ4.sjs

use strict;
use File::Basename;

my %CJKV_AppQ = (

    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 1: added non-kanji'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_78-vs-83-1.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],

    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 2: original code had simplified, and unsimplified was given new code'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_78-vs-83-2.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0,1] },
    ],

    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 3: 22 simplified and traditional exchanged code'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_78-vs-83-3.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0,1] },
    ],

    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 4: shapes were altered'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_78-vs-83-4.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],

    'JIS X 0208-1983 Versus JIS X 0208-1990 two kanji were appended'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_83-vs-90-1.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],

    'JIS X 0208-1983 Versus JIS X 0208-1990 glyph changes'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_83-vs-90-2.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],

    'JIS X 0212-1990 Versus JIS C 6226-1978'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_TJ2.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],

    'Joyo Kanji'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_TJ3.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],

    'IBM DBCS-PC Versus JIS X 0208-1990'
    => [
        'https.__resources.oreilly.com_examples_9781565922242_blob_master_AppQ_TJ4.sjs',
        sub { (m/\(([234567][0123456789ABCDEF][234567][0123456789ABCDEF])\)/g)[0] },
    ],
);

my %not_JIS78 = ();
for my $title ((),
    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 1: added non-kanji',
    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 2: original code had simplified, and unsimplified was given new code',
    'JIS X 0208-1983 Versus JIS X 0208-1990 two kanji were appended',

    # 以下を有効にすると数文字の変化が現れるが、検証が必要
    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 3: 22 simplified and traditional exchanged code',

    # 以下を有効にするとかなりの変化がある
    'JIS C 6226-1978 Versus JIS X 0208-1983 Category 4: shapes were altered',

    # 以下を有効にするとかなりの変化がある
    'JIS X 0208-1983 Versus JIS X 0208-1990 glyph changes',

    # 以下は問題なさそうだが、1文字ずつの検証が必要
    'JIS X 0212-1990 Versus JIS C 6226-1978',
) {
    my($file,$get) = @{$CJKV_AppQ{$title}};
    open(FILE,"@{[File::Basename::dirname(__FILE__)]}/$file") || die;
    while (<FILE>) {
        @_ = $get->();
        $not_JIS78{$_} = 1 for @_;
    }
    close(FILE);
}

sub not_JIS78 {
    my($jis) = @_;
    return $not_JIS78{$jis};
}

sub keys_of_not_JIS78 {
    return keys %not_JIS78;
}

sub values_of_not_JIS78 {
    return values %not_JIS78;
}

1;

__END__
