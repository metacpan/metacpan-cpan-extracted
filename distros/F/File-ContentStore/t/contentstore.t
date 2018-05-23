use strict;
use warnings;
use Test::More;

use Path::Tiny ();
use File::ContentStore;

my $CAN_SYMLINK = eval { symlink( "", "" ); 1 };

sub build_work_tree {

    # where the data files live
    my $file = Path::Tiny->new( 't', 'files' );

    # setup our temporary directories
    my %dir = ( tmp => Path::Tiny->tempdir );
    ( $dir{$_} = $dir{tmp}->child($_) )->mkpath for qw( obj src );

    # process the mapping
    for ( split /\n/, shift ) {
        my ( $from, $to ) = map Path::Tiny->new($_), split / +/;
        $to ||= $from;
        $dir{src}->child( $to->parent )->mkpath;
        $file->child($from)->copy( $dir{src}->child($to) );
    }

    return %dir;
}

# copy some files to src
my %dir = build_work_tree( << 'TREE' );
img-01.jpg
img-01.jpg         img-02.jpg
IMG_0025.JPG
git-fusion.png
TREE

# create the ContentRepo
my $store = File::ContentStore->new( $dir{obj} );
isa_ok( $store, 'File::ContentStore' );
is_deeply( $store->inode, {}, 'Empty inode cache' );

# add all files in src
$store->link_dir( $dir{src} );

# check each file in src now has at least 2 links
$dir{src}->visit(
    sub { cmp_ok( $_->stat->nlink, '>=', 2, "$_ has at least 2 links" ) },
    { recurse => 1 },
);

# check duplicates
is(
    $dir{src}->child('img-01.jpg')->stat->ino,
    $dir{src}->child('img-02.jpg')->stat->ino,
    "img-01.jpg and img-02.jpg are linked"
);

# check mode
is( $dir{src}->child('img-01.jpg')->stat->mode & 00222,
    0, 'Files not writeable any more' );

# check inode cache
is(
    $store->inode->{ $dir{src}->child('img-01.jpg')->stat->ino },
    '2c/37ddd32a282aba524d0b6b211125f33cf251e7',
    'inode added to the cache'
);

# fsck
is_deeply( $store->fsck, {}, 'fsck' );

# fsck errors
unlink $dir{src}->child('IMG_0025.JPG');    # orphan file
$store->path->child('01')->mkpath;
rename(                                     # corrupted + empty dir
    $store->path->child( '2c', '37ddd32a282aba524d0b6b211125f33cf251e7', ),
    $store->path->child( '01', '23456789abcdef0123456789abcdef01234567' )
);
if ($CAN_SYMLINK) {
    symlink(
        $store->path->child( '01', '23456789abcdef0123456789abcdef01234567' ),
        $store->path->child( '01', 'a7f51a27b82b640a285c6dfa7c336c7610dbf1', ),
    );
}

is_deeply(
    $store->fsck,
    {
        empty  => [ $store->path->child('2c') ],
        orphan => [
            $store->path->child(
                '63', 'b1a831fb99ba85c4d7072a47efd7b84b7f9074'
            )
        ],
        corrupted => [
            $store->path->child(
                '01', '23456789abcdef0123456789abcdef01234567'
            )
        ],
      ( symlink => [
            $store->path->child(
                '01', 'a7f51a27b82b640a285c6dfa7c336c7610dbf1'
            ),
        ] )x!! $CAN_SYMLINK,
    },
    'fsck, 1 empty, 1 orphan, 1 corrupted'
);

# collision tests
%dir = build_work_tree( << 'TREE' );
md5-1
md5-2 subdir/md5-2
TREE

my $md5_store = File::ContentStore->new( {
    path           => $dir{obj},
    digest         => 'MD5',
    make_read_only => '',
    file_callback  =>
      sub { is( $_[1], '008ee33a9d58b51cfeb425b0959121c9', "@_" ) },
} );

ok( !eval { $md5_store->link_dir($dir{src}); 1; }, 'link_dir failed' );
like(
    $@,
    qr{^Collision found for $dir{src}/subdir/md5-2 and ${\$md5_store->path}/00/8ee33a9d58b51cfeb425b0959121c9: content differs },
    '... on an MD5 collision'
);

isnt( $dir{src}->child('md5-1')->stat->mode & 0222,
    0, 'File initially writable' );

$dir{src}->child('md5-1')
  ->chmod( $dir{src}->child('md5-1')->stat->mode | 0100 );
is( $dir{src}->child('md5-1')->stat->mode & 0100, 0100, 'File now executable' );

$md5_store = File::ContentStore->new(
    path                 => $dir{obj},
    digest               => 'MD5',
    check_for_collisions => '',
);
ok(
    eval { $md5_store->link_dir( $dir{src} ); 1; },
    'link_dir succeeded without collision check'
);
is(
    $dir{src}->child('md5-1')->stat->ino,
    $dir{src}->child('subdir/md5-2')->stat->ino,
    "different files linked together!"
);
is( $dir{src}->child('md5-1')->stat->mode & 00222,
    0, 'Files not writeable any more' );
is( $dir{src}->child('md5-1')->stat->mode & 00100,
    0100, 'Files still executable' );

# check the inode cache behaviour
%dir = build_work_tree( 'img-01.jpg' );
$store = File::ContentStore->new( $dir{obj} );
is_deeply( $store->inode, {}, 'Empty inode cache' );

my $ino = $dir{src}->child('img-01.jpg')->stat->ino;
link( $dir{src}->child('img-01.jpg'), $dir{src}->child('img-02.jpg') );
is( $dir{src}->child('img-02.jpg')->stat->ino,
    $ino, "Files hard linked to $ino" );

$store->link_dir( $dir{src} );
is( $_->stat->ino, $ino, "$_ linked to inode $ino" )
  for map $dir{src}->child("img-0$_.jpg"), 1 .. 2;
is_deeply(
    $store->inode,
    { $ino => '2c/37ddd32a282aba524d0b6b211125f33cf251e7' },
    'inode cache filled as expected'
);

# a new store on an existing content directory
$store = File::ContentStore->new( $dir{obj} );
is_deeply(
    $store->inode,
    { $ino => '2c/37ddd32a282aba524d0b6b211125f33cf251e7' },
    'inode cache pre-filled'
);

# a symlink test (on systems that support them)
if ($CAN_SYMLINK) {
    %dir = build_work_tree('img-01.jpg');
    symlink( $dir{src}->child('img-01.jpg'), $dir{src}->child('img-02.jpg') );
    symlink( $dir{src}->child('empty'),      $dir{src}->child('null') );
    symlink( $dir{src}->child('null'),       $dir{src}->child('zero') );
    link( $dir{src}->child('null'), $dir{src}->child('nil') );
    $dir{src}->child('empty')->touch;

    $store = File::ContentStore->new( $dir{obj} );
    $store->link_dir( $dir{src} );
    ok( !-l, "$_ is not a symlink" )
      for map $dir{obj}->child($_), values %{ $store->inode };
}

done_testing;
