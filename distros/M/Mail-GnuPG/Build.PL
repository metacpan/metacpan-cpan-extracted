use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Mail::GnuPG',
   dist_author => [ 'Robert Spier <rspier@cpan.org>', 
		    'David Bremner <ddb@cpan.org>'],
   (sign => 1),
   requires => {
		'File::Spec' => 0,
		'File::Temp' => 0,
		'GnuPG::Interface' => 0,
		'IO::Handle' => 0,
		'MIME::Entity' => 0,
		'MIME::Parser' => 0,
		'Mail::Address' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
               },
   license => 'unknown',
   create_readme => 0,
   meta_merge => { 
		  resources => 
		  { homepage =>
		    'http://pivot.cs.unb.ca/git/?p=mail-gnupg.git;a=summary' }
		 }
  );

$build->create_build_script;
