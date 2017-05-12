use strict;
use warnings;

use lib 't/lib';

use Test::AnyOf;
use Test::More 0.88;

use File::LibMagic::FFI;

my %standard = (
    'foo.foo' => [
        'ASCII text', qr{text/plain(?:; charset=us-ascii)?} ],
    'foo.c'   => [
        [ 'ASCII C program text', 'C source, ASCII text' ],
        qr{text/x-c(?:; charset=us-ascii)?}
    ],
);

my %custom = (
    'foo.foo' => [ 'A foo file', qr{text/plain(?:; charset=us-ascii)?} ],
    'foo.c'   => [
        [ 'ASCII text', 'ASCII C program text', 'C source, ASCII text' ],
        qr{text/(?:plain|(?:x-)?c)(?:; charset=us-ascii)?}
    ],
);

# try using a the standard magic database
my $flm = File::LibMagic::FFI->new();
isa_ok( $flm, 'File::LibMagic::FFI' );

for my $file ( sort keys %standard ) {
    my ( $descr, $mime ) = @{ $standard{$file} };
    $file = "t/samples/$file";

    # the original file utility uses text/plain;...  so does gentoo, debian,
    # etc ..., but OpenSUSE returns text/plain... (no semicolon)
    $mime =~ s/;/;?/g;
    like(
        $flm->checktype_filename($file), qr/$mime/,
        "MIME $file - standard magic file"
    );

    if ( ref $descr ) {
        is_any_of(
            $flm->describe_filename($file), $descr,
            "Describe $file - standard magic file"
        );
    }
    else {
        is(
            $flm->describe_filename($file), $descr,
            "Describe $file - standard magic file"
        );
    }

    my $data = do {
        local $/;
        open my $fh, '<', $file or die $!;
        <$fh>;
    };

    like(
        $flm->checktype_contents($data), qr/$mime/,
        "MIME data $file file contents - standard magic file"
    );

    like(
        $flm->checktype_contents(\$data), qr/$mime/,
        "MIME data $file contents as ref - standard magic file"
    );

    if ( ref $descr ) {
        is_any_of(
            $flm->describe_contents($data), $descr,
            "Describe data $file contents - standard magic file"
        );
        is_any_of(
            $flm->describe_contents(\$data), $descr,
            "Describe data $file contents as ref - standard magic file"
        );
    }
    else {
        is(
            $flm->describe_contents($data), $descr,
            "Describe data $file contents - standard magic file"
        );
        is(
            $flm->describe_contents(\$data), $descr,
            "Describe data $file contents as ref - standard magic file"
        );
    }
}

# try using a custom magic database
$flm = File::LibMagic::FFI->new('t/samples/magic');
isa_ok( $flm, 'File::LibMagic::FFI' );

for my $file ( sort keys %custom ) {
    my ( $descr, $mime ) = @{ $custom{$file} };
    $file = "t/samples/$file";

    # OpenSUSE fix
    $mime =~ s/;/;?/g;

    # text/x-foo to keep netbsd and older solaris installations happy
    like(
        $flm->checktype_filename($file), qr{$mime|text/x-foo},
        "MIME $file - custom magic file"
    );

    if ( ref $descr ) {
        is_any_of(
            $flm->describe_filename($file), $descr,
            "Describe $file - custom magic file"
        );
    }
    else {
        is(
            $flm->describe_filename($file), $descr,
            "Describe $file - custom magic file"
        );
    }
    my $data = do {
        local $/;
        open my $fh, '<', $file or die $!;
        <$fh>;
    };

    # text/x-foo to keep netbsd and older solaris installations happy
    like(
        $flm->checktype_contents($data), qr{$mime|text/x-foo},
        "MIME data $file - custom magic file"
    );

    if ( ref $descr ) {
        is_any_of(
            $flm->describe_contents($data), $descr,
            "Describe data $file - custom magic file"
        );
    }
    else {
        is(
            $flm->describe_contents($data), $descr,
            "Describe data $file - custom magic file"
        );
    }
}

my $subclass = My::Magic::Subclass->new();
isa_ok( $subclass, 'My::Magic::Subclass', 'subclass' );
is(
    $subclass->checktype_filename('t/samples/missing'),
    'text/x-test-passes'
);

done_testing();

{
    package My::Magic::Subclass;

    use base qw( File::LibMagic::FFI );

    sub checktype_filename { 'text/x-test-passes' }
}
