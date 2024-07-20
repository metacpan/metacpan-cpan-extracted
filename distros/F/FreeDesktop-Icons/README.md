# FreeDesktop-Icons

This module gives access to icon libraries on your system. It more
or less conforms to 
[the Free Desktop specifications here](https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html).

Furthermore it allows you to add your own icon folders through the rawpath method.

We have made provisions to make it work on Windows as well.

The constructor takes a list of folders where it finds the icons
libraries. If you specify nothing, it will assign default values for:

Windows:  $ENV{ALLUSERSPROFILE} . '\Icons'. It will not create 
the folder if it does not exist.

Others: $ENV{HOME} . '/.local/share/icons',  and the folders 'icons' in $ENV{XDG_DATA_DIRS}.

# Installation

    * perl Makefile.PL
    * make
    * make test
    * make install

# On Windows

If you use the windows operating system please make sure you have an icon library installed.
We found a suitable one on softicons.com. [Download it from here](https://www.softicons.com/system-icons/oxygen-icons-by-oxygen).

Extract the file and rename the folder png to Oxygen. 
Create a folder Icons in C:\ProgramData and move the Oxygen folder into it.
Downloading it from the Oxygen github repository gives all kinds of problems on Windows.