use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%params = ();

# Linux machine
if ($^O =~ /linux/) {
    $incfile = "ugpib.h";
    $incpath = "/usr/local/gpib/include";
    $libfile = "gpib";
    $libpath = "/usr/local/gpib/lib";

    %params = (
        'NAME'	          => 'GPIB::ni',
        'VERSION_FROM'    => 'ni.pm',
        'LIBS'	          => ["-L$libpath -l$libfile"],
        'DEFINE'	  => '-DUNIX',
        'INC'	          => "-I$incpath", 
        ($] ge '5.005') ? (
            'AUTHOR' => 'Jeff Mock (jeff@mock.com)',
            'ABSTRACT' => 'GPIB device control',
        ) : (),
    );

    # Look for include file and library
    $err = 0;
    unless (-s "$incpath/$incfile") {
        print "Cannot find file $incpath/$incfile for GPIB, module GPIB::ni.\n";
        $err = 1;
    }
    unless (-s "$libpath/lib$libfile.a") {
        print "Cannot find file $libpath/lib$libfile.a for GPIB, module GPIB::ni.\n";
        $err = 1;
    }
    exit 1 if $err;
}

# Win32 (I've only tested on NT4.0)
#
# I've tested this with National Instruments GPIB-PCI card.
#
if ($^O =~ /MSWin32/) {
    $incfile = "decl-32.h";
    $libfile = "gpib-32.obj";
    $incpath = 'C:\Program Files\National Instruments\NI-488.2\Languages\Microsoft C';   # geez
    $libpath = $incpath; 

    %params = (
        'NAME'	          => 'GPIB::ni',
        'VERSION_FROM'    => 'ni.pm', 
        'LIBS'	          => [''],  
        'OBJECT'          => "ni.obj \"$libpath\\$libfile\"",
        'INC'	          => "-I\"$incpath\"",
        ($] ge '5.005') ? (
            'AUTHOR' => 'Jeff Mock (jeff@mock.com)',
            'ABSTRACT' => 'GPIB device control',
        ) : (),
    );

    # Look for include file and library
    $err = 0;
    unless (-s "$incpath/$incfile") {
        print "Cannot find file $incpath\\$incfile for GPIB, module GPIB::ni.\n";
        $err = 1;
    }
    unless (-s "$libpath/$libfile") {
        print "Cannot find file $libpath\\$libfile for GPIB, module GPIB::ni.\n";
        $err = 1;
    }
    exit 1 if $err;
}

# Look for include file libraries here so we can fail early if
# GPIB driver is not installed


WriteMakefile(%params);
