package GSAPI;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use Tie::Handle;

our @ISA = qw(Exporter Tie::Handle);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GSAPI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'const' => [ qw(
    DISPLAY_555_MASK
    DISPLAY_ALPHA_FIRST
    DISPLAY_ALPHA_LAST
    DISPLAY_ALPHA_MASK
    DISPLAY_ALPHA_NONE
    DISPLAY_BIGENDIAN
    DISPLAY_BOTTOMFIRST
    DISPLAY_COLORS_CMYK
    DISPLAY_COLORS_GRAY
    DISPLAY_COLORS_MASK
    DISPLAY_COLORS_NATIVE
    DISPLAY_COLORS_RGB
    DISPLAY_DEPTH_1
    DISPLAY_DEPTH_12
    DISPLAY_DEPTH_16
    DISPLAY_DEPTH_2
    DISPLAY_DEPTH_4
    DISPLAY_DEPTH_8
    DISPLAY_DEPTH_MASK
    DISPLAY_ENDIAN_MASK
    DISPLAY_FIRSTROW_MASK
    DISPLAY_LITTLEENDIAN
    DISPLAY_NATIVE_555
    DISPLAY_NATIVE_565
    DISPLAY_TOPFIRST
    DISPLAY_UNUSED_FIRST
    DISPLAY_UNUSED_LAST
    DISPLAY_VERSION_MAJOR
    DISPLAY_VERSION_MINOR
    ERROR_NAMES
    GSDLLAPI
    GSDLLAPIPTR
    GSDLLCALL
    GSDLLCALLPTR
    GSDLLEXPORT
    LEVEL1_ERROR_NAMES
    LEVEL2_ERROR_NAMES
    e_ExecStackUnderflow
    e_Fatal
    e_Info
    e_InterpreterExit
    e_NeedInput
    e_NeedStderr
    e_NeedStdin
    e_NeedStdout
    e_Quit
    e_RemapColor
    e_VMerror
    e_VMreclaim
    e_configurationerror
    e_dictfull
    e_dictstackoverflow
    e_dictstackunderflow
    e_execstackoverflow
    e_interrupt
    e_invalidaccess
    e_invalidcontext
    e_invalidexit
    e_invalidfileaccess
    e_invalidfont
    e_invalidid
    e_invalidrestore
    e_ioerror
    e_limitcheck
    e_nocurrentpoint
    e_rangecheck
    e_stackoverflow
    e_stackunderflow
    e_syntaxerror
    e_timeout
    e_typecheck
    e_undefined
    e_undefinedfilename
    e_undefinedresource
    e_undefinedresult
    e_unknownerror
    e_unmatchedmark
    e_unregistered
    gs_error_interrupt	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'const'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.5';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&GSAPI::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('GSAPI', $VERSION);

# Preloaded methods go here.

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GSAPI - Perl extension for accessing GNU Ghostscript

=head1 SYNOPSIS

  use GSAPI;
  my $inst = GSAPI::new_instance();
  GSAPI::init_with_args($inst);
  GSAPI::run_string($inst, "12345679 9 mul pstack quit\n");
  GSAPI::exit($inst);
  GSAPI::delete_instance $inst;

=head1 ABSTRACT

GSAPI is an interface to GNU Ghostscript.
It's mainly written to provide a simply interface to ghostscript
that works under Win32 and Unix.

=head1 DESCRIPTION

GSAPI is a very simple interface to the GNU Ghostscript Interpreter API. 
This API allows you to use Ghostscript without calling an external program. It
also provides to more control over any output.

Please read the L<current Ghostscript
documentation|http://pages.cs.wisc.edu/~ghost/doc/svn/Readme.htm> for more details.

=head1 FUNCTIONS

=head2 revision

    my($prod, $cpy, $rev, $revd) = GSAPI::revision();

Returns Product name, Copyright, Revision and Revision Date
of the ghostscript release.

=head2 new_instance

    my $inst = GSAPI::new_instance();

Returns the instance handle.

=head2 delete_instance

    GSAPI::delete_instance($inst);

Destroys the instance.

=head2 set_stdio

    GSAPI::set_stdio($inst, &stdin, &stdout, &stderr)

Sets the callbacks for ghostscript I/O
C<stdin> gets the maximum number of bytes to return on input and should
return a string up to that length.

C<stdout/stderr> gets the string passed and they should return the number
of bytes written.

Example:

   set_stdio $inst,
             sub { "\n" },
             sub { print STDOUT $_[0]; length $_[0] },
             sub { print STDERR $_[0]; lenngth $_[0] };

=head2 init_with_args

    $rc = GSAPI::init_with_args($inst, @args)

Initializes the ghostscript library.  C<@args> is an array that contains
the same strings you would use on the C<gs> command line.

=head2 exit

    $rc = GSPAI::exit($inst)

Calls gsapi_exit

=head2 run_string

    $rc = GSAPI::run_string($inst, $string, [$user_errors ])

Calls C<gsapi_run_string_with_length()>, executing the Postscript code
in C<$string>.

=head2 run_file

    $rc = GSAPI::run_file($inst, $filename, [$user_errors])

Calls C<gsapi_run_file()>, running the Postscript code in C<$filename>.

=head2 run_string_begin

    $rc = GSAPI::run_string_begin($inst, [$user_errors])

Calls C<gsapi_run_string_begin()>, which gets the interpreter ready to run
the Postscript code given via subsequent L</run_string_continue> calls.

=head2 run_string_continue

    $rc = GSAPI::run_string_continue($inst, $string, [$user_errors])

Calls C<gsapi_run_string_continue()>, running the Postscript code in
C<$string> in the interpreter which has been prepared with
L</run_string_begin>.

=head2 run_string_end

    $rc = GSAPI::run_string_end($inst, [$user_errors])

Calls L<gsapi_run_string_end()>, finishing the execution started in
L</run_string_begin>.
   

=head2 set_display_callback

    $rc = GSAPI::set_display_callback( $inst, &callback );

Sets the callback used for C<-sDEVICE=display>.
  
Your callback should look like:

    sub callback {
        my( $func, $handle, $device, @more ) = @_;
        ...
        return $rv;
    }

The arguments are:

=over 4

=item $func

Name of the current callback.  See below.

=item $handle

Value of C<-dDeviceHandle=> as passed to L<init_with_args>.

=item $device

Opaque pointer to Ghostscript's internal device.

=item @more

Extra parameters.  See below.

=back


The callback function is called multiple times.  What is happening is decided
by C<$func>.

=over 4

=item display_open

New device has been opened.  First call.

=item display_presize

Allows you to accept or reject a size and/or format.

    my( $width, $height, $raster, $format ) = @more;

C<$width> width of the page.  Note that this is different from the width of
the image, if there is a bounding box defined.
C<$height> is the height of the page.
C<$raster> is the byte count of a row.
C<$format> format of the data.

=item display_size

Called when the page size is fixed.

    my( $width, $height, $raster, $format ) = @more;

Note that in the GSAPI, display_size() is called with a pointer (C<pimage>)
to the raw data.  However, because of how XS works, this data is only
available to L</display_sync> and L</display_page>.

=item display_sync

    my( $pimage ) = @more;

Called when a page is ready to be flushed.  Note that C<$pimage> will be a
blank page, if this is called before L</display_page>.
   
=item display_page

Called when a page is ready to be shown.
  
    my( $copies, $flush, $pimage ) = @more;

C<$pimage> is a string containing the raw image data.  It's format is
decided by C<-dDisplayFormat> which you passed to L</init_with_args>.

To get the start of a given row, you use C<$rowN * $raster> where C<$raster>
was provided to L</display_size>.

See C<eg/imager.pl> for an example of how to get the data.

=item display_preclose

Device is about to be closed.

=item display_close

Device has been closed. This is the last call for this device.

=back

Please refer to the Ghostscript documentation and examples for more details.

=head1 TIEHANDLE

    TIEHANDLE 'GSAPI', [ stdin => sub { getc STDIN }, ]
                        [ stdout => &stdout, ]
                        [ stderr => stderr, ]
                        [ args => [ arg1, arg2, ...], ]
                        [ user_errors => 0|1, ]

You may also tie a GSAPI instance to a file handle.  This allows you to
print your Postscript code as if to the C<gs> command.

  my $output = '';
  tie *FH, "GSAPI", stdout => sub { $output .= $_[0]; length $_[0] },
                   args => [ "gsapi",
                             "-sDEVICE=pdfwrite",
                             "-dNOPAUSE",
                             "-dBATCH",
                             "-sPAPERSIZE=a4",
                             "-DSAFER",
                             "-sOutputFile=/dev/null",
                           ];

  $output = '';
  print FH "12345679 9 mul pstack quit\n";
  close FH;

  ## $output will contain 111111111.

=cut

sub TIEHANDLE {
   my ($class,%args) = @_;
   my $inst = new_instance();
   $args{stdin} ||= sub { getc STDIN };
   $args{stdout} ||= sub { print STDOUT $_[0]; length $_[0] };
   $args{stderr} ||= sub { print STDERR $_[0]; length $_[0] };
   $args{args} ||= [];
   $args{user_errors} ||= 0;
   $args{inst} = $inst;
   set_stdio($inst, $args{stdin}, $args{stdout}, $args{stderr});
   delete @args{qw/stdin stdout stderr/};
   init_with_args($inst, @{$args{args}});
   run_string_begin($inst, $args{user_errors});
   bless \%args, $class;
}

sub WRITE ($$$$) {
   my ($ref, $buf, $len, $offs) = @_;
   run_string_continue($ref->{inst}, substr($buf, 0, $len), $ref->{user_errors});
}

sub DESTROY ($) {
   my $inst = $_[0]->{inst};
   run_string_end($inst, $_[0]->{user_errors});
   GSAPI::exit($inst);
   delete_instance($inst);
}

=begin

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<http://pages.cs.wisc.edu/~ghost/doc/svn/Readme.htm>

=head1 AUTHORS

Stefan Traby, E<lt>stefan@hello-penguin.comE<gt>
Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Philip Gwyn.
Copyright 2003,2005 by Stefan Traby <stefan@hello-penguin.com>.
Copyright (C) 2003,2005 by KW-Computer Ges.m.b.H Graz, Austria.

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License 2.0 or any later version.

The main reason why this module is not available under dual license
(Artistic/GPL) is simply the fact that GNU Gostscript is only available
under GPL and not under Artistic License.

=cut

1;
__END__

