
sub display_usage {

    my($version) = @ARG;

    # Open a Toplevel widget and insert some fanciful help text.

    if (Exists($USAGE)) {
	$USAGE->deiconify;
	return;
    }

    $USAGE = $genPerlTk_mw->Toplevel;
    $USAGE->title('Usage');
    $USAGE->iconname('Usage');

    $uhf = $USAGE->Frame;
    $uht = $uhf->Text(qw(-relief raised -bd 1 -setgrid true -height 36 
        -wrap word),
    );
    $uhs = $uhf->Scrollbar(qw(-relief flat), -command => [$uht => 'yview']);
    $uht->configure(-yscrollcommand => [$uhs => 'set']);
    $uht->pack(qw(-side left -expand yes -fill both));
    $uhs->pack(qw(-side right -fill y));

    $uhm = $USAGE->Frame(qw/-borderwidth 2 -relief raised/);
    $uhm->pack(qw(-side top -fill x -expand yes));
    $uhmf = $uhm->Menubutton(qw(-text File -underline 0 -relief raised));
    $uhmf->pack(qw(-side left));
    $uhmf->command(
        -label     => 'Close',
        -command   => [$USAGE => 'withdraw'],
        -underline => 0,
    );
    $uhf->pack(qw(-side left -expand yes -fill both));

    $uhl = $USAGE->Frame(-borderwidth => 5);
    $uhl->pack(qw( -side right -fill y));
    $uhl_label = $uhl->Label(-text => 'Table of Contents');
    $uhl_label->pack(qw(-side top -fill x));
    $uhll = $uhl->Listbox(
        qw(-relief sunken  -setgrid 1),
	-selectbackground => $genPerlTk_highlight,
    );
    $uhll->pack(qw(-side left -fill y));
    $uhll->bind('<Double-1>' => [sub {
        my($l, $uht) = @ARG;
        my $mark = $l->get('active');
        $mark =~ s/ /_/g;
        $uht->yview("mark_usage_help_${mark}");
    }, $uht]);
    $uhl->AddScrollbars($uhll);
    $uhl->configure(-scrollbars => 'e');

    $uhll->insert('end', 'Introduction');
    $uhll->insert('end', 'Quick Start');
    $uhll->insert('end', 'Unix Command Syntax');
    $uhll->insert('end', '  The Problem');
    $uhll->insert('end', '  A Solution');
    $uhll->insert('end', 'Parameter Types');
    $uhll->insert('end', '  String');
    $uhll->insert('end', '  Integer');
    $uhll->insert('end', '  Real');
    $uhll->insert('end', '  File');
    $uhll->insert('end', '  Key');
    $uhll->insert('end', '  Boolean');
    $uhll->insert('end', '  Switch');
    $uhll->insert('end', '  Name');
    $uhll->insert('end', '  Application');
    $uhll->insert('end', 'Lists');
    $uhll->insert('end', 'The `Do It\' Button');
    $uhll->insert('end', 'Windows');
    $uhll->insert('end', '  Main Window');
    $uhll->insert('end', '    Main File Menu');
    $uhll->insert('end', '    Main Edit Menu');
    $uhll->insert('end', '    Main Help Menu');
    $uhll->insert('end', '  Output Window');
    $uhll->insert('end', '    Output File Menu');
    $uhll->insert('end', '  Help Window');
    $uhll->insert('end', '    Help File Menu');
    $uhll->insert('end', 'Revision History');
    $uhll->insert('end', 'Credits');

    $uht->tag('configure', qw(bold -font -Adobe-Courier-Bold-O-Normal-*-120-*));
    $uht->tag('configure', qw(big -font -Adobe-Courier-Bold-R-Normal-*-140-*));
    $uht->tag('configure', qw(verybig -font -Adobe-Helvetica-Bold-R-Normal-*-240-*));
    if ($USAGE->depth > 1) {
	$uht->tag('configure', qw(color2 -foreground blue));
    } else {
	$uht->tag('configure', qw(color2 -background black -foreground white));
    }
    $uht->tag('configure', qw(bgstipple -background black -borderwidth 0
        -bgstipple gray25));
    $uht->tag('configure', qw(fgstipple -fgstipple gray50));
    $uht->tag('configure', qw(underline -underline on));

    ####### New section #######

    $uht->insert('end', '

                       Introduction

', 'big');
    my $start;
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Introduction', "$start.0");
    $uht->insert('end', 'You are interacting with an X11 Perl/Tk Graphical User Interface for a typical Unix program.  Although unimportant to you, this program uses as its command line interface the function ');
    $uht->insert('end', "Evaluate Parameters", 'color2');
    $uht->insert('end', ', which makes the creation of this GUI possible.  By filling out a form and pushing buttons you can easily run this Unix program, avoiding most if not all of the pitfalls that Unix throws at you!

This program is brought to you courtesy of ');
    $uht->insert('end', 'generate_PerlTk_program', 'color2');
    $uht->insert('end', ', ');
    $uht->insert('end', 'Perl', 'color2');
    $uht->insert('end', ', ',);
    $uht->insert('end', 'Tk', 'color2');
    $uht->insert('end', ' and '),
    $uht->insert('end', 'Evaluate Parameters', 'color2');
    $uht->insert('end', '.');

####### New section #######

    $uht->insert('end', '

                       Quick Start

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Quick_Start', "$start.0");
    $uht->insert('end', 'In 25 words or less:  fill in the blanks, push the required buttons and click on `Do It\'.  That\'s really all there is to it.

Some parameters ');
    $uht->insert('end', 'require', 'bold');
    $uht->insert('end', ' a value:  for parameters with an Entry box the value `$REQUIRED\' is displayed; for parameters with Radio or Check buttons none of the buttons are highlighted, so you must click on at least one.

Scroll through the window containing the command\'s help text to see what information the programmer has provided for you.

If the parameter is a list you may enter multiple space-separated items.

At the bottom of the main window is a box that displays the Unix command.  As parameter values are entered you can watch the command update in realtime.

An output window opens to capture the command\'s standard output and standard error, which you can view, save to a file or send to a command pipeline.');

####### New section #######

    $uht->insert('end', '

                   Unix Command Syntax

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Unix_Command_Syntax', "$start.0");
    $uht->insert('end', 'Generally, Unix commands consist of cryptic command  line parameters whose meanings and functions are nearly impossible to determine.  Because there are no conventions in the Unix world for naming command line parameters and parsing the command line, the user interface changes from program to program.');

####### New section #######

    $uht->insert('end', '

                       The Problem

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___The_Problem', "$start.0");
    $uht->insert('end', 'For example, typical Unix programs expect either standalone switches or parameters, preceeded by a `-\',  with the value of non-switch parameters to follow immediately.  Sometimes an optional list of file names is expected:

        ');
    $uht->insert('end', 'cc', 'bold');
    $uht->insert('end', ' -O -o my_prog.exe -L/usr/local/lib -levap my_prog.c

Notice that some parameters like ');
    $uht->insert('end', '-o', 'bold');
    $uht->insert('end', ' must have a space between them and their value, but other parameters line ');
    $uht->insert('end', '-L', 'bold');
    $uht->insert('end', ' and ');
    $uht->insert('end', '-l', 'bold');
    $uht->insert('end', ' cannot have a space.

As another example take the ');
    $uht->insert('end', 'tar', 'bold');
    $uht->insert('end', ' command, where command line options are bundled together after the `-\' and values follow in a one-to-one correspondence:

        ');
    $uht->insert('end', 'tar', 'bold');
    $uht->insert('end', ' -cvf my_tar.tar *

Some Unix developers go so far as to dispense with the dash as a parameter indicator and disallow it entirely, as in the ');
    $uht->insert('end', 'ar', 'bold');
    $uht->insert('end', ' command:

	');
    $uht->insert('end', 'ar', 'bold');
    $uht->insert('end', ' rcv my_archive.a *.o

So as you can see, the only thing consistent about command line parsing in Unix is its inconsistency :-).

To further complicate matters there is no regularity in command usage information - some commands provide it and some do not.  If you\'re lucky enough to see usage information it always varies from program to program.');

####### New section #######

    $uht->insert('end', '

                        A Solution

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___A_Solution', "$start.0");
    $uht->insert('end', 'All these considerations spurred the developement of ');
    $uht->insert('end', 'Evaluate Parameters', 'color2');
    $uht->insert('end', ' for Unix.

There are C, Perl and Tcl implementations which provide for a simple and consistent user interface, type-check parameter values and provide three levels of command and parameter help.  Because there is so much consistency it was possible to write a new program called ');
    $uht->insert('end', 'generate_PerlTk_program', 'color2');
    $uht->insert('end', ' that can create a Graphical User Interface like this one for ');
    $uht->insert('end', 'any', 'bold');
    $uht->insert('end', ' program using ');
    $uht->insert('end', 'Evaluate Parameters', 'color2');
    $uht->insert('end', ' to parse its command line.  What you are seeing and using is a GUI front-end that was generated ');
    $uht->insert('end', 'automatically', 'bold');
    $uht->insert('end', ' by ');
    $uht->insert('end', 'generate_PerlTk_program', 'color2');
    $uht->insert('end',  '!');

####### New section #######

    $uht->insert('end', '

                       Parameter Types

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Parameter_Types', "$start.0");
    $uht->insert('end', 'All values that you enter for command line parameters must be of the appropriate type.  For instance, if a parameter expects an integer you must supply a positive or negative number.  The following types are supported:

	');
    $uht->insert('end', 's', [qw(underline color2)]);
    $uht->insert('end', 'tring ');
    $uht->insert('end', 'i', [qw(underline color2)]);
    $uht->insert('end', 'nteger ');
    $uht->insert('end', 'r', [qw(underline color2)]);
    $uht->insert('end', 'eal ');
    $uht->insert('end', 'f', [qw(underline color2)]);
    $uht->insert('end', 'ile ');
    $uht->insert('end', 'k', [qw(underline color2)]);
    $uht->insert('end', 'ey ');
    $uht->insert('end', 'b', [qw(underline color2)]);
    $uht->insert('end', 'oolean ');
    $uht->insert('end', 'sw', [qw(underline color2)]);
    $uht->insert('end', 'itch ');
    $uht->insert('end', 'n', [qw(underline color2)]);
    $uht->insert('end', 'ame ');
    $uht->insert('end', 'a', [qw(underline color2)]);
    $uht->insert('end', 'pplication');
    $uht->insert('end', '

Do you really care what type of value a command line parameter expects?  Well, yes!  If the program wants a number and you give it letters you will be yelled at.

If you look at the main window, to the right of the names of the command line parameters and to the left of where you specify their values, you see some coded information in parentheses, like:

	(s )
	(i )
	(r )
	(sw)

This one-letter code corresponds to the first letter of the parameter\'s type,
except for ');
    $uht->insert('end', 'sw', [qw(underline color2)]);
    $uht->insert('end', 'itch');
    $uht->insert('end', ' parameters which use the first two letters to distinguish them from ');
    $uht->insert('end', 's', [qw(underline color2)]);
    $uht->insert('end', 'tring parameters.

If you see the letter `l\' following a type code you know that the parameter can be a list, which means that multiple value can be specified.  For more details on lists, see the section ');
    $uht->insert('end', 'Lists', 'bold');
    $uht->insert('end', ' which follows.');

####### New section #######

    $uht->insert('end', '

                           String

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___String', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'string', 'bold');
    $uht->insert('end', ' parameter is a list of characters, which may include whitespace, enclosed in either single or double quotes.  You specify value(s) by typing in the Entry box.

	"Hello world!"
	\'Hello World!\'');

####### New section #######

    $uht->insert('end', '

                           Integer
  
', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Integer', "$start.0");
    $uht->insert('end', 'An ');
    $uht->insert('end', 'integer', 'bold');
    $uht->insert('end', ' parameter is a list of digts, with an optional leading sign.  You specify value(s) by typing in the Entry box.

	945
	-23');

####### New section #######

    $uht->insert('end', '

                            Real

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Real', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'real', 'bold');
    $uht->insert('end', ' parameter is a list of digits, with an optional leading sign, possibly a decimal point, and an optional trailing exponent.  You specify value(s) by typing in the Entry box.

	-0.345
	+1.1e-7');

####### New section #######

    $uht->insert('end', '

                            File

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___File', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'file', 'bold');
    $uht->insert('end', ' parameter is a Unix file name.  You specify value(s) by typing in the Entry box.

	my_file
	/home/lusol/.profile');

####### New section #######

    $uht->insert('end', '

                            Key

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Key', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'key', 'bold');
    $uht->insert('end', ' parameter can be given only certain value(s) that the programmer has allowed.  You specify value(s) by pushing a Radiobutton or, in the case of a list, one or more Checkbuttons.');

####### New section #######

    $uht->insert('end', '

                           Boolean

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Boolean', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'boolean', 'bold');
    $uht->insert('end', ' parameter can be in one of two states:  on or off.  You specify value(s) by pushing a Radiobutton or, in the case of a list, typing in the Entry box.

	TRUE or YES or ON or 1
	FALSE or NO or OFF or 0');

####### New section #######

    $uht->insert('end', '

                           Switch

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Switch', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'switch', 'bold');
    $uht->insert('end', ' parameter can be in one of two states:  on or off.  If the ');
    $uht->insert('end', 'switch', 'bold');
    $uht->insert('end', ' is specified on the command line it is 1, otherwise it is 0.  You specify a value by pushing a Radiobutton.

	-verbose');

####### New section #######

    $uht->insert('end', '

                            Name

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Name', "$start.0");
    $uht->insert('end', 'A ');
    $uht->insert('end', 'name', 'bold');
    $uht->insert('end', ' parameter is similar to a ');
    $uht->insert('end', 'string', 'bold');
    $uht->insert('end', ' except that embedded whitespace is not permitted, therefore bounding quotes are not required.  You specify value(s) by typing in the Entry box.

	NoQuotesRequired');

####### New section #######

    $uht->insert('end', '

                        Application

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Application', "$start.0");
    $uht->insert('end', 'An ');
    $uht->insert('end', 'application', 'bold');
    $uht->insert('end', ' parameter is special in that no type checking is performed. The interpretation of this parameter is application specific.  You will rarely see this parameter type.  You specify value(s) by typing in the Entry box.

	"A special type, application specific!"');

####### New section #######

    $uht->insert('end', '

                           Lists

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Lists', "$start.0");
    $uht->insert('end', 'Except for ');
    $uht->insert('end', 'switches', 'bold');
    $uht->insert('end', ', all parameter types can be lists, which simply means that multiple values can be supplied to the program.  You can tell if a parameter can take a list by inspecting the type-code field in the main window - the letter `l\' indicates a list parameter.

For most types you can simply enter your values separated by spaces, but don\'t forget to quote ');
    $uht->insert('end', 'strings', 'bold');
    $uht->insert('end', '.  A list of ');
    $uht->insert('end', 'keys', 'bold');
    $uht->insert('end', ' is specified by pushing one or more Checkbuttons.');

####### New section #######

    $uht->insert('end', '

                       The `Do It\' Button

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_The_`Do_It\'_Button', "$start.0");
    $uht->insert('end', 'After you are through customizing parameter values, click on ');
    $uht->insert('end', 'Do It', 'bold');
    $uht->insert('end', ' to start command execution.  The button changes to ');
    $uht->insert('end', 'Working ...', 'bold');
    $uht->insert('end', ' and an Output window opens.

The button now changes to ');
    $uht->insert('end', 'Cancel', 'bold');
    $uht->insert('end', ' and begins blinking.');
    $uht->insert('end', '  This means that you can abort the command at any time.');

####### New section #######

    $uht->insert('end', '

                          Windows

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Windows', "$start.0");
    $uht->insert('end', 'This section describes this application\'s Toplevel windows.  The Main window is already open, you are using the Help window now, and there is an Output window which may or may not be open at this time.');

####### New section #######

    $uht->insert('end', '

                        Main Window

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Main_Window', "$start.0");
    $uht->insert('end', 'The Main window is the one you use most often.  It contains the main controls for this X11 application which allow you to enter or change command parameter values, view help information, execute the Unix command and exit this X11 application.  All these actions are performed by pulling down menus or pushing the ');
    $uht->insert('end', 'Do It', 'bold');
    $uht->insert('end', ' button.  The menus are described below.');

####### New section #######

    $uht->insert('end', '

                       Main File Menu

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_____Main_File_Menu', "$start.0");
    $uht->insert('end', 'The Main window ');
    $uht->insert('end', 'File', 'bold');
    $uht->insert('end', ' menu contains these selections:

');
    $uht->insert('end',  '	Open ...
', 'bold');

    $uht->tag('configure', qw(lmargin -lmargin1 90 -lmargin2 90));
    $uht->tag('configure', qw(rmargin -rmargin  90));

    $uht->insert('end', 'If the Unix program expects a trailing File Name you see this selection to browse your directory tree for the desired file.  After a selection is made the file name is appended to the generated Unix command.  If you are using a color monitor the Entry box is highlighted.  Of course, you can type this file name in the Entry box manually.

', [qw(lmargin rmargin)]);
    $uht->insert('end', '	Quit
', 'bold');
    $uht->insert('end', 'Make this selection to quit the X11 application.
', [qw(lmargin rmargin)]);

####### New section #######

    $uht->insert('end', '

                       Main Edit Menu

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_____Main_Edit_Menu', "$start.0");
    $uht->insert('end', 'The Main window ');
    $uht->insert('end', 'Edit', 'bold');
    $uht->insert('end', ' menu contains this selection:

        ');
    $uht->insert('end', 'Undo All
', 'bold');
    $uht->insert('end', 'Make this selection to reset all parameter values to their default values.', [qw(lmargin rmargin)]);

####### New section #######

    $uht->insert('end', '

                       Main Help Menu

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_____Main_Help_Menu', "$start.0");
    $uht->insert('end', 'The Main window ');
    $uht->insert('end', 'Help', 'bold');
    $uht->insert('end', ' menu contains these selections:

');
    $uht->insert('end', '        About
', 'bold');
    $uht->insert('end', 'This selection tells you a little bit about the Unix program, and gives me some credit!  (-:
', [qw(lmargin rmargin)]);
    $uht->insert('end', '
	Usage
', 'bold');
    $uht->insert('end', 'This selction opens the Help window which you are currently using.
', [qw(lmargin rmargin)]);

####### New section #######

    $uht->insert('end', '

                      Output Window

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Output_Window', "$start.0");
    $uht->insert('end', 'The Output window holds standard output and standard error resulting from the execution of the Unix command.  After clicking on the ');
    $uht->insert('end', 'Do It', 'bold');
    $uht->insert('end', ' button this window appears.
');

####### New section #######

    $uht->insert('end', '

                     Output File Menu

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_____Output_File_Menu', "$start.0");
    $uht->insert('end', 'The Output window ');
    $uht->insert('end', 'File', 'bold');
    $uht->insert('end', ' menu contains these selections:
');
    $uht->insert('end', '
	Save As ...
', 'bold');
    $uht->insert('end', 'Use this selection to save the contents of the Output window to a file.
', [qw(lmargin rmargin)]);
    $uht->insert('end', '
	Pipe To ...
', 'bold');
    $uht->insert('end', 'Use this selection to write the contents of the Output window to a command pipeline.  You might print or mail the window contents using this feature.
', [qw(lmargin rmargin)]);
    $uht->insert('end', '
	Close
', 'bold');
    $uht->insert('end', 'Make this selection to close the Output window.
', [qw(lmargin rmargin)]);

####### New section #######

    $uht->insert('end', '

                       Help Window

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help___Help_Window', "$start.0");
    $uht->insert('end', 'The Help window is in use at this very momment.  Hopefully all the information that you need to run this X11 application and execute the Unix command can be found here.  If not, or you have further suggestions or comments, please send mail to me, Steve Lidie, at this email address:
');
    $uht->insert('end', '
	Stephen.O.Lidie@Lehigh.EDU
', 'color2');

####### New section #######

    $uht->insert('end', '

                      Help File Menu

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_____Help_File_Menu', "$start.0");
    $uht->insert('end', 'The Help window ');
    $uht->insert('end', 'File', 'bold');
    $uht->insert('end', ' menu contains this selection:
');
    $uht->insert('end', '
	Close
', 'bold');
    $uht->insert('end', 'Make this selection to close the Help window.
', [qw(lmargin rmargin)]);

####### New section #######

    $uht->insert('end', '

                      Revision History

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Revision_History', "$start.0");
    $uht->insert('end', "This is version $version of ");
    $uht->insert('end', 'generate_PerlTk_program', 'color2');
    $uht->insert('end', ", that corresponds to version $version of ");
    $uht->insert('end', 'Evaluate Parameters', 'color2');
    $uht->insert('end', ' for ');
    $uht->insert('end', 'C', 'color2');
    $uht->insert('end', ', ');
    $uht->insert('end', 'Perl', 'color2');
    $uht->insert('end', ' and ');
    $uht->insert('end', 'Tcl', 'color2');
    $uht->insert('end', '.');
    $uht->insert('end', '


95/10/26, version 2.3
  . Original release.

98/07/26, version 2.3.3.
  . Update for Perl 5.005 and Tk 800.008.

99/04/03, version 2.3.5.
  . Update for Perl 5.005_03 and Tk 800.013.
');

####### New section #######

    $uht->insert('end', '

                          Credits

', 'big');
    $start = $uht->index('end') - 4;
    $uht->mark('set', 'mark_usage_help_Credits', "$start.0");

    $uht->tag('configure', qw(lmargin2 -lmargin1 20 -lmargin2 20));
    $uht->tag('configure', qw(rmargin2 -rmargin  20));

    $uht->insert('end', 'John K. Ousterhout, Scriptics.
');
    $uht->insert('end', 'For writing ', [qw(lmargin2 rmargin2)]);
    $uht->insert('end', 'Tcl/Tk', [qw(lmargin2 rmargin2 color2)]);
    $uht->insert('end', ',  marvelous products that make creating X11 applications a piece of cake.  I would never have attempted this using Xlib and Xt.', [qw(lmargin2 rmargin2)]);
    $uht->insert('end', '

Nick Ing-Simmons, Texas Instruments. 
');
    $uht->insert('end', 'For porting ', [qw(lmargin2 rmargin2)]);
    $uht->insert('end', 'Tk', , [qw(lmargin2 rmargin2 color2)]);
    $uht->insert('end', ' to ', [qw(lmargin2 rmargin2)]);
    $uht->insert('end', 'Perl', , [qw(lmargin2 rmargin2 color2)]);
    $uht->insert('end', ', thus providing a rich, object oriented widget set for the Camel community.', [qw(lmargin2 rmargin2)]);
    $uht->insert('end', '

Stephen O. Lidie, Lehigh University.
');
    $uht->insert('end', 'Hey, for writing ', [qw(lmargin2 rmargin2)]);
    $uht->insert('end', 'Evaluate Parameters', [qw(lmargin2 rmargin2 color2)]);
    $uht->insert('end', '. ', [qw(lmargin2 rmargin2)]);

    $uht->configure(qw(-state disabled));

} # end usage

1;
