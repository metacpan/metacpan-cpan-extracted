BEGIN {				# Magic Perl CORE pragma
    chdir 't' if -d 't';
    unshift @INC,'../lib';
}

# be as strict and verbose as possible
use strict;
use warnings;

# initializations
use Test::More tests => 182;
my $manifest= <<"TEXT";
maintblead                      maint/blead test (added by Devel::MaintBlead)
TEXT

# make sure we start clean
my @files= ( qw(
 default
 maintblead
 lib/Foo/Bar.pm
 lib/Foo/Bar/Baz.pm
 lib_maint/Foo/Bar.pm_maint
 Makefile.PL
 MANIFEST
 MANIFEST_maint
 t/foo.t
 t_maint/foo.t_maint
), map { ( "STDERR.$_", "STDOUT.$_" ) } 1 .. 11 );
unlink(@files); # handy during development / fix previous failures

# set up MANIFESTs
foreach ( '', '_maint' ) {
    ok( open( OUT, ">MANIFEST$_" ), "Failed to open MANIFEST$_: $!" );
    ok( close OUT, "Failed to close MANIFEST$_: $!" );
    ok( -e "MANIFEST$_", "Check if MANIFEST$_ exists" );
}

# set up code for success
my $initial_code= <<"CODE";
\$LIB_TREE= 'Foo';
\$REQUIRED= $];
eval "use Devel::MaintBlead";
open( OUT, '>size' );  # cannot use STDOUT first run
print OUT \$Devel::MaintBlead::SIZE;
close OUT;
CODE
( my $final_code= $initial_code ) =~
  s#(MaintBlead)"#$1; 1" or do 'maintblead'#;

# set up blead source file
mkdir 'lib';
mkdir 'lib/Foo';
create_file( "lib/Foo/Bar.pm", "blead version of source file #1" );
mkdir 'lib/Foo/Bar';
create_file( "lib/Foo/Bar/Baz.pm", "blead version of source file #2" );

# set up maint source file
mkdir 'lib_maint';
mkdir 'lib_maint/Foo';
create_file( 'lib_maint/Foo/Bar.pm_maint', "maint version of source file" );

# set up blead test file
mkdir 't';
create_file( 't/foo.t', "blead version of test file" );

# set up maint test file
mkdir 't_maint';
create_file( 't_maint/foo.t_maint', "maint version of test file" );

# set up Makefile.PL
Makefile($initial_code);

# checks for first time (blead)
run( 1, '', 0, <<"STDERR", '_maint' );
Installing 'maintblead' code version logic for Makefile.PL
Files for blead already in position
STDERR

# empty directories created
ok( -d 'lib_blead', "check existence of lib_blead" );
ok( -d 'lib_blead/Foo', "check existence of lib_blead/Foo" );
ok( -d 't_blead', "check existence of t_blead" );

# checks for second time (blead)
run( 2, '', 0, <<"STDERR", '_maint' );
Files for blead already in position
STDERR

# checks for selecting maint
run( 3, 'maint', 0, <<STDERR, '_blead' );
Forcing to use the 'maint' version of the code
Moving maint files into position
STDERR
ok( -d 'lib_blead/Foo/Bar', "check existence of lib_blead/Foo/Bar" );

# checks for selecting maint again (indirectly)
run( 4, '', 0, <<STDERR, '_blead' );
Files for maint already in position
STDERR

# checks for selecting blead again
run( 5, 'blead', 0, <<"STDERR", '_maint' );
Forcing to use the 'blead' version of the code
Moving blead files into position
STDERR
ok( -d 'lib_maint/Foo/Bar', "check existence of lib_maint/Foo/Bar" );

# set up Makefile.PL for not allowing blead
my $vthis=    vstring($]);
my $required= sprintf '%1.6f', $] + 0.000001;
my $vthat=    vstring($required);
$final_code =~ s#$]# sprintf '%1.6f', $required #se;
Makefile($final_code);

# checks for selecting blead with wrong Perl version
run( 6, '', 1, <<"STDERR", '_maint' );

This distribution requires at least Perl $required to be installed.  Since this
is an older distribution, with a history spanning almost a decade, it is also
available inside this distribution as a previous incarnation, which is actively
maintained as well.

You can install that version of this distribution by running this Makefile.PL
with the additional "maint" parameter, like so:

 $^X Makefile.PL maint 

Or you can provide an automatic selection behavior, which would automatically
select and install the right version of this distribution for the version of
Perl provided, by setting the AUTO_SELECT_MAINT_OR_BLEAD environment variable
to a true value.  On Unix-like systems like so:

 AUTO_SELECT_MAINT_OR_BLEAD=1 $^X Makefile.PL 

Thank you for your attention.

Perl $vthat required--this is only $vthis, stopped at Makefile.PL line 306.
STDERR

# check for automatic selection
$ENV{AUTO_SELECT_MAINT_OR_BLEAD}= 1;
run( 7, '', 0, <<"STDERR", '_blead' );
Moving maint files into position
STDERR

# restore original Makefile.PL
$final_code =~ s#$required#$]#s;
Makefile($final_code);

# move back to blead
run( 8, 'blead', 0, <<"STDERR", '_maint' );
Forcing to use the 'blead' version of the code
Moving blead files into position
STDERR

# force to blead if blead already there
run( 9, 'blead', 0, <<"STDERR", '_maint' );
Forcing to use the 'blead' version of the code
Files for blead already in position
STDERR

# try two other parameters, staying same with blead
run( 10, 'INSTALLDIRS=site PREFIX=duh', 0, <<"STDERR", '_maint' );
Files for blead already in position
STDERR

# going to blead without change
run( 11, 'blead INSTALLDIRS=site', 0, <<"STDERR", '_maint' );
Forcing to use the 'blead' version of the code
Files for blead already in position
STDERR

# cleanup
is( unlink(@files), scalar(@files), 'make sure we end up cleanly' );
foreach ( qw(
  lib/Foo/Bar
  lib/Foo
  lib
  lib_blead/Foo
  lib_blead
  lib_maint/Foo/Bar
  lib_maint/Foo
  lib_maint
  t
  t_blead
  t_maint
) ) {
    diag "Could not remove directory '$_': $!"
      if !ok( rmdir, "removing '$_'" );
}

#-------------------------------------------------------------------------------
#  IN: 1 filename
# OUT: 1 contents

sub slurp { open IN, $_[0]; undef $/; <IN> } #slurp

#-------------------------------------------------------------------------------
#  IN 1 filename
#     2 comment
#
# Good for 3 tests

sub create_file {
    my ( $filename, $comment )= @_;

    ok( open( OUT, ">$filename" ), "Failed to create $filename: $!" );;
    ok( close OUT, "Failed to close $filename: $!" );
    ok( -e $filename, $comment);
} #create_file

#-------------------------------------------------------------------------------
#  IN: 1 contents of Makefile.PL
#
# Good for 3 tests

sub Makefile {
    ok( open( OUT, ">Makefile.PL" ), "Failed to open Makefile.PL: $!" );
    print OUT shift;
    ok( close OUT, "Failed to close Makefile.PL: $!" );
    ok( -e "Makefile.PL", "Check if Makefile.PL exists" );
} #Makefile

#-------------------------------------------------------------------------------
#  IN: 1 ordinal number
#      2 extra parameters in call
#      3 expected status
#      4 STDERR contents required
#      5 type of extra manifest to check
#
# Good for 12 or 13 tests

sub run {
    my ( $n, $extra, $status, $stderr, $type )= @_;

    my $result= system(
      "$^X -I../blib/lib Makefile.PL $extra 2>STDERR.$n >STDOUT.$n"
    ) >> 8;
    is( $result, $status, "call $n ok" );

    # only if this worked out ok
    SKIP: {
        skip( "cannot determine size after failure", 2 ) if $result;

        # check size
        my $size= -s 'maintblead';
        is( slurp('size'), $size, "contents of size #$n" );
        ok( unlink('size'), 'unlink size' );
    } #SKIP

    # direct results
    is( slurp("STDOUT.$n"), '', "contents of STDOUT.$n" );
    is( slurp("STDERR.$n"), $stderr, "contents of STDERR.$n" );
    is( slurp("Makefile.PL"), $final_code, "contents of Makefile.PL #$n" );
    is( slurp("MANIFEST"), $manifest, "contents of MANIFEST #$n" );
    is( slurp("MANIFEST$type"), $manifest, "contents of MANIFEST$type #$n" );

    # indirect results
    foreach ( '', $type ) {
        ok( -e "lib$_/Foo/Bar.pm$_", "check existence of lib$_/Foo/Bar.pm$_" );
        ok( -e "t$_/foo.t$_", "check existence of t$_/foo.t$_" );
    }

    # check deeper files if necessary
    ok( -e "lib$type/Foo/Bar/Baz.pm$type", "check existence of lib$type/Foo/Bar/Baz.pm$type" )
      if $type ne '_maint';
} #run

#-------------------------------------------------------------------------------
#  IN: 1 Perl version number, $] style
# OUT: 1 Perl version number, v style

sub vstring {

    ( my $v= shift ) =~
      s#(\d)\.(\d\d\d)(\d\d\d)# sprintf 'v%d.%d.%d', $1, $2, $3 #se;

    return $v;
} #vstring

#-------------------------------------------------------------------------------
