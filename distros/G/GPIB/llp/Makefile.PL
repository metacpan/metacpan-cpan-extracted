use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%params = ();

# Linux machine
die "GPIB::llp only works with Linux\n  " unless ($^O =~ /linux/); 

$incfile = "ib.h";
$incpath = "/usr/local/llp/include";
$libfile = "gpib";
$libpath = "/usr/local/llp/lib";

%params = (
    'NAME'	          => 'GPIB::llp',
    'VERSION_FROM'        => 'llp.pm',
    'LIBS'	          => ["-L$libpath -l$libfile -lfl"],
    'DEFINE'	          => '-DUNIX',
    'INC'	          => "-I$incpath", 
    ($] ge '5.005') ? (
        'AUTHOR' => 'Jeff Mock (jeff@mock.com)',
        'ABSTRACT' => 'GPIB device control',
    ) : (),
);

# Look for include file and library
$err = 0;
unless (-s "$incpath/$incfile") {
    print "Cannot find file $incpath/$incfile for GPIB, module GPIB::llp.\n";
    $err = 1;
}
unless (-s "$libpath/lib$libfile.a") {
    print "Cannot find file $libpath/lib$libfile.a for GPIB, module GPIB::llp.\n";
    $err = 1;
}
exit 1 if $err;

WriteMakefile(%params);
