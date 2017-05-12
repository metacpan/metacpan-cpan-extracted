# installer for Exporter::VA.
# All it does is copy the file to sitelib location.

require 5.6.1;
use strict;
use warnings;
use Config;
use File::Path;  #create directory tree
use File::Spec;  #concat name parts with system-specific delimiters
use File::Copy;

# where am I copying TO?
my $sitelib= $Config{installsitelib};
my $install_location= File::Spec->catdir ($sitelib, 'Exporter');
unless (-d $install_location) {
   my $count= mkpath ($install_location);
   die "Error creating path $install_location\n"  unless $count == 1;
   }
my $dest= File::Spec->catfile ($install_location, 'VA.pm');

# where am I running FROM?
my ($volume,$directories,$file) = File::Spec->splitpath($0);
my $source= File::Spec->catpath ($volume, $directories, 'VA.pm');

# OK, do what I came here for.
# >> could check versions here.

# move any old copy to a temp file in case I need to roll it back.
my $have_old= -e $dest;
my $tempfile = $dest . ".BACKUP";
if ($have_old) {
   move ($dest, $tempfile)  or die qq(Could not move "$dest" to "$tempfile");
   }
copy ($source, $dest)  or die qq(Could not copy "$source" to "$dest"\n);
print qq(Copied "$source" to "$dest"\n);
# test, then clean up
if (test_module()) {
   # all went well so get rid of the backup.
   print "OK.\n";
   unlink $tempfile;
   }
else {
   # problem, so roll back
   print "Module test failed! ";
   if ($have_old) {
      print "restoring old file.\n";
      move ($tempfile, $dest)  or die qq(Problem restoring old file!! Could not move "$tempfile" back to "$dest");
      }
   else {
      print "deleting installed file.\n";
      unlink $dest;
      }
   }
update_TOC();  # if on ActiveState Perl.

### end of main code.

sub test_module
 {
 my $testprog= "test.t";
 print "Testing the module...\n";
 chdir 't';  # run from that directory
 my $retcode= system ($^X, $testprog, "--quiet");
 return $retcode == 0;
 }

sub update_TOC
 {
 eval "use ActivePerl::DocTools; use Pod::Html;";
 return if $@;  # stop trying with no visible error if modules are not present.
 # This is for ActiveState Perl.  Attempting to load the module was a test to see if that's what I'm running on.
 if (convertPod2html ($dest)) {
    ActivePerl::DocTools::WriteTOC();
    print "Updated ActiveState documentation.\n";
    }
 }

sub convertPod2html
 {
 # based on the code found at < http://www.perlmonks.org/index.pl?node_id=72809 >
 (my $podfile = shift) =~ s#\\#/#g;
 (my $htmlroot = $Config{installhtmldir}) =~ s#\\#/#g; 
 (my $podroot  = $Config{installprefix}) =~ s#\\#/#g; 
 my ($path,$name) = ($podfile =~ m!$podroot/(.*)/(\w+)\.p(od|l|m|erl)$!i);
 die "Could not update document table of contents because \"$dest\" is not under the tree of \"$podroot\"\n"
    unless defined $name;
 my $outfile = "$htmlroot/$path/$name.html";
 return 0  if (-e $outfile && -M $podfile > -M $outfile); # redundant re-install; don't bother updating.
 (my $stylesheetpath = "$path") =~ s#\w+(/?)#..$1#g;
 mkpath("$htmlroot/$path"); 
 chdir File::Spec->tmpdir();
 pod2html(    "--infile=$podfile", 
     "--outfile=$outfile", 
     "--header", 
     "--podroot=$podroot", 
     "--podpath=site/lib:lib", 
     "--htmlroot=$htmlroot",
     "--css=$stylesheetpath/Active.css"
   );
return 1;
}

