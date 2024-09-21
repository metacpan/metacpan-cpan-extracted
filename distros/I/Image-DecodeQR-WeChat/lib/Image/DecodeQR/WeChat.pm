package Image::DecodeQR::WeChat;

# we rely on having T_AVREF_REFCOUNT_FIXED
use 5.16.0;

use strict;
use warnings;

use File::ShareDir;
use Time::HiRes;

use vars qw($VERSION @ISA);

our @ISA = qw(Exporter);
# the EXPORT_OK and EXPORT_TAGS is code by [kcott] @ Perlmongs.org, thanks!
# see https://perlmonks.org/?node_id=11115288
our (@EXPORT_OK, %EXPORT_TAGS);

our $VERSION = '2.2';

BEGIN {
	$VERSION = '2.2';
	if ($] > 5.006) {
		require XSLoader;
		XSLoader::load(__PACKAGE__, $VERSION);
	} else {
		require DynaLoader;
		@ISA = qw(DynaLoader);
		__PACKAGE__->bootstrap;
	}
	@EXPORT_OK = qw/detect_and_decode_qr detect_and_decode_qr_xs modelsdir opencv_has_highgui_xs/;
	%EXPORT_TAGS = (
		# the :all tag: so we can use this like
		#  use Image::DecodeQR::WeChat qw/:all/;
		all => [@EXPORT_OK]
	);
}

# The main sub calling the XS detect_and_decode_qr_xs()
# The input parameters are supplied via a HASHref
# allowing for "named" parameters.
# Some parameters are optional and defaults will be used.
# It returns an ARRAYref of tuples (text, bounding box) on success
# (the returned array will contain just 2 empty arrays if no QR code was detected)
# It returns undef on failure
sub detect_and_decode_qr {
	my $params = $_[0];
	die  "params are required" unless $params;
	my (@params, $m);
	if( ! exists($params->{'input'}) || ! defined($m=$params->{'input'}) ){ print STDERR "detect_and_decode_qr() : error, input parameter 'input' must be specified.\n"; return undef; }
	push @params, $m;

	if( ! exists($params->{'modelsdir'}) || ! defined($m=$params->{'modelsdir'}) ){
		# this will be filled in by Makefile.PL during install
		push @params, modelsdir();
	} else { push @params, $m }

	if( ! exists($params->{'outbase'}) || ! defined($m=$params->{'outbase'}) ){
		push @params, undef;
	} else { push @params, $m }

	my $verbosity = exists($params->{'verbosity'}) && defined($params->{'verbosity'})
		? $params->{'verbosity'}
		: 0
	;
	push @params, $verbosity;

	if( ! exists($params->{'graphicaldisplayresult'}) || ! defined($m=$params->{'graphicaldisplayresult'}) ){
		push @params, 0;
	} else {
		# we were asked for displaying graphical output
		# do we have highgui? was Opencv compiled with that option?
		if( ($m == 1) && (opencv_has_highgui_xs() == 0) ){
			print STDERR "detect_and_decode_qr() : warning, it seems that the current OpenCV installation does not support 'highgui' (which is optional), so parameter 'graphicaldisplayresult=1' will be ignored.\n";
			push @params, 0;
		} else { push @params, $m }
	}

	if( ! exists($params->{'dumpqrimagestofile'}) || ! defined($m=$params->{'dumpqrimagestofile'}) ){
		push @params, 0;
	} else { push @params, $m }

	# this prints Wide character in print but I don't want to touch it ...
	if( $verbosity > 0 ){ print "calling with these params: '".join("','", map { defined($_) ? $_ : '<undef>' } @params)."'.\n" }

	# Call the XS function with all 6 parameters
	# It returns an ARRAYref of tuples (text, bounding box) on success
	# (the returned array will contain just 2 empty arrays if no QR code was detected)
	# It returns undef on failure
	return detect_and_decode_qr_xs(
		# yes we have 6 parameters, make this explicit
		$params[0],
		$params[1],
		$params[2],
		$params[3],
		$params[4],
		$params[5]
	);
}

# During installation of the module, pre-trained CNN QR code detection models
# are installed in a standard location in Module's install dir
# this returns the path to this dir.
# Note that calls to detect_and_decode_qr() allow for specifying a different models dir
sub modelsdir() { return File::ShareDir::dist_dir('Image-DecodeQR-WeChat') }

# opencv_has_highgui_xs() is an XS function which returns 1 or 0
# it is implemented in file WeChat.xs of this module.
# depending whether this installation of OpenCV contains the GUI interface
# libraries. If it does then setting graphicaldisplayresult=1 to
# detect_and_decode_qr()/detect_and_decode_qr_xs() will also open a GUI image viewer displaying
# the detected QR codes as part of the input image.

=pod

=encoding utf8

=head1 NAME

Image::DecodeQR::WeChat - Decode QR code(s) from images using the OpenCV/WeChat library via XS

=head1 VERSION

Version 2.2

=head1 SYNOPSIS

This module detects and
decodes QR code(s) in an input image.

It provides a Perl interface to the C++ OpenCV/WeChat QR code
decoder via XS code.
OpenCV/WeChat library uses CNN (Convolutional Neural Networks)
to do this with pre-trained models. It works quite well.

This module has been tested with OpenCV v4.5.5, v4.8.1, v4.9
and Perl v5.32, v5.38 on
Linux. But check the CPANtesters matrix on the left for all the tests done
on this module (although tests may be sparse and rare because of the OpenCV
dependency).

The OpenCV/WeChat library is relatively successful even for non-orthogonally
rotated codes. It remains
to be tested fully on the minimum size of the code images. 60px was the minimum
size with my tests. See section L</"TESTING THE QR CODE DETECTION ALGORITHM"> for more details.

Here is some code to get you started:

    use Image::DecodeQR::WeChat;

    # decode QR image with convenient "named" params
    my $ret = Image::DecodeQR::WeChat::detect_and_decode_qr({
        # these are required
        'input' => 'input.jpg',
        # optional with defaults:
        # specify a different models dir
        #'modelsdir' => '...',
        # dump results to file(s) whose name
        # is prepended by param 'outbase'
        #'outbase' => 'outs',
        # set this to 1 to also dump images of
        # QR codes detected as well text files with
        # payload and bounding box coordinates
        #'dumpqrimagestofile' => 0,
        # use OpenCV's GUI image viewer to display
        # this needs a non-headless OS and OpenCV highgui
        #'graphicaldisplayresult'' => 0,
        #'verbosity' => 0,
    });
    die "failed" unless $ret;

    # we got back an array-of-2-arrays
    # * one contains the QR-code-text (called payload)
    # * one contains bounding boxes, one for each payload
    # we have as many payloads and bounding boxes as
    # are the QR-codes detected (some may have been skipped)

    # the number of QR code images found in the input
    # NOTE: the returned array will contain
    # just 2 empty arrays if no QR code was detected
    # so this is the right way:
    my $num_qr_codes_detected = scalar @$payloads;
    
    my ($payloads, $boundingboxes) = @$ret;
    for (0..$#$payloads){
      print "Payload got: '".$payloads->[$_]
        ."' bbox: @{$boundingboxes->[$_]}"
        .".\n";
    }

    # Alternatively, a less convenient method to
    # decode a QR code is via the XS sub.
    # It requires that all parameters be specified
    # unlike detect_and_decode_qr() which uses
    # "named" parameters  with defaults.
    my $ret = Image::DecodeQR::WeChat::detect_and_decode_qr_xs(
	# the input image containing one or more QR-codes
	'an-input-image.png',

	# the dir with model parameters required by the library.
	# Model files come with this Perl module and are curtesy of WeChat
	# which is part of OpenCV contrib packages.
        # They are installed with this module and their default location
        # is given by Image::DecodeQR::WeChat::modelsdir()
        # Alternatively, you specify here your own model files:
	Image::DecodeQR::WeChat::modelsdir(),

	# outbase for all output files, optional = set to undef,
	# if more than one QR-codes were detected then an index will
	# be appended to the filename. And there will be JPEG image files
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

    # again, the same data structure returned:
    my ($payloads, $boundingboxes) = @$ret;
    my $num_qr_codes_detected = scalar @$payloads;
    for (0..$#$payloads){
      print "Payload got: '".$payloads->[$_]
        ."' bbox: @{$boundingboxes->[$_]}"
        .".\n";
    }

    # Where is it looking for default
    # pre-trained models location ?
    # (they are installed with this module)
    print "my models are in here: ".Image::DecodeQR::WeChat::modelsdir()."\n"

    # returns 1 or 0 when OpenCV was compiled with highgui or not
    # and supports GUI display like imshow() which displays an image in a window
    my $has_highgui_support = opencv_has_highgui_xs();


This code interfaces functions and methods from OpenCV/WeChat library (written in C++)
for decoding B<one or more QR code images>
found embedded in images.
It's just that: a very thin wrapper of a C++ library written in XS. It only interfaces
the OpenCV/WeChat library for QR code decoding and accommodates its returned
data into a Perl array (ref).

It can detect multiple QR codes embeded in a single image. It has been
successfully tested with images as small as 60 x 60 pixels.

The payload (i.e. the QR-code's text) and the coordinates of the
bounding box around each QR code image detected are returned
back as Perl array of tuples (i.e. C<[[QR code text, bounding box]...>).

Optionally, it can output the portion of the input image corresponding
to each QR-code (that is a sub-image, part of the input image),
its bounding box and the payload in separate files,
useful for debugging and identification when multiple QR codes exist
in a single input image.

=head1 FUTURE WORK

Following the XS code in this module as a guide, it will be trivial to
interface other parts of the OpenCV library:

    Ιδού πεδίον δόξης λαμπρόν
       (behold a glorious field of glory)


=head1 EXPORT
 
=over 4
 
=item * C<detect_and_decode_qr()>
 
=item * C<detect_and_decode_qr_xs()>
 
=item * C<modelsdir()>
 
=item * C<opencv_has_highgui_xs()>
 
=back

=head1 SUBROUTINES/METHODS

=head2 C<detect_and_decode_qr(\%params)>

It tries to detect all
the QR codes in the input image
(specified by its B<filepath>) with one or more
QR codes embedded in it.

It wraps the XS function L<detect_and_decode_qr_xs(\@params)>
and replaces missing optional parameters with defaults.

These are the C<\%params> it accepts:

=over 4

=item * B<input> : the I<filepath> of the input image possibly embedded with QR code(s).
The format of the input image can be anything OpenCV supports, see
L<OpenCV's imread()|https://docs.opencv.org/4.9.0/d4/da8/group__imgcodecs.html>.

=item * B<modelsdir> : B<optional> parameter to specify an alternative
models location, other than the one installed during the module's installation.
The current models dir is found using L<modelsdir()>. See L</"MODELS">
for more information on what this directory should contain. If this
parameter is omitted the default value is determined by what
L<modelsdir()> returns.

=item * B<dumpqrimagestofile> : B<optional> flag (0 or 1) to specify whether to
write results into output files (as well as returning them back as an ARRAYref).
If this parameter is omitted the default value is zero, meaning NO don't dump files.

These are what the set of output files comprises of:

=over 4

=item * An image of the detected QR code. This is part of the input image
detailing only the detected QR code. It is saved as a JPEG image file.

=item * XML output with 1) the detected QR code payload (the text it contains), followed by
2) the coordinates of the bounding box of the detected QR code. These coordinates
are for the input image. Here is an example:

  <qrcodes>
    <qrcode>
      <payload>Just another Perl hacker</payload>
      <boundingbox>[9, 1], [409, 1], [409, 401], [9, 401]</boundingbox>
    </qrcode>
  </qrcodes>

=back

There will be as many pairs of files as the detected QR codes in the input image.
The filenames will be formed with the C<outbase> parameter (which is mandadory if
this parameter is set to 1) followed by a zero-based index number denoting
the sequence of the detected QR code (even if there is only one detected QR code, the
output files will still contain an index number, in this case it will be C<0>),
followed by the extentsion C<.jpg> for the image file and C<.xml> for the
text file. For example C<$outbase.1.xml> and C<$outbase.1.jpg>, where
C<$outbase> is the specified in the input parameters (see below).

Additionally, an overall output file whose name is the same as above except
that it has no index number, will be created to contain the payloads of ALL
QR codes detected. Each on its own line.

=item * B<outbase> : B<optional> parameter which must be specified if B<dumpqrimagestofile>
is set to 1. If left C<undef> then no results are written to files. If specified
but B<dumpqrimagestofile> is set to 0, then it saves all results into a single
file C<$outbase.xml>. If specified and B<dumpqrimagestofile> is set to 1 then
in addition to the overall XML file, for each QR code detected there will
be an output image as a copy of the input with the detected QR code outlined
and an output XML file with metadata (the payload and bounding box coordinates).

WARNING: if you set B<dumpqrimagestofile> to 1 then as many output images
as the detected QR codes will be created and all will be a copy of the input
image, that can be a lot of large images ...

B<outbase> will be prepended to the name of each of the output result
files. B<outbase> may contain directory components but make sure they do
exist because they will not be created.

=item * B<graphicaldisplayresult> : B<optional> flag which
applies only
in the case where the underlying OpenCV installation contains
the C<highgui> GUI component which allows for displaying
images. If that component exists (which can be determined by
calling  L<opencv_has_highgui_xs()>) then setting this parameter
to 1 will also display image results (the detected QR codes)
into a GUI window as the detection process is happening.
The user must close this window in order for detection process
to continue until the script exits. The default value is zero, meaning NO do not
display any output images.

=item * B<verbosity> : set this to a positive integer in order
for the program to print debugging messages to standard output.
Verbosity increases as this
value increases. With zero, the default value, being completely mute.

=back

=head3 Returned data by C<detect_and_decode_qr()>

On success, it returns results back as an
ARRAYref of 2-item-arrays (tuples) containing:

=over 4

=item * The text of the decoded QR code detected.

=item * The coordinates of the bounding box around
the QR code image detetced.

=back

It returns an array of two  zero-length arrays if no
QR codes were detected.

It returns C<undef> on failure.

Noting all the above, here is a way of calling it,
checking its success and iterating over all
the QR codes data returned:

  my $ret = detect_and_decode_qr(\%params);
  die "failed to detect_and_decode_qr()" unless defined $ret;
  my ($payloads, $bounding_boxes) = @$ret;
  # the number of detected QR codes (can be zero!):
  my $num_qr_codes_detected = scalar @$payloads;
  for ( 0 .. ($num_qr_codes_detected-1) ){
    print "payload: ".$payloads->[$_]."\n";
    print "bbox: ".$bounding_boxes->[$_]."\n";
  }

=head2 C<detect_and_decode_qr_xs(infile, modelsdir, outbase, verbosity, graphicaldisplayresult, dumpqrimagestofile)>

It tries to detect all
the QR codes in the input image
(specified by its B<filepath>) with one or more
QR codes embedded in it.

This is an XS function (which can be called safely by a Perl script)
wrapped by L<detect_and_decode_qr(\%params)> which is more convenient as
it replaces missing parameters with defaults, unlike this
function which expects all the parameters to be specified.

These are the C<@params> it accepts, in this order:

=over 4

=item * B<input> : the filepath to the input image possibly containing QR codes.
The format of the input image can be anything OpenCV supports, see
L<OpenCV's imread()|https://docs.opencv.org/4.5.5/d4/da8/group__imgcodecs.html>.

=item * B<modelsdir> : the path to the directory conntaining the pre-trained
CNN models which are used for the QR code detection. This parameter must be
specified. The default models dir is given by calling L<modelsdir()>. You can
pass the return of L<modelsdir()> as this parameter if you do not
have your own models.

=item * B<outbase> : the string prepended to all the output files.
It must be specified (i.e. not left C<undef>) only when B<dumpqrimagestofile>
is set to 1.

=item * B<verbosity> : set it to a positive integer to get debugging output
to standard output. Set it to zero for mute operation.

=item * B<graphicaldisplayresult> : set it to 1 to display image results into
an image viewer provided by OpenCV (C<highgui> and C<imgview()>).
Set it to 0 for not displaying anything. If set to 1, OpenCV must contain
the C<highgui> library component which is optional. OpenCV installations
to headless servers most likely will not contain this component. Although
it is possible to install it.

=item * B<dumpqrimagestofile> : set it to 1 in order to dump results (text and images) to output
files whose names are prepended by B<outbase>. Set it to 0 for not saving any results to files.
Results will still be returned back by this function as an array.

=back

It returns exactly the same results as L<detect_and_decode_qr()>, see L<Returned data by C<detect_and_decode_qr()>>
for details.


=head2 C<modelsdir()>

It returns the path to the default location of the directory
containing the pre-trained CNN models.

=head2 C<opencv_has_highgui_xs()>

It returns 0 or 1 depending whether OpenCV's C<highgui> library
component was detected during this module's installation.
If the result is 1 then the component is installed in your system
and the B<graphicaldisplayresult> parameter to both L<detect_and_decode_qr(\%params)>
and L<detect_and_decode_qr_xs(@params)> can be set to 1. See L<CAVEATS> for the
efficacy of this subroutine.

=head1 COMMAND LINE SCRIPT

  image-decodeqr-wechat.pl --input image-with-qr-code.jpg

  image-decodeqr-wechat.pl --help

A CLI script is provided and will be installed by this module. Basic usage is as above. Here is its usage:

  Usage : script/image-decodeqr-wechat.pl <options>

  where options are:

    --input F :
      the filename of the input image
      which supposedly contains QR codes to be detected.

    --modelsdir M :
      optionally use your own models contained
      in this directory instead of the ones
      this program was shipped with.

    --outbase O :
      basename for all output files
      (if any, depending on whether --dumpqrimagestofile is on).

    --verbosity L :
      verbosity level, 0:mute, 1:C code, 10:C+XS code.

    --graphicaldisplayresult :
      display a graphical window with input image
      and QR codes outlined. Using --dumpqrimagestofile
      and specifying --outbase, images and payloads and
      bounding boxes will be saved to files, if you do
      not have graphical interface.

    --dumpqrimagestofile :
      it has effect only of --outbase was specified. Payloads,
      Bounding Boxes and images of each QR-code detected will
      be saved in separate files.

=head1 PREREQUISITES

=over 4

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

=head1 INSTALLING OpenCV

In my case installing OpenCV using Linux's package
manager (dnf, fedora)
was not successful with default repositories.
It required to add another
repository (rpmfusion) which wanted to install its own versions
of packages I already had. So I prefered to install
OpenCV from sources. This is the procedure I followed:

=over 4

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
equivalent to C<cmake-gui>,  use it like: C<ccmake ../>
(from within the build dir).

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

=item * I have successfully installed this module
on a system with CUDA-capable GPU (with CUDA 10.2 installed)
host and, also, on a headless remote host with no GPU or basic. In general,
CUDA is not required for building this module. It is just an addition for
making things run faster, possibly. OpenCV is responsible for
detecting and utilising GPU processing via CUDA.

=item * It is also possible to download a binary distribution of OpenCV
with developer files (e.g. header files and perhaps a pkg-config or cmake configuration file).
Just make sure that it supports all the things I mentioned above.

=item * If all else fails, then add C<rpmfusion> repository to
your Linux's package manager and then add package OpenCV, developer version.
Make sure there is the WeChat OpenCV library too. If there is not,
C<perl Makefile.PL> will complain and fail.

=back

Your mileage may vary.

If you are seriously in need of installing
this module then consider migrating to a serious operating system
such as Linux as your first action.

=head1 INSTALLING THIS MODULE

This module depends on the existence of the OpenCV library with all
the extensions and contributed modules mentioned in section L</"PREREQUISITES">.

Detecting where this library is located in your system is the weakest
link in the installation process of this module. C<Makefile.PL> contains
code to do this with C<pkg-config> or C<cmake>. If these fail,
it will look for ENVironment variables: C<OPENCV_LDFLAGS> and
C<OPENCV_CFLAGS>, which should contain the C<CFLAGS> (for example:
C<-I/usr/include/opencv4/>) and C<LDFLAGS> (for example:
C<-L/usr/lib64 -lopencv_world>). Set these variables manually
prior installation if the automatic methods mentioned above fail.

One last thing to check is that if your OpenCV installation (developer version)
was correct, there should be a C<pkg-config> file, perhaps in
C</usr/lib64/pkgconfig/opencv4.pc> or C</usr/local/lib64/pkgconfig/opencv4.pc>.
This file details all the C<CFLAGS> and C<LDFLAGS> and should be
found by C<Makefile.PL> if it is in a standard location,
or adjust the list of paths
in environment variable C<PKG_CONFIG_PATH> which is where C<pkg-config> searches
for these files.

=head1 TESTING THE QR CODE DETECTION ALGORITHM

You will want to produce QR codes in order to assess how well
the algorithm (basically the CNN pre-trained models supplied by OpenCV/WeChat)
detects codes and find out the minimum size, quality, rotation angles etc.
for optimal detection.

In producing test images from an original QR code,
with software like the L<GIMP|https://www.gimp.org/>,
one should be aware of the distortions caused
by transforms such as scale and rotation to the final QR code images,
rotation in particular. Add certain enhancements
to the final image to "look good" and
the resultant image looks like QR code but it is not.
Failure of the
library on such artificially produced images would be somehow expected.

Instead I would suggest testing with images B<which have been scanned with a QR code
image attached to them in random angles and zoom factors>. Using a photocopier
or a scanner.

My use case was to process
scanned images with a glued-in QR code tag which is detected
and archive the document from the scanner to the appropriate files.

=head1 UNIT TESTING

There are two sets of tests which can be performed before installation of this module.
The first test is done by default and can be run with:

  perl Makefile.PL
  make all
  make test

The second set of tests is what is called I<author tests> and 
is optionally run with:

  perl Makefile.PL
  make all
  prove -bl xt

In both sets setting the environment variable C<TEMP_DIRS_KEEP> to 1
will keep all temporary files created so that inspection
of output files is possible. By default all temporary files
created during testing are erased on test's exit.

=head1 MODELS

The OpenCV/WeChat QR code detector algorithm
uses CNN (Convolutional Neural Networks) which are required
to be trained first with data containing example QR code images.
The detector kindly provided by OpenCV/WeChat
already contains trained models (see L<LICENSE AND COPYRIGHT> for license)
which are
also contained in and distributed with this module.
These pre-trained models are installed as part of this module, along
with everything else. You do not need to download them manually.

The pre-trained models can be found
L<here|https://github.com/WeChatCV/opencv_3rdparty> where it also
shows their MD5 signatures. Their total size is about 1 MB.

The models directory must contain four files: C<detect.caffemodel>,
C<detect.prototxt>, C<sr.caffemodel> and C<sr.prototxt>.

Use L<modelsdir()> to get the location
of the installed models.

=head1 IMPLEMENTATION DETAILS

This code demonstrates how to call OpenCV (modern OpenCV v4) C++ methods using the
technique suggested by C<Botje @ #perl> in order to avoid all the
function, macro, data structures name clashes between Perl and OpenCV
(for example C<seed()>, C<do_open()>, C<do_close()> and
most notably C<struct cv> and C<namespace cv> in Perl and OpenCV respectively).

The trick suggested is to put all the OpenCV-calling code in a separate C++ file
and provide high-level functions to be called by XS. So that the XS code does
not see any OpenCV header files.

C<Makefile.PL> will happily compile any C<.c> and/or C<.cpp>
files found in the dir it resides
by placing C<OBJECT =E<gt> '$(O_FILES)'> in C<%WriteMakefileArgs>.
And will have no problems with specifying also these:

    CC      => 'g++',
    LD      => 'g++',
    XSOPT   => '-C++',

With one caveat, C<g++> B<compiler will mangle the names of the functions>
when placing them in the object files. And that will cause L<XSLoader> to report
missing and undefined symbols.

The cure to this is to wrap any function you want to remain unmangled
between these two blocks:

    #ifdef __cplusplus
    extern "C" {
    #endif

and

    #ifdef __cplusplus
    } //extern "C" {
    #endif

This only need happen in the header file: C< wechat_qr_decode_lib.hpp >
and in the XS file where the Perl headers are included.

=head1 CAVEATS

Checking for whether local OpenCV installation has highgui
support is currently very lame.
It tries to detect it with three methods (see C<find_if_opencv_highgui_is_supported()> in
C<Makefile.PL> for the implementation)

=over 4

=item * Use L<FFI::CheckLib::find_lib> to check if library C<opencv_highgui> exists.

=item * Search Include dirs for file C<opencv2/highgui.hpp>. This is the most OS-agnostic method.

=item * Use L<Devel::CheckLib::check_lib> to check if a sample C program can link to the C<opencv_highgui> library. This requires a C compiler.

=back

Note that L<DynaLoader> (or L<FFI::CheckLib> which uses it)
can search for symbols in any library
(e.g. highgui library should contain function C<imshow()> in C<libopencv_highgui> or  C<libopencv_world>).
This would have been the most straight-forward way but alas, these are C++ libraries
and the contained function names are mangled to weird function names like:

    ZN2cv3viz6imshowERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEERKNS_11_InputArrayERKNS_5Size_IiEE()

There's an C<imshow> string in there but without a regex symbol-name search
the symbol can not be detected. Currently, L<DynaLoader> (which is called by L<FFI::CheckLib>)
does not provide a regular expression symbol name matching, only exact.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>


=begin HTML

<!--<p><img src="https://fastapi.metacpan.org/source/BLIAKO/Image-DecodeQR-WeChat-2.0/t/testimages/japh.png" alt="Just another Perl hacker" /></p>-->
<div>
  <img src="data:image/png;base64, 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
gfZaOH9NXAAAAABJRU5ErkJggg==" alt="Just another Perl hacker" />
</div>

=end HTML

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-decodeqr-wechat at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-DecodeQR-WeChat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::DecodeQR::WeChat


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-DecodeQR-WeChat>

=item * Review this module at PerlMonks

L<https://www.perlmonks.org/?node_id=21144>

=item * Search CPAN

L<https://metacpan.org/release/Image-DecodeQR-WeChat>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

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

=item * The Hackers of Free Software.

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The OpenCV/WeChat CNN trained models redistributed with
this module are licensed under

  The Apache License Version 2.0

See the full licence
L<here|https://github.com/WeChatCV/opencv_3rdparty/commit/3487ef7cde71d93c6a01bb0b84aa0f22c6128f6b>.


=head1 HUGS

!Almaz!

=cut

1; # End of Image::DecodeQR::WeChat
