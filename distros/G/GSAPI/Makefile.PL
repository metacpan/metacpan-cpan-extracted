use 5.008;
use ExtUtils::MakeMaker;

my $IDIR;
my( $next, @argv );
foreach( @ARGV ) {
    if( $next ) {
        $IDIR = $_;
        last;
    }
    if( /^--include=(.+)/ ) {
        $IDIR=$1;
        last;
    }
    if( /^--include$/ ) {
        $next = 1;
        next;
    }
    push @argv, $_;
}
@ARGV = @argv;

unless( $IDIR ) {
    foreach my $dir ( "/usr/local/include/ghostscript", 
                      "/usr/include/ghostscript" ) {
        next unless -f "$dir/iapi.h";
        print "Found $dir/iapi.h\n";
        $IDIR = $dir;
    }
}

unless( $IDIR ) {
    warn "Didn't find iapi.h.\nYou must specify the path to iapi.h with CCFLAGS= or --include=\n";
}

$INC = "-I.";
$INC .= " -I$IDIR" if $IDIR;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GSAPI',
    'VERSION_FROM'	=> 'GSAPI.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'GSAPI.pm', # retrieve abstract from module
       AUTHOR     => 'Stefan Traby <stefan@hello-penguin.com>') : ()),
    'LIBS'		=> ['-lgs'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> $INC,
    'clean'             =>  { FILES => "const-c.inc const-xs.inc" },
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
         qw(
         DISPLAY_555_MASK DISPLAY_ALPHA_MASK DISPLAY_COLORS_MASK 
         DISPLAY_DEPTH_MASK DISPLAY_ENDIAN_MASK DISPLAY_FIRSTROW_MASK
         DISPLAY_VERSION_MAJOR DISPLAY_VERSION_MINOR 

         e_ExecStackUnderflow
         e_Fatal e_Info e_InterpreterExit e_NeedInput e_NeedStderr
         e_NeedStdin e_NeedStdout e_Quit e_RemapColor e_VMerror
         e_VMreclaim e_configurationerror e_dictfull
         e_dictstackoverflow e_dictstackunderflow e_execstackoverflow
         e_interrupt e_invalidaccess e_invalidcontext e_invalidexit
         e_invalidfileaccess e_invalidfont e_invalidid e_invalidrestore
         e_ioerror e_limitcheck e_nocurrentpoint e_rangecheck
         e_stackoverflow e_stackunderflow e_syntaxerror e_timeout
         e_typecheck e_undefined e_undefinedfilename
         e_undefinedresource e_undefinedresult e_unknownerror
         e_unmatchedmark e_unregistered gs_error_interrupt), 

        # The following are enums, which would fail the #ifdef check
        # so we assume they are allways present, with macro=>1
        map { { name=>$_, macro=>1} } qw(
                    DISPLAY_COLORS_CMYK DISPLAY_COLORS_GRAY
                    DISPLAY_COLORS_NATIVE DISPLAY_COLORS_RGB
                    DISPLAY_ALPHA_FIRST DISPLAY_ALPHA_LAST
                    DISPLAY_ALPHA_NONE DISPLAY_UNUSED_FIRST
                    DISPLAY_UNUSED_LAST DISPLAY_DEPTH_1 DISPLAY_DEPTH_12
                    DISPLAY_DEPTH_16 DISPLAY_DEPTH_2 DISPLAY_DEPTH_4
                    DISPLAY_DEPTH_8 DISPLAY_BIGENDIAN DISPLAY_LITTLEENDIAN
                    DISPLAY_TOPFIRST DISPLAY_BOTTOMFIRST DISPLAY_NATIVE_555
                    DISPLAY_NATIVE_565
        ) );
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'GSAPI',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
