# -*- perl -*-

use Test::More tests => 14;

BEGIN { use_ok( 'File::Find::Random' ); }
BEGIN { use_ok( 'Cwd' ); }
use strict;
use File::Spec::Functions;
my $orig_cwd = cwd();
chdir('t') if(-d 't');
my $cwd = cwd();

{
    ok(chdir('testdir'), "Enter the testdir $!");
    
    my $file = File::Find::Random->find();
   
    ok($file, "Returned random file - $file");
    chdir('..');
    like($file, qr/\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file");
}

{
    
    my $file = File::Find::Random->find('testdir');
   
    ok($file, "Returned random file using a base path - $file");
    like($file, qr/testdir.\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file from the directory tree");
}

{

    
    my $file = File::Find::Random->find(catdir($cwd,'testdir'));
   
    ok($file, "Returned random file using a base path - $file");
    like($file, qr/testdir.\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file from the directory tree");
}


{

    my $file = File::Find::Random->new()->base_path('testdir')->find();
    like($file, qr/testdir.\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file from the directory tree - '$file' ");
}
{
    my $finder = File::Find::Random->new()->base_path('testdir');
    my $file = $finder->find();
    like($file, qr/testdir.\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file from the directory tree - '$file' ");
    $finder->base_path(curdir());
    ok(chdir('testdir'));
    
    $file = $finder->find();
    like($file, qr/\d+.\d+.\d+.\d+\.txt/ , "Check that it returns a file from the directory tree - '$file' ");
    ok(chdir('..'));

}
chdir($orig_cwd);
1;
