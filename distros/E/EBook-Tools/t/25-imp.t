use strict; use warnings; use utf8;
use Cwd qw(chdir getcwd);
use Digest::MD5 qw(md5);
use File::Basename qw(basename);
use File::Path;    # Exports 'mkpath' and 'rmtree'
use Image::Size;
use Test::More tests => 84;
BEGIN { use_ok('EBook::Tools::IMP',':all') };

my $cwd;
my $imp = EBook::Tools::IMP->new();
my $filename;
my $headerdata;
my $bookpropdata;
my $resdirname;
my $tocdata;
my $resource;
my $resourceref;
my $fh_header;
my $fh_imp;
my $fh_res;
my $md5 = Digest::MD5->new();
my $md5check = Digest::MD5->new();
my ($imagex,$imagey,$imagetype);
my $scalar;
my @list;


########## TESTS BEGIN ##########

ok( (basename(getcwd()) eq 't') || chdir('t/'), "Working in 't/" ) or die;
$cwd = getcwd();

ok($imp->load('imp/REBTestDocument.imp'),
   "load('imp/REBTestDocument.imp') returns succesfully");

open($fh_header,'<:raw','imp/REBTestDocument.imp')
    or die("Failed to load imp/REBTestDocument.imp! [@!]");
sysread($fh_header,$headerdata,48);
sysread($fh_header,$bookpropdata,$imp->bookproplength);
sysread($fh_header,$resdirname,$imp->resdirlength);
sysread($fh_header,$tocdata,$imp->version * 10 * $imp->filecount);
sysread($fh_header,$resource,$imp->tocentry(0)->{size} + $imp->version * 10);
close($fh_header);

foreach my $type (keys %{$imp->resources})
{
    next if($imp->resource($type)->{name} eq '    ');
    my $resdata = $imp->resource($type)->{data};
    ok(detect_resource_type(\$resdata) eq $type,
       "detect_resource_type() correctly detects '$type'");
}

is($imp->image(),undef,'image() returns undef');
is($imp->image('jpg'),undef,'image(jpg) returns undef');

$scalar = $imp->image('jpg',3918);
($imagex,$imagey,$imagetype) = imgsize(\$scalar);
is($imagetype,'JPG','image(jpg,$id) finds JPG data');

@list = sort {$a <=> $b} keys %{$imp->image_hashref('jpg')};
is_deeply(\@list, [ 128,3918,19840,35354,36173,47032 ],
          'image_hashref(jpg) finds expected image ids');

@list = sort keys %{$imp->image_hashref('jpg',3918)};
is_deeply(\@list, [ 'const0','data','length','offset','unknown' ],
          'jpeg_hashref(jpg,$id) finds expected hash keys');

@list = sort {$a <=> $b} $imp->image_ids('jpg');
is_deeply(\@list, [ 128,3918,19840,35354,36173,47032 ],
          'image_ids(jpg) finds expected image ids');

is($imp->pack_imp_header,$headerdata,
   'pack_imp_header() creates the correct data');
is($imp->pack_imp_book_properties,$bookpropdata,
   'pack_imp_book_properties() creates the correct data');
is($imp->resdirname,$resdirname,
   'resdirname() returns the correct name');
is($imp->pack_imp_toc,$tocdata,
   'pack_imp_tocdata() creates the correct data');
$resourceref = $imp->pack_imp_resource(type => $imp->tocentry(0)->{type});
ok($$resourceref eq $resource,
   'pack_imp_resource(type) creates the correct data');
$resourceref = $imp->pack_imp_resource(name => $imp->tocentry(0)->{name});
ok($$resourceref eq $resource,
   'pack_imp_resource(name) creates the correct data');

ok($imp->write_imp('repack.imp'),
   'write_imp() returns successfully');
ok(-f 'repack.imp',
   'write_imp() creates repack.imp');

$md5check->reset;
open($fh_imp,'<:raw','imp/REBTestDocument.imp')
    or die("Unable to open 'imp/REBTestDocument.imp' for reading! [@!]\n");
$md5check->addfile($fh_imp);
close($fh_imp);
$md5->reset;
open($fh_imp,'<:raw','repack.imp')
    or die("Unable to open 'repack.imp' for reading! [@!]\n");
$md5->addfile($fh_imp);
close($fh_imp);
ok($md5->digest eq $md5check->digest,
   'write_imp() output has correct checksum');

ok($imp->write_resdir,
   "write_resdir() returns successfully");
ok(-d 'REBtestdoc.RES',
   'write_resdir() creates the correct directory');

while(<imp/REBtestdoc-ETI.RES/*>)
{
    $md5check->reset;
    open($fh_res,'<:raw',$_)
        or die("Unable to open '",$_,"' for reading! [@!]\n");
    $md5check->addfile($fh_res);
    close($fh_res);

    $md5->reset;
    $filename = 'REBtestdoc.RES/' . basename($_);
    open($fh_res,'<:raw',$filename)
        or die("Unable to open '",$filename,"' for reading! [@!]\n");
    $md5->addfile($fh_res);
    close($fh_res);

    ok($md5->digest eq $md5check->digest,
       "write_resdir() correctly unpacks '$filename'");
}


########## CLEANUP ##########

rmtree('REBtestdoc.RES');
unlink('repack.imp');
