package Image::DecodeQR::WeChat;

# we rely on having T_AVREF_REFCOUNT_FIXED
use 5.16.0;

use strict;
use warnings;

use File::ShareDir;
use Time::HiRes;

use vars qw($VERSION @ISA);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	decode
	decode_xs
	modelsdir
); # symbols to export on request (WHY?)

our $VERSION = '0.9';


BEGIN {
    $VERSION = '0.9';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }
}

sub modelsdir() { return File::ShareDir::dist_dir('Image-DecodeQR-WeChat') }
sub decode {
	my $params = $_[0];
	die  "params are required" unless $params;
	my (@params, $m);
	if( ! exists($params->{'input'}) || ! defined($m=$params->{'input'}) ){ print STDERR "decode() : error, input parameter 'input' must be specified.\n"; return undef; }
	push @params, $m;

	if( ! exists($params->{'modelsdir'}) || ! defined($m=$params->{'modelsdir'}) ){
		# this will be filled in by Makefile.PL during install
		push @params, modelsdir();
	} else { push @params, $m }

	if( ! exists($params->{'outbase'}) || ! defined($m=$params->{'outbase'}) ){
		push @params, undef;
	} else { push @params, $m }

	if( ! exists($params->{'verbosity'}) || ! defined($m=$params->{'verbosity'}) ){
		push @params, 1;
	} else { push @params, $m }

	if( ! exists($params->{'graphicaldisplayresult'}) || ! defined($m=$params->{'graphicaldisplayresult'}) ){
		push @params, 0;
	} else {
		# we were asked for displaying graphical output
		# do we have highgui? was Opencv compiled with that option?
		if( ($m == 1) && (opencv_has_highgui_xs() == 0) ){
			print STDERR "decode() : warning, it seems that the current OpenCV installation does not support 'highgui' (which is optional), so parameter 'graphicaldisplayresult=1' will be ignored.\n";
			push @params, 0;
		} else { push @params, $m }
	}

	if( ! exists($params->{'dumpqrimagestofile'}) || ! defined($m=$params->{'dumpqrimagestofile'}) ){
		push @params, 0;
	} else { push @params, $m }

	print "calling with these params: '".join("','", map { defined($_) ? $_ : '<undef>' } @params)."'.\n";

	return decode_xs(
		$params[0],
		$params[1],
		$params[2],
		$params[3],
		$params[4],
		$params[5]
	);
}

=pod

=encoding utf8

=head1 NAME

Image::DecodeQR::WeChat - Decode QR code(s) from images using the OpenCV/WeChat library via XS

=head1 VERSION

Version 0.9


=head1 SYNOPSIS

This module provides a Perl interface to the OpenCV/WeChat QR code
decoder via XS code.
OpenCV/WeChat library uses CNN to do this with pre-trained models.

This module has been tested by myself with OpenCV v4.5.5 and Perl v5.32 on
Linux. But check the CPANtesters matrix on the left for all the tests done
on this module.

The library is relatively successful even for rotated codes. It remains
to be tested on the minimum size ofthe code images (60px in my case).

Here is some code to get you started:

    # this ensures that both input params can contain utf8 strings
    # but also results (somehow but beyond me)
    use Image::DecodeQR::WeChat;

    # this will be fixed, right now params are hardoded in XS code
    my $ret = Image::DecodeQR::WeChat::decode_xs(
	# the input image containing one or more QR-codes
	'an-input-image.png',

	# the dir with model parameters required by the library.
	# Model files come with this Perl module and are curtesy of WeChat
	# which is part of OpenCV contrib packages.
        # They are installed with this module and their default location
        # is given by Image::DecodeQR::WeChat::modelsdir()
        # Alternatively, you specify here your own model files:
	Image::DecodeQR::WeChat::modelsdir(),

	# outbase for all output files, optional
	# if more than one QR-codes were detected then an index will
	# be appended to the filename. And there will be png image files
	# containing the portion of the image which was detected
	# and there will be txt files with QR-code text (payload)
	# and its bounding box. And there will be an overall
	# text file with all payloads. This last one will be
	# printed to STDOUT if no outbase was specified:
	'output.detected',

	# verbosity level. 0:mute, 1:C code messages, 10:C+XS code
	10,

	# display results in a window with QR codes found highlighted
	# make sure you have an interactive shell and GUI
	1,

	# dump image and metadata to files for each QR code detected
	# only if outbase was specified
	1,
    );
    die "failed" unless $ret;
    # we got back an array-of-2-arrays
    # * one contains the QR-code-text (called payload)
    # * one contains bounding boxes, one for each payload
    # we have as many payloads and bounding boxes as
    # are the QR-codes detected (some may have been skipped)
    
    my ($payloads, $boundingboxes) = @$ret;
    for (0..$#$payloads){
      print "Payload got: '".$payloads->[$_]
        ."' bbox: @{$boundingboxes->[$_]}"
        .".\n";
    }

    # The above decode_xs() expects all parameters to be present
    # while decode() below takes a hash of params and fills the
    # missing params with defaults. Then it calls decode_xs()
    # So, it is still calling XS code but via a Perl sub
    # The important bit is that the modelsdir is filled in automatically
    # rather than the user looking for it
    my $ret = Image::DecodeQR::WeChat::decode({
        # these are required
        'input' => 'input.jpg',
        'outbase' => 'outs',
        # these are optional and have defaults
        #'modelsdir' => '...', # use it only if you have your own models
        #'verbosity' => 0,
        #'graphicaldisplayresult'' => 0,
        #'dumpqrimagestofile' => 0,
    });
    die "failed" unless $ret;
    my ($payloads, $boundingboxes) = @$ret;
    for (0..$#$payloads){
      print "Payload got: '".$payloads->[$_]
        ."' bbox: @{$boundingboxes->[$_]}"
        .".\n";
    }

    # pre-trained models location (installed with this module)
    print "my models are in here: ".Image::DecodeQR::WeChat::modelsdir()."\n"

    # returns 1 or 0 when OpenCV was compiled with highgui or not
    # and supports GUI display like imshow() which displays an image in a window
    my $has_highgui_support = opencv_has_highgui_xs();

This code calls functions and methods from OpenCV/WeChat library (written in C++)
for decoding one or more QR codes found embedded in images.
It's just that: a very thin wrapper of a C++ library written in XS. It only interfaces
the OpenCV/WeChat library for QR code decoding.

It can detect multiple QR codes embeded in a single image. And has been
successfully tested with as small sizes as 60 x 60 px.

The payload(s) (the QR-code's text) are returned back as an ARRAYref.

Optionally, it can output the portion of the input image corresponding
to each QR-code, its bounding box and the payload in separate files,
useful for debugging and identification when multiple QR codes exist
in a single input image.

Following this code as an example, it will be trivial to
interface other parts of the OpenCV library:

    Ιδού πεδίον δόξης λαμπρόν
       (behold a glorious field of glory)


=head1 EXPORT

=over

=item * C<decode()>

=item * C<decode_xs()>

=item * C<modelsdir()>

=item * C<opencv_has_highgui_xs()>

=back


=head1 COMMAND LINE SCRIPT

  image-decodeqr-wechat.pl --input in.jpg

  image-decodeqr-wechat.pl --help

A CLI script is provided and will be installed by this module. Basic usage is as above.

=head1 PREREQUISITES

=over

=item * OpenCV library with contributed modules is required.
The contributed modules must include the QR-code decoder library by WeChat.
OpenCV must also contain the include dir (headers) - just saying.

=item * A C++ compiler must be installed in your system.

=item * Optionally, C<pkg-config> or C<cmake> must be installed in order to
aid discovering the location of OpenCV's library and include dir. If you
don't have these installed then you must manually set environment
variables C<OPENCV_LDFLAGS> and C<OPENCV_CFLAGS> to point
to those paths and then attempt to install this module (e.g. C<perl Makefile.PL; make all ; make install>)

=item * Optionally, OpenCV can contain the Highgui library so that
output images can be displayed in their own window. But this is
superfluous, because the basic operation of this module allows for
saving output files to disk.

=back

=head1 SUBROUTINES/METHODS

=head3 C< decode_xs(infile, modelsdir, outbase, verbosity, graphicaldisplayresult, dumpqrimagestofile) >

It takes in the filename of an input image which may contain
one or more QR codes and returns back an ARRAYref of
strings containing all the payloads of the codes which
have successfully been decoded (some QR codes may
fail to be decoded because of resolution or quality etc.)

It returns undef on failure.

It returns an empty ARRAYref (i.e. a ref to an empty array)
if no QR codes were found or decoded successfully.

These are the parameters it requires. They must all be present, with
optional parameters allowed to be C<undef>:


=over

=item * C<infile> : the input image with zero or more QR codes.
All the image formats of OpenCV's L<imread()|https://docs.opencv.org/4.5.5/d4/da8/group__imgcodecs.html>
are supported.

=item * C<modelsdir> : the location of the directory holding all model files (CNN trained models)
required for QR code detection. These models are already included with this Perl module and will be
installed in a shared dir during installation. Their total size is about 1MB.
They have been kindly contributed by WeChat along with their library for QR Code detection.
They can be found L<https://github.com/WeChatCV/opencv_3rdparty|here>. The installed
models location is returned by L<modelsdir()>. If you do not want to experiment with
your own models then just plug the output of L<modelsdir()> to this parameter, else
specify your own.

=item * C<outbase> : optionally specify output files basename which will contain
detected QR-codes' payloads, bounding boxes and QR-code images extracted from
the input image (one set of files for each QR-code detected).
If C<dumpqrimagestofile> is set to 1 all the aforementioned files will
be created. If it is set to 0 then only the payloads will be saved in a single
file (all in one file). If C<outbase> is left C<undef> then nothing is written to
a file. As usual all detected codes' data is returned back via the returned
value of L<decode_xs()>.

=item * C< verbosity > levels: 0 is mute, 1 is only for C code, 10 is for C+XS code.

=item * C< graphicaldisplayresult> : if set to 1, it will display a window with the input image
and the detected QR-code(s) outlined. This
is subject to whether current OpenCV installation was compiled to support
C< imshow() > (with C < highgui > enabled).

=item * C<dumpqrimagestofile> : if set to 0, and C<outbase> is specified, then all payloads
are written to a single file using the basename specified. If set to 1 a lot more information
is written to separate files, one for each detected code. This is mainly for debugging purposes
because the returned value contains the payloads and their corresponding QR-codes' bounding
boxes. See C<outbase> above.

=back


=head3 C< decode(\%params) >


This is a Perl wrapper to the C<decode_xs()> and allows a user to specify
only a minimal set of parameters with the rest to be filled in by defaults.

Like L<decode_xs()>, it returns undef on failure. Or an arrayref of
two arrays. The C<payloads> array and the C<bounding-boxes> array.
Each has a number of items equal to the QR codes detected.

An ARRAYref of two empty arrays will be returned
if no QR codes were found or decoded successfully.

The C< params > hashref:

=over

=item * C<input> : the name of the input image file which can contain one or more QR codes.

=item * C<outbase> : optional, if specified payloads (QR-code text) will be dumped to a text file.
If further, C<dumpqrimagestofile> is set to 1 then image files with the detected QR-codes will
be dumped one for each QR-code as well as text files with payloads and bounding boxes wrt the
input image.

=item * C<modelsdir> : optional, use it only if you want to use your own model files (for their
format have a look at L<https://docs.opencv.org/4.x/d5/d04/classcv_1_1wechat__qrcode_1_1WeChatQRCode.html>, they are CNN training files).
This Perl module has included the model files kindly submitted by WeChat as a contribution to OpenCV
and will be installed in your system with all other files. Use C<modelsdir()> to see the location
of installed model files. Their total size is about 1MB.

=item * C<verbosity> : default is 0 which is muted. 1 is for verbose C code and 10 is for verbose C and XS code.

=item * C<dumpqrimagestofile> : default is 0, set to 1 to have lots of image and text files dumped (relative to C<outbase>)
for each QR code detected.

=item * C<graphicaldisplayresult> : default is 0, set to 1 to have a window popping up with the input image
and the QR-code detected highlighted, once for each code detected. This
is subject to whether current OpenCV installation was compiled to support
C< imshow() > (with C < highgui > enabled).

=back


=head3 C< modelsdir() >

It returns the path where the models included in this Perl module
have been installed.
This is useful when you want to use C<decode_xs()> and need to specify
the C<modelsdir>.
Just pass the output of this to C<decode_xs()> as its C<modelsdir> parameter.
However, you can not set the location of your own modelsdir using C< modelsdir() >.

=head3 C< opencv_has_highgui_xs() >

It returns 1 or 0 depending on whether current OpenCV installation has
support for graphical display of images (the C<imshow()> function). This
affects the option C<graphicaldisplayresult> to L<decode()> and L<decode_xs()>
which will be ignored if there is no highgui support.

Caveat: checking for whether current OpenCV installation has highgui
support is currently very lame, it merely tries to find the include file C<< opencv2/highgui.hpp >>
in the Include dirs. I have tried several methods (see ```Makefile.PL```), for
example L<DynaLoader> or L<FFI::CheckLib> can search for symbols in any library
(e.g. searching for C<imshow()> in C<libopencv_highgui> or  C<libopencv_world>).
This would have been the most straight-forward way but alas, these are C++ libraries
and function names are mangled to weird function names like:

    ZN2cv3viz6imshowERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEERKNS_11_InputArrayERKNS_5Size_IiEE()

There's an imshow() in there but without a regex symbol-name search
the symbol can not be detected.

Another take is with L<Devel::CheckLib> which supports compiling code
snippets when searching for a particular library. This fails because they
... allow only a C compiler but we need a C++ compiler.

Finally, using L<Inline::CPP> to compile our own snippet is totally in vain
because of its useless form of running as C<use Inline CPP => ... >. I could
not find any way of telling it to use specific CFLAGS and LDFLAGS with this
useless C<use Inline CPP> form.


=head1 IMPLEMENTATION DETAILS

This code demonstrates how to call OpenCV (modern OpenCV v4) C++ methods using the
technique suggested by C<Botje @ #perl> in order to avoid all the
function, macro, data structures name clashes between Perl and OpenCV
(for example C<seed()>, C<do_open()>, C<do_close()> and
most notably C<struct cv> and C<namespace cv> in Perl and OpenCV respectively).

The trick suggested is to put all the OpenCV-calling code in a separate C++ file
and provide high-level functions to be called by XS. So that the XS code does
not see any OpenCV header files.

C<Makefile.PL> will happily compile any C<.c and/or .cpp> files found in the dir it resides
by placing C<OBJECT =E<gt> '$(O_FILES)'> in C<%WriteMakefileArgs>. And will
have no problems with specifying also these:

    CC      => 'g++',
    LD      => 'g++',
    XSOPT   => '-C++',

With one caveat, C<g++> B<compiler will mangle the names of the functions>
when placing them in the object files. And that will cause L<XSLoader> to report
missing and undefined symbols.

The cure to this is to wrap any function you want to remain unmangled
within

    #ifdef __cplusplus
    extern "C" {
    #endif

and

    #ifdef __cplusplus
    } //extern "C" {
    #endif

This only need happen in the header file: C< wechat_qr_decode_lib.hpp >
and in the XS file where the Perl headers are included.


=head1 INSTALLING OpenCV

In my case downloading OpenCV using Linux's package
manager was not successful.It required to add another
repository which wanted to install its own versions
of packages I already had. So I prefered to install
OpenCV from sources. This is the procedure I followed:

=over

=item * Download OpenCV sources and also its contributed modules.

=item * Extract the sources and change to the source dir.

=item * From within the source dir extract the contrib archive.

=item * Create a C<build> dir and change to it.

=item * There are two ways to make C<cmake> just tolerable:
C<cmake-gui> and C<ccmake>. The former is a full-gui interface
to setting the billion C<cmake> variables. Use it
if you are on a machine which offers a GUI like this: C<cmake-gui ..>
If you are on a headless or remote host possibly over telnet or ssh
then do not despair because C<ccmake> is the CLI, curses-based
equivalent to C<cmake-gui>,  use it like: C<ccmake ..> (from within the build dir).

=item * Once on either of the cmake GUIs, first do a
C<configure>, then check the
list of all variables (you can search on both, for searching
in the CLI, press C</> and then C<n> for next hit)
to suit you and then C<generate>, quit
and  C<VERBOSE=1 make -j4 all>

=item * I guess, cmake variables you want to modify
are C<OPENCV_EXTRA_MODULES_PATH>
and turn ON C<OPENCV_ENABLE_NONFREE> and anything that has to do with C<CNN> or C<DNN>.
If you have CUDA installed and a CUDA-capable GPU then enable CUDA
(search for CUDA string to find the variable(s)). Also, VTK, Ceres Solver,
Eigen3, Intel's TBB, CNN, DNN etc. You need to install all these
additional packages first, before finally compiling OpenCV.

=item * I had a problem with compiling OpenCV with a GUI (the C<highgui>)
on a headless host. So, I just disabled it. That's easy to achieve
during the above.

=item * I have installed this on a CUDA-capable GPU (with CUDA 10.2 installed)
host and on a headless remote host with no GPU or basic. CUDA is
not required for building this module.

=item * It is also possible to download a binary distribution of OpenCV.
Just make sure that it supports all the things I mentioned above.
And that it has all the required headers (in an include dir) - just saying.

=back

Your mileage may vary.

If you are seriously in need of installing
this module then consider migrating to a serious operating system
such as Linux as your first action.

=head1 INSTALLING THIS MODULE

This module depends on the existence of the OpenCV library with all
the extensions and contributed modules mentioned in section C<PREREQUISITES>.

Detecting where this library is located in your system is the weakest
link in the installation process of this module. C<Makefile.PL> contains
code to do this with C<pkg-config> or C<cmake>. If these fail,
it will look for ENVironment variables: C<OPENCV_LDFLAGS> and
C<OPENCV_CFLAGS>, which should contain the C<CFLAGS> (for example:
C<<-I/usr/include/opencv4/>>) and C<LDFLAGS> (for example:
C<<-L/usr/lib64 -lopencv_world>>). Set these variables manually
prior installation if the automatic methods mentioned above fail.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-decodeqr-wechat at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-DecodeQR-WeChat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::DecodeQR::WeChat


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-DecodeQR-WeChat>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Image-DecodeQR-WeChat>

=item * Search CPAN

L<https://metacpan.org/release/Image-DecodeQR-WeChat>

=back


=head1 ACKNOWLEDGEMENTS

=over

=item * The great Open Source L<OpenCV|https://opencv.org/>
image processing library
and its contributed module
L<WeChat QRDetector|https://docs.opencv.org/4.x/dd/d63/group__wechat__qrcode.html>
which form the backbone of this module and do all the heavy lifting.

=item * Botje and xenu at #perl for help.

=item * Jiro Nishiguchi (L<JIRO | https://metacpan.org/author/JIRO>) whose
(obsolete with modern - at the time of writing - OpenCV)
module L<Image::DecodeQR> serves as the skeleton for this module.

=item * Thank you! to all those who responded to this SO question L<https://stackoverflow.com/questions/71402095/perl-xs-create-and-return-array-of-strings-char-taken-from-calling-a-c-funct>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=head1 HUGS

!Almaz!

=cut

1; # End of Image::DecodeQR::WeChat
