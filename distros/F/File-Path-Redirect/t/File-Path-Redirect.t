use strict;
use warnings;

use File::Path qw<make_path remove_tree>;
use File::Spec::Functions qw<abs2rel catfile catdir>;
use File::Basename qw<dirname basename>;
use Test::More;
BEGIN { use_ok('File::Path::Redirect') };



my $contents="Contents of original";
my $temp_dir= "testing_dir";
my $temp_dir2= "testing_dir2";
my $source_file=catfile $temp_dir, $temp_dir2,"original_file.txt";
my $target_file=catfile $temp_dir,"target_file.txt";
make_path catdir $temp_dir, $temp_dir2;

# Create  a source file
open my $fh, ">", $source_file;
print $fh $contents;
close $fh;

my $relative=make_redirect($source_file, $target_file, 1);

# Test if it is a redirect
ok is_redirect($target_file), "Is a redirect file";
ok !is_redirect($source_file), "Is not redirect file";




my $expected=abs2rel($source_file, dirname $target_file);
ok $relative eq $expected,"Relative path match";


my $redirect=follow_redirect $target_file;
ok $redirect eq $source_file, "Redirect to source file";

ok is_redirect($target_file), "File is redirect file";

ok ! is_redirect($source_file), "File is not redirect file";

my $trace=[];
$redirect=redirect_chained(5,$trace);
ok((defined($redirect)), "Chained redirects");

$redirect=redirect_chained(10, $trace);
ok((!defined($redirect) and $! == File::Path::Redirect::TOO_MANY()), "Too many Chained redirects");

sub redirect_chained{
  my $count=shift;
  my $trace=shift;
  my $s_file;
  my $t_file;
  for(1..$count){

    $s_file=catfile $temp_dir,"@{[$_+0]}.txt";
    $t_file=catfile $temp_dir,"@{[$_+1]}.txt";

    my $relative=make_redirect($s_file, $t_file,1);

  }
  open my $fh, ">", catfile $temp_dir,"1.txt";
  print $fh $contents;
  close $fh;


  $redirect=follow_redirect $t_file, undef, $trace;

}


remove_tree $temp_dir;

done_testing;
