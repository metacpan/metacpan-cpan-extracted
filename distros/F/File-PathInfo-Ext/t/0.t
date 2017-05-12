use Test::Simple 'no_plan';
use strict;
use lib './lib';	
use File::PathInfo::Ext;
use Cwd;
use warnings;
use Carp;

#$File::PathInfo::RESOLVE_SYMLINKS = 0;


$ENV{DOCUMENT_ROOT} = cwd().'/t/public_html';



my $i = 0;

sub ok_part {
   printf STDERR "\n\n===================\nPART [%s], %s\n\n", ++$i, uc(+shift);
   return 1;
}


# test ones we know are in docroot
for my $argument (qw(
./t/public_html/demo
./t/public_html/seven.pdf
demo
./t/public_html/demo/hellokitty.gif
./t/public_html/demo/../demo/civil.txt
demo/../demo/civil.txt
demo/civil.txt
)){
	ok_part($argument);
	my $f = new File::PathInfo::Ext($argument) ;#or die( $File::PathInfo::Ext::errstr );

	#ok($f, "instanced for '$argument'");
	my $filename = $f->filename;

	$f->meta->{title} = 'hello';
	
	ok( $f->meta_save,'meta_save()');
	
	ok(-f $f->abs_loc.'/.'.$f->filename .'.meta','meta present');	

	# try rename
	my $newname = 'hahahahaha.hahaha';

	ok( $f->rename($newname),'rename()' );
	# make sure meta was renamed
	ok(-f $f->abs_loc.'/.'.$newname.'.meta');
	ok($f->meta->{title} eq 'hello');

	# rename back

	ok( $f->rename($filename) ,'meta rename');

	
	

	
	
	ok( $f->meta_delete ,'meta delete');
	
	ok( !(-f $f->abs_loc.'/.'.$f->filename .'.meta'),'meta gone');

   
   if( $^O=~/linux|unix|gnu/i ){

      for my $stat_key (
         qw(ctime mtime nlink size blocks atime_pretty mtime_pretty ctime_pretty ino)
      ){	
         my $stat_val = $f->$stat_key;
         

         no warnings;
         print STDERR " stat key '$stat_key' = '$stat_val'\n";
         
         unless( defined $stat_val ){
            print STDERR ("no return for stat key/method '$stat_key'")
               and next;
         }
         
         ok($f->$stat_key, "stat key method  '$stat_key()'") ;
         
      }
   }

   else {

      ok( 1,'skipping stat tests, not unix/linux/gnu');

   }

	if ($f->is_file){
		my $digest;
		
		ok($digest = $f->md5_hex, (sprintf "got md5: %s %s",$f->abs_path,$digest));


      my $mime = $f->mime_type;
      ok($mime, "mime is $mime");

	}

   

}

