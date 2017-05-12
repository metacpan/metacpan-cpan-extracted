use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url $test_cwd do_test fail_tests test_callback);


# Sends out a propfind request to the server 
# specified in "PROPFIND" in the TestDetails 
# module.

my $TESTS;
$TESTS=39;
plan tests => $TESTS;

my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
my $cwd = $test_cwd;

fail_tests($TESTS) unless $test_url =~ /http/;

HTTP::DAV::DebugLevel(2);
my $dav;

# Test get_workingurl on empty client
$dav = HTTP::DAV->new( );
do_test $dav, $dav->get_workingurl(), "", "Empty get_workingurl";

# Test an empty open. Should fail.
do_test $dav, $dav->open(), 0, "OPEN nothing";

$dav = HTTP::DAV->new();
# Set some creds and then open the URL
$dav->credentials( $user, $pass, $url );

do_test $dav, $dav->open( $url ), 1, "OPEN $url";

do_test $dav, $dav->open( -url => $url ), 1, "OPEN $url";

# Try opening a non-collection. It should fail.
#do_test $dav, $dav->open( -url => $geturl ), 0, "OPEN $geturl";

# Test various ways of getting the working url
my $working_url1 = $dav->get_workingresource()->get_uri();
my $working_url2 = $dav->get_workingurl();
my $test_url = $url;
ok($working_url1 eq $test_url);
ok($working_url2 eq $test_url);
ok($working_url1 eq $working_url2);

print "AM STARTING THE OPERATIONS!!\n";

# Make a directory with our process id after it 
# so that it is somewhat random
my $newdir = "perldav_test$$";
do_test $dav, $dav->mkcol($newdir), 1, "MKCOL $newdir";

# Try it again. This time it should fail.
do_test $dav, $dav->mkcol($newdir), 0, "MKCOL $newdir";

# Try changing to it. It should work
do_test $dav, $dav->cwd($newdir), 1, "CWD to $newdir";

# Make another in newdir.
do_test $dav, $dav->mkcol("subdir"),1, 'MKCOL "subdir"';

# Go back again. cwd .. It should work.
do_test $dav, $dav->cwd(".."), 1, "CWD to '..'";

######################################################################
# PUT some files
print "Doing PUT\n";
my $localdir = "/tmp/perldav";

# Test put with absolute paths

do_test $dav, $dav->put("t/test_data","$newdir",\&test_callback), 1, "put t";
print scalar $dav->message() . "\n";

# Try putting the directory to a bogus location
do_test $dav, $dav->put("t/test_data","/foobar/$newdir/",\&test_callback), 0, "put t";

if (!open(F,">/tmp/tmpfile.txt") ) {
   print "Couldn't open /tmp/tmpfile.txt";
}
print F "I am content that came from a local file \n";
close F;

my $some_content="I am content that came from a scalar\n";

do_test $dav, $dav->put("/tmp/tmpfile.txt","$newdir/file.txt"), 1, "put $newdir/file.txt";
print scalar $dav->message() . "\n";
do_test $dav, $dav->put(\$some_content,"$newdir/scalar_to_file.txt"), 1, 'put \$some_content';
print scalar $dav->message() . "\n";

print  "Test put with relative paths\n";

do_test $dav, $dav->cwd($newdir), 1, "CWD to $newdir";
do_test $dav, $dav->put("/tmp/tmpfile.txt"), 1, "put /tmp/tmpfile.txt";
print scalar $dav->message() . "\n";

do_test $dav, $dav->put("/tmp/tmpfile.txt", "file2.txt"), 1, "put file2.txt";
print scalar $dav->message() . "\n";

do_test $dav, $dav->put("/tmp/tmpfile.txt", "subdir/file2.txt"), 1, "put subdir/file2.txt";
print scalar $dav->message() . "\n";

chdir "/tmp" || die "Couldn't change to /tmp\n";

do_test $dav, $dav->put("tmpfile.txt", "file3.txt"), 1, "put file3.txt";
print scalar $dav->message() . "\n";

do_test $dav, $dav->put("tmpfile.txt", "subdir/file3.txt"), 1, "put subdir/file3.txt";
print scalar $dav->message() . "\n";

do_test $dav, $dav->cwd('..'), 1, "CWD to ..";
unlink("/tmp/tmpfile.txt") || print "Couldn't remove /tmp/tmpfile.txt\n";

#my $put_url  = $dav->get_absolute_uri("$newdir/file.txt");
#my $put_res  = $dav->new_resource($put_url);
#my $put_resp;
#
#$put_resp = $put_res->get();
#if (ok $put_resp->is_success) {
#   print "GET succeded on file.txt. Contents:\n" . $put_resp->content . "\n";
#} else {
#   print "GET failed on $put_url. ". $put_resp->message . "\n";
#}

######################################################################
# GET some files
# We're now at the base directory again but have two nested subdirectories with some files in there.
# Let's start getting things !!

# Create a local directory
# No error checking required. Don't care if it fails.
if (!mkdir $localdir ) {
   print "Local mkdir failed: $!\n" if $!;
}


# Get it the normal way
do_test $dav, $dav->get($newdir, $localdir, \&test_callback ), 1, "GET of $newdir";
do_test $dav, -e ("$localdir/$newdir/file.txt"), 1, "ls of $localdir/$newdir/file.txt";
print scalar $dav->message() . "\n";

# Let's try getting the coll without passing a local 
# working directory. It should fail.
do_test $dav, $dav->get($newdir), 0, "GET of $newdir";

# Let's try getting the coll and passing it '.' as the cwd. But first
# let's try it when the local directory already exists (retrieved
# above).
chdir($localdir); 
do_test $dav, $dav->get($newdir,'.',\&test_callback), 0, "GET of $newdir";

# Let's try getting the coll and passing it '.'. But this time let's do
# it properly, we'll remove the local directory first so we have a clean
# slate.
system("rm -rf $localdir/$newdir") if $localdir =~ /\w/;
chdir("$localdir"); 
do_test $dav, $dav->get($newdir,'.',\&test_callback), 1, "GET of $newdir";
do_test $dav, -e ("$localdir/$newdir/file.txt"),1,"ls of $localdir/$newdir/file.txt";
print scalar $dav->message() . "\n";


# Now let's get file.txt (created earlier) rather than a coll.
# Put it in $localdir and call it newfile.txt
my $file = "$newdir/file.txt";
my $scal = "$newdir/scalar_to_file.txt";
chdir("$localdir/$newdir") || print "chdir to $localdir/$newdir failed\n";

do_test $dav, $dav->get($file,'../newfile.txt',\&test_callback), 1, "GET of $file to ../newfile.txt";
do_test $dav, -e ("$localdir/newfile.txt"), 1, "ls of $localdir/newfile.txt";
print scalar $dav->message() . "\n";

do_test $dav, $dav->get($file,"$localdir/$newdir/subdir/newfile.txt",\&test_callback), 1, "GET of $file to $localdir/$newdir/subdir/newfile.txt";
do_test $dav, -e ("$localdir/$newdir/subdir/newfile.txt"), 1, "ls of $localdir/$newdir/subdir/newfile.txt";
print scalar $dav->message() . "\n";

# Now let's get file.txt and file2.txt but don't save it 
# to disk. Expect it back as text
my $string;
$dav->get($file,\$string);
do_test $dav, $string, '/from a local file/', "GET of $file to \$scalar";

$dav->get($scal,\$string);
do_test $dav, $string, '/from a scalar/',     "GET of $scal to \$scalar";

# Get a nonexistent file
# Expect undef
$file="$newdir/foobar";
do_test $dav, $dav->get($file), 0, "GET of $file to \$scalar";

######################################################################
######################################################################
# DELETE some files
# Remove the directory (and it's subdirectory). It should succeed.

END {
   if ( $url =~ /http/ ) {
      print "Cleaning up\n";
      do_test $dav, $dav->delete(-url=>"$newdir/test_data/file*",-callback=>\&test_callback ),1,"DELETE $newdir/test_data/file*";

      do_test $dav, $dav->delete($newdir),  1,  "DELETE $newdir";
      
      # Remove the directory again. It should fail
      do_test $dav, $dav->delete($newdir),  0,  "DELETE $newdir";
      
      chdir $cwd;
      system("rm -rf $localdir") if $localdir =~ /\w/;
   }
}
