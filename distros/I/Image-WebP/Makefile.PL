use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;

my @linux_objs = (
'webp-src/src/dsp/libwebpdsp_la-cpu.o',
'webp-src/src/dsp/libwebpdsp_la-dec.o',
'webp-src/src/dsp/libwebpdsp_la-lossless.o',
'webp-src/src/dsp/libwebpdsp_la-upsampling_neon.o',
'webp-src/src/dsp/libwebpdsp_la-upsampling.o',
'webp-src/src/dsp/libwebpdsp_la-upsampling_sse2.o',
'webp-src/src/dsp/libwebpdsp_la-dec_neon.o',
'webp-src/src/dsp/libwebpdsp_la-dec_sse2.o',
'webp-src/src/dsp/libwebpdsp_la-enc.o',
'webp-src/src/dsp/libwebpdsp_la-yuv.o',
'webp-src/src/dsp/libwebpdsp_la-enc_neon.o',
'webp-src/src/dsp/libwebpdsp_la-enc_sse2.o',
'webp-src/src/enc/libwebpencode_la-alpha.o',
'webp-src/src/enc/libwebpencode_la-iterator.o',
'webp-src/src/enc/libwebpencode_la-webpenc.o',
'webp-src/src/enc/libwebpencode_la-analysis.o',
'webp-src/src/enc/libwebpencode_la-picture.o',
'webp-src/src/enc/libwebpencode_la-token.o',
'webp-src/src/enc/libwebpencode_la-vp8l.o',
'webp-src/src/enc/libwebpencode_la-histogram.o',
'webp-src/src/enc/libwebpencode_la-frame.o',
'webp-src/src/enc/libwebpencode_la-tree.o',
'webp-src/src/enc/libwebpencode_la-config.o',
'webp-src/src/enc/libwebpencode_la-cost.o',
'webp-src/src/enc/libwebpencode_la-filter.o',
'webp-src/src/enc/libwebpencode_la-layer.o',
'webp-src/src/enc/libwebpencode_la-backward_references.o',
'webp-src/src/enc/libwebpencode_la-quant.o',
'webp-src/src/enc/libwebpencode_la-syntax.o',
'webp-src/src/dec/libwebpdecode_la-idec.o',
'webp-src/src/dec/libwebpdecode_la-layer.o',
'webp-src/src/dec/libwebpdecode_la-quant.o',
'webp-src/src/dec/libwebpdecode_la-frame.o',
'webp-src/src/dec/libwebpdecode_la-io.o',
'webp-src/src/dec/libwebpdecode_la-webp.o',
'webp-src/src/dec/libwebpdecode_la-alpha.o',
'webp-src/src/dec/libwebpdecode_la-buffer.o',
'webp-src/src/dec/libwebpdecode_la-vp8l.o',
'webp-src/src/dec/libwebpdecode_la-tree.o',
'webp-src/src/dec/libwebpdecode_la-vp8.o',
'webp-src/src/utils/rescaler.o',
'webp-src/src/utils/bit_reader.o',
'webp-src/src/utils/color_cache.o',
'webp-src/src/utils/filters.o',
'webp-src/src/utils/huffman.o',
'webp-src/src/utils/bit_writer.o',
'webp-src/src/utils/huffman_encode.o',
'webp-src/src/utils/quant_levels.o',
'webp-src/src/utils/utils.o',
'webp-src/src/utils/quant_levels_dec.o',
'webp-src/src/utils/thread.o'
);

my $ldd_flags;
if (! ($Config{osname} =~ /Win/)) {
	chdir("webp-src");
	system("./configure --disable-shared");
	system("make");
	chdir("..");

	$ldd_flags = " -lpthread " . join(" ", @linux_objs);
}
else {
	my @objs = <precompiled\\win32\\*.o>;
	$ldd_flags = " " . join(" ", @objs) . " ";
}



WriteMakefile(
    NAME             => 'Image::WebP',
    AUTHOR           => q{Zargener <zargener@gmail.com>},
    VERSION_FROM     => 'lib/Image/WebP.pm',
    ABSTRACT_FROM    => 'lib/Image/WebP.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-WebP-*' },
    LDDLFLAGS => $Config{lddlflags} . $ldd_flags
);
