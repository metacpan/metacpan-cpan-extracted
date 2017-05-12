
package DB ;

##
## Expedient fix for perl 5.8.0.  True DB::DB is further down.
## 
##
sub DB {}



use Tk ;

#
# If you've loaded this file via a browser
# select "Save As..." from your file menu
#
#        ptkdb Perl Tk perl Debugger
#
#          Copyright 1998, 2003, Andrew E. Page
#         All rights reserved.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of either:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version, or
#
# b) the "Artistic License" which comes with this Kit.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
#    the GNU General Public License or the Artistic License for more details.
#


####################################
### Sample .Xresources for ptkdb ###
####################################
#  /*
#   * Perl Tk Debugger XResources.  
#   * Note... These resources are subject to change.  
#   *
#   * Use 'xfontsel' to select different fonts.
#   *
#   * Append these resource to ~/.Xdefaults | ~/.Xresources
#   * and use xrdb -override ~/.Xdefaults | ~/.Xresources
#   * to activate them.  
#   */
# /* Set Value to se to place scrollbars on the right side of windows 
#   CAUTION:  extra whitespace at the end of the line is causing
#   failures with Tk800.011.
# */
# ptkdb*scrollbars: sw
# 
# /* controls where the code pane is oriented, down the left side, or across the top */
# /* values can be set to left, right, top, bottom */
# ptkdb*codeside: left
# /*
# * Background color for the balloon
# * CAUTION:  For certain versions of Tk trailing
# * characters after the color produces an error
# */
# ptkdb.frame2.frame1.rotext.balloon.background: green
# ptkdb.frame2.frame1.rotext.balloon.font: fixed                       /* Hot Variable Balloon Font */
# 
# 
# ptkdb.frame*font: fixed                           /* Menu Bar */
# ptkdb.frame.menubutton.font: fixed                /* File menu */
# ptkdb.frame2.frame1.rotext.font: fixed            /* Code Pane */
# ptkdb.notebook.datapage.frame1.hlist.font: fixed  /* Expression Notebook Page */
#              
# ptkdb.notebook.subspage*font: fixed               /* Subroutine Notebook Page */
# ptkdb.notebook.brkptspage*entry.font: fixed       /* Delete Breakpoint Buttons */
# ptkdb.notebook.brkptspage*button.font: fixed      /* Breakpoint Expression Entries */
# ptkdb.notebook.brkptspage*button1.font: fixed     /* Breakpoint Expression Entries */
# ptkdb.notebook.brkptspage*checkbutton.font: fixed /* Breakpoint Checkbuttons */
# ptkdb.notebook.brkptspage*label.font: fixed       /* Breakpoint "Cond" label */
#              
# ptkdb.toplevel.frame.textundo.font: fixed         /* Eval Expression Entry Window */
# ptkdb.toplevel.frame1.text.font: fixed            /* Eval Expression Results Window */
# ptkdb.toplevel.button.font:  fixed                /* "Eval..." Button */
# ptkdb.toplevel.button1.font: fixed                /* "Clear Eval" Button */
# ptkdb.toplevel.button2.font: fixed                /* "Clear Results" Button */
# ptkdb.toplevel.button3.font: fixed                /* "Clear Dismiss" Button */
# 
# 
#  /*
#   * Background color for where the debugger has stopped 
#   */  
#  ptkdb*stopcolor: blue
#
#  /*
#   * Background color for set breakpoints  
#   */
#  ptkdb*breaktagcolor: red
#
#  /*
#   * Font for where the debugger has stopped
#   */
#  ptkdb*stopfont: -*-fixed-bold-*-*-*-*-*-*-*-*-*-*-*
#
#  /*
#   * Background color for the search tag
#   */  
#  ptkdb*searchtagcolor: green

use strict ;
use vars qw($VERSION @dbline %dbline);


#
# This package is the main_window object
# for the debugger.  We start with the Devel::
# prefix because we want to install it with 
# the DB:: package that is required to be in a Devel/
# subdir of a directory in the @INC set.  
#
package Devel::ptkdb ;

##
## do this check once, rather than repeating the string comparison again and again
##


my $isWin32 = $^O eq 'MSWin32' ;

=head1 NAME

Devel::ptkdb - Perl debugger using a Tk GUI

=head1 DESCRIPTION

  ptkdb is a debugger for perl that uses perlTk for a user interface.
  Features include:

    Hot Variable Inspection
    Breakpoint Control Panel
    Expression List
    Subroutine Tree
    

=begin html

    <body bgcolor=white>

=end html

=head1 SYNOPSIS

To debug a script using ptkdb invoke perl like this:

    perl -d:ptkdb myscript.pl

=head1 Usage

    perl -d:ptkdb myscript.pl

=head1 Code Pane

=over 4

=item Line Numbers

 Line numbers are presented on the left side of the window. Lines that
 have lines through them are not breakable. Lines that are plain text
 are breakable. Clicking on these line numbers will insert a
 breakpoint on that line and change the line number color to
 $ENV{'PTKDB_BRKPT_COLOR'} (Defaults to Red). Clicking on the number
 again will remove the breakpoint.  If you disable the breakpoint with
 the controls on the BrkPt notebook page the color will change to
 $ENV{'PTKDB_DISABLEDBRKPT_COLOR'}(Defaults to Green).

=item Cursor Motion

If you place the cursor over a variable (i.e. $myVar, @myVar, or
%myVar) and pause for a second the debugger will evaluate the current
value of the variable and pop a balloon up with the evaluated
result. I<This feature is not available with Tk400.>

If Data::Dumper(standard with perl5.00502)is available it will be used
to format the result.  If there is an active selection, the text of
that selection will be evaluated.

=back

=head1 Notebook Pane

=over 2

=item Exprs

 This is a list of expressions that are evaluated each time the
 debugger stops. The results of the expresssion are presented
 heirarchically for expression that result in hashes or lists.  Double
 clicking on such an expression will cause it to collapse; double
 clicking again will cause the expression to expand. Expressions are
 entered through B<Enter Expr> entry, or by Alt-E when text is
 selected in the code pane.

 The B<Quick Expr> entry, will take an expression, evaluate it, and
 replace the entries contents with the result.  The result is also
 transfered to the 'clipboard' for pasting.

=item Subs

 Displays a list of all the packages invoked with the script
 heirarchially. At the bottom of the heirarchy are the subroutines
 within the packages.  Double click on a package to expand
 it. Subroutines are listed by their full package names.

=item BrkPts

 Presents a list of the breakpoints current in use. The pushbutton
 allows a breakpoint to be 'disabled' without removing it. Expressions
 can be applied to the breakpoint.  If the expression evaluates to be
 'true'(results in a defined value that is not 0) the debugger will
 stop the script.  Pressing the 'Goto' button will set the text pane
 to that file and line where the breakpoint is set.  Pressing the
 'Delete' button will delete the breakpoint.

=back

=head1 Menus

=head2 File Menu

=over

=item About...

Presents a dialog box telling you about the version of ptkdb.  It
recovers your OS name, version of perl, version of Tk, and some other
information

=item Open

Presents a list of files that are part of the invoked perl
script. Selecting a file from this list will present this file in the
text window.

=item Save Config...

Requires Data::Dumper. Prompts for a filename to save the
configuration to. Saves the breakpoints, expressions, eval text and
window geometry. If the name given as the default is used and the
script is reinvoked, this configuration will be reloaded
automatically.

    B<NOTE:>  You may find this preferable to using 

=item Restore Config...

Requires Data::Dumper.  Prompts for a filename to restore a configuration saved with
the "Save Config..." menu item.  

=item Goto Line...

Prompts for a line number.  Pressing the "Okay" button sends the window to the line number entered.
item Find Text...

Prompts for text to search for.  Options include forward search,
backwards search, and regular expression searching.

=item Quit

 Causes the debugger and the target script to exit. 

=back

=head2 Control Menu

=over

=item Run

The debugger allows the script to run to the next breakpoint or until the script exits.
item Run To Here

Runs the debugger until it comes to wherever the insertion cursor
in text window is placed.

=item Set Breakpoint

Sets a breakpoint on the line at the insertion cursor.  
item Clear Breakpoint

Remove a breakpoint on the at the insertion cursor.

=item Clear All Breakpoints

Removes all current breakpoints

=item Step Over

Causes the debugger to step over the next line.  If the line is a
subroutine call it steps over the call, stopping when the subroutine
returns.

=item Step In

Causes the debugger to step into the next line.  If the line is a
subroutine call it steps into the subroutine, stopping at the first
executable line within the subroutine.

=item Return

Runs the script until it returns from the currently executing
subroutine.  

=item Restart

Saves the breakpoints and expressions in a temporary file and restarts
the script from the beginning.  CAUTION: This feature will not work
properly with debugging of CGI Scripts.

=item Stop On Warning

When C<-w> is enabled the debugger will stop when warnings such as, "Use
of uninitialized value at undef_warn.pl line N" are encountered.  The debugger
will stop on the NEXT line of execution since the error can't be detected
until the current line has executed.  

This feature can be turned on at startup by adding:

$DB::ptkdb::stop_on_warning = 1 ;

to a .ptkdbrc file

=back

=head2 Data Menu

=over

=item Enter Expression

When an expression is entered in the "Enter Expression:" text box,
selecting this item will enter the expression into the expression
list.  Each time the debugger stops this expression will be evaluated
and its result updated in the list window.

=item Delete Expression

 Deletes the highlighted expression in the expression window.

=item Delete All Expressions

 Delete all expressions in the expression window.

=item Expression Eval Window

Pops up a two pane window. Expressions of virtually unlimitted length
can be entered in the top pane.  Pressing the 'Eval' button will cause
the expression to be evaluated and its placed in the lower pane. If
Data::Dumper is available it will be used to format the resulting
text.  Undo is enabled for the text in the upper pane.

HINT:  You can enter multiple expressions by separating them with commas.  

=item Use Data::Dumper for Eval Window

Enables or disables the use of Data::Dumper for formatting the results
of expressions in the Eval window.  

=back

=head2 Stack Menu

Maintains a list of the current subroutine stack each time the
debugger stops. Selecting an item from this menu will set the text in
the code window to that particular subourtine entry point.

=head2 Bookmarks Menu

Maintains a list of bookmarks.  The booksmarks are saved in ~/.ptkdb_bookmarks

=over

=item Add Bookmark

Adds a bookmark to the bookmark list.  

=back

=head1 Options

Here is a list of the current active XResources options. Several of
these can be overridden with environmental variables. Resources can be
added to .Xresources or .Xdefaults depending on your X configuration.
To enable these resources you must either restart your X server or use
the xrdb -override resFile command.  xfontsel can be used to select
fonts.

    /*
    * Perl Tk Debugger XResources.   
    * Note... These resources are subject to change.   
    *
    * Use 'xfontsel' to select different fonts.
    *
    * Append these resource to ~/.Xdefaults | ~/.Xresources
    * and use xrdb -override ~/.Xdefaults | ~/.Xresources
    * to activate them. 
    */
    /* Set Value to se to place scrollbars on the right side of windows 
  CAUTION:  extra whitespace at the end of the line is causing
    failures with Tk800.011.
    
    sw -> puts scrollbars on left, se puts scrollars on the right
    
    */
    ptkdb*scrollbars: sw
    /* controls where the code pane is oriented, down the left side, or across the top */
    /* values can be set to left, right, top, bottom */
    ptkdb*codeside: left
    
    /*
    * Background color for the balloon
    * CAUTION:  For certain versions of Tk trailing
    * characters after the color produces an error
    */
    ptkdb.frame2.frame1.rotext.balloon.background: green
    ptkdb.frame2.frame1.rotext.balloon.font: fixed                       /* Hot Variable Balloon Font */
    
    
    ptkdb.frame*font: fixed                           /* Menu Bar */
    ptkdb.frame.menubutton.font: fixed                /* File menu */
    ptkdb.frame2.frame1.rotext.font: fixed            /* Code Pane */
    ptkdb.notebook.datapage.frame1.hlist.font: fixed  /* Expression Notebook Page */
    
    ptkdb.notebook.subspage*font: fixed               /* Subroutine Notebook Page */
    ptkdb.notebook.brkptspage*entry.font: fixed       /* Delete Breakpoint Buttons */
    ptkdb.notebook.brkptspage*button.font: fixed      /* Breakpoint Expression Entries */
    ptkdb.notebook.brkptspage*button1.font: fixed     /* Breakpoint Expression Entries */
    ptkdb.notebook.brkptspage*checkbutton.font: fixed /* Breakpoint Checkbuttons */
    ptkdb.notebook.brkptspage*label.font: fixed       /* Breakpoint Checkbuttons */
    
    ptkdb.toplevel.frame.textundo.font: fixed         /* Eval Expression Entry Window */
    ptkdb.toplevel.frame1.text.font: fixed            /* Eval Expression Results Window */
    ptkdb.toplevel.button.font:  fixed                /* "Eval..." Button */
    ptkdb.toplevel.button1.font: fixed                /* "Clear Eval" Button */
    ptkdb.toplevel.button2.font: fixed                /* "Clear Results" Button */
    ptkdb.toplevel.button3.font: fixed                /* "Clear Dismiss" Button */
    
    /*
    * Background color for where the debugger has stopped 
    */  
    ptkdb*stopcolor: blue
    
    /*
    * Background color for set breakpoints  
    */
    ptkdb*breaktagcolor*background: yellow
    ptkdb*disabledbreaktagcolor*background: white
    /*
    * Font for where the debugger has stopped
    */
    ptkdb*stopfont: -*-fixed-bold-*-*-*-*-*-*-*-*-*-*-*
    
    /*
    * Background color for the search tag
    */  
    ptkdb*searchtagcolor: green

=head1 Environmental Variables

=over 4

=item PTKDB_BRKPT_COLOR

Sets the background color of a set breakpoint

=item PTKDB_DISABLEDBRKPT_COLOR

Sets the background color of a disabled breakpoint

=item PTKDB_CODE_FONT

Sets the font of the Text in the code pane.

=item PTKDB_CODE_SIDE

Sets which side the code pane is packed onto.  Defaults to 'left'.
Can be set to 'left', 'right', 'top', 'bottom'.  

Overrides the Xresource ptkdb*codeside: I<side>.

=item PTKDB_EXPRESSION_FONT

 Sets the font used in the expression notebook page.

=item PTKDB_EVAL_FONT

 Sets the font used in the Expression Eval Window

=item PTKDB_EVAL_DUMP_INDENT

 Sets the value used for Data::Dumper 'indent' setting. See man Data::Dumper

=item PTKDB_SCROLLBARS_ONRIGHT

 A non-zero value Sets the scrollbars of all windows to be on the
 right side of the window. Useful for Windows users using ptkdb in an
 XWindows environment.

=item PTKDB_LINENUMBER_FORMAT

Sets the format of line numbers on the left side of the window.  Default value is %05d.  useful
if you have a script that contains more than 99999 lines.  

=item PTKDB_DISPLAY

Sets the X display that the ptkdb window will appear on when invoked.  Useful for debugging CGI
scripts on remote systems.  

=item PTKDB_BOOKMARKS_PATH

Sets the path of the bookmarks file.  Default is $ENV{'HOME'}/.ptkdb_bookmarks

=item PTKDB_STOP_TAG_COLOR

Sets the color that highlights the line where the debugger is stopped 

=back

=head1 FILES

=head2 .ptkdbrc

If this file is present in ~/ or in the directory where perl is
invoked the file will be read and executed as a perl script before the
debugger makes its initial stop at startup.  There are several 'api'
calls that can be used with such scripts. There is an internal
variable $DB::no_stop_at_start that may be set to non-zero to prevent
the debugger from stopping at the first line of the script.  This is
useful for debugging CGI scripts.

There is a system ptkdbrc file in $PREFIX/lib/perl5/$VERS/Devel/ptkdbrc

=over 4

=item brkpt($fname, @lines)

Sets breakspoints on the list of lines in $fname.  A warning message
is generated if a line is not breakable.

=item condbrkpt($fname, @($line, $expr) ) 

Sets conditional breakpoints in $fname on pairs of $line and $expr. A
warning message is generated if a line is not breakable.  NOTE: the
validity of the expression will not be determined until execution of
that particular line.

=item brkonsub(@names)

Sets a breakpoint on each subroutine name listed. A warning message is
generated if a subroutine does not exist.  NOTE: for a script with no
other packages the default package is "main::" and the subroutines
would be "main::mySubs".

=item brkonsub_regex(@regExprs)

Uses the list of @regExprs as a list of regular expressions to set breakpoints.  Sets breakpoints 
on every subroutine that matches any of the listed regular expressions.

=item textTagConfigure(tag, ?option?, ?value?)

Allows the user to format the text in the code window. The option
value pairs are the same values as the option for the tagConfigure
method documented in Tk::Text. Currently the following tags are in
effect:

    
    'code'               Format for code in the text pane
    'stoppt'             Format applied to the line where the debugger is currently stopped
    'breakableLine'      Format applied to line numbers where the code is 'breakable'
    'nonbreakableLine'   Format applied to line numbers where the code is no breakable
    'breaksetLine'       Format applied to line numbers were a breakpoint is set
    'breakdisabledLine'  Format applied to line numbers were a disabled breakpoint is set
    'search_tag'         Format applied to text when located by a search.  

 Example:

 #
 # Turns off the overstrike on lines that you can't set a breakpoint on
 # and makes the text color yellow. 
 #
    textTagConfigure('nonbreakableLine', -overstrike => 0, -foreground => "yellow") ;

=item add_exprs(@exprList)

Add a list of expressions to the 'Exprs' window. NOTE: use the single
quote character \' to prevent the expression from being "evaluated" in
the string context.


  Example:

    #
    # Adds the $_ and @_ expressions to the active list
    #

    add_exprs('$_', '@_') ;

=back

=head1 NOTES

=head2 Debugging Other perlTk Applications

ptkdb can be used to debug other perlTk applications if some cautions
are observed. Basically, do not click the mouse in the application's
window(s) when you've entered the debugger and do not click in the
debugger's window(s) while the application is running.  Doing either
one is not necessarily fatal, but it can confuse things that are going
on and produce unexpected results.

Be aware that most perlTk applications have a central event loop.
User actions, such as mouse clicks, key presses, window exposures, etc
will generate 'events' that the script will process. When a perlTk
application is running, its 'MainLoop' call will accept these events
and then dispatch them to appropriate callbacks associated with the
appropriate widgets.

Ptkdb has its own event loop that runs whenever you've stopped at a
breakpoint and entered the debugger. However, it can accept events
that are generated by other perlTk windows and dispatch their
callbacks.  The problem here is that the application is supposed to be
'stopped', and logically the application should not be able to process
events.

A future version of ptkdb will have an extension that will 'filter'
events so that application events are not processed while the debugger
is active, and debugger events will not be processed while the target
script is active.

=head2 Debugging CGI Scripts

One advantage of ptkdb over the builtin debugger(-d) is that it can be
used to debug CGI perl scripts as they run on a web server. Be sure
that that your web server's perl instalation includes Tk.

Change your

  #! /usr/local/bin/perl

to

  #! /usr/local/bin/perl -d:ptkdb

TIP: You can debug scripts remotely if you're using a unix based
Xserver and where you are authoring the script has an Xserver.  The
Xserver can be another unix workstation, a Macintosh or Win32 platform
with an appropriate XWindows package.  In your script insert the
following BEGIN subroutine:

    sub BEGIN {
      $ENV{'DISPLAY'} = "myHostname:0.0" ;
    }

Be sure that your web server has permission to open windows on your
Xserver (see the xhost manpage).

Access your web page with your browswer and 'submit' the script as
normal.  The ptkdb window should appear on myHostname's monitor. At
this point you can start debugging your script.  Be aware that your
browser may timeout waiting for the script to run.

To expedite debugging you may want to setup your breakpoints in
advance with a .ptkdbrc file and use the $DB::no_stop_at_start
variable.  NOTE: for debugging web scripts you may have to have the
.ptkdbrc file installed in the server account's home directory (~www)
or whatever username your webserver is running under.  Also try
installing a .ptkdbrc file in the same directory as the target script.

=head1 KNOWN PROBLEMS

=over

=item I<Breakpoint Controls>

If the size of the right hand pane is too small the breakpoint controls
are not visible.  The breakpoints are still there, the window may have
to be enlarged in order for them to be visible.  

=item Balloons and Tk400

The Balloons in Tk400 will not work with ptkdb.  All other functions
are supported, but the Balloons require Tk800 or higher.

=back

=head1 AUTHOR

Andrew E. Page, aepage@users.sourceforge.net

=head1 ACKNOWLEDGEMENTS

Matthew Persico    For suggestions, and beta testing.

=head1 BUG REPORTING

Please report bugs through the following URL:

http://sourceforge.net/tracker/?atid=437609&group_id=43854&func=browse

=cut


require 5.004 ;


##
## Perform a check to see if we have the Tk library, if not, attempt
## to load it for the user
##

sub BEGIN {

eval {
require Tk  ;
} ;
if( $@ ) {
print << "__PTKDBTK_INSTALL__" ;
***
*** The PerlTk library could not be found.  Ptkdb requires the PerlTk library.
***
Preferably Tk800.015 or better: 

In order to install this the following conditions must be met:

1.  You have to have access to a C compiler.
2.  You must have sufficient permissions to install the libraries on your system.

To install PerlTk:

a  Download the Tk library source from http://www.perl.com/CPAN/modules/by-category/08_User_Interfaces/Tk
b  Uncompress the archive and run "perl Makefile.PL"
c  run "make install"

   If this process completes successfully ptkdb should be operational now.  

We can attempt to run the CPAN module for you.  This will, after some questions, download
and install the Tk library automatically.  

Would you like to run the CPAN module? (y/n) 
__PTKDBTK_INSTALL__

my $answer = <STDIN> ;
chomp $answer ;
if( $answer =~ /y|yes/i) {
  require CPAN ;
  CPAN::install Tk ;
} # if

} # if $@


} # end of sub BEGIN 

use Tk 800 ;
use Data::Dumper ;
use FileHandle ;

require Tk::Dialog;
require Tk::TextUndo ;
require Tk::ROText;
require Tk::NoteBook ;
require Tk::HList ;
require Tk::Table ;

use vars qw(@dbline) ;

use Config ;

sub DoBugReport {
	my($str) = 'sourceforge.net/tracker/?atid=437609&group_id=43854&func=browse' ;
	my(@browsers) = qw/netscape mozilla/ ;
	my($fh, $pid, $sh) ;
	
	if( $isWin32 ) {
	    $sh = '' ;
	    @browsers = '"' . $ENV{'PROGRAMFILES'} . '\\Internet Explorer\\IEXPLORE.EXE' . '"' ;
	    
	}
	else {
	    $sh = 'sh' ;
	    $str = "\'http://" . $str . "\'" ;
	}

	$fh = new FileHandle() ;

	for( @browsers ) {
	    $pid = open($fh, "$sh $_ $str 2&> /dev/null |") ;
	    sleep(2) ; 
	     waitpid $pid, 0 ;
	     return if( $? == 0 ) ;
	} 

	print "##\n" ;
	print "## Please submit a bug report through the following URL:\n" ;
	print '##    http://sourceforge.net/tracker/?atid=437609&group_id=43854&func=browse', "\n" ;
	print "##\n" ;	
}

#
# Check to see if the package actually
# exists. If it does import the routines
# and return a true value ;
#
# NOTE:  this needs to be above the 'BEGIN' subroutine,
# otherwise it will not have been compiled by the time
# that it is called by sub BEGIN.
#
sub check_avail {
  my ($mod, @list) = @_ ;

  eval {
    require $mod ; import $mod @list ;
  } ;

  return 0 if $@ ;
  return 1 ;

} # end of check_avail

sub BEGIN {

 $DB::on = 0 ;     
   
 $DB::subroutine_depth = 0 ; # our subroutine depth counter
 $DB::step_over_depth = -1 ;

   #
   # the bindings and font specs for these operations have been placed here
   # to make them accessible to people who might want to customize the 
   # operations.  REF The 'bind.html' file, included in the perlTk FAQ has
   # a fairly good explanation of the binding syntax.  
   # 

   #
   # These lists of key bindings will be applied
   # to the "Step In", "Step Out", "Return" Commands
   #
 $Devel::ptkdb::pathSep = '\x00' ;
 $Devel::ptkdb::pathSepReplacement = "\0x01" ;

 @Devel::ptkdb::step_in_keys = ( '<Shift-F9>', '<Alt-s>', '<Button-3>' ) ; # step into a subroutine
 @Devel::ptkdb::step_over_keys = ( '<F9>', '<Alt-n>', '<Shift-Button-3>' ) ; # step over a subroutine
 @Devel::ptkdb::return_keys   = ( '<Alt-u>', '<Control-Button-3>' ) ; # return from a subroutine
 @Devel::ptkdb::toggle_breakpt_keys = ( '<Alt-b>' ) ; # set or unset a breakpoint

   # Fonts used in the displays
   
   #
   # NOTE:   The environmental variable syntax here works like this:
   # $ENV{'NAME'} accesses the environmental variable "NAME"
   #
   # $ENV{'NAME'} || 'string' results in  $ENV{'NAME'} or 'string' if  $ENV{'NAME'} is not defined.  
   #
   #
   
 @Devel::ptkdb::button_font = $ENV{'PTKDB_BUTTON_FONT'} ? ( "-font" => $ENV{'PTKDB_CODE_FONT'} ) : () ; # font for buttons
 @Devel::ptkdb::code_text_font = $ENV{'PTKDB_CODE_FONT'} ? ( "-font" => $ENV{'PTKDB_CODE_FONT'} ) : () ;

 @Devel::ptkdb::expression_text_font = $ENV{'PTKDB_EXPRESSION_FONT'} ? ( "-font" => $ENV{'PTKDB_EXPRESSION_FONT'} ) : () ;
 @Devel::ptkdb::eval_text_font = $ENV{'PTKDB_EVAL_FONT'} ? ( -font => $ENV{'PTKDB_EVAL_FONT'} ) : () ; # text for the expression eval window

 $Devel::ptkdb::eval_dump_indent = $ENV{'PTKDB_EVAL_DUMP_INDENT'} || 1 ;

   #
   # Windows users are more used to having scroll bars on the right.
   # If they've set PTKDB_SCROLLBARS_ONRIGHT to a non-zero value
   # this will configure our scrolled windows with scrollbars on the right
   #
   # this can also be done by setting:
   #
   # ptkdb*scrollbars: se
   #
   # in the .Xdefaults/.Xresources file on X based systems
   #
   if( exists $ENV{'PTKDB_SCROLLBARS_ONRIGHT'} && $ENV{'PTKDB_SCROLLBARS_ONRIGHT'} ) {
   @Devel::ptkdb::scrollbar_cfg = ('-scrollbars' => 'se') ;
   }
   else {
   @Devel::ptkdb::scrollbar_cfg = ( ) ;
   }

   #
   # Controls how far an expression result will be 'decomposed'.   Setting it
   # to 0 will take it down only one level, setting it to -1 will make it 
   # decompose it all the way down. However, if you have a situation where
   # an element is a ref   back to the array or a root of the array
   # you could hang the debugger by making it recursively evaluate an expression
   #
 $Devel::ptkdb::expr_depth = -1 ;
 $Devel::ptkdb::add_expr_depth = 1 ; # how much further to expand an expression when clicked

 $Devel::ptkdb::linenumber_format = $ENV{'PTKDB_LINENUMBER_FORMAT'} || "%05d " ;
 $Devel::ptkdb::linenumber_length = 5 ;

 $Devel::ptkdb::linenumber_offset = length sprintf($Devel::ptkdb::linenumber_format, 0) ;
 $Devel::ptkdb::linenumber_offset -= 1 ;

   #
   # Check to see if "Data Dumper" is available
   # if it is we can save breakpoints and other 
   # various "functions". This call will also
   # load the subroutines needed.
   #
 $Devel::ptkdb::DataDumperAvailable = 1 ; # assuming that it is now
 $Devel::ptkdb::useDataDumperForEval = $Devel::ptkdb::DataDumperAvailable ;

   #
   # DB Options (things not directly involving the window)
   #

   # Flag to disable us from intercepting $SIG{'INT'}

 $DB::sigint_disable = defined $ENV{'PTKDB_SIGINT_DISABLE'} && $ENV{'PTKDB_SIGINT_DISABLE'} ;
#
# Possibly for debugging perl CGI Web scripts on
# remote machines.  
#
   $ENV{'DISPLAY'} = $ENV{'PTKDB_DISPLAY'} if exists $ENV{'PTKDB_DISPLAY'} ;

 } # end of BEGIN

##
## subroutine provided to the user for initializing
## files in .ptkdbrc
##
sub brkpt {
  my ($fName, @idx) = @_ ;
  my($offset) ;
  local(*dbline) = $main::{'_<' . $fName} ;

  $offset = $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ? 1 : 0 ;

  for( @idx ) {
    if( !&DB::checkdbline($fName, $_ + $offset) ) {
      my ($package, $filename, $line) = caller ;
      print "$filename:$line:  $fName line $_ is not breakable\n" ;
      next ;
    }
  $DB::window->insertBreakpoint($fName, $_, 1) ; # insert a simple breakpoint
  }
} # end of brkpt

#
# Set conditional breakpoint(s)
#
sub condbrkpt {
  my ($fname) = shift ;
  my($offset) ;
  local(*dbline) = $main::{'_<' . $fname} ;

  $offset = $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ? 1 : 0 ;

  while( @_ ) { # arg loop
    my($index, $expr) = splice @_, 0, 2 ; # take args 2 at a time

    if( !&DB::checkdbline($fname, $index + $offset) ) {
      my ($package, $filename, $line) = caller ;
      print "$filename:$line:  $fname line $index is not breakable\n" ;
      next ;
    }
  $DB::window->insertBreakpoint($fname, $index, 1, $expr) ; # insert a simple breakpoint
  } # end of arg loop

} # end of conditionalbrkpt

sub brkonsub {
  my(@names) = @_ ;
  
  for( @names ) {
    
    # get the filename and line number range of the target subroutine
    
    if( !exists $DB::sub{$_} ) {
      print "No subroutine $_.  Try main::$_\n" ;
      next ;
    }

  $DB::sub{$_} =~ /(.*):([0-9]+)-([0-9]+)$/o ; # file name will be in $1, start line $2, end line $3

    for( $2..$3 ) {
      next unless &DB::checkdbline($1, $_) ;
    $DB::window->insertBreakpoint($1, $_, 1) ;
      last ; # only need the one breakpoint
    }
  } # end of name loop

} # end of brkonsub

#
# set breakpoints on subroutines matching a regular
# expression
#
sub brkonsub_regex {
  my(@regexps) = @_ ;
  my($regexp, @subList) ;

  #
  # accumulate matching subroutines
  #
  foreach $regexp ( @regexps ) {
    study $regexp ;
    push @subList, grep /$regexp/, keys %DB::sub ;
  } # end of brkonsub_regex

  brkonsub(@subList) ; # set breakpoints on matching subroutines

} # end of brkonsub_regex

#
# Allow the user Access to our tag configurations
#
sub textTagConfigure {
  my ($tag, @config) = @_ ;

 $DB::window->{'text'}->tagConfigure($tag, @config) ;
  
} # end of textTagConfigure

##
## Change the tabs in the text field
##
sub setTabs {
  
 $DB::window->{'text'}->configure(-tabs => [ @_ ]) ;

}

#
# User .ptkdbrc API
# allows the user to add expressions to
# the expression list window.  
#
sub add_exprs {
  push @{$DB::window->{'expr_list'}}, map { 'expr' => $_, 'depth' => $Devel::ptkdb::expr_depth }, @_ ;
} # end of add_exprs


##
## register a subroutine reference that will be called whenever
## ptkdb sets up it's windows
##
sub register_user_window_init {
  push @{$DB::window->{'user_window_init_list'}}, @_ ;
} # end of register_user_window_init

##
## register a subroutine reference that will be called whenever
## ptkdb enters from code
##
sub register_user_DB_entry {
  push @{$DB::window->{'user_window_DB_entry_list'}}, @_ ;
} # end of register_user_DB_entry

sub get_notebook_widget {
  return $DB::window->{'notebook'} ;
} # end of get_notebook_widget


#
# Run files provided by the user
#
sub do_user_init_files {
  use vars qw($dbg_window) ;
  local $dbg_window = shift ;

  eval {
    do "$Config{'installprivlib'}/Devel/ptkdbrc" ;
  } if -e "$Config{'installprivlib'}/Devel/ptkdbrc" ;

  if( $@ ) {
    print "System init file $Config{'installprivlib'}/ptkdbrc failed: $@\n" ;
  }

  eval {
    do "$ENV{'HOME'}/.ptkdbrc" ;
  } if exists $ENV{'HOME'} && -e "$ENV{'HOME'}/.ptkdbrc" ;

  if( $@ ) {
    print "User init file $ENV{'HOME'}/.ptkdbrc failed: $@\n" ;
  }

  eval {
    do ".ptkdbrc" ;
  } if -e ".ptkdbrc" ;

  if( $@ ) {
    print "User init file .ptkdbrc failed: $@\n" ;
  }

  &set_stop_on_warning() ;
}

#
# Constructor for our Devel::ptkdb
#
sub new {
  my($type) = @_ ;
  my($self) = {} ;
  
  bless $self, $type ;

  # Current position of the executing program

  $self->{DisableOnLeave} = [] ; # List o' Widgets to disable when leaving the debugger

  $self->{current_file} = "" ; 
  $self->{current_line} = -1 ; # initial value indicating we haven't set our line/tag
  $self->{window_pos_offset} = 10 ; # when we enter how far from the top of the text are we positioned down
  $self->{search_start} = "0.0" ;
  $self->{fwdOrBack} = 1 ;
  $self->{BookMarksPath} = $ENV{'PTKDB_BOOKMARKS_PATH'} || "$ENV{'HOME'}/.ptkdb_bookmarks" || '.ptkdb_bookmarks'  ;

  $self->{'expr_list'} = [] ; # list of expressions to eval in our window fields:  {'expr'} The expr itself {'depth'} expansion depth


  $self->{'brkPtCnt'} = 0 ;
  $self->{'brkPtSlots'} = [] ; # open slots for adding breakpoints to the table 

  $self->{'main_window'} = undef ;

  $self->{'user_window_init_list'} = [] ;
  $self->{'user_window_DB_entry_list'} = [] ;

  $self->{'subs_list_cnt'} = 0 ;

  $self->setup_main_window() ;

  return $self ;

} # end of new

sub setup_main_window {
  my($self) = @_ ;

  # Main Window
  

  $self->{main_window} = MainWindow->new() ;
  $self->{main_window}->geometry($ENV{'PTKDB_GEOMETRY'} || "800x600") ;

  $self->setup_options() ; # must be done after MainWindow and before other frames are setup

  $self->{main_window}->bind('<Control-c>', \&DB::dbint_handler) ;

  #
  # Bind our 'quit' routine to a close command from the window manager (Alt-F4) 
  # 
  $self->{main_window}->protocol('WM_DELETE_WINDOW', sub { $self->close_ptkdb_window() ; } ) ;

  # Menu bar

  $self->setup_menu_bar() ;

  #
  # setup Frames
  #
  # Setup our Code, Data, and breakpoints

  $self->setup_frames() ;

}

#
# Check for changes to the bookmarks and quit
#
sub DoQuit {
	my($self) = @_ ;

  $self->save_bookmarks($self->{BookMarksPath}) if $Devel::ptkdb::DataDumperAvailable && $self->{'bookmarks_changed'};
	$self->{main_window}->destroy if $self->{main_window} ; 
	$self->{main_window} = undef if defined $self->{main_window} ; 

	exit ;
}

#
# This supports the File -> Open menu item
# We create a new window and list all of the files
# that are contained in the program.  We also
# pick up all of the perlTk files that are supporting
# the debugger.  
#
sub DoOpen {
  my $self = shift ;
  my ($topLevel, $listBox, $frame, $selectedFile, @fList) ;

  #
  # subroutine we call when we've selected a file
  #

  my $chooseSub = sub { $selectedFile = $listBox->get('active') ;
                        print "attempting to open $selectedFile\n" ;
                      $DB::window->set_file($selectedFile, 0) ;
                        destroy $topLevel ; 
                      } ;

  #
  # Take the list the files and resort it.  
  # we put all of the local files first, and
  # then list all of the system libraries.
  #
  @fList = sort { 
    # sort comparison function block
    my $fa = substr($a, 0, 1) ;
    my $fb = substr($b, 0, 1) ;

    return $a cmp $b if ($fa eq '/') && ($fb eq '/') ;

    return -1 if ($fb eq '/') && ($fa ne '/') ;
    return 1 if ($fa eq '/' ) && ($fb ne '/') ;

    return $a cmp $b ;

  } grep s/^_<//, keys %main:: ;

  #
  # Create a list box with all of our files
  # to select from
  #
  $topLevel = $self->{main_window}->Toplevel(-title => "File Select", -overanchor => 'cursor') ;

  $listBox = $topLevel->Scrolled('Listbox', 
                               @Devel::ptkdb::scrollbar_cfg,
                               @Devel::ptkdb::expression_text_font,
                                -width => 30)->pack(-side => 'top', -fill => 'both', -expand => 1) ;


  # Bind a double click on the mouse button to the same action
  # as pressing the Okay button

  $listBox->bind('<Double-Button-1>' => $chooseSub) ;
  
  $listBox->insert('end', @fList) ;

  $topLevel->Button( -text => "Okay", -command => $chooseSub, @Devel::ptkdb::button_font,
                     )->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  $topLevel->Button( -text => "Cancel", @Devel::ptkdb::button_font,
                     -command => sub { destroy $topLevel ; } )->pack(-side => 'left', -fill => 'both', -expand => 1) ;
} # end of DoOpen

sub do_tabs {
  my($tabs_str) ;
  my($w, $result, $tabs_cfg) ;
  require Tk::Dialog ;

  $w = $DB::window->{'main_window'}->DialogBox(-title => "Tabs", -buttons => [qw/Okay Cancel/]) ;
  
  $tabs_cfg = $DB::window->{'text'}->cget(-tabs) ;

  $tabs_str = join " ", @$tabs_cfg if $tabs_cfg ;

  $w->add('Label', -text => 'Tabs:')->pack(-side => 'left') ;

  $w->add('Entry', -textvariable => \$tabs_str)->pack(-side => 'left')->selectionRange(0,'end') ;

  $result = $w->Show() ;

  return unless $result eq 'Okay' ;

 $DB::window->{'text'}->configure(-tabs => [ split /\s/, $tabs_str ]) ;
}

sub close_ptkdb_window {
  my($self) = @_ ;

  $DB::window->{'event'} = 'run' ;
  $self->{current_file} = "" ; # force a file reset
  $self->{'main_window'}->destroy ;
  $self->{'main_window'} = undef ;
}

sub setup_menu_bar {
  my ($self) = @_ ;
  my $mw = $self->{main_window} ;
  my ($mb, $items) ;
  
  #
  # We have menu items/features that are not available if the Data::DataDumper module
  # isn't present.  For any feature that requires it we add this option list.
  #
  my @dataDumperEnableOpt = ( state => 'disabled' ) unless $Devel::ptkdb::DataDumperAvailable ;


  $self->{menu_bar} = $mw->Frame(-relief => 'raised', -borderwidth => '1')->pack(-side => 'top', -fill => 'x') ;

  $mb = $self->{menu_bar} ;

  # file menu in menu bar

  $items = [ [ 'command' => 'About...', -command => sub { $self->DoAbout() ; } ],
						 [ 'command' => 'Bug Report...', -command => \&DoBugReport ],
             "-",

             [ 'command' => 'Open', -accelerator => 'Alt+O',
               -underline => 0,
               -command => sub { $self->DoOpen() ; } ],

             [ 'command' => 'Save Config...', 
               -underline => 0,
               -command => \&DB::SaveState,
               @dataDumperEnableOpt ],

             [ 'command' => 'Restore Config...',
               -underline => 0,
               -command => \&DB::RestoreState,
               @dataDumperEnableOpt ],

             [ 'command' => 'Goto Line...',
               -underline => 0,
               -accelerator => 'Alt-g',
               -command => sub { $self->GotoLine() ; },
               @dataDumperEnableOpt ] ,

             [ 'command' => 'Find Text...',
               -accelerator => 'Ctrl-f',
               -underline => 0,
               -command => sub { $self->FindText() ; } ],

             [ 'command' => "Tabs...", -command => \&do_tabs ],

             "-",

             [ 'command' => 'Close Window and Run', -accelerator => 'Alt+W',
               -underline => 6, -command => sub { $self->close_ptkdb_window ; } ],
             
             [ 'command' => 'Quit...', -accelerator => 'Alt+Q',
               -underline => 0,
               -command => sub { $self->DoQuit } ]
             ] ;

                 
  $mw->bind('<Alt-g>' =>  sub { $self->GotoLine() ; }) ;
  $mw->bind('<Control-f>' => sub { $self->FindText() ; }) ;
  $mw->bind('<Control-r>' => \&Devel::ptkdb::DoRestart) ;
  $mw->bind('<Alt-q>' => sub { $self->{'event'} = 'quit' } ) ;
  $mw->bind('<Alt-w>' => sub { $self->close_ptkdb_window ; }) ;

  $self->{file_menu_button} = $mb->Menubutton(-text => 'File',
                                              -underline => 0,
                                              -menuitems => $items
                                              )->pack(-side =>, 'left',
                                                      -anchor => 'nw',
                                                      -padx => 2) ;

  # Control Menu

  my $runSub = sub { $DB::step_over_depth = -1 ; $self->{'event'} = 'run' } ;

  my $runToSub = sub { $DB::window->{'event'} = 'run' if  $DB::window->SetBreakPoint(1) ; } ;

  my $stepOverSub = sub { &DB::SetStepOverBreakPoint(0) ; 
                        $DB::single = 1 ; 
                        $DB::window->{'event'} = 'step' ; 
                        } ;
  

  my $stepInSub = sub { 
                      $DB::step_over_depth = -1 ; 
                      $DB::single = 1 ; 
                      $DB::window->{'event'} = 'step' ; } ;


  my $returnSub =  sub { 
    &DB::SetStepOverBreakPoint(-1) ;
    $self->{'event'} = 'run' ;
  } ;


  $items = [ [ 'command' => 'Run', -accelerator => 'Alt+r', -underline => 0, -command => $runSub ],
             [ 'command' => 'Run To Here', -accelerator => 'Alt+t', -underline => 5, -command => $runToSub ],
             '-',
             [ 'command' =>  'Set Breakpoint', -underline => 4, -command => sub { $self->SetBreakPoint ; }, -accelerator => 'Ctrl-b' ],
             [ 'command' => 'Clear Breakpoint', -command => sub { $self->UnsetBreakPoint } ],
             [ 'command' => 'Clear All Breakpoints', -underline => 6, -command => sub {     
             $DB::window->removeAllBreakpoints($DB::window->{current_file}) ;
               &DB::clearalldblines() ;
             } ],
             '-',
             [ 'command' => 'Step Over', -accelerator => 'Alt+N', -underline => 0, -command => $stepOverSub ],
             [ 'command' => 'Step In', -accelerator => 'Alt+S', -underline => 5, -command => $stepInSub ],
             [ 'command' => 'Return', -accelerator => 'Alt+U', -underline => 3, -command => $returnSub ],
             '-',
             [ 'command' => 'Restart...', -accelerator => 'Ctrl-r', -underline => 0, -command => \&Devel::ptkdb::DoRestart ],
             '-',
             [ 'checkbutton' => 'Stop On Warning', -variable => \$DB::ptkdb::stop_on_warning, -command => \&set_stop_on_warning ]

             
               ] ; # end of control menu items

  
  $self->{control_menu_button} = $mb->Menubutton(-text => 'Control',
                                                 -underline => 0,
                                                 -menuitems => $items,
                                                 )->pack(-side =>, 'left',
                                                         -padx => 2) ;


  $mw->bind('<Alt-r>' => $runSub) ;
  $mw->bind('<Alt-t>', $runToSub) ;
  $mw->bind('<Control-b>', sub { $self->SetBreakPoint ; }) ;

  for( @Devel::ptkdb::step_over_keys ) {
    $mw->bind($_ => $stepOverSub );
  }

  for( @Devel::ptkdb::step_in_keys ) {
    $mw->bind($_ => $stepInSub );
  }

  for( @Devel::ptkdb::return_keys ) {
    $mw->bind($_ => $returnSub );
  }

  # Data Menu

  $items = [ [ 'command' => 'Enter Expression', -accelerator => 'Alt+E', -command => sub { $self->EnterExpr() } ],
             [ 'command' => 'Delete Expression', -accelerator => 'Ctrl+D', -command => sub { $self->deleteExpr() } ],
             [ 'command' => 'Delete All Expressions',  -command => sub { 
                                       $self->deleteAllExprs() ;
                                       $self->{'expr_list'} = [] ; # clears list by dropping ref to it, replacing it with a new one  
                                     } ],
             '-',
             [ 'command' => 'Expression Eval Window...', -accelerator => 'F8', -command => sub { $self->setupEvalWindow() ; } ],
             [ 'checkbutton' => "Use DataDumper for Eval Window?", -variable => \$Devel::ptkdb::useDataDumperForEval, @dataDumperEnableOpt ]
              ] ;


  $self->{data_menu_button} = $mb->Menubutton(-text => 'Data', -menuitems => $items,
                                              -underline => 0,
                                              )->pack(-side => 'left',
                                                      -padx => 2) ;

  $mw->bind('<Alt-e>' => sub { $self->EnterExpr() } ) ;
  $mw->bind('<Control-d>' => sub { $self->deleteExpr() } );
  $mw->bind('<F8>', sub { $self->setupEvalWindow() ; }) ;
  #
  # Stack menu
  #
  $self->{stack_menu} = $mb->Menubutton(-text => 'Stack',
                                        -underline => 2,
                                        )->pack(-side => 'left',
                                                -padx => 2) ;

  #
  # Bookmarks menu
  #
  $self->{bookmarks_menu} = $mb->Menubutton(-text => 'Bookmarks',
                                            -underline => 0,
                                            @dataDumperEnableOpt
                                            )->pack(-side => 'left',
                                                    -padx => 2) ;
  $self->setup_bookmarks_menu() ;

  #
  # Windows Menu
  #
  my($bsub) = sub { $self->{'text'}->focus() } ;
  my($csub) = sub { $self->{'quick_entry'}->focus() } ;
  my($dsub) = sub { $self->{'entry'}->focus() } ;

  $items = [ [ 'command' => 'Code Pane', -accelerator => 'Alt+0', -command => $bsub ],
             [ 'command' => 'Quick Entry', -accelerator => 'F9', -command => $csub ],
             [ 'command' => 'Expr Entry', -accelerator => 'F11', -command => $dsub ]
             ] ;

  $mb->Menubutton(-text => 'Windows', -menuitems => $items
                  )->pack(-side => 'left',
                          -padx => 2) ;

  $mw->bind('<Alt-0>', $bsub) ;
  $mw->bind('<F9>', $csub) ;
  $mw->bind('<F11>', $dsub) ;

  #
  # Bar for some popular controls
  #

  $self->{button_bar} = $mw->Frame()->pack(-side => 'top') ;

  $self->{stepin_button} = $self->{button_bar}->Button(-text, => "Step In", @Devel::ptkdb::button_font,
                                                       -command => $stepInSub) ;
  $self->{stepin_button}->pack(-side => 'left') ;

  $self->{stepover_button} = $self->{button_bar}->Button(-text, => "Step Over", @Devel::ptkdb::button_font,
                                                         -command => $stepOverSub) ;
  $self->{stepover_button}->pack(-side => 'left') ;

  $self->{return_button} = $self->{button_bar}->Button(-text, => "Return", @Devel::ptkdb::button_font,
                                                       -command => $returnSub) ;
  $self->{return_button}->pack(-side => 'left') ;

  $self->{run_button} = $self->{button_bar}->Button(-background => 'green', -text, => "Run", @Devel::ptkdb::button_font,
                                                    -command => $runSub) ;
  $self->{run_button}->pack(-side => 'left') ;

  $self->{run_to_button} = $self->{button_bar}->Button(-text, => "Run To", @Devel::ptkdb::button_font,
                                                       -command => $runToSub) ;
  $self->{run_to_button}->pack(-side => 'left') ;

  $self->{breakpt_button} = $self->{button_bar}->Button(-text, => "Break", @Devel::ptkdb::button_font,
                                                        -command => sub { $self->SetBreakPoint ; } ) ;
  $self->{breakpt_button}->pack(-side => 'left') ;

  push @{$self->{DisableOnLeave}}, @$self{'stepin_button', 'stepover_button', 'return_button', 'run_button', 'run_to_button', 'breakpt_button'} ;
  
} # end of setup_menu_bar

sub edit_bookmarks {
  my ($self) = @_ ;

  my ($top) =  $self->{main_window}->Toplevel(-title => "Edit Bookmarks") ;
  
  my $list = $top->Scrolled('Listbox', -selectmode => 'multiple')->pack(-side => 'top', -fill => 'both', -expand => 1) ;
  
  my $deleteSub = sub {
    my $cnt = 0 ;
    for( $list->curselection ) {
      $list->delete($_ - $cnt++) ;
    }
  } ;

  my $okaySub = sub {
    $self->{'bookmarks'} = [ $list->get(0, 'end') ]  ; # replace the bookmarks
  } ;
  
  my $frm = $top->Frame()->pack(-side => 'top', -fill => 'x', -expand => 1 ) ;
  
  my $deleteBtn = $frm->Button(-text => 'Delete', -command => $deleteSub)->pack(-side => 'left', -fill => 'x', -expand => 1 ) ;
  my $cancelBtn = $frm->Button(-text => 'Cancel', -command => sub { destroy $top ; })->pack(-side  =>'left', -fill => 'x', -expand => 1 ) ;
  my $dismissBtn = $frm->Button(-text => 'Okay', -command => $okaySub)->pack(-side => 'left', -fill => 'x', -expand => 1 ) ;
  
  $list->insert('end', @{$self->{'bookmarks'}}) ;

} # end of edit_bookmarks

sub setup_bookmarks_menu {
  my ($self) = @_ ;

  #
  # "Add bookmark" item
  #
  my $bkMarkSub = sub { $self->add_bookmark() ; } ;

  $self->{'bookmarks_menu'}->command(-label => "Add Bookmark",
                                     -accelerator => 'Alt+k',
                                     -command => $bkMarkSub
                                     ) ;

  $self->{'main_window'}->bind('<Alt-k>', $bkMarkSub) ;

  $self->{'bookmarks_menu'}->command(-label => "Edit Bookmarks", 
                                     -command => sub { $self->edit_bookmarks() } ) ;

  $self->{'bookmarks_menu'}->separator() ;

  #
  # Check to see if there is a bookmarks file
  #
  return unless -e $self->{BookMarksPath} && -r $self->{BookMarksPath} ;
  
  use vars qw($ptkdb_bookmarks) ;
  local($ptkdb_bookmarks) ; # ref to hash of bookmark entries

  do $self->{BookMarksPath} ; # eval the file

  $self->add_bookmark_items(@$ptkdb_bookmarks) ;

} # end of setup_bookmarks_menu

#
# $item = "$fname:$lineno"
#
sub add_bookmark_items {
  my($self, @items) = @_ ;
  my($menu) = ( $self->{'bookmarks_menu'} ) ;

  $self->{'bookmarks_changed'} = 1 ;

  for( @items ) {
    my $item = $_ ;
    $menu->command( -label => $_,
                    -command => sub { $self->bookmark_cmd($item) }) ;
    push @{$self->{'bookmarks'}}, $item ;
  }
} # end of add_bookmark_item

#
# Invoked from the "Add Bookmark" command
#
sub add_bookmark {
  my($self) = @_ ;
  
  my $line = $self->get_lineno() ;
  my $fname = $self->{'current_file'} ;
  $self->add_bookmark_items("$fname:$line") ;

} # end of add_bookmark

#
# Command executed when someone selects
# a bookmark
#
sub bookmark_cmd {
  my ($self, $item) = @_ ;

  $item =~ /(.*):([0-9]+)$/ ;

  $self->set_file($1,$2) ;

} # end of bookmark_cmd

sub save_bookmarks {
  my($self, $pathName) = @_ ;

  return unless $Devel::ptkdb::DataDumperAvailable ; # we can't save without the data dumper
  local(*F) ;

  eval {
    open F, ">$pathName" || die "open failed" ;
    my $d = Data::Dumper->new([ $self->{'bookmarks'} ], 
                              [  'ptkdb_bookmarks' ]) ;

    $d->Indent(2) ; # make it more editable for people  

    my $str ;
    if( $d->can('Dumpxs') ) {
      $str = $d->Dumpxs() ;
    }
    else {
      $str = $d->Dump() ;
    }

    print F $str || die "outputing bookmarks failed" ;
    close(F) ;
  } ;

  if( $@ ) {
    $self->DoAlert("Couldn't save bookmarks file $@") ;
    return ;
  }

} # end of save_bookmarks 

#
# This is our callback from a double click in our
# HList.  A click in an expanded item will delete
# the children beneath it, and the next time it
# updates, it will only update that entry to that
# depth.  If an item is 'unexpanded' such as 
# a hash or a list, it will expand it one more
# level.  How much further an item is expanded is
# controled by package variable $Devel::ptkdb::add_expr_depth
#
sub expr_expand {
  my ($path) = @_ ;
  my $hl = $DB::window->{'data_list'} ;
  my ($parent, $root, $index, @children, $depth) ;

  $parent = $path ;
  $root = $path ;
  $depth = 0 ;

  for( $root = $path ; defined $parent && $parent ne "" ; $parent = $hl->infoParent($root) ) {
    $root = $parent ;
    $depth += 1 ;
  } #end of root search

  #
  # Determine the index of the root of our expression
  #
  $index = 0 ;
  for( @{$DB::window->{'expr_list'}} ) {
    last if $_->{'expr'} eq $root ;
    $index += 1 ;
  }

  #
  # if we have children we're going to delete them
  #

  @children = $hl->infoChildren($path) ;

  if( scalar @children > 0 ) {

    $hl->deleteOffsprings($path) ;

  $DB::window->{'expr_list'}->[$index]->{'depth'} = $depth - 1 ; # adjust our depth
  }
  else {
    #
    # Delete the existing tree and insert a new one
    #
    $hl->deleteEntry($root) ;
    $hl->add($root, -at => $index) ;
  $DB::window->{'expr_list'}->[$index]->{'depth'} += $Devel::ptkdb::add_expr_depth ;
    #
    # Force an update on our expressions
    #
  $DB::window->{'event'} = 'update' ;
  }
} # end of expr_expand

sub line_number_from_coord {
  my($txtWidget, $coord) = @_ ;
  my($index) ;
  
  $index = $txtWidget->index($coord) ;

  # index is in the format of lineno.column

  $index =~ /([0-9]*)\.([0-9]*)/o ;

  #
  # return a list of (col, line).  Why
  # backwards?  
  #

  return ($2 ,$1) ;
  
} # end of line_number_from_coord

#
# It may seem as if $txtWidget and $self are
# erroneously reversed, but this is a result
# of the calling syntax of the text-bind callback.  
#
sub set_breakpoint_tag {
  my($txtWidget, $self, $coord, $value) = @_ ;
  my($idx) ;

  $idx = line_number_from_coord($txtWidget, $coord) ;

  $self->insertBreakpoint($self->{'current_file'}, $idx, $value) ;

} # end of set_breakpoint_tag

sub clear_breakpoint_tag {
  my($txtWidget, $self, $coord) = @_ ;
  my($idx) ;

  $idx = line_number_from_coord($txtWidget, $coord) ;
  
  $self->removeBreakpoint($self->{'current_file'}, $idx) ;

} # end of clear_breakpoint_tag

sub change_breakpoint_tag {
  my($txtWidget, $self, $coord, $value) = @_ ;
  my($idx, $brkPt, @tagSet) ;

  $idx = line_number_from_coord($txtWidget, $coord) ;

  #
  # Change the value of the breakpoint
  #
  @tagSet = ( "$idx.0", "$idx.$Devel::ptkdb::linenumber_length" ) ;

  $brkPt = &DB::getdbline($self->{'current_file'}, $idx + $self->{'line_offset'}) ;
  return unless $brkPt ;

  #
  # Check the breakpoint tag
  #

  if ( $txtWidget ) {
    $txtWidget->tagRemove('breaksetLine', @tagSet ) ;
    $txtWidget->tagRemove('breakdisabledLine', @tagSet ) ;
  }

  $brkPt->{'value'} = $value ;
  
  if ( $txtWidget ) {
    if ( $brkPt->{'value'} ) {
      $txtWidget->tagAdd('breaksetLine', @tagSet ) ;
    }
    else {
      $txtWidget->tagAdd('breakdisabledLine', @tagSet ) ;    
    }
  }

} # end of change_breakpoint_tag

#
# God Forbid anyone comment something complex and tightly optimized.
#
#  We can get a list of the subroutines from the interpreter
# by querrying the *DB::sub typeglob:  keys %DB::sub
#
# The list appears broken down by module:
#
#  main::BEGIN
#  main::mySub
#  main::otherSub
#  Tk::Adjuster::Mapped
#  Tk::Adjuster::Packed
#  Tk::Button::BEGIN
#  Tk::Button::Enter
#  
#  We would like to break this list down into a heirarchy.
#
#         main                             Tk
#  |        |       |                       |
# BEGIN   mySub  OtherSub          |                 |
#                               Adjuster           Button 
#                             |         |        |        |
#                           Mapped    Packed   BEGIN    Enter
#
#
#  We translate this list into a heirarchy of hashes(say three times fast).
# We take each entry and split it into elements.  Each element is a leaf in the tree.  
# We traverse the tree with the inner for loop.  
# With each branch we check to see if it already exists or
# we create it.  When we reach the last element, this becomes our entry.
# 

#
# An incoming list is potentially 'large' so we
# pass in the ref to it instead.
#
#  New entries can be inserted by providing a $topH
# hash ref to an existing tree.  
#
sub tree_split {
  my ($listRef, $separator, $topH) = @_ ; 
  my ($h, $list_elem) ;

  $topH = {} unless $topH ;

  foreach $list_elem ( @$listRef ) {
    $h = $topH ;
    for( split /$separator/o, $list_elem ) { # Tk::Adjuster::Mapped  -> ( Tk Adjuster Mapped )
      $h->{$_} or $h->{$_} = {} ; # either we have an entry for this OR we create one
      $h = $h->{$_} ;
    }
    @$h{'name', 'path'} = ($_, $list_elem) ; # the last leaf is our entry
  } # end of tree_split loop

  return $topH ;

} # end of tree_split

#
# callback executed when someone double clicks
# an entry in the 'Subs' Tk::Notebook page.
#
sub sub_list_cmd {
  my ($self, $path) = @_ ;
  my ($h) ;
  my $sub_list = $self->{'sub_list'} ;

  if (  $sub_list->info('children', $path)  ) {
    #
    # Delete the children
    #
    $sub_list->deleteOffsprings($path) ;
    return ;
  }

  #
  # split the path up into elements
  # end descend through the tree.
  #
  $h = $Devel::ptkdb::subs_tree ; 
  for ( split /\./o, $path ) {
    $h = $h->{$_} ; # next level down
  }

  #
  # if we don't have a 'name' entry we
  # still have levels to decend through.
  #
  if ( !exists $h->{'name'} ) {
    #
    # Add the next level paths
    #   
    for ( sort keys %$h ) {

      if ( exists $h->{$_}->{'path'} ) {
        $sub_list->add($path . '.' . $_, -text => $h->{$_}->{'path'}) ;
      }
      else {
        $sub_list->add($path . '.' . $_, -text => $_) ;
      }
    }
    return ;
  }

 $DB::sub{$h->{'path'}} =~ /(.*):([0-9]+)-[0-9]+$/o ; # file name will be in $1, line number will be in $2 */

  $self->set_file($1, $2) ;

} # end of sub_list_cmd

sub fill_subs_page {
  my($self) = @_ ;

  $self->{'sub_list'}->delete('all') ; # clear existing entries

  my @list = keys %DB::sub ;

 $Devel::ptkdb::subs_tree = tree_split(\@list, "::") ;

  # setup to level of list

  for ( sort keys %$Devel::ptkdb::subs_tree ) {
    $self->{'sub_list'}->add($_, -text => $_) ;
  } # end of top level loop
}

sub setup_subs_page {
  my($self) = @_ ;

  $self->{'subs_page_activated'} = 1 ;

  $self->{'sub_list'} = $self->{'subs_page'}->Scrolled('HList',  -command => sub { $self->sub_list_cmd(@_) ; } ) ;

  $self->fill_subs_page() ;

  $self->{'sub_list'}->pack(-side => 'left', -fill => 'both', -expand => 1
                            ) ;

  $self->{'subs_list_cnt'} = scalar keys %DB::sub ;


} # end of setup_subs_page


sub check_search_request {
  my($entry, $self, $searchButton, $regexBtn) = @_ ;
  my($txt) = $entry->get ;

  if( $txt =~ /^\s*[0-9]+\s*$/ ) {
    $self->DoGoto($entry) ;
    return ;
  }

  if( $txt =~ /\.\*/ ) { # common regex search pattern
    $self->FindSearch($entry, $regexBtn, 1) ;
    return ;
  }

  # vanilla search
  $self->FindSearch($entry, $searchButton, 0) ;
}

sub setup_search_panel {
  my ($self, $parent, @packArgs) = @_ ;
  my ($frm, $srchBtn, $regexBtn, $entry) ;

  $frm = $parent->Frame() ;

  $frm->Button(-text => 'Goto', -command => sub { $self->DoGoto($entry) })->pack(-side => 'left') ;
  $srchBtn = $frm->Button(-text => 'Search', -command => sub { $self->FindSearch($entry, $srchBtn, 0) ; }
                          )->pack(-side => 'left' ) ;

  $regexBtn = $frm->Button(-text => 'Regex',
                           -command => sub { $self->FindSearch($entry, $regexBtn, 1) ; }
                           )->pack(-side => 'left',
                                   ) ;


  $entry = $frm->Entry(-width => 50)->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  $entry->bind('<Return>', sub { check_search_request($entry, $self, $srchBtn, $regexBtn) ; } ) ;

  $frm->pack(@packArgs) ;

} # end of setup search_panel

sub setup_breakpts_page {
  my ($self) = @_ ;
  require Tk::Table ;

  $self->{'breakpts_page'} = $self->{'notebook'}->add("brkptspage", -label => "BrkPts") ;

  $self->{'breakpts_table'} = $self->{'breakpts_page'}->Table(-columns => 1, -scrollbars => 'se')->
      pack(-side => 'top', -fill => 'both', -expand => 1
           )   ;

  $self->{'breakpts_table_data'} = { } ; # controls addressed by "fname:lineno"

} # end of setup_breakpts_page

sub setup_frames {
  my ($self) = @_ ;
  my $mw = $self->{'main_window'} ;
  my ($txt, $place_holder, $frm) ;
  require Tk::ROText ;
  require Tk::NoteBook ;
  require Tk::HList ;
  require Tk::Balloon ;
  require Tk::Adjuster ;

  # get the side that we want to put the code pane on
  
  my($codeSide) = $ENV{'PTKDB_CODE_SIDE'} || $mw->optionGet("codeside", "") || 'left' ;

  

  $mw->update ; # force geometry manager to map main_window
  $frm = $mw->Frame(-width => $mw->reqwidth()) ; # frame for our code pane and search controls

  $self->setup_search_panel($frm, -side => 'top', -fill => 'x') ;

  #
  # Text window for the code of our currently viewed file
  #
  $self->{'text'} = $frm->Scrolled('ROText',
                                   -wrap => "none",
                                 @Devel::ptkdb::scrollbar_cfg,
                                 @Devel::ptkdb::code_text_font
                                   ) ;


  $txt = $self->{'text'} ;
  for( $txt->children ) {
    next unless (ref $_) =~ /ROText$/ ;
    $self->{'text'} = $_ ;
    last ;
  }

  $frm->packPropagate(0) ;
  $txt->packPropagate(0) ;

  $frm->packAdjust(-side => $codeSide, -fill => 'both', -expand => 1) ;
  $txt->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  # $txt->form(-top => [ $self->{'menu_bar'} ], -left => '%0', -right => '%50') ;
  # $frm->form(-top => [ $self->{'menu_bar'} ], -left => '%50', -right => '%100') ;

  $self->configure_text() ;

  #
  # Notebook
  #

  $self->{'notebook'} = $mw->NoteBook() ;
  $self->{'notebook'}->packPropagate(0) ;
  $self->{'notebook'}->pack(-side => $codeSide, -fill => 'both', -expand => 1) ;

  #
  # an hlist for the data entries
  #
  $self->{'data_page'} = $self->{'notebook'}->add("datapage", -label => "Exprs") ;

  #
  # frame, entry and label for quick expressions
  #
  my $frame = $self->{'data_page'}->Frame()->pack(-side => 'top', -fill => 'x') ;
  
  my $label = $frame->Label(-text => "Quick Expr:")->pack(-side => 'left') ;
  
  $self->{'quick_entry'} = $frame->Entry()->pack(-side => 'left', -fill => 'x', -expand => 1) ;

  $self->{'quick_entry'}->bind('<Return>', sub { $self->QuickExpr() ; } ) ;
  

  #
  # Entry widget for expressions and breakpoints
  #
  $frame = $self->{'data_page'}->Frame()->pack(-side => 'top', -fill => 'x') ;

  $label = $frame->Label(-text => "Enter Expr:")->pack(-side => 'left') ;

  $self->{'entry'} = $frame->Entry()->pack(-side => 'left', -fill => 'x', -expand => 1) ;

  $self->{'entry'}->bind('<Return>', sub { $self->EnterExpr() }) ;

  #
  # Hlist for data expressions
  #


  $self->{data_list} = $self->{'data_page'}->Scrolled('HList',
                                                    @Devel::ptkdb::scrollbar_cfg, 
                                                      separator => $Devel::ptkdb::pathSep,
                                                    @Devel::ptkdb::expression_text_font,
                                                      -command => \&Devel::ptkdb::expr_expand,
                                                      -selectmode => 'multiple'
                                                      ) ;

  $self->{data_list}->pack(-side => 'top', -fill => 'both', -expand => 1
                           ) ;


  $self->{'subs_page_activated'} = 0 ;
  $self->{'subs_page'} = $self->{'notebook'}->add("subspage", -label => "Subs", -createcmd => sub { $self->setup_subs_page }) ;

  $self->setup_breakpts_page() ;    

} # end of setup_frames



sub configure_text {
  my($self) = @_ ;
  my($txt, $mw) = ($self->{'text'}, $self->{'main_window'}) ;
  my($place_holder) ;

  $self->{'expr_balloon'} = $txt->Balloon();
  $self->{'balloon_expr'} = ' ' ; # initial expression

  # If Data::Dumper is available setup a dumper for the balloon
  
  if ( $Devel::ptkdb::DataDumperAvailable ) {
    $self->{'balloon_dumper'} = new Data::Dumper([$place_holder]) ;
    $self->{'balloon_dumper'}->Terse(1) ;
    $self->{'balloon_dumper'}->Indent($Devel::ptkdb::eval_dump_indent) ;

    $self->{'quick_dumper'} = new Data::Dumper([$place_holder]) ;
    $self->{'quick_dumper'}->Terse(1) ;
    $self->{'quick_dumper'}->Indent(0) ;
  }
  
  $self->{'expr_ballon_msg'} = ' ' ;
  
  $self->{'expr_balloon'}->attach($txt, -initwait => 300,
                                  -msg => \$self->{'expr_ballon_msg'},
                                  -balloonposition => 'mouse',
                                  -postcommand => \&Devel::ptkdb::balloon_post,
                                  -motioncommand => \&Devel::ptkdb::balloon_motion ) ;
  
  # tags for the text
  
  my @stopTagConfig = ( -foreground => 'white', -background  => $mw->optionGet("stopcolor", "background") || $ENV{'PTKDB_STOP_TAG_COLOR'} || 'blue' ) ;
  
  my $stopFnt = $mw->optionGet("stopfont", "background") || $ENV{'PTKDB_STOP_TAG_FONT'} ;
  push @stopTagConfig, ( -font => $stopFnt ) if $stopFnt ; # user may not have specified a font, if not, stay with the default
  
  $txt->tagConfigure('stoppt', @stopTagConfig) ;
  $txt->tagConfigure('search_tag', "-background" => $mw->optionGet("searchtagcolor", "background") || "green") ;
  
  $txt->tagConfigure("breakableLine", -overstrike => 0) ;
  $txt->tagConfigure("nonbreakableLine", -overstrike => 1) ;
  $txt->tagConfigure("breaksetLine", -background => $mw->optionGet("breaktagcolor", "background") || $ENV{'PTKDB_BRKPT_COLOR'} || 'red') ;
  $txt->tagConfigure("breakdisabledLine", -background => $mw->optionGet("disabledbreaktagcolor", "background") || $ENV{'PTKDB_DISABLEDBRKPT_COLOR'} || 'green') ;
  
  $txt->tagBind("breakableLine", '<Button-1>', [ \&Devel::ptkdb::set_breakpoint_tag, $self, Ev('@'), 1 ]  ) ;
  $txt->tagBind("breakableLine", '<Shift-Button-1>', [ \&Devel::ptkdb::set_breakpoint_tag, $self, Ev('@'), 0 ]  ) ;
  
  $txt->tagBind("breaksetLine", '<Button-1>',  [ \&Devel::ptkdb::clear_breakpoint_tag, $self, Ev('@') ]  ) ;
  $txt->tagBind("breaksetLine", '<Shift-Button-1>',  [ \&Devel::ptkdb::change_breakpoint_tag, $self, Ev('@'), 0 ]  ) ;
  
  $txt->tagBind("breakdisabledLine", '<Button-1>', [ \&Devel::ptkdb::clear_breakpoint_tag, $self, Ev('@') ]  ) ;
  $txt->tagBind("breakdisabledLine", '<Shift-Button-1>', [ \&Devel::ptkdb::change_breakpoint_tag, $self, Ev('@'), 1 ]  ) ;
  
} # end of configure_text


sub setup_options {
  my ($self) = @_ ;
  my $mw = $self->{main_window} ;

  return unless $mw->can('appname') ;
  
  $mw->appname("ptkdb") ;
  $mw->optionAdd("stopcolor" => 'cyan', 60 ) ;
  $mw->optionAdd("stopfont" => 'fixed', 60 ) ;
  $mw->optionAdd("breaktag" => 'red', 60 ) ;
  $mw->optionAdd("searchtagcolor" => 'green') ;
  
  $mw->optionClear ; #  necessary to reload xresources

} # end of setup_options

sub DoAlert {
  my($self, $msg, $title) = @_ ;
  my($dlg) ;
  my $okaySub = sub {
    destroy $dlg ;
  } ;

  $dlg = $self->{main_window}->Toplevel(-title => $title || "Alert", -overanchor => 'cursor') ;

  $dlg->Label( -text => $msg )->pack( -side => 'top' ) ;

  $dlg->Button( -text => "Okay", -command => $okaySub )->pack( -side => 'top' )->focus   ;
  $dlg->bind('<Return>', $okaySub) ;

} # end of DoAlert

sub simplePromptBox {
  my ($self, $title, $defaultText, $okaySub, $cancelSub) = @_ ;
  my ($top, $entry, $okayBtn) ;

  $top = $self->{main_window}->Toplevel(-title => $title, -overanchor => 'cursor' ) ;

 $Devel::ptkdb::promptString = $defaultText ;

  $entry = $top->Entry('-textvariable' => \$Devel::ptkdb::promptString)->pack(-side => 'top', -fill => 'both', -expand => 1) ;
  
  
  $okayBtn = $top->Button( -text => "Okay", @Devel::ptkdb::button_font, -command => sub {  &$okaySub() ; $top->destroy ;}
                           )->pack(-side => 'left', -fill => 'both', -expand => 1) ;
  
  $top->Button( -text => "Cancel", -command => sub { &$cancelSub() if $cancelSub ; $top->destroy() }, @Devel::ptkdb::button_font,
                )->pack(-side => 'left', -fill => 'both', -expand => 1) ;
  
  $entry->icursor('end') ;
  
  $entry->selectionRange(0, 'end') if $entry->can('selectionRange') ; # some win32 Tk installations can't do this

  $entry->focus() ;

  return $top ;
  
} # end of simplePromptBox

sub get_entry_text {
  my($self) = @_ ;
  
  return $self->{entry}->get() ; # get the text in the entry
} # end of get_entry_text


#
# Clear any text that is in the entry field.  If there
# was any text in that field return it.  If there
# was no text then return any selection that may be active.  
#
sub clear_entry_text {
  my($self) = @_ ;
  my $str =  $self->{'entry'}->get() ;
  $self->{'entry'}->delete(0, 'end') ;

  #
  # No String
  # Empty String
  # Or a string that is only whitespace
  #
  if( !$str || $str eq "" || $str =~ /^\s+$/ ) {
    #
    # If there is no string or the string is just white text
    # Get the text in the selction( if any)
    # 
    if( $self->{'text'}->tagRanges('sel') ) { # check to see if 'sel' tag exists (return undef value)
      $str = $self->{'text'}->get("sel.first", "sel.last") ; # get the text between the 'first' and 'last' point of the sel (selection) tag
    }
    # If still no text, bring the focus to the entry
    elsif( !$str || $str eq "" || $str =~ /^\s+$/ ) {
      $self->{'entry'}->focus() ;
      $str = "" ;
    }
  }
  #
  # Erase existing text
  #
  return $str ;
} # end of clear_entry_text

sub brkPtCheckbutton {
  my ($self, $fname, $idx, $brkPt) = @_ ;
  my ($widg) ;

  change_breakpoint_tag($self->{'text'}, $self, "$idx.0", $brkPt->{'value'}) if $fname eq $self->{'current_file'} ;

} # end of brkPtCheckbutton

#
# insert a breakpoint control into our breakpoint list.  
# returns a handle to the control
#
#  Expression, if defined, is to be evaluated at the breakpoint
# and execution stopped if it is non-zero/defined.
#
# If action is defined && True then it will be evalled
# before continuing.  
#
sub insertBreakpoint {
  my ($self, $fname, @brks) = @_ ;
  my ($btn, $cnt, $item) ;

  my($offset) ;

  local(*dbline) = $main::{'_<' . $fname} ;

  $offset = $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ? 1 : 0 ;

  while( @brks ) {
    my($index, $value, $expression) = splice @brks, 0, 3 ; # take args 3 at a time

    my $brkPt = {} ; 
    my $txt = &DB::getdbtextline($fname, $index) ;
    @$brkPt{'type', 'line',  'expr',      'value', 'fname', 'text'} =
        ('user',   $index, $expression, $value,   $fname,  "$txt") ;

    &DB::setdbline($fname, $index + $offset, $brkPt) ;
    $self->add_brkpt_to_brkpt_page($brkPt) ;

    next unless $fname eq $self->{'current_file'} ;

    $self->{'text'}->tagRemove("breakableLine", "$index.0", "$index.$Devel::ptkdb::linenumber_length") ;    
    $self->{'text'}->tagAdd($value ? "breaksetLine" : "breakdisabledLine",  "$index.0", "$index.$Devel::ptkdb::linenumber_length") ;
  } # end of loop
} # end of insertBreakpoint

sub add_brkpt_to_brkpt_page { 
  my($self, $brkPt) = @_ ;
  my($btn, $fname, $index, $frm, $upperFrame, $lowerFrame) ; 
  my ($row, $btnName, $width) ;
  # 
  # Add the breakpoint to the breakpoints page 
  # 
  ($fname, $index) = @$brkPt{'fname', 'line'} ; 
  return if exists $self->{'breakpts_table_data'}->{"$fname:$index"} ; 
  $self->{'brkPtCnt'} += 1 ; 

  $btnName = $fname ;
  $btnName =~ s/.*\/([^\/]*)$/$1/o ; 

  # take the last leaf of the pathname 
  
  $frm = $self->{'breakpts_table'}->Frame(-relief => 'raised') ; 
  $upperFrame = $frm->Frame()->pack(-side => 'top', '-fill' => 'x', -expand => 1) ; 

  
  $btn = $upperFrame->Checkbutton(-text => "$btnName:$index",
                                  -variable => \$brkPt->{'value'}, # CAUTION value tracking
                                  -command => sub { $self->brkPtCheckbutton($fname, $index, $brkPt) }) ;

  $btn->pack(-side => 'left') ;

  $btn = $upperFrame->Button(-text => "Delete", -command => sub { $self->removeBreakpoint($fname, $index) ; } ) ;
  $btn->pack(-side => 'left', -fill => 'x', -expand => 1) ;
  
  $btn = $upperFrame->Button(-text => "Goto", -command => sub { $self->set_file($fname, $index) ; } ) ;
  $btn->pack(-side => 'left', -fill => 'x', -expand => 1) ;

  $lowerFrame = $frm->Frame()->pack(-side => 'top', '-fill' => 'x', -expand => 1) ;

  $lowerFrame->Label(-text => "Cond:")->pack(-side => 'left') ;
  
  $btn = $lowerFrame->Entry(-textvariable => \$brkPt->{'expr'}) ;
  $btn->pack(-side => 'left', -fill => 'x', -expand => 1) ;
  
  $frm->pack(-side => 'top', -fill => 'x', -expand => 1) ;

  $row = pop @{$self->{'brkPtSlots'}} or $row = $self->{'brkPtCnt'} ;

  $self->{'breakpts_table'}->put($row, 1, $frm) ;
  
  $self->{'breakpts_table_data'}->{"$fname:$index"}->{'frm'} = $frm ;
  $self->{'breakpts_table_data'}->{"$fname:$index"}->{'row'} = $row ;

  $self->{'main_window'}->update ;

  $width = $frm->width ;

  if ( $width > $self->{'breakpts_table'}->width ) {
    $self->{'notebook'}->configure(-width => $width) ;
  }
  
} # end of add_brkpt_to_brkpt_page

sub remove_brkpt_from_brkpt_page {
  my($self, $fname, $idx) = @_ ;
  my($table) ;

  $table = $self->{'breakpts_table'} ;

  # Delete the breakpoint control in the breakpoints window

  $table->put($self->{'breakpts_table_data'}->{"$fname:$idx"}->{'row'}, 1) ; # delete?

  #
  # Add this now empty slot to the list of ones we have open
  #

  push @{$self->{'brkPtSlots'}}, $self->{'breakpts_table_data'}->{"$fname:$idx"}->{'row'} ;

  $self->{'brkPtSlots'} = [ sort { $b <=> $a } @{$self->{'brkPtSlots'}} ] ;
  
  delete $self->{'breakpts_table_data'}->{"$fname:$idx"} ;
  
  $self->{'brkPtCnt'} -= 1 ;

} # end of remove_brkpt_from_brkpt_page


#
# Supporting the "Run To Here..." command
#
sub insertTempBreakpoint {
  my ($self, $fname, $index) = @_ ;
  my($offset) ;
  local(*dbline) = $main::{'_<' . $fname} ;

  $offset = $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ? 1 : 0 ;

  return if( &DB::getdbline($fname, $index + $offset) ) ; # we already have a breakpoint here

  &DB::setdbline($fname, $index + $offset, {'type' => 'temp', 'line' => $index, 'value' => 1 } ) ;

} # end of insertTempBreakpoint

sub reinsertBreakpoints {
  my ($self, $fname) = @_ ;
  my ($brkPt) ;

  foreach $brkPt ( &DB::getbreakpoints($fname) ) {
    #
    # Our breakpoints are indexed by line
    # therefore we can have 'gaps' where there
    # lines, but not breaks set for them.
    #
    next unless defined $brkPt ;
    
    $self->insertBreakpoint($fname, @$brkPt{'line', 'value', 'expr'}) if( $brkPt->{'type'} eq 'user' ) ;
    $self->insertTempBreakpoint($fname, $brkPt->{line}) if( $brkPt->{'type'} eq 'temp' ) ;
  } # end of reinsert loop

} # end of reinsertBreakpoints

sub removeBreakpointTags {
  my ($self, @brkPts) = @_ ;
  my($idx, $brkPt) ;
  
  foreach $brkPt (@brkPts) {

    $idx = $brkPt->{'line'} ;

    if ( $brkPt->{'value'} ) {
      $self->{'text'}->tagRemove("breaksetLine", "$idx.0", "$idx.$Devel::ptkdb::linenumber_length") ;
    }
    else {
      $self->{'text'}->tagRemove("breakdisabledLine", "$idx.0", "$idx.$Devel::ptkdb::linenumber_length") ; 
    }
    
    $self->{'text'}->tagAdd("breakableLine", "$idx.0", "$idx.$Devel::ptkdb::linenumber_length") ;         
  }
} # end of removeBreakpointTags

#
# Remove a breakpoint from the current window
#
sub removeBreakpoint {
  my ($self, $fname, @idx) = @_ ;
  my ($idx, $chkIdx, $i, $j, $info) ;
  my($offset) ;
  local(*dbline) = $main::{'_<' . $fname} ;

  $offset = $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ? 1 : 0 ;

  foreach $idx (@idx) { # end of removal loop
    next unless defined $idx ;
    my $brkPt = &DB::getdbline($fname, $idx + $offset) ;
    next unless $brkPt ; # if we do not have an entry
    &DB::cleardbline($fname, $idx + $offset) ;

    $self->remove_brkpt_from_brkpt_page($fname, $idx) ;

    next unless $brkPt->{fname} eq $self->{'current_file'}  ; # if this isn't our current file there will be no controls

    # Delete the ext associated with the breakpoint expression (if any)    

    $self->removeBreakpointTags($brkPt) ;
  } # end of remove loop
  
  return ;
} # end of removeBreakpoint

sub removeAllBreakpoints {
  my ($self, $fname) = @_ ;
  
  $self->removeBreakpoint($fname, &DB::getdblineindexes($fname)) ;

} # end of removeAllBreakpoints

#
# Delete expressions prior to an update
#
sub deleteAllExprs {
  my ($self) = @_ ;
  $self->{'data_list'}->delete('all') ;
} # end of deleteAllExprs

sub EnterExpr {
  my ($self) = @_ ;
  my $str = $self->clear_entry_text() ;
  if( $str && $str ne "" && $str !~ /^\s+$/ ) { # if there is an expression and it's more than white space
    $self->{'expr'} = $str ;
    $self->{'event'} = 'expr' ;
  }
} # end of EnterExpr

#
#
#
sub QuickExpr {
  my ($self) = @_ ;

  my $str = $self->{'quick_entry'}->get() ;

  if( $str && $str ne "" && $str !~ /^\s+$/ ) { # if there is an expression and it's more than white space
    $self->{'qexpr'} = $str ;
    $self->{'event'} = 'qexpr' ;
  }
} # end of QuickExpr

sub deleteExpr {
  my ($self) = @_ ;
  my ($entry, $i, @indexes) ;
  my @sList = $self->{'data_list'}->info('select') ;

  #
  # if we're deleteing a top level expression
  # we have to take it out of the list of expressions
  #

  foreach $entry ( @sList ) {
    next if ($entry =~ /\//) ; # goto next expression if we're not a top level ( expr/entry)
    $i = 0 ;
    grep { push @indexes, $i if ($_->{'expr'} eq $entry) ; $i++ ; } @{$self->{'expr_list'}} ;
  } # end of check loop
  
  # now take out our list of indexes ;

  for( 0..$#indexes ) {
       splice @{$self->{'expr_list'}}, $indexes[$_] - $_, 1 ;
     }

  for( @sList ) {
    $self->{'data_list'}->delete('entry', $_) ;
  }
} # end of deleteExpr

sub fixExprPath {
  my(@pathList) = @_ ;
  
  for (@pathList) {
    s/$Devel::ptkdb::pathSep/$Devel::ptkdb::pathSepReplacement/go ;
  } # end of path list

  return $pathList[0] unless wantarray ;
  return @pathList ;

} # end of fixExprPath

##
##  Inserts an expression($theRef) into an HList Widget($dl).  If the expression
## is an array, blessed array, hash, or blessed hash(typical object), then this
## routine is called recursively, adding the members to the next level of heirarchy,
## prefixing array members with a [idx] and the hash members with the key name.
## This continues until the entire expression is decomposed to it's atomic constituents.
## Protection is given(with $reusedRefs) to ensure that 'circular' references within
## arrays or hashes(i.e. where a member of a array or hash contains a reference to a
## parent element within the heirarchy.  
##
#
# Returns 1 if sucessfully added 0 if not
#
sub insertExpr {
  my($self, $reusedRefs, $dl, $theRef, $name, $depth, $dirPath) = @_ ;
  my($label, $type, $result, $selfCnt, @circRefs) ;
  local($^W) = 0 ; # spare us uncessary warnings about comparing strings with ==  

  #
  # Add data new data entries to the bottom
  # 
  $dirPath = "" unless defined $dirPath ;

  $label = "" ;
  $selfCnt = 0 ;

  while( ref $theRef eq 'SCALAR' ) {
    $theRef = $$theRef ;
  }
 REF_CHECK: for( ; ; ) {
   push @circRefs, $theRef ;
   $type = ref $theRef ;
   last unless ($type eq "REF")  ;
   $theRef = $$theRef ; # dref again
   
   $label .= "\\" ; # append a 
   if( grep $_ == $theRef, @circRefs ) {
     $label .= "(circular)" ;
     last ;
   }
 }

  if( !$type || $type eq "" || $type eq "GLOB" || $type eq "CODE") {
    eval {
      if( !defined $theRef ) {
        $dl->add($dirPath . $name, -text => "$name = $label" . "undef") ;
      }
      else {
        $dl->add($dirPath . $name, -text => "$name = $label$theRef") ;
      }
    } ;
    $self->DoAlert($@), return 0 if $@ ;
    return 1 ;
  }

  if( $type eq 'ARRAY' or "$theRef" =~ /ARRAY/ ) {
    my ($r, $idx) ;
    $idx = 0 ;
    eval {
      $dl->add($dirPath . $name, -text => "$name = $theRef") ;
    } ;
    if( $@ ) {
      $self->DoAlert($@) ;
      return 0 ;
    }
    $result = 1 ;
    foreach $r ( @{$theRef} ) {

      if( grep $_ == $r, @$reusedRefs ) { # check to make sure that we're not doing a single level self reference
        eval {
          $dl->add($dirPath .  fixExprPath($name) . $Devel::ptkdb::pathSep . "__ptkdb_self_path" . $selfCnt++, -text => "[$idx] = $r REUSED ADDR") ;
        } ;
        $self->DoAlert($@) if( $@ ) ;
        next ;
      }
      
      push @$reusedRefs, $r ;
      $result = $self->insertExpr($reusedRefs, $dl, $r, "[$idx]", $depth-1, $dirPath . fixExprPath($name) . $Devel::ptkdb::pathSep) unless $depth == 0 ;
      pop @$reusedRefs ;

      return 0 unless $result ;
      $idx += 1 ;
    }
    return 1 ;
  } # end of array case

  if(  "$theRef" !~ /HASH\050\060x[0-9a-f]*\051/o ) {
    eval {
      $dl->add($dirPath . fixExprPath($name), -text => "$name = $theRef") ;
    } ;
    if( $@ ) {
      $self->DoAlert($@) ;
      return 0 ;
    }
    return 1 ;
  }
# 
# Anything else at this point is
# either a 'HASH' or an object
# of some kind.
#
  my($r, @theKeys, $idx) ;
  $idx = 0 ;
  @theKeys = sort keys %{$theRef} ;
  $dl->add($dirPath . $name, -text => "$name = " . "$theRef") ;
  $result = 1 ;

  foreach $r ( @$theRef{@theKeys} ) { # slice out the values with the sorted list

    if( grep $_ == $r, @$reusedRefs ) { # check to make sure that we're not doing a single level self reference
      eval {
        $dl->add($dirPath .  fixExprPath($name) . $Devel::ptkdb::pathSep . "__ptkdb_self_path" . $selfCnt++, -text => "$theKeys[$idx++] = $r REUSED ADDR") ;
      } ;
      print "bad path $@\n" if( $@ ) ;
      next ;
    }

    push @$reusedRefs, $r ;

    $result = $self->insertExpr($reusedRefs,                              # recursion protection
                                $dl,                                      # data list widget
                                $r,                                       # reference whose value is displayed
                                $theKeys[$idx],                           # name
                                $depth-1,                                 # remaining expansion depth
                                $dirPath . $name . $Devel::ptkdb::pathSep # path to add to
                                ) unless $depth == 0 ;

    pop @$reusedRefs ;

    return 0 unless $result ;
    $idx += 1 ;
  } # end of ref add loop

  return 1 ;
} # end of insertExpr

#
# We're setting the line where we are stopped.  
# Create a tag for this and set it as bold.  
#
sub set_line {
  my ($self, $lineno) = @_ ;
  my $text = $self->{'text'} ;

  return if( $lineno <= 0 ) ;

  if( $self->{current_line} > 0 ) {
    $text->tagRemove('stoppt', "$self->{current_line}.0 linestart", "$self->{current_line}.0 lineend") ;
  }
  $self->{current_line} = $lineno - $self->{'line_offset'} ;
  $text->tagAdd('stoppt', "$self->{current_line}.0 linestart", "$self->{current_line}.0 lineend") ;

  $self->{'text'}->see("$self->{current_line}.0 linestart") ;
} # end of set_line

#
# Set the file that is in the code window.
#
# $fname the 'new' file to view
# $line the line number we're at
# $brkPts any breakpoints that may have been set in this file
#

use Carp ;

sub set_file {
  my ($self, $fname, $line) = @_ ;
  my ($lineStr, $offset, $text, $i, @text, $noCode, $title) ;
  my (@breakableTagList, @nonBreakableTagList) ;

  return unless $fname ;  # we're getting an undef here on 'Restart...'

  local(*dbline) = $main::{'_<' . $fname};

  #
  # with the #! /usr/bin/perl -d:ptkdb at the header of the file
  # we've found that with various combinations of other options the
  # files haven't come in at the right offsets
  #
  $offset = 0 ;
  $offset = 1 if $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ;
  $self->{'line_offset'} = $offset ;

  $text = $self->{'text'} ;
   
  if( $fname eq $self->{current_file} ) {
    $self->set_line($line) ;
    return ;
  } ;

	$title = $fname ; # removing the - messes up stashes on -e invocations
  $title =~ s/^\-// ; # Tk does not like leadiing '-'s 
  $self->{main_window}->configure('-title' => $title) ;

  # Erase any existing text

  $text->delete('0.0','end') ;
  
  my $len = $Devel::ptkdb::linenumber_length ;

  #
  # This is the tightest loop we have in the ptkdb code.
  # It is here where performance is the most critical.
  # The map block formats perl code for display.  Since
  # the file could be potentially large, we will try
  # to make this loop as thin as possible. 
  #
  # NOTE:  For a new perl individual this may appear as
  # if it was intentionally obfuscated.  This is not
  # not the case.  The following code is the result
  # of an intensive effort to optimize this code.
  # Prior versions of this code were quite easier
  # to read, but took 3 times longer.
  # 

  $lineStr = " " x 200 ; # pre-allocate space for $lineStr
  $i = 1 ;

  local($^W) = 0 ; # spares us useless warnings under -w when checking $dbline[$_] != 0
  #
  # The 'map' call will build list of 'string', 'tag' pairs
  # that will become arguments to the 'insert' call.  Passing
  # the text to insert "all at once" rather than one insert->('end', 'string', 'tag')
  # call at time provides a MASSIVE savings in execution time.
  #
  $noCode = ($#dbline - ($offset + 1)) < 0 ;

  $text->insert('end', map {
    #
    # build collections of tags representing
    # the line numbers for breakable and 
    # non-breakable lines.  We apply these
    # tags after we've built the text
    #
    
    ($_ != 0 && push @breakableTagList, "$i.0", "$i.$len") || push @nonBreakableTagList, "$i.0", "$i.$len" ;

    $lineStr = sprintf($Devel::ptkdb::linenumber_format, $i++) . $_ ; # line number + text of the line

		substr $lineStr, -2, 1, '' if $isWin32 ; # removes the CR from win32 instances

		$lineStr .= "\n" unless /\n$/o ; # append a \n if there isn't one already

    ($lineStr, 'code') ; # return value for block, a string,tag pair for text insert
    
  } @dbline[$offset+1 .. $#dbline] ) unless $noCode ;
            
  #
  # Apply the tags that we've collected
  # NOTE:  it was attempted to incorporate these
  # operations into the 'map' block above, but that
  # actually degraded performance.  
  #
  $text->tagAdd("breakableLine", @breakableTagList) if @breakableTagList ; # apply tag to line numbers where the lines are breakable
  $text->tagAdd("nonbreakableLine", @nonBreakableTagList) if @nonBreakableTagList ; # apply tag to line numbers where the lines are not breakable.  
            
  #
    # Reinsert breakpoints (if info provided)
    #

    $self->set_line($line) ;
    $self->{current_file} = $fname ;
    return $self->reinsertBreakpoints($fname) ;
} # end of set_file

#
# Get the current line that the insert cursor is in
#
sub get_lineno {
  my ($self) = @_ ; 
  my ($info) ;
  
  $info = $self->{'text'}->index('insert') ; # get the location for the insertion point
  $info =~ s/\..*$/\.0/ ;

  return int $info ;
} # end of get_lineno

sub DoGoto {
  my ($self, $entry) = @_ ;

  my $txt = $entry->get() ;
  
  $txt =~ s/(\d*).*/$1/ ; # take the first blob of digits
  if( $txt eq "" ) {
    print "invalid text range\n" ;
    return if $txt eq "" ;
  }
  
  $self->{'text'}->see("$txt.0") ;
  
  $entry->selectionRange(0, 'end') if $entry->can('selectionRange')

    } # end of DoGoto

sub GotoLine {
  my ($self) = @_ ;
  my ($topLevel) ;

  if( $self->{goto_window} ) {
    $self->{goto_window}->raise() ;
    $self->{goto_text}->focus() ;
    return ;
  }

  #
  # Construct a dialog that has an
  # entry field, okay and cancel buttons
  #
  my $okaySub = sub { $self->DoGoto($self->{'goto_text'}) } ;
  
  $topLevel = $self->{main_window}->Toplevel(-title => "Goto Line?", -overanchor => 'cursor') ;

  $self->{goto_text} = $topLevel->Entry()->pack(-side => 'top', -fill => 'both', -expand => 1) ;

  $self->{goto_text}->bind('<Return>', $okaySub) ; # make a CR do the same thing as pressing an okay

  $self->{goto_text}->focus() ;

  # Bind a double click on the mouse button to the same action
  # as pressing the Okay button

  $topLevel->Button( -text => "Okay", -command => $okaySub, @Devel::ptkdb::button_font,
                     )->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  #
  # Subroutone called when the 'Dismiss'
  # button is pushed.
  #
  my $dismissSub = sub {
    delete $self->{goto_text} ;
    destroy {$self->{goto_window}} ;
    delete $self->{goto_window} ; # remove the entry from our hash so we won't
  } ;

  $topLevel->Button( -text => "Dismiss", @Devel::ptkdb::button_font,
                     -command => $dismissSub )->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  $topLevel->protocol('WM_DELETE_WINDOW', sub { destroy $topLevel ; } ) ;

  $self->{goto_window} = $topLevel ;

} # end of GotoLine


#
# Subroutine called when the 'okay' button is pressed
#
sub FindSearch {
  my ($self, $entry, $btn, $regExp) = @_ ;
  my (@switches, $result) ;
  my $txt = $entry->get() ;

  return if $txt eq "" ; 

  push @switches, "-forward" if $self->{fwdOrBack} eq "forward" ;
  push @switches, "-backward" if $self->{fwdOrBack} eq "backward" ;
  
  if( $regExp ) {
    push @switches, "-regexp" ;
  }
  else {
    push @switches, "-nocase" ; # if we're not doing regex we may as well do caseless search
  }

  $result = $self->{'text'}->search(@switches, $txt, $self->{search_start}) ;

  # untag the previously found text

  $self->{'text'}->tagRemove('search_tag', @{$self->{search_tag}}) if defined $self->{search_tag} ;

  if( !$result || $result eq "" ) {
    # No Text was found
    $btn->flash() ;
    $btn->bell() ;

    delete $self->{search_tag} ;
    $self->{'search_start'} = "0.0" ;
  }
  else { # text found
    $self->{'text'}->see($result) ;
    # set the insertion of the text as well
    $self->{'text'}->markSet('insert' => $result) ;
    my $len = length $txt ;

    if( $self->{fwdOrBack} ) {
      $self->{search_start}  = "$result +$len chars"  ;
      $self->{search_tag} = [ $result, $self->{search_start} ]  ;
    }
    else {
      # backwards search 
      $self->{search_start}  = "$result -$len chars"  ;
      $self->{search_tag} = [ $result, "$result +$len chars"  ]  ;
    }

    # tag the newly found text

    $self->{'text'}->tagAdd('search_tag', @{$self->{search_tag}}) ;
  } # end of text found

  $entry->selectionRange(0, 'end') if $entry->can('selectionRange') ;

} # end of FindSearch


#
# Support for the Find Text... Menu command
#
sub FindText {
  my ($self) = @_ ;
  my ($top, $entry, $rad1, $rad2, $chk, $regExp, $frm, $okayBtn) ;

  #
  # if we already have the Find Text Window
  # open don't bother openning another, bring
  # the existing one to the front.  
  #
  if( $self->{find_window} ) {
    $self->{find_window}->raise() ;
    $self->{find_text}->focus() ;
    return ;
  }

  $self->{search_start} = $self->{'text'}->index('insert') if( $self->{search_start} eq "" ) ;

  #
  # Subroutine called when the 'Dismiss' button
  # is pushed.  
  #
  my $dismissSub = sub {
    $self->{'text'}->tagRemove('search_tag', @{$self->{search_tag}}) if defined $self->{search_tag} ;
    $self->{search_start} = "" ;
    destroy {$self->{find_window}} ; 
    delete $self->{search_tag} ;
    delete $self->{find_window} ;
  } ;

  #
  # Construct a dialog that has an entry field, forward, backward, regex option, okay and cancel buttons
  #
  $top = $self->{main_window}->Toplevel(-title => "Find Text?") ;

  $self->{find_text} = $top->Entry()->pack(-side => 'top', -fill => 'both', -expand => 1) ;

  
  $frm = $top->Frame()->pack(-side => 'top', -fill => 'both', -expand => 1) ;

  $self->{fwdOrBack} = 'forward' ;
  $rad1 = $frm->Radiobutton(-text => "Forward", -value => 1, -variable => \$self->{fwdOrBack}) ;
  $rad1->pack(-side => 'left', -fill => 'both', -expand => 1) ;
  $rad2 = $frm->Radiobutton(-text => "Backward", -value => 0, -variable => \$self->{fwdOrBack}) ;
  $rad2->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  $regExp = 0 ;
  $chk = $frm->Checkbutton(-text => "RegExp", -variable => \$regExp) ;
  $chk->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  # Okay and cancel buttons

  # Bind a double click on the mouse button to the same action
  # as pressing the Okay button

  $okayBtn = $top->Button( -text => "Okay", -command => sub { $self->FindSearch($self->{find_text}, $okayBtn, $regExp) ; }, 
                         @Devel::ptkdb::button_font,
                           )->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  $self->{find_text}->bind('<Return>', sub { $self->FindSearch($self->{find_text}, $okayBtn, $regExp) ; }) ;

  $top->Button( -text => "Dismiss", @Devel::ptkdb::button_font,
                -command => $dismissSub)->pack(-side => 'left', -fill => 'both', -expand => 1) ;

  $top->protocol('WM_DELETE_WINDOW', $dismissSub) ;

  $self->{find_text}->focus() ;

  $self->{find_window} = $top ;

} # end of FindText

sub main_loop {
  my ($self) = @_ ;
  my ($evt, $str, $result) ;
  my $i = 0;
 SWITCH: for ($self->{'event'} = 'null' ; ; $self->{'event'} = undef ) {

   Tk::DoOneEvent(0);
   next unless $self->{'event'} ;

   $evt = $self->{'event'} ;
   $evt =~ /step/o && do { last SWITCH ; } ;
   $evt =~ /null/o && do { next SWITCH ; } ;
   $evt =~ /run/o && do { last SWITCH ; } ;
   $evt =~ /quit/o && do { $self->DoQuit ; } ;
   $evt =~ /expr/o && do { return $evt ; } ; # adds an expression to our expression window
   $evt =~ /qexpr/o && do { return $evt ; } ; # does a 'quick' expression
   $evt =~ /update/o && do { return $evt ; } ; # forces an update on our expression window
   $evt =~ /reeval/o && do { return $evt ; } ; # updated the open expression eval window
   $evt =~ /balloon_eval/ && do { return $evt } ;
 } # end of switch block
  return $evt ;
} # end of main_loop

#
# $subStackRef   A reference to the current subroutine stack
#

sub goto_sub_from_stack {
  my ($self, $f, $lineno) = @_ ;
  $self->set_file($f, $lineno) ;
} # end of goto_sub_from_stack ;

sub refresh_stack_menu {
  my ($self) = @_ ;
  my ($str, $name, $i, $sub_offset, $subStack) ;

  #
  # CAUTION:  In the effort to 'rationalize' the code
  # are moving some of this function down from DB::DB
  # to here.  $sub_offset represents how far 'down'
  # we are from DB::DB.  The $DB::subroutine_depth is
  # tracked in such a way that while we are 'in' the debugger
  # it will not be incremented, and thus represents the stack depth
  # of the target program.  
  #
  $sub_offset = 1 ;
  $subStack = [] ;

  # clear existing entries

  for( $i = 0 ; $i <= $DB::subroutine_depth ; $i++ ) {
    my ($package, $filename, $line, $subName) = caller $i+$sub_offset ;
    last if !$subName ;
    push @$subStack, { 'name' => $subName, 'pck' => $package, 'filename' => $filename, 'line' => $line } ;
  }

  $self->{stack_menu}->menu->delete(0, 'last') ; # delete existing menu items

  for( $i = 0 ; $subStack->[$i] ; $i++ ) {

    $str = defined $subStack->[$i+1] ? "$subStack->[$i+1]->{name}" : "MAIN" ;

    my ($f, $line) = ($subStack->[$i]->{filename}, $subStack->[$i]->{line}) ; # make copies of the values for use in 'sub'
    $self->{stack_menu}->command(-label => $str, -command => sub { $self->goto_sub_from_stack($f, $line) ; } ) ;
  }
} # end of refresh_stack_menu

no strict ;

sub get_state {
  my ($self, $fname) = @_ ;
  my ($val) ;
  local($files, $expr_list, $eval_saved_text, $main_win_geometry) ;
  
  do "$fname"  ;

  if( $@ ) {
    $self->DoAlert($@) ;
    return ( undef ) x 4 ; # return a list of 4 undefined values
  }

  return ($files, $expr_list, $eval_saved_text, $main_win_geometry) ;
} # end of get_state

use strict ;

sub restoreStateFile {
  my ($self, $fname) = @_ ;
  local(*F) ;
  my ($saveCurFile, $s, @n, $n) ;

  if (!(-e $fname && -r $fname)) {
    $self->DoAlert("$fname does not exist") ;
    return ;
  }

  my ($files, $expr_list, $eval_saved_text, $main_win_geometry) = $self->get_state($fname) ;
  my ($f, $brks) ;

  return unless defined $files || defined $expr_list ;

  &DB::restore_breakpoints_from_save($files) ;

  #
  # This should force the breakpoints to be restored
  #
  $saveCurFile = $self->{current_file} ;

  @$self{ 'current_file', 'expr_list', 'eval_saved_text' } =
      ( ""             , $expr_list,  $eval_saved_text) ;

  $self->set_file($saveCurFile, $self->{current_line}) ;

  $self->{'event'} = 'update' ;

  if ( $main_win_geometry && $self->{'main_window'} ) { 
    # restore the height and width of the window
    $self->{main_window}->geometry( $main_win_geometry ) ;
  }
} # end of retstoreState

sub updateEvalWindow {
  my ($self, @result) = @_ ;
  my ($leng, $str, $d) ;

  $leng = 0 ;
  for( @result ) {
    if( $self->{hexdump_evals} ) {
      # eventually put hex dumper code in here
			
			$self->{eval_results}->insert('end', hexDump($_)) ;

    }
    elsif( !$Devel::ptkdb::DataDumperAvailable || !$Devel::ptkdb::useDataDumperForEval ) {
      $str = "$_\n" ;
    }
    else {
      $d = Data::Dumper->new([ $_ ]) ;
      $d->Indent($Devel::ptkdb::eval_dump_indent) ;
      $d->Terse(1) ;
      if( Data::Dumper->can('Dumpxs') ) { 
        $str = $d->Dumpxs( $_ ) ;
      }
      else {
        $str = $d->Dump( $_ ) ;
      }
    }
    $leng += length $str ;
    $self->{eval_results}->insert('end', $str) ;
  }
} # end of updateEvalWindow


##
## converts non printable chars to '.' for a string
##
sub printablestr {
    return join "", map { (ord($_) >= 32 && ord($_) < 127) ? $_ : '.' } split //, $_[0] ;
}

##
## hex dump utility function
##
sub hexDump {
    my(@retList) ;
    my($width) = 8 ;
    my($offset) ;
    my($len, $fmt, $n, @elems) ;

    for( @_ ) {
	my($str) ;
	$len = length $_ ;
	
	while($len) {
	    $n = $len >= $width ? $width : $len ;

	    $fmt = "\n%04X  " . ("%02X " x $n ) . ( '   ' x ($width - $n) ) . " %s" ;
	    @elems = map ord, split //, (substr $_, $offset, $n) ;
	    $str .= sprintf($fmt, $offset, @elems, printablestr(substr $_, $offset, $n)) ;
	    $offset += $width ;

	    $len -= $n ;
	} # while

	push @retList, $str ;
    } # for

    return $retList[0] unless wantarray ;
    return @retList ;
} # end of hd


sub setupEvalWindow {
  my($self) = @_ ;
  my($top, $dismissSub) ;
  my $f ;
  $self->{eval_window}->focus(), return if exists $self->{eval_window} ; # already running this window?

  $top = $self->{main_window}->Toplevel(-title => "Evaluate Expressions...") ;
  $self->{eval_window} = $top ;
  $self->{eval_text} = $top->Scrolled('TextUndo',
                                    @Devel::ptkdb::scrollbar_cfg,
                                    @Devel::ptkdb::eval_text_font,
                                      width => 50,
                                      height => 10,
                                      -wrap => "none",
                                      )->packAdjust(-side => 'top', -fill => 'both', -expand => 1) ;

  $self->{eval_text}->insert('end', $self->{eval_saved_text}) if exists $self->{eval_saved_text} && defined $self->{eval_saved_text} ;

  $top->Label(-text, "Results:")->pack(-side => 'top', -fill => 'both', -expand => 'n') ;

  $self->{eval_results} = $top->Scrolled('Text',
                                       @Devel::ptkdb::scrollbar_cfg,
                                         width => 50,
                                         height => 10,
                                         -wrap => "none",
                                       @Devel::ptkdb::eval_text_font
                                         )->pack(-side => 'top', -fill => 'both', -expand => 1) ;

  my $btn = $top->Button(-text => 'Eval...', -command => sub { $DB::window->{event} = 'reeval' ; }
                         )->pack(-side => 'left', -fill => 'x', -expand => 1) ;

  $dismissSub = sub { 
    $self->{eval_saved_text} = $self->{eval_text}->get('0.0', 'end') ;
    $self->{eval_window}->destroy ;
    delete $self->{eval_window} ;
  } ;

  $top->protocol('WM_DELETE_WINDOW', $dismissSub ) ;

  $top->Button(-text => 'Clear Eval', -command => sub { $self->{eval_text}->delete('0.0', 'end') }
               )->pack(-side => 'left', -fill => 'x', -expand => 1) ;

  $top->Button(-text => 'Clear Results', -command => sub { $self->{eval_results}->delete('0.0', 'end') }
               )->pack(-side => 'left', -fill => 'x', -expand => 1) ;

  $top->Button(-text => 'Dismiss', -command => $dismissSub)->pack(-side => 'left', -fill => 'x', -expand => 1) ;
	$top->Checkbutton(-text => 'Hex', -variable => \$self->{hexdump_evals})->pack(-side => 'left') ;

} # end of setupEvalWindow ;

sub filterBreakPts {
  my ($breakPtsListRef, $fname) = @_ ;
  my $dbline = $main::{'_<' . $fname}; # breakable lines
  local($^W) = 0 ;
  #
  # Go through the list of breaks and take out any that
  # are no longer breakable
  #

  for( @$breakPtsListRef ) {
    next unless defined $_ ;

    next if $dbline->[$_->{'line'}] != 0 ; # still breakable

    $_ = undef ;
  }
} # end of filterBreakPts

sub DoAbout {
  my $self = shift ;
  my $str = "ptkdb $DB::VERSION\nCopyright 1998,2003 by Andrew E. Page\nFeedback to aepage\@users.sourceforge.net\n\n" ;
  my $threadString = "" ;
  
  $threadString = "Threads Available" if $Config::Config{usethreads} ;
  $threadString = " Thread Debugging Enabled" if $DB::usethreads ;
  
  $str .= <<"__STR__" ;
  This program is free software; you can redistribute it and/or modify
      it under the terms of either:

      a) the GNU General Public License as published by the Free
    Software Foundation; either version 1, or (at your option) any
    later version, or

    b) the "Artistic License" which comes with this Kit.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
    the GNU General Public License or the Artistic License for more details.

    OS $^O
    Tk Version $Tk::VERSION
    Perl Version $]
Data::Dumper Version $Data::Dumper::VERSION
    $threadString
__STR__

    $self->DoAlert($str, "About ptkdb") ;
} # end of DoAbout

#
# return 1 if succesfully set,
# return 0 if otherwise
#
sub SetBreakPoint {
  my ($self, $isTemp) = @_ ;
  my $dbw = $DB::window ;
  my $lineno = $dbw->get_lineno() ;
  my $expr = $dbw->clear_entry_text() ;
  local($^W) = 0 ;

  if( !&DB::checkdbline($DB::window->{current_file}, $lineno + $self->{'line_offset'}) ) {
    $dbw->DoAlert("line $lineno in $DB::window->{current_file} is not breakable") ;
    return 0 ;
  }

  if( !$isTemp ) {
    $dbw->insertBreakpoint($DB::window->{current_file}, $lineno, 1, $expr) ;
    return 1 ;
  }
  else {
    $dbw->insertTempBreakpoint($DB::window->{current_file}, $lineno) ;
    return 1 ;
  }

  return 0 ;
} # end of SetBreakPoint

sub UnsetBreakPoint {
  my ($self) = @_ ;
  my $lineno = $self->get_lineno() ;
  
  $self->removeBreakpoint($DB::window->{current_file}, $lineno) ;
} # end of UnsetBreakPoint

sub balloon_post {
  my $self = $DB::window ;
  my $txt = $DB::window->{'text'} ;

  return 0 if ($self->{'expr_ballon_msg'} eq "") || ($self->{'balloon_expr'} eq "") ; # don't post for an empty string

  return $self->{'balloon_coord'} ;
}

sub balloon_motion {
  my ($txt, $x, $y) = @_ ;
  my ($offset_x, $offset_y) = ($x + 4, $y + 4) ;
  my $self = $DB::window ;
  my $txt2 = $self->{'text'} ;
  my $data ;

  $self->{'balloon_coord'} = "$offset_x,$offset_y" ;

  $x -= $txt->rootx ;
  $y -= $txt->rooty ;
  #
  # Post an event that will cause us to put up a popup
  #
  
  if( $txt2->tagRanges('sel') ) { # check to see if 'sel' tag exists (return undef value)
    $data = $txt2->get("sel.first", "sel.last") ; # get the text between the 'first' and 'last' point of the sel (selection) tag
  }
  else {
    $data = $DB::window->retrieve_text_expr($x, $y) ;
  }

  if( !$data ) {
    $self->{'balloon_expr'} = "" ;
    return 0 ; 
  }
  
  return 0 if ($data eq $self->{'balloon_expr'}) ; # nevermind if it's the same expression

  $self->{'event'} = 'balloon_eval' ;
  $self->{'balloon_expr'} = $data ;

  return 1 ; # ballon will be canceled and a new one put up(maybe)
} # end of balloon_motion

sub retrieve_text_expr {
  my($self, $x, $y) = @_ ;
  my $txt = $self->{'text'} ;

  my $coord = "\@$x,$y" ;

  my($idx, $col, $data, $offset) ;

  ($col, $idx) = line_number_from_coord($txt, $coord) ;

  $offset = $Devel::ptkdb::linenumber_length + 1 ; # line number text + 1 space

  return undef if $col < $offset ; # no posting

  $col -= $offset ;

  local(*dbline) = $main::{'_<' . $self->{current_file}} ;   

  return undef if( !defined $dbline[$idx] || $dbline[$idx] == 0 ) ; # no executable text, no real variable(?)
  
  $data = $dbline[$idx] ;
  
  # if we're sitting over white space, leave
  my $len = length $data ;
  return unless $data && $col && $len > 0 ;

  return if substr($data, $col, 1) =~ /\s/ ;

  # walk backwards till we find some whitespace

  $col = $len if $len < $col ;
  while( --$col >= 0 ) {
    last if  substr($data, $col, 1) =~ /[\s\$\@\%]/ ;
  }

  substr($data, $col) =~ /^([\$\@\%][a-zA-Z0-9_]+)/ ;

  return $1 ;
}

#
# after DB::eval get's us a result
#
sub code_motion_eval {
  my ($self, @result) = @_ ;
  my $str ;

  if( exists $self->{'balloon_dumper'} ) {

    my $d = $self->{'balloon_dumper'} ;

    $d->Reset() ;
    $d->Values( [ $#result == 0 ? @result : \@result ] ) ;      

                  if( $d->can('Dumpxs') ) {
                    $str = $d->Dumpxs() ;
                  }
                  else {
                    $str = $d->Dump() ;
                  }

                  chomp($str) ;
                }
                else {
                  $str = "@result" ;
                }

                #
                # Cut the string down to 1024 characters to keep from
                # overloading the balloon window
                #
                
                $self->{'expr_ballon_msg'} = "$self->{'balloon_expr'} = " . substr $str, 0, 1024 ;
              } # end of code motion eval

#
# Subroutine called when we enter DB::DB()
# In other words when the target script 'stops'
# in the Debugger
#
sub EnterActions {
  my($self) = @_ ;

#  $self->{'main_window'}->Unbusy() ;

} # end of EnterActions

#
# Subroutine called when we return from DB::DB()
# When the target script resumes.  
#
sub LeaveActions {
  my($self) = @_ ;
  
  #  $self->{'main_window'}->Busy() ;
} # end of LeaveActions


sub BEGIN {
 $Devel::ptkdb::scriptName = $0 ;
 @Devel::ptkdb::script_args = @ARGV ; # copy args

}

##
## Save the ptkdb state file and restart the debugger
##
sub DoRestart {
  my($fname) ;

  $fname = $ENV{'TMP'} || $ENV{'TMPDIR'} || $ENV{'TMP_DIR'} || $ENV{'TEMP'} || $ENV{'HOME'} ;
  $fname .= '/' if $fname ;
  $fname = "" unless $fname ;

  $fname .= "ptkdb_restart_state$$" ;

  # print "saving temp state file $fname\n" ;
  
  &DB::save_state_file($fname) ;

  $ENV{'PTKDB_RESTART_STATE_FILE'} = $fname ;

  ##
  ## build up the command to do the restart
  ##

  $fname = "perl -w -d:ptkdb $Devel::ptkdb::scriptName @Devel::ptkdb::script_args" ;

  # print "$$ doing a restart with $fname\n" ;

  exec $fname ;

} # end of DoRestart

##
## Enables/Disables the feature where we stop
## if we've encountered a perl warning such as:
## "Use of uninitialized value at undef_warn.pl line N"
##

sub stop_on_warning_cb {
  &$DB::ptkdb::warn_sig_save() if $DB::ptkdb::warn_sig_save ; # call any previously registered warning
 $DB::window->DoAlert(@_) ;
 $DB::single = 1 ; # forces debugger to stop next time
}

sub set_stop_on_warning {

  if( $DB::ptkdb::stop_on_warning ) {
    
    return if $DB::ptkdb::warn_sig_save == \&stop_on_warning_cb ; # prevents recursion

    $DB::ptkdb::warn_sig_save = $SIG{'__WARN__'} if $SIG{'__WARN__'} ;
    $SIG{'__WARN__'} = \&stop_on_warning_cb ;
     }
  else {
    ##
    ## Restore any previous warning signal
    ##
    local($^W) = 0 ;
    $SIG{'__WARN__'} = $DB::ptkdb::warn_sig_save ;
  }
} # end of set_stop_on_warning

1 ; # end of Devel::ptkdb

package DB ;

use vars '$VERSION', '$header' ;

$VERSION = '1.1091' ;
$header = "ptkdb.pm version $DB::VERSION";
$DB::window->{current_file} = "" ;

#
# Here's the clue...
# eval only seems to eval the context of
# the executing script while in the DB
# package.  When we had updateExprs in the Devel::ptkdb
# package eval would turn up an undef result.
#

sub updateExprs {
  my ($package) = @_ ;
  #
  # Update expressions
  # 
 $DB::window->deleteAllExprs() ;
  my ($expr, @result);

  foreach $expr ( @{$DB::window->{'expr_list'}} ) {
    next if length $expr == 0 ;

    @result = &DB::dbeval($package, $expr->{'expr'}) ;

    if(  @result == 1 ) {
      $DB::window->insertExpr([ $result[0] ], $DB::window->{'data_list'}, $result[0], $expr->{'expr'}, $expr->{'depth'}) ;
      }
    else {
      $DB::window->insertExpr([ \@result ], $DB::window->{'data_list'}, \@result, $expr->{'expr'}, $expr->{'depth'}) ;
      }
  }

} # end of updateExprs

no strict ; # turning strict off (shame shame) because we keep getting errrs for the local(*dbline)

#
# returns true if line is breakable
#
use Carp ;
sub checkdbline($$) { 
  my ($fname, $lineno) = @_ ;

  return 0 unless $fname; # we're getting an undef here on 'Restart...'

  local($^W) = 0 ; # spares us warnings under -w
  local(*dbline) = $main::{'_<' . $fname} ;

  my $flag = $dbline[$lineno] != 0 ;

  return $flag;
  
} # end of checkdbline

#
# sets a breakpoint 'through' a magic 
# variable that perl is able to interpert
#
sub setdbline($$$) {
  my ($fname, $lineno, $value) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};

  $dbline{$lineno} = $value ;
} # end of setdbline

sub getdbline($$) {
  my ($fname, $lineno) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};
  return $dbline{$lineno} ;
} # end of getdbline

sub getdbtextline {
  my ($fname, $lineno) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};
  return $dbline[$lineno] ;
} # end of getdbline


sub cleardbline($$;&) {
  my ($fname, $lineno, $clearsub) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};
  my $value ; # just in case we want it for something

  $value = $dbline{$lineno} ;
  delete $dbline{$lineno} ;
  &$clearsub($value) if $value && $clearsub ;

  return $value ;
} # end of cleardbline

sub clearalldblines(;&) {
  my ($clearsub) = @_ ;
  my ($key, $value, $brkPt, $dbkey) ;
  local(*dbline) ;

  while ( ($key, $value) = each %main:: )  { # key loop
    next unless $key =~ /^_</ ;
    *dbline = $value ;

    foreach $dbkey (keys %dbline) {
      $brkPt = $dbline{$dbkey} ;
      delete $dbline{$dbkey} ;
      next unless $brkPt && $clearSub ;
      &$clearsub($brkPt) ; # if specificed, call the sub routine to clear the breakpoint
    }

  } # end of key loop

} # end of clearalldblines

sub getdblineindexes {
  my ($fname) = @_ ;
  local(*dbline) = $main::{'_<' . $fname} ;
  return keys %dbline ;
} # end of getdblineindexes

sub getbreakpoints {
  my (@fnames) = @_ ;
  my ($fname, @retList) ;

  foreach $fname (@fnames) {
    next unless  $main::{'_<' . $fname} ;
    local(*dbline) = $main::{'_<' . $fname} ;    
    push @retList, values %dbline ;
  }
  return @retList ;
} # end of getbreakpoints

#
# Construct a hash of the files
# that have breakpoints to save
#
sub breakpoints_to_save {
  my ($file, @breaks, $brkPt, $svBrkPt, $list) ;
  my ($brkList) ;

  $brkList = {} ;

  foreach $file ( keys %main:: ) { # file loop
    next unless $file =~ /^_</ && exists $main::{$file} ;
    local(*dbline) = $main::{$file} ;

    next unless @breaks = values %dbline ;
    $list = [] ;
    foreach $brkPt ( @breaks ) {
      
      $svBrkPt = { %$brkPt } ; # make a copy of it's data
      
      push @$list, $svBrkPt ;

    } # end of breakpoint loop

    $brkList->{$file} = $list ;

  } # end of file loop

  return $brkList ;

} # end of breakpoints_to_save

#
# When we restore breakpoints from a state file
# they've often 'moved' because the file
# has been editted.  
#
# We search for the line starting with the original line number,
# then we walk it back 20 lines, then with line right after the
# orginal line number and walk forward 20 lines.  
#
# NOTE: dbline is expected to be 'local'
# when called
#
sub fix_breakpoints {
  my(@brkPts) = @_ ;
  my($startLine, $endLine, $nLines, $brkPt) ;
  my (@retList) ;
  local($^W) = 0 ;

  $nLines = scalar @dbline ;

  foreach $brkPt (@brkPts) {

    $startLine = $brkPt->{'line'} > 20 ? $brkPt->{'line'} - 20 : 0 ;
    $endLine   = $brkPt->{'line'} < $nLines - 20 ? $brkPt->{'line'} + 20 : $nLines ;

    for( (reverse $startLine..$brkPt->{'line'}), $brkPt->{'line'} + 1 .. $endLine ) {
      next unless $brkPt->{'text'} eq $dbline[$_] ;
      $brkPt->{'line'} = $_ ;
      push @retList, $brkPt ;
      last ;
    }
  } # end of breakpoint list
  
  return @retList ;

} # end of fix_breakpoints

#
# Restore breakpoints saved above
#
sub restore_breakpoints_from_save {
  my ($brkList) = @_ ;
  my ($offset, $key, $list, $brkPt, @newList) ;
  
  while ( ($key, $list) = each %$brkList ) { # reinsert loop
    next unless exists $main::{$key} ;
    local(*dbline) = $main::{$key} ;

    $offset = 0 ;
    $offset = 1 if $dbline[1] =~ /use\s+.*Devel::_?ptkdb/ ;

    @newList = fix_breakpoints(@$list) ;
    
    foreach $brkPt ( @newList ) {
      if( !&DB::checkdbline($key, $brkPt->{'line'} + $offset) ) {
        print "Breakpoint $key:$brkPt->{'line'} in config file is not breakable.\n" ;
        next ;
      }
      $dbline{$brkPt->{'line'}} = { %$brkPt } ; # make a fresh copy
    }
  } # end of reinsert loop
  
} # end of restore_breakpoints_from_save ;

use strict ;

sub dbint_handler {
  my($sigName) = @_ ;
 $DB::single = 1 ;
  print "signalled\n" ;
} # end of dbint_handler

#
# Do first time initialization at the startup
# of DB::DB
#
sub Initialize {
  my ($fName) = @_ ;
  return if $DB::ptkdb::isInitialized ;
 $DB::ptkdb::isInitialized = 1 ;

 $DB::window = new Devel::ptkdb ;

 $DB::window->do_user_init_files() ;


 $DB::dbint_handler_save = $SIG{'INT'} unless $DB::sigint_disable ; # saves the old handler
  $SIG{'INT'} = "DB::dbint_handler" unless $DB::sigint_disable ;
  
  # Save the file name we started up with
 $DB::startupFname = $fName ;

  # Check for a 'restart' file

  if( $ENV{'PTKDB_RESTART_STATE_FILE'} && $Devel::ptkdb::DataDumperAvailable && -e $ENV{'PTKDB_RESTART_STATE_FILE'} ) {
    ##
    ## Restore expressions and breakpoints in state file
    ##
    $DB::window->restoreStateFile($ENV{'PTKDB_RESTART_STATE_FILE'}) ;
    unlink $ENV{'PTKDB_RESTART_STATE_FILE'} ; # delete state file

    # print "restoring state from $ENV{'PTKDB_RESTART_STATE_FILE'}\n" ;

    $ENV{'PTKDB_RESTART_STATE_FILE'} = "" ; # clear entry
  }
  else {
    &DB::restoreState($fName) if $Devel::ptkdb::DataDumperAvailable ;
  }

} # end of Initialize 

sub restoreState {
  my($fName) = @_ ;
  my ($stateFile, $files, $expr_list, $eval_saved_text, $main_win_geometry, $restoreName) ;

  $stateFile = makeFileSaveName($fName) ;
  
  if( -e $stateFile && -r $stateFile ) {
    ($files, $expr_list, $eval_saved_text, $main_win_geometry) = $DB::window->get_state($stateFile) ;
    &DB::restore_breakpoints_from_save($files) ;
  $DB::window->{'expr_list'} = $expr_list if defined $expr_list ;
  $DB::window->{eval_saved_text} = $eval_saved_text ;
    
    if ( $main_win_geometry ) { 
      # restore the height and width of the window
    $DB::window->{main_window}->geometry($main_win_geometry) ;
    }
  }

} # end of Restore State

sub makeFileSaveName {
  my ($fName) = @_ ;
  my $saveName = $fName ;

  if(  $saveName =~ /.p[lm]$/ ) {
    $saveName =~ s/.pl$/.ptkdb/ ;
  }
  else {
    $saveName .= ".ptkdb" ;
  }

  return $saveName ;
} # end of makeFileSaveName

sub save_state_file {
  my($fname) = @_ ;
  my($files, $d, $saveStr) ;
      
  $files = &DB::breakpoints_to_save() ;
  
  $d = Data::Dumper->new( [ $files, $DB::window->{'expr_list'}, "" ], 
                          [ "files", "expr_list",  "eval_saved_text" ] ) ;
    
  $d->Purity(1) ;
  if( Data::Dumper->can('Dumpxs') ) {
    $saveStr = $d->Dumpxs() ;
  } else {
    $saveStr = $d->Dump() ;
  }    
  
  local(*F) ;
  open F, ">$fname" || die "Couldn't open file $fname" ;
  
  print F $saveStr || die "Couldn't write file" ;
    
  close F ;
} # end of save_state_file

sub SaveState {
  my($name_in) = @_ ;
  my ($top, $entry, $okayBtn, $win) ;
  my ($fname, $saveSub, $cancelSub, $saveName, $eval_saved_text, $d) ;    
  my ($files, $main_win_geometry);
  #
  # Create our default name
  #
  $win = $DB::window ;
  
  #
  # Extract the height and width of our window
  #
  $main_win_geometry = $win->{main_window}->geometry ;

  if ( defined $win->{save_box} ) {
    $win->{save_box}->raise ;
    $win->{save_box}->focus ;
    return ;
  }

  $saveName = $name_in || makeFileSaveName($DB::startupFname) ;
  
  

  $saveSub = sub {
    $win->{'event'} = 'null' ;

    my $saveStr ;

    delete $win->{save_box} ;

    if( exists $win->{eval_window} ) {
      $eval_saved_text = $win->{eval_text}->get('0.0', 'end') ;
    }
    else {
      $eval_saved_text =  $win->{eval_saved_text} ;
    }
    
    $files = &DB::breakpoints_to_save() ;

    $d = Data::Dumper->new( [ $files, $win->{'expr_list'}, $eval_saved_text,   $main_win_geometry ], 
                            [ "files", "expr_list",        "eval_saved_text",  "main_win_geometry"] ) ;
    
    $d->Purity(1) ;
    if( Data::Dumper->can('Dumpxs') ) {
      $saveStr = $d->Dumpxs() ;
    } else {
      $saveStr = $d->Dump() ;
    }    
    
    local(*F) ;
    eval {
      open F, ">$saveName" || die "Couldn't open file $saveName" ;
      
      print F $saveStr || die "Couldn't write file" ;
      
      close F ;
    } ;
    $win->DoAlert($@) if $@ ;
  } ; # end of save sub

  $cancelSub = sub {
    delete $win->{'save_box'}
  } ; # end of cancel sub
  
  #
  # Create a dialog
  #
  
  $win->{'save_box'} = $win->simplePromptBox("Save Config?", $saveName, $saveSub, $cancelSub) ;

} # end of SaveState

sub RestoreState {
  my ($top, $restoreSub) ;

  $restoreSub = sub {
  $DB::window->restoreStateFile($Devel::ptkdb::promptString) ;
  } ;

  $top = $DB::window->simplePromptBox("Restore Config?", makeFileSaveName($DB::startupFname), $restoreSub) ;

} # end of RestoreState

sub SetStepOverBreakPoint {
  my ($offset) = @_ ;
 $DB::step_over_depth = $DB::subroutine_depth + ($offset ? $offset : 0) ;
} # end of SetStepOverBreakPoint

#
# NOTE:   It may be logical and somewhat more economical
#         lines of codewise to set $DB::step_over_depth_saved 
#         when we enter the subroutine, but this gets called
#         for EVERY callable line of code in a program that
#         is being debugged, so we try to save every line of
#         execution that we can.
#
sub isBreakPoint {
  my ($fname, $line, $package) = @_ ;
  my ($brkPt) ;

  if ( $DB::single && ($DB::step_over_depth < $DB::subroutine_depth) && ($DB::step_over_depth > 0) && !$DB::on) {
  $DB::single = 0  ;
    return 0 ;
  }
  #
  # doing a step over/in
  # 

  if( $DB::single || $DB::signal ) {
  $DB::single = 0 ;
  $DB::signal = 0 ;
  $DB::subroutine_depth = $DB::subroutine_depth ;
    return 1 ;
  }
  #
  # 1st Check to see if there is even a breakpoint there.  
  # 2nd If there is a breakpoint check to see if it's check box control is 'on'
  # 3rd If there is any kind of expression, evaluate it and see if it's true.  
  #
  $brkPt = &DB::getdbline($fname, $line) ;

  return 0 if( !$brkPt || !$brkPt->{'value'} || !breakPointEvalExpr($brkPt, $package) ) ;

  &DB::cleardbline($fname, $line) if( $brkPt->{'type'} eq 'temp' ) ;

 $DB::subroutine_depth = $DB::subroutine_depth ;

  return  1 ;
} # end of isBreakPoint

#
# Check the breakpoint expression to see if it
# is true.  
#
sub breakPointEvalExpr {
  my ($brkPt, $package) = @_ ;
  my (@result) ;

  return 1 unless $brkPt->{expr} ; # return if there is no expression

  no strict ;

  @result = &DB::dbeval($package, $brkPt->{'expr'}) ;

  use strict ;
  
 $DB::window->DoAlert($@) if $@ ;

  return $result[0] or @result ; # we could have a case where the 1st element is undefined
  # but subsequent elements are defined

} # end of breakPointEvalExpr

#
# Evaluate the given expression, return the result.
# MUST BE CALLED from within DB::DB in order for it
# to properly interpret the vars
#
sub dbeval {
  my($ptkdb__package, $ptkdb__expr) = @_ ;
  my(@ptkdb__result, $ptkdb__str) ;
  my(@ptkdb_args) ;
  local($^W) = 0 ; # temporarily turn off warnings
  
  no strict ;
  #
  # This substitution is done so that 
  # we return HASH, as opposed to an ARRAY.
  # An expression of %hash results in a
  # list of key/value pairs.  
  #

  $ptkdb__expr =~ s/^\s*%/\\%/o ;

  @_ = @DB::saved_args ; # replace @_ arg array with what we came in with

  @ptkdb__result = eval <<__EVAL__ ;


  \$\@ = \$DB::save_err ;

  package $ptkdb__package ;

  $ptkdb__expr ;

__EVAL__

      @ptkdb__result = ("ERROR ($@)") if $@ ;

  use strict ;

  return @ptkdb__result ;
} # end of dbeval

#
# Call back we give to our 'quit' button
# and binding to the WM_DELETE_WINDOW protocol
# to quit the debugger.  
#
sub dbexit {
  exit ;
} # end of dbexit

#
# This is the primary entry point for the debugger.  When a perl program
# is parsed with the -d(in our case -d:ptkdb) option set the parser will
# insert a call to DB::DB in front of every excecutable statement.  
# 
# Refs:  Progamming Perl 2nd Edition, Larry Wall, O'Reilly & Associates, Chapter 8
#


##
## Since perl 5.8.0 we need to predeclare the sub DB{} at the start of the 
## package or else the compilation fails.  We need to disable warnings though
## since in 5.6.x we get warnings on the sub DB begin redeclared.  Using
## local($^W) = 0 will leave warnings disabled for the rest of the compile
## and we don't want that.
##
my($saveW) ;
sub BEGIN {
  $saveW = $^W ;
  $^W = 0 ;
}

no strict ;
sub DB {
  @DB::saved_args = @_ ; # save arg context
 $DB::save_err = $@ ; # save value of $@
   my ($package, $filename, $line) = caller ;
   my ($stop, $cnt) ;

    $^W = $saveW ;
   unless( $DB::ptkdb::isInitialized ) {
     return if( $filename ne $0 ) ; # not in our target file
     &DB::Initialize($filename) ;
   }

   if (!isBreakPoint($filename, $line, $package) ) {
   $DB::single = 0 ;
     $@ = $DB::save_err ;
     return ;
   }

   if ( !$DB::window ) { # not setup yet
     $@ = $DB::save_err ;
     return ;
   }

 $DB::window->setup_main_window() unless $DB::window->{'main_window'} ;

 $DB::window->EnterActions() ; 

   my ($saveP) ;
   $saveP = $^P ;
   $^P = 0 ;

 $DB::on = 1 ;

#
# The user can specify this variable in one of the startup files,
# this will make the debugger run right after startup without
# the user having to press the 'run' button.  
#
   if( $DB::no_stop_at_start ) {
   $DB::no_stop_at_start = 0 ;
   $DB::on = 0 ;
     $@ = $DB::save_err ;
     return ;
   }

   if( !$DB::sigint_disable ) {
     $SIG{'INT'} = $DB::dbint_handler_save if $DB::dbint_handler_save ; # restore original signal handler
     $SIG{'INT'} = "DB::dbexit" unless   $DB::dbint_handler_save ;
   }

  #$DB::window->{main_window}->raise() ; # bring us to the top make sure OUR event loop runs
 $DB::window->{main_window}->focus() ;

 $DB::window->set_file($filename, $line) ;
   #
   # Refresh the exprs to see if anything has changed
   #
   updateExprs($package) ;

   #
   # Update subs Page if necessary
   #
   $cnt = scalar keys %DB::sub ;
   if ( $cnt != $DB::window->{'subs_list_cnt'} && $DB::window->{'subs_page_activated'} ) {
     $DB::window->fill_subs_page() ;
     $DB::window->{'subs_list_cnt'} = $cnt ;
   }
   #
   # Update the subroutine stack menu
   #
 $DB::window->refresh_stack_menu() ;
   
 $DB::window->{run_flag} = 1 ;

   my ($evt, @result, $r) ;

   for( ; ; ) {
     #
     # we wait here for something to do
     #
     $evt = $DB::window->main_loop() ;

     last if( $evt eq 'step' ) ;

   $DB::single = 0 if ($evt eq 'run' )  ;

     if ($evt eq 'balloon_eval' ) {
     $DB::window->code_motion_eval(&DB::dbeval($package, $DB::window->{'balloon_expr'})) ;
       next ;
     }

     if ( $evt eq 'qexpr' ) {
       my $str ;
       @result = &DB::dbeval($package, $DB::window->{'qexpr'}) ;
     $DB::window->{'quick_entry'}->delete(0, 'end') ; # clear old text
       if (exists $DB::window->{'quick_dumper'}) {
       $DB::window->{'quick_dumper'}->Reset() ;
       $DB::window->{'quick_dumper'}->Values( [ $#result == 0 ? @result : \@result ] ) ;
                                                if( $DB::window->{'quick_dumper'}->can('Dumpxs') ) {
                                                  $str = $DB::window->{'quick_dumper'}->Dumpxs() ;
                                                }
                                                else {
                                                  $str = $DB::window->{'quick_dumper'}->Dump() ;
                                                } 
                                              }
                                              else {
                                                $str = "@result" ;
                                              }
                                            $DB::window->{'quick_entry'}->insert(0, $str) ; #enter the text
                                            $DB::window->{'quick_entry'}->selectionRange(0, 'end') ; # select it
                                              $evt = 'update' ; # force an update on the expressions
                                            }

         if( $evt eq 'expr' ) {
           #
           # Append the new expression to the list
           # but first check to make sure that we don't
           # already have it.
           #
           
           if ( grep $_->{'expr'} eq $DB::window->{'expr'}, @{$DB::window->{'expr_list'}} ) {
           $DB::window->DoAlert("$DB::window->{'expr'} is already listed") ;
             next ;
           }

           @result = &DB::dbeval($package, $DB::window->{expr}) ;

           if(  @result == 1 ) {
             $r = $DB::window->insertExpr([ $result[0] ], $DB::window->{'data_list'}, $result[0], $DB::window->{'expr'}, $Devel::ptkdb::expr_depth) ;
           }
           else {
             $r = $DB::window->insertExpr([ \@result ], $DB::window->{'data_list'}, \@result, $DB::window->{'expr'}, $Devel::ptkdb::expr_depth)  ;
           }
           
           #
           # $r will be 1 if the expression was added succesfully, 0 if not,
           # and it if wasn't added sucessfully it won't be reevalled the 
           # next time through.  
           #
           push @{$DB::window->{'expr_list'}}, { 'expr' => $DB::window->{'expr'}, 'depth' => $Devel::ptkdb::expr_depth } if $r ;
           
           next ;
         }
         if( $evt eq 'update' ) {
           updateExprs($package) ;
           next ;
         }
         if( $evt eq 'reeval' ) {
           #
           # Reevaluate the contents of the expression eval window
           #
           my $txt = $DB::window->{'eval_text'}->get('0.0', 'end') ;
           my @result = &DB::dbeval($package, $txt) ;

         $DB::window->updateEvalWindow(@result) ;

           next ;
         }
         last ;
       }
       $^P = $saveP ;
       $SIG{'INT'} = "DB::dbint_handler"   unless $DB::sigint_disable ; # set our signal handler

     $DB::window->LeaveActions() ;

       $@ = $DB::save_err ;
     $DB::on = 0 ;
     } # end of DB

##
## in this case we do not use local($^W) since we would like warnings
## to be issued past this point, and the localized copy of $^W will not
## go out of scope until  the end of compilation
##
##

#
# This is another place where we'll try and keep the
# code as 'lite' as possible to prevent the debugger
# from slowing down the user's application
#
# When a perl program is parsed with the -d(in our case a -d:ptkdb) option
# the parser will route all subroutine calls through here, setting $DB::sub
# to the name of the subroutine to be called, leaving it to the debugger to
# make the actual subroutine call and do any pre or post processing it may
# need to do.  In our case we take the opportunity to track the depth of the call
# stack so that we can update our 'Stack' menu when we stop.  
#
# Refs:  Progamming Perl 2nd Edition, Larry Wall, O'Reilly & Associates, Chapter 8
#
#
     sub sub {
       my ($result, @result) ;
#
# See NOTES(1)
#
			 $DB::subroutine_depth += 1 unless $DB::on ;
       $DB::single = 0 if ( ($DB::step_over_depth < $DB::subroutine_depth) && ($DB::step_over_depth >= 0) && !$DB::on) ;

       if( wantarray ) {
				 #
				 # array context
				 #
         no strict ; # otherwise perl gripes about calling the sub by the reference
         @result = &$DB::sub ; # call the subroutine by name
         use strict ;

       $DB::subroutine_depth -= 1 unless $DB::on ;
       $DB::single = 1 if ($DB::step_over_depth >= $DB::subroutine_depth && !$DB::on) ;  
         return @result ; 
       }
       elsif(defined wantarray) {

				 #
				 # scalar context
				 #
         no strict ; 
         $result = &$DB::sub ; 
         use strict ;

       $DB::subroutine_depth -= 1 unless $DB::on ;
       $DB::single = 1 if ($DB::step_over_depth >= $DB::subroutine_depth  && !$DB::on) ;
         return $result ; 
       } else {
				 #
				 # void context
				 #
				 
         no strict ; 
         &$DB::sub ; 
         use strict ;

       $DB::subroutine_depth -= 1 unless $DB::on ;
       $DB::single = 1 if ($DB::step_over_depth >= $DB::subroutine_depth && !$DB::on) ;
         return $result ; 

				 return ;
       }
       
     } # end of sub 

1 ; # return true value

# ptkdb.pm,v
# Revision 1.15  2004/03/31 02:08:40  aepage
# fixes for various lacks of backwards compatiblity in Tk804
# Added a 'bug report' item to the File Menu.
#
# Revision 1.14  2003/11/20 01:59:40  aepage
# version fix
#
# Revision 1.12  2003/11/20 01:46:45  aepage
# Hex Dumper and correction of some parameters for Tk804.025_beta6
#
# Revision 1.11  2003/06/26 13:42:49  aepage
# fix for chars at the end of win32 platforms.
#
# Revision 1.10  2003/05/12 14:38:34  aepage
# win32 pushback
#
# Revision 1.9  2003/05/12 13:46:46  aepage
# optmization of win32 line fixing
#
# Revision 1.8  2003/05/11 23:42:20  aepage
# fix to remove stray win32 chars
#
# Revision 1.7  2003/05/11 23:15:26  aepage
# email address changes, fixes for perl 5.8.0
#
# Revision 1.6  2002/11/28 19:17:43  aepage
# Changed many options to widgets and pack from bareword or 'bareword'
# to -bareword to support Tk804.024(Devel).
#
# Revision 1.5  2002/11/25 23:47:03  aepage
# A perl debugger package is required to define a subroutine name 'sub'.
# This routine is a 'proxy' for handling subroutine calls and allows the
# debugger pacakage to track subroutine depth so that it can implement
# 'step over', 'step in' and 'return' functionality.  It must also
# handle the same context as the proxied routine; it must return a
# scalar where a scalar was being expected, an array where an array is
# being expected and a void where a void was being expected.  Ptkdb was
# not handling the case for void.  99.9% of the time this will have no
# ill effects although it is being handled incorrectly. Ref Programming
# Perl 3rd Edition pg 827
#
# Revision 1.4  2002/10/24 17:07:10  aepage
# fix for warning for undefined value assigend to typeglob during restart
#
# Revision 1.3  2002/10/20 23:49:51  aepage
#
# changed email address to aepage@ptkdb.sourceforge.net
# 
# localized $^W in dbeval
# 
# fix for instances where there is no code in a package.
# 
# Initialized $self->{'subs_list_cnt'} in the new constructor to 0 to
# prevent warnings with -w.
#
