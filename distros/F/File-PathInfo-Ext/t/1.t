use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::PathInfo::Ext;
use Cwd;
use warnings;
use Carp;
use Cwd;
$File::PathInfo::RESOLVE_SYMLINKS = 0;
$ENV{DOCUMENT_ROOT} = cwd().'/t/public_html';



`touch $ENV{DOCUMENT_ROOT}/test.file`;


my $f = new File::PathInfo::Ext("$ENV{DOCUMENT_ROOT}/test.file") ;#or die( $File::PathInfo::Ext::errstr );


ok($f->rename('bla1'), 'renamed to bla1');
ok( !($f->rename('awe/gfaw/egawg/\\pou*()^T)(T3wt//n23')));

ok($f->rename('test.file'));
unlink "$ENV{DOCUMENT_ROOT}/test.file";

### ok.


### try out ls

my $d = new File::PathInfo::Ext(cwd());

ok ( $d->ls, 'ls');
ok ( $d->lsa, 'lsa' );
ok ( $d->lsf,'lsf');
ok( $d->lsfa,'lsfa');
ok($d->lsd,'lsd');
ok($d->lsda,'lsda');


ok( !$d->is_empty_dir, 'is empty dir returns no for '.cwd()) or die;



mkdir cwd().'/tmp2';

$d->set(cwd().'/tmp2');

ok( $d->is_empty_dir , 'is_empty_dir() is empty dir returns yes' );



my $datahash = $d->get_datahash;

ok( exists $datahash->{is_empty_dir} );
### $datahash


# put hidden file in there and make sure it returns false for empty dir
`touch ./tmp2/.ha`;
-f './tmp2/.ha' or die;
ok( $d->set('./tmp2') );
ok( ! $d->is_empty_dir,'is not empty dir if hidden file resides');


unlink './tmp2/.ha';



rmdir $d->abs_path;




