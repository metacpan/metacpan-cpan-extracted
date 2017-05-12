#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('GSAPI') };

my $fail = 0;
foreach my $constname (qw(
    DISPLAY_555_MASK DISPLAY_ALPHA_FIRST DISPLAY_ALPHA_LAST
    DISPLAY_ALPHA_MASK DISPLAY_ALPHA_NONE DISPLAY_BIGENDIAN
    DISPLAY_BOTTOMFIRST DISPLAY_COLORS_CMYK DISPLAY_COLORS_GRAY
    DISPLAY_COLORS_MASK DISPLAY_COLORS_NATIVE DISPLAY_COLORS_RGB
    DISPLAY_DEPTH_1 DISPLAY_DEPTH_12 DISPLAY_DEPTH_16 DISPLAY_DEPTH_2
    DISPLAY_DEPTH_4 DISPLAY_DEPTH_8 DISPLAY_DEPTH_MASK DISPLAY_ENDIAN_MASK
    DISPLAY_FIRSTROW_MASK DISPLAY_LITTLEENDIAN DISPLAY_NATIVE_555
    DISPLAY_NATIVE_565 DISPLAY_TOPFIRST DISPLAY_UNUSED_FIRST
    DISPLAY_UNUSED_LAST DISPLAY_VERSION_MAJOR DISPLAY_VERSION_MINOR
    e_ExecStackUnderflow e_Fatal
    e_Info e_InterpreterExit e_NeedInput e_NeedStderr e_NeedStdin
    e_NeedStdout e_Quit e_RemapColor e_VMerror e_VMreclaim
    e_configurationerror e_dictfull e_dictstackoverflow
    e_dictstackunderflow e_execstackoverflow e_interrupt e_invalidaccess
    e_invalidcontext e_invalidexit e_invalidfileaccess e_invalidfont
    e_invalidid e_invalidrestore e_ioerror e_limitcheck e_nocurrentpoint
    e_rangecheck e_stackoverflow e_stackunderflow e_syntaxerror e_timeout
    e_typecheck e_undefined e_undefinedfilename e_undefinedresource
    e_undefinedresult e_unknownerror e_unmatchedmark e_unregistered
    gs_error_interrupt)) {
  next if (eval "my \$a = GSAPI::$constname(); 1");
  if ($@ =~ /^Your vendor has not defined Errors macro $constname/) {
    diag( "pass: $@" );
  } else {
    diag( "fail: $@" );
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
