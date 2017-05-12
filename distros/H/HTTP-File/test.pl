# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTTP::File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

do 'GetString.pl';

$cgi_dir_query=q{
=========================================================================
Ok, the first thing I need to know is an absolute or relative URL to your 
cgi-bin directory. For example, if cgi-scripts on your system are called 
via: 

http://www.superbuys.com/cgi-bin/buynow.cgi,

Then the absolute URL for your cgi-bin directory would be:

http://www.superbuys.com/cgi-bin

(note the absence of the filename --- this is not a mistake).

The relative URL for your cgi-bin directory would be /cgi-bin

(note the leading '/' --- this is not a mistake either).

Enter your cgi-bin directory URL (relative or absolute): 
};

$cgi_dir = GetString($cgi_dir_query, '/cgi-bin');

system "perl -pe 's|<CGI_DIR>|$cgi_dir|' savepage.html.template > savepage.html";



$phys_cgi_dir_query=q{
===========================================================================
Ok, now what is the physical path to the cgi-bin directory? I will
copy my cgi file upload test script to this directory.
};

$phys_cgi_dir = GetString($phys_cgi_dir_query, '/usr/local/apache/cgi-bin');

$pwd=`pwd`;
chomp($pwd);
system "perl -pe 's|<BUILD_DIR>|$pwd|' savepage.cgi.template > savepage.cgi";
system "chmod 777 savepage.cgi";
system "cp savepage.cgi $phys_cgi_dir";


$html_dir_query=q{
===========================================================================
Ok, now what is the physical path to the HTML directory? This is know as 
the document root in Apache. I will copy my HTML file upload file to this 
directory. 
};

$html_dir = GetString($html_dir_query, '/usr/local/apache/htdocs');

system "cp savepage.html $html_dir";

print <<END;
============================================================================
Ok, the file savepage.html has been copied to $html_dir. Now visit this HTML
file in your browser and upload a file. For example, if you said the
HTML directory was /usr/local/apache/htdocs, then you would probably visit
http://www.superbuys.com/savepage.html

If you said the HTML directory was /usr/local/apache/htdocs/test, 
then you would probably visit http://www.superbuys.com/test/savepage.html


I will save the file you upload to /tmp. After you have done so, type
the name of the file below and I will check for the file's
existence. If it is there, then installation is successful.  

Only type the basename of the file. That is, if you uploaded a file from your
machine called C:\\Temp\\test.dat, only enter test.dat below.
END

$basename = GetString('type basename of uploaded file');

print "Checking for $basename in /tmp...\n";

system "ls -l /tmp/$basename";

if (-e "/tmp/$basename") {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}
