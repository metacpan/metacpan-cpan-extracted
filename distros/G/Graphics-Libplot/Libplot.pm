package Graphics::Libplot;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD 
  @INTLOWLEVEL @FLOATLOWLEVEL @DEVICECONTROL @MAPPING @ATTRIBUTES @GENERAL 
  @ALLBUTDRAW
);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
#@EXPORT = qw(
#	LIBPLOT_VERSION
#	__BEGIN_DECLS
#	__END_DECLS
#	___const
#);
$VERSION = '2.2.4';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Libplot macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}


@DEVICECONTROL = qw(
pl_newpl
pl_selectpl
pl_deletepl
pl_parampl
pl_closepl
pl_openpl
pl_flushpl
   );

@MAPPING = qw (
pl_fconcat
pl_frotate
pl_fscale
pl_ftranslate
	       );

@ATTRIBUTES = qw (
pl_bgcolor
pl_bgcolorname
pl_linemod
pl_capmod
pl_color
pl_colorname
pl_filltype
pl_fillcolor
pl_fillcolorname
pl_fontname
pl_fontsize
pl_havecap
pl_joinmod
pl_pencolor
pl_pencolorname
pl_linewidth
pl_labelwidth	  
pl_restorestate
pl_savestate
pl_textangle

);

@GENERAL = qw(
pl_label
pl_erase
pl_outfile
pl_endpath
     );

@INTLOWLEVEL = qw (
pl_arc
pl_box
pl_circle
pl_cont
pl_line
pl_move
pl_point
pl_space
pl_alabel
pl_arcrel
pl_boxrel
pl_circlerel
pl_contrel
pl_ellarc
pl_ellarcrel
pl_ellipse
pl_ellipserel
pl_linerel
pl_marker
pl_markerrel
pl_moverel
pl_pointrel
pl_space2
);

@FLOATLOWLEVEL = qw (
pl_ffontname
pl_ffontsize
pl_flabelwidth
pl_ftextangle
pl_farc
pl_farcrel
pl_fbox
pl_fboxrel
pl_fcircle
pl_fcirclerel
pl_fcont
pl_fcontrel
pl_fellarc
pl_fellarcrel
pl_fellipse
pl_fellipserel
pl_fline
pl_flinerel
pl_flinewidth
pl_fmarker
pl_fmarkerrel
pl_fmove
pl_fmoverel
pl_fpoint
pl_fpointrel
pl_fspace
pl_fspace2
);



@EXPORT_OK = ( 
@INTLOWLEVEL, @FLOATLOWLEVEL, @DEVICECONTROL, @MAPPING, @ATTRIBUTES, @GENERAL
 );
@EXPORT = ();
@ALLBUTDRAW=(@DEVICECONTROL, @MAPPING, @ATTRIBUTES, @GENERAL);

%EXPORT_TAGS = ('INTEGERLOW' => [@ALLBUTDRAW, @INTLOWLEVEL],
              'FLOATLOW' => [@ALLBUTDRAW, @FLOATLOWLEVEL]
		);
$EXPORT_TAGS{'ALL'} = [@ALLBUTDRAW,@FLOATLOWLEVEL,@INTLOWLEVEL
		      ];

bootstrap Graphics::Libplot $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Graphics::Libplot - Perl extension for libplot plotting library

=head1 SYNOPSIS

  use Graphics::Libplot ':All';

=head1 DESCRIPTION

This module lets you create plots by calling the routines in
the libplot library.  The libplot library is included in the
plotutils package.  Wrappers for each published C function
are present. So the section of the plotutils info pages on
programming in C should be your main reference.  There are a
few possible confusions, which are noted below. libplot has
three different api's. This perl module provides and
interface to the second one. It is the same as the most
recent api, except that the the functions are not
re-entrant. The api supported here is described in the
section "Older C application programming interfaces" in the
libplot manual.


Some of the C routines require character constants rather
than strings.  When using the equivalent perl function, you
must wrap the character with the 'ord' function. For
instance, alabel(ord 'c', ord 'c', "some text"); , will
write some centered text.

There is another unrelated perl-module interface to GNU libplot, called
C<Graphics::Plotter>.

=head1 EXPORTING FUNCTIONS

None of the libplot functions is exported by default. If you
do not import any functions you must prepend the module name
to each function.  To call the pl_openpl() function you
would give,

 Graphics::Libplot::pl_openpl();


However, if you include the library with

 use Graphics::Libplot ':All'

then all of the functions will be exported, and you do not need to prepend the
module name.  In this case you need to be careful because there are many
function names which may collide with others in your program.

On the other hand you can use one of

 use Graphics::Libplot ':INTEGERLOW'
 use Graphics::Libplot ':FLOATLOW'

to get just integer or just floating point plotting.

Be aware that the interface is still under development so more names will
be added, and your scripts may need to be changed.

=head1 EXAMPLES

There are additional examples included in the source distribution. 
(They are in /usr/share/doc/libplot-perl/examples on debian systems.)
This example draws a spiraling box pattern.

 use Graphics::Libplot ':ALL';

 # type of plotting device
 $device = 'X';
 if (@ARGV) {
    $device = $ARGV[0];	
    die "Uknown device: $ARGV[0]" unless $ARGV[0] =~ /^ps|X|fig$/;
 }

 {   # environment for local variables

  my $SIZE=100;
  my ($i,$f,$s,$sf);
  pl_parampl ("BITMAPSIZE", "700x700");
  $handle = pl_newpl($device, stdin, stdout, stderr); # open xwindow display
  pl_selectpl($handle); 
  pl_openpl();
  pl_fspace(-$SIZE,-$SIZE, $SIZE, $SIZE); # specify user coord system 
  pl_pencolorname ("blue");
  pl_fontname("HersheySerif");
  $s = 10;
  $f = 10;
  $sf = 1- .0012;
  for($i=1;$i<3000;$i++){
     pl_fscale($sf,$sf);
     pl_fbox(60+$s*sin($i/$f),
	  60+$s*sin($i/$f),
	  75-$s*cos($i/$f),
	  75-$s*cos($i/$f));
     pl_frotate(1);
  }
 }
 pl_closepl();
 pl_selectpl(0);
 pl_deletepl($handle);


=head1 BUGS

The newest API is not supported. There is no test suite with this module, so
it is not clear that everything works correctly.

=head1 AUTHOR

John Lapeyre <lapeyre@physics.arizona.edu> wrote this
perl interface.

The libplot C library is developed by Robert Maier.

=head1 COPYRIGHT

libplot-perl is copyrighted by John Lapeyre and may
be distributed only under the terms of either
the Gnu General Public License, or of the perl
Artistic License.

=head1 SEE ALSO

perl(1).

=cut
