# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.
#
# Based on files from PDL and Perl 

use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($^O eq 'VMS' or $^O eq 'os2');  # "case-forgiving"

unlink $file if -f $file;
open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
        if 0;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

##########################################################################
# Here starts the actual script
# GENERATED FROM freewrl.PL -- DO NOT MODIFY

# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# The following is POD documentation for the freewrl command.
# It will be automatically installed in a manual page upon make install.
# See the perlpod manpage for the I<>, C<> &c explanation

=head1 NAME

freewrl -- run the FreeWRL VRML97 browser on the command line

=head1 SYNOPSIS

C<freewrl> [I<options>] I<url> [I<debugcode> ...]

=head1 DESCRIPTION

See the bottom of this text for the copyright and license.

This command runs the FreeWRL VRML browser.
See L<VRML::Viewer> for details on the user interface and 
L<VRML::Browser> for some other things. This manual
page explains how to use the browser, how to start it on 
the command line, and how to use it with XSwallow..

=head1 KEYS/MOUSE

FreeWRL supports, as per VRML97 spec, several different I<navigation modes>.
In each mode, the meanings of mouse movements and keystrokes are different.

Mouse button 2 + motion is usually unbound so if you want to click
and drag something in the scene, use it.

In addition to the keys described below, there are some keys
which work in all the modes:

=over 4

=item d

Switch to the Fly navigation mode

=item e

Switch to the Examine navigation mode

=item w

Switch to the Walk navigation mode

=item v

Go to the next viewpoint in the scene

=item b

Go to the previous viewpoint in the scene

=item q

Quit the browser 

=back

=head2 Walk

Drag the mouse while mouse button 1 is pressed to move forwards/backwards
or turn.

=head2 Fly

This mode is fun if you have ever played the game Descent
using the keyboard (definitely worth doing ;).

There is currently no mouse control, rather, all motion is controlled
by 12 keys, two for each of your 6 degrees of freedom (3 translations, 
3 rotations).

The default keymap in this mode is

=over 4

=item 

"8"/"k" : rotation down/up

=item 

"u"/"o" : rotation left/right

=item 

"7"/"9" : rotation about the Z axis

=item 

"a"/"z" : translation forwards/backwards

=item 

"j"/"l" : translation left/right

=item 

"p"/";" : translation up/down

=back

It may take a while to get used to the FLY navigation mode but it is the only
one with full freedom of motion currently.

=head2 Examine

The examine navigation mode is analogous to holding an object in your
hand and rotating it to see it from various sides: your line of view
always goes through the same point but you can rotate the object and
translate yourself closer and farther away.

Currently, dragging with mouse button 1 pressed
rotates the scene and dragging up or down mouse button 3 pressed 
translates you towards and away from the scene. There are no other controls.

The center around which you rotate is determined by taking the initial
position and orientation of the viewpoint given in the VRML file. 
A ray is cast along your line of view and the closest that ray comes 
to the origin of the local coordinate system is defined as the origin
of the rotations.

=head2 None

As the name says, there is nothing you can do in the NONE navigation mode.


=head1 OPTIONS

=over 4

=item C<-url> I<baseurl>

The browser downloads the URL given as the first argument on the command
line. The contents of the VRML file can refer to relative URLs just like HTML.
If given, this option is used to resolve the relative URLs instead
of the first commandline argument.

=item C<-eai> I<host:port>

The browser will try to connect to the socket at I<host:port> to obtain
an EAI connection. This option is mostly for internal use by 
the EAI libraries.

=item C<-zpl> I<number>

Set the Z-buffer backplane level. If your world is very big, try setting
this number large. (NOTE: once NavigationInfo properly works, this option
will probably be deprecated)

=item C<-best>

Enables the best-quality rendering (this may slow down your frame rate
considerably)

=item C<-fast>

Enables the fastest rendering in exchange for poorer picture quality.
This is the default and overrides any C<-best> options seen on the command
line.

=item C<-geo[metry]> I<geom>

Set the initial window geometry with the usual X window format string.

=item C<-[no]colormap> 

Install / don't install the freewrl colormap.

=item C<-[no]lwp

Use / don't use libwww-perl. If you use the option -nolwp, you can only
view documents on your local file system.

=item C<-fontdir> I<dir>

Look for the FreeWRL fonts in directory I<dir>. Default: ./fonts
(assumes you are running in the FreeWRL build directory).
This behaviour will probably change.

=item C<-log> I<file>

Log stdout and stderr into I<file>.

=item C<-save> I<dir>

Save all the documents used in I<dir>. Useful if you want to see what
went wrong over a slow network connection. 

This feature will probably be upgraded later to modify the urls and 
filenames in a proper way, for now it just plonks down files with
names "s0", "s1" etc.

=item I<debugcode>

Various strings here turn on debugging for various parts of the browser.
Mostly of interest to developers, who can see the file C<freewrl.PL> 
in the distribution for the codes.

=back

=head1 USING FREEWRL WITH XSWALLOW

Add the following, B<all on one line>, to your xswallow.conf.
Of course, replace the directories with where your copy of freewrl is located.

	x-world/x-vrml;  vr,wrl;      
	    /usr/bin/perl -Mblib=/home/tjl/c/VRML 
	    		 /home/tjl/c/VRML/freewrl  
	                 -url %u -log /tmp/VRMLlog -save /tmp 
			 -fontdir /home/tjl/c/VRML/fonts %s ; 
	    "FreeWRL Scene Viewer" "FreeWRL" ;  Embedded Vrml

after this, you need to do Edit/Preferences/Navigator/Applications
(in Netscape 4.05) to enable displaying Embedded VRML with FreeWRL.

=head1 AUTHOR

Project started by Tuomas J. Lukka, with contributions of code
from Bernhard Reiter, John Breen and Robin Williams.
VRML::Browser also uses the mozilla javascript code.

Please send bug reports to C<lukka@iki.fi> which will redirect
them to wherever I am at the moment. Including the word "freewrl" 
on the subject line will make sure that I'll notice it. Also,
see the FreeWRL home page at C<http://www.iki.fi/lukka/freewrl>.

There is absolutely no warranty, express or implied for this software.
For details on the conditions of use, see the FreeWRL distribution.

FreeWRL is Copyright (C) 1998 Tuomas J. Lukka and others.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


=cut

use Carp;
$SIG{__DIE__} = sub {print Carp::longmess(@_);die;};

BEGIN{

	# use VRML::Browser;

	use Getopt::Long;

	GetOptions(
		"url=s" => \$url,
		"eai=s" => \$eai,
		"zpl=f" => \$zpl,
		"best" => \$best,
		"fast" => \$fast, 
		"geometry=s" => \$geometry,
		"colormap!" => \$VRML::ENV{FREEWRL_NO_COLORMAP},
		"lwp!" => \$VRML::ENV{FREEWRL_NO_LWP},
		"save=s" => \$VRML::ENV{FREEWRL_SAVE},
		"fontdir=s" => \$VRML::ENV{FREEWRL_FONTDIR},
		"log=s" => \$log,
	);

	if($log) {
		open STDOUT, ">$log" || die("Can't redirect stdout to $log: $!");
		open STDERR, ">&STDOUT" || die("Can't redirect stderr to stdout: $!");
	}
	eval"use blib;"; warn "Use blib failed" if $@;
}

my @verb = @ARGV[1..$#ARGV];

sub verb {return !!grep {$_ eq $_[0] or $_ eq "all"} @verb}
sub verbn {return !!grep {$_ eq $_[0]} @verb}

# Turn these switches on if you are debugging
$VRML::verbose = verb all;
$VRML::verbose::be = verb be;
$VRML::verbose::oint = verb oint; # OrientationIntepr
$VRML::verbose::events = verb ev;
$VRML::verbose::script = verb scr ;  
$VRML::verbose::glsens = verb glsens;  # GL sensor code
$VRML::verbose::tief = verb "tie";    # The tied RFields-hash
$VRML::verbose::timesens = verb "time";
$VRML::verbose::interp = verb "interp"; # interpolators
$VRML::verbose::text = verbn "text"; 
$VRML::verbose::rend = verb "rend";
$VRML::verbose::nodec = verb "nodec";
$VRML::verbose::bind = verb "bind";
$VRML::verbose::prox = verb "prox";
$VRML::verbose::js = verb "js";
$VRML::verbose::java = verb "java";
$VRML::verbose::scene = verb "scene";
$VRML::verbose::url = verb "url"; # URL processing and data loading

if($VRML::verbose::text) {
	eval 'require VRML::Text; VRML::Text::set_verbose(1);'
}

require 'VRML/Browser.pm';

$b = new VRML::Browser({BackEnd => [Geometry => $geometry]}); # By default creates front- and back-ends.

$be = $b->get_backend;

if($fast) {
	$be->set_fast();
} elsif($best) {
	$be->set_best();
}

$b->load_file($ARGV[0],$url);

if($zpl) {VRML::VRMLFunc::set_vpdist($zpl)}

if($eai) {
	require "VRML/VRMLServ.pm";
	$s = VRML::EAIServer->new($b);
	$s->connect($eai);
}

$b->eventloop();

!NO!SUBS!

close OUT;
chmod 0555, $file;


