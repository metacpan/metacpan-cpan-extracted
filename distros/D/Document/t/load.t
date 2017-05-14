# AUTHOR: Dale M Amon
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Spec::BaseParse;
use File::Spec::DatedPage;
use File::Spec::Dated;
use File::Spec::PublicationPage;
use Document::LogFile;
use Document::Members;
use Document::NotesFile;
use Document::PageId;
use Document::PageIterator;
use Document::TocFile;
use Document::Toc;
use Document::Directory;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

