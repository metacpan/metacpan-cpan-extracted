use t::boilerplate;

use Test::More;
use Capture::Tiny              qw( capture );
use Config;
use Cwd;
use English                    qw( -no_match_vars );
use File::pushd                qw( tempd );
use File::Spec::Functions      qw( catdir catfile curdir );
use IO::Handle;
use Path::Tiny                 qw( );
use Scalar::Util               qw( blessed refaddr );
use Test::Deep                 qw( cmp_deeply );
use File::DataClass::Constants qw( LOCK_NONBLOCKING );
use File::DataClass::Functions qw( is_mswin is_ntfs );
use File::DataClass::IO;

my $io;

sub p { join ';', grep { not m{ \.svn }mx } @_ }
sub f { my $s = shift; is_mswin and $s =~ s/\//\\/g; return $s }

isa_ok( io( $PROGRAM_NAME ), 'File::DataClass::IO' );

subtest 'Deliberate errors' => sub {
   eval { io()->all };

   like $EVAL_ERROR, qr{ \Qnot specified\E }mx,
      'Filename unspecified';

   eval { io( 'quack' )->slurp };

   like $EVAL_ERROR, qr{ File \s+ \S+ \s+ cannot \s+ open }mx,
      'Cannot open file';

   eval { io( [ qw( non_existant file ) ] )->println( 'x' ) };

   like $EVAL_ERROR, qr{ File \s+ \S+ \s+ cannot \s+ open }mx,
      'Cannot create file in non existant directory';

   eval { io( catdir( qw( t xxxxx ) ) )->next };

   like $EVAL_ERROR, qr{ Directory \s+ \S+ \s+ cannot \s+ open }mx,
      'Cannot open directory';

   eval { io( 'qwerty' )->empty };

   like $EVAL_ERROR, qr{ Path \s+ \S+ \s+ not \s+ found }mx, 'No test empty';

   eval { io( 'qwerty' )->encoding };

   like $EVAL_ERROR, qr{ \Qnot specified\E }imx, 'Encoding requires a value';

   ok ! io( 'qwerty' )->exists, 'Non existant file';

   eval { io( 'qwerty' )->rmdir };

   like $EVAL_ERROR, qr{ Path \s+ \S+ \s+ not \s+ removed }mx,
      'Cannot remove non existant directory';

   eval { io( { name => undef } ) };

   like $EVAL_ERROR, qr{ \Qnot a simple string\E }mx,
      'Undefined name not alllowed';

   eval { io()->assert_filepath };

   like $EVAL_ERROR, qr{ \Qnot specified\E }mx,
      'Cannot assert filepath without a name';

   eval { io( 'not_bloody_likely' )->tail };

   like $EVAL_ERROR, qr{ \Qcannot open backward\E }mx,
      'Cannot open a non-existant file to read backwards';
};

subtest 'Polymorphic Constructor' => sub {
   sub _filename { [ qw( t mydir file1 ) ] }

   ok io( catfile( qw( t mydir file1 ) ) )->exists, 'Constructs from path';
   ok io( [ qw( t mydir file1 ) ] )->exists, 'Constructs from arrayref';
   ok io( \&_filename )->exists, 'Constructs from coderef';
   ok io( { name => catfile( qw( t mydir file1 ) ) } )->exists,
      'Constructs from hashref';
   $io = io( [ qw( t mydir file1 ) ], 'r', oct '400' ); $io = io( $io );
   ok $io->exists, 'Constructs from object';
   $io = io( $io, { mode => 'a+', perms => '666' } );
   is $io->mode, 'a+', 'Constructs from object - merges hashref';
   $io = io( [ qw( t mydir file1 ) ], { perms => oct '400' } );
   ok $io->exists && (sprintf "%o", $io->_perms & 07777) eq '400',
      'Constructs from name and hashref';
   is( (sprintf "%o", $io->_perms & 07777), '400',
      'Duplicates permissions from original object' );

   my ($homedir) = glob( '~' ); $homedir =~ s{ / \z }{}mx;

   is io( '~' ), $homedir, 'Expands tilde';
   is io( '~/' ), $homedir, 'Expands tilde with trailing "/"';
   is io( '~/foo/bar' ), "${homedir}/foo/bar", 'Expands tilde with longer path';
   $io = io( '~/foo/bar/' );
   is $io, "${homedir}/foo/bar", 'Expands tilde, longer path and trailing "/"';
   is io( curdir ), Cwd::getcwd, 'Constructs from "."';

   my $ptt = Path::Tiny::path( 't' );

   is io( $ptt )->name, 't', 'Constructs from foreign object';
   ok io( [ qw( t mydir file1 ) ], 'r' )->exists,
    'Constructs from name and mode';
   ok io( name => [ qw( t mydir file1 ) ], mode => 'r' )->exists,
    'Constructs from list of keys and values';

   $io = io( 'test' ); my $clone = $io->clone;
   is $clone->name, 'test', 'Clones';

   eval { File::DataClass::IO->clone };
   like $EVAL_ERROR, qr{ \Qobject method\E }mx, 'Clone is an object method';
};

subtest 'Overload' => sub {
   $io = io( $PROGRAM_NAME );
   is "${io}", $PROGRAM_NAME, 'Stringifies - name';
   is !!$io, 1, 'Boolean true - name';
   $io = io q();
   is !!$io, q(), 'Boolean false - name';
   $io = io;
   like "${io}", qr{ \QIO::Handle\E }mx, 'Stringifies - file handle';
   is !!$io, 1, 'Boolean true - file handle';
};

subtest 'File::Spec::Functions' => sub {
   is( io( '././t/default.xml' )->canonpath, f( catfile( qw( t default.xml ) )),
       'Canonpath' );
   is( io( '././t/bogus'       )->canonpath, f( catfile( qw( t bogus ) ) ),
       'Bogus canonpath' );
   ok( io( catfile( q(), qw( foo bar ) ) )->is_absolute, 'Is absolute' );

   my ($v, $d, $f) = io( catdir( qw( foo bar ) ) )->splitpath;

   is( $d.q(x), catdir( q(foo), q(x) ), 'Splitpath directory' );
   is( $f, q(bar), 'Splitpath file' );

   my @dirs = io( catdir( qw( foo bar baz ) ) )->splitdir;

   is scalar @dirs, 3, 'Splitdir count';
   is( (join q(+), @dirs), q(foo+bar+baz), 'Splitdir string' );
   is io( catdir( q(), qw(foo bar baz) ) )->abs2rel( catdir( q(), q(foo) ) ),
      f( catdir( qw(bar baz) ) ), 'Can abs2rel';
   is io( catdir( qw(foo bar baz) ) )->rel2abs( catdir( q(), q(moo) ) ),
      f( catdir( q(), qw(moo foo bar baz) ) ), 'Can rel2abs';
   is io()->dir( catdir( qw(doo foo) ) )->catdir( qw(goo hoo) ),
      f( catdir( qw(doo foo goo hoo) ) ), 'Catdir 1';
   is io()->dir->catdir( qw(goo hoo) ), f( catdir( qw(goo hoo) ) ), 'Catdir 2';
   is io()->catdir( qw(goo hoo) ), f( catdir( qw(goo hoo) ) ), 'Catdir 3';
   is io()->file( catdir( qw(doo foo) ) )->catfile( qw(goo hoo) ),
       f( catfile( qw(doo foo goo hoo) ) ), 'Catfile 1';
   is io()->file->catfile( qw(goo hoo) ), f( catfile( qw(goo hoo) ) ),
       'Catfile 2';
   is io()->catfile( qw(goo hoo) ), f( catfile( qw(goo hoo) ) ), 'Catfile 3';
   is io( [ qw( t mydir dir1 ) ] )->dirname, catdir( qw(t mydir) ), 'Dirname';
   ok io( [ qw( t mydir dir1 ) ] )->parent->is_dir, 'Parent';
   is io( [ qw( t mydir dir1 ) ] )->parent( 2 ), 't', 'Parent with count';
   ok io( [ qw( t mydir dir1 ) ] )->sibling( 'dir2' )->is_dir, 'Sibling';
   is io( [ qw( t output print.t ) ] )->basename, 'print.t', 'Basename';
   is io()->basename, undef, 'Basename - no name';
   is io( [ qw( t ) ] )->child( undef, {} ), 't', 'Child with undef args';
};

subtest 'Absolute/relative pathname conversions' => sub {
   $io = io()->absolute( 't' );
   is "${io}", 't', 'Absolute - defaults to base';
   $io = io( $PROGRAM_NAME )->absolute;
   is "${io}", File::Spec->rel2abs( $PROGRAM_NAME ), 'Absolute';
   $io->relative;
   is "${io}", File::Spec->abs2rel( $PROGRAM_NAME ), 'Relative';
   ok io( 't' )->absolute->next->is_absolute, 'Absolute directory paths';

   my $tmp = File::Spec->tmpdir;

   is io( $PROGRAM_NAME )->absolute( $tmp ),
      File::Spec->rel2abs( $PROGRAM_NAME, $tmp ), 'Absolute with base';
};

my ($device, $inode, $mode, $nlink, $uid, $gid, $device_id, $size,
    $atime, $mtime, $ctime, $blksize, $blocks) = stat( $PROGRAM_NAME );
my $stat = $io->stat;

subtest 'Retrieves inode status fields' => sub {
   is( $stat->{device},    $device,       'Stat device'      );
   is( $stat->{inode},     $inode,        'Stat inode'       );
   is( $stat->{mode},      $mode,         'Stat mode'        );
   is( $stat->{nlink},     $nlink,        'Stat nlink'       );
   is( $stat->{uid},       $uid,          'Stat uid'         );
   is( $stat->{gid},       $gid,          'Stat gid'         );
   is( $stat->{device_id}, $device_id,    'Stat device_id'   );
   is( $stat->{size},      $size,         'Stat size'        );
   ok( ($stat->{atime} ==  $atime)
    || ($stat->{atime} == ($atime + 1)),  'Stat access time' );
   is( $stat->{mtime},     $mtime,        'Stat modify time' );
   is( $stat->{ctime},     $ctime,        'Stat create time' );
   is( $stat->{blksize},   $blksize,      'Stat block size'  );
   is( $stat->{blocks},    $blocks,       'Stat blocks'      );
};

my $exp1 = 't/mydir/dir1;t/mydir/dir2;t/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp2 = 't/mydir/dir1;t/mydir/dir1/dira;t/mydir/dir1/file1;t/mydir/dir2;t/mydir/dir2/file1;t/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp3 = 't/mydir/dir1;t/mydir/dir1/dira;t/mydir/dir1/dira/dirx;t/mydir/dir1/file1;t/mydir/dir2;t/mydir/dir2/file1;t/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp4 = 't/mydir/dir1;t/mydir/dir1/dira;t/mydir/dir1/dira/dirx;t/mydir/dir1/dira/dirx/file1;t/mydir/dir1/file1;t/mydir/dir2;t/mydir/dir2/file1;t/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp_files1 = 't/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp_files2 = 't/mydir/dir1/file1;t/mydir/dir2/file1;t/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp_files4 = 't/mydir/dir1/dira/dirx/file1;t/mydir/dir1/file1;t/mydir/dir2/file1;t/mydir/file1;t/mydir/file2;t/mydir/file3';
my $exp_dirs1 = 't/mydir/dir1;t/mydir/dir2';
my $exp_dirs2 = 't/mydir/dir1;t/mydir/dir1/dira;t/mydir/dir2';
my $exp_dirs3 = 't/mydir/dir1;t/mydir/dir1/dira;t/mydir/dir1/dira/dirx;t/mydir/dir2';
my $exp_filt1 = 't/mydir/dir1/dira;t/mydir/dir1/dira/dirx';
my $exp_filt2 = 't/mydir/dir1/dira/dirx';

my $dir = catdir( qw(t mydir) );

subtest 'List all files and directories' => sub {
   is( p( io( $dir )->all       ), f( $exp1 ), 'All default'      );
   is( p( io( $dir )->all(1)    ), f( $exp1 ), 'All level 1'      );
   is( p( io( $dir )->all(2)    ), f( $exp2 ), 'All level 2'      );
   is( p( io( $dir )->all(3)    ), f( $exp3 ), 'All level 3'      );
   is( p( io( $dir )->all(4)    ), f( $exp4 ), 'All level 4'      );
   is( p( io( $dir )->all(5)    ), f( $exp4 ), 'All level 5'      );
   is( p( io( $dir )->all(0)    ), f( $exp4 ), 'All level 0'      );
   is( p( io( $dir )->deep->all ), f( $exp4 ), 'All default deep' );

   is( p( io( $dir )->all_files       ), f( $exp_files1 ), 'All files'      );
   is( p( io( $dir )->all_files(1)    ), f( $exp_files1 ), 'All files 1'    );
   is( p( io( $dir )->all_files(2)    ), f( $exp_files2 ), 'All files 2'    );
   is( p( io( $dir )->all_files(3)    ), f( $exp_files2 ), 'All files 3'    );
   is( p( io( $dir )->all_files(4)    ), f( $exp_files4 ), 'All files 4'    );
   is( p( io( $dir )->all_files(5)    ), f( $exp_files4 ), 'All files 5'    );
   is( p( io( $dir )->all_files(0)    ), f( $exp_files4 ), 'All files 0'    );
   is( p( io( $dir )->deep->all_files ), f( $exp_files4 ), 'All files deep' );

   is( p( io( $dir )->all_dirs       ), f( $exp_dirs1 ), 'All dirs'      );
   is( p( io( $dir )->all_dirs(1)    ), f( $exp_dirs1 ), 'All dirs 1'    );
   is( p( io( $dir )->all_dirs(2)    ), f( $exp_dirs2 ), 'All dirs 2'    );
   is( p( io( $dir )->all_dirs(3)    ), f( $exp_dirs3 ), 'All dirs 3'    );
   is( p( io( $dir )->all_dirs(4)    ), f( $exp_dirs3 ), 'All dirs 4'    );
   is( p( io( $dir )->all_dirs(5)    ), f( $exp_dirs3 ), 'All dirs 5'    );
   is( p( io( $dir )->all_dirs(0)    ), f( $exp_dirs3 ), 'All dirs 0'    );
   is( p( io( $dir )->deep->all_dirs ), f( $exp_dirs3 ), 'All dirs deep' );
};

subtest 'Directory listing' => sub {
   my @list = io( $dir )->read_dir;
   is @list, 5, 'Correct number of entries';
};

subtest 'Filters matching patterns from directory listing' => sub {
   is p( io( $dir )->filter( sub { m{ dira }mx } )->deep->all_dirs ),
      f( $exp_filt1 ), 'Filter 1';
   is p( io( $dir )->filter( sub { m{ x }mx    } )->deep->all_dirs ),
      f( $exp_filt2 ), 'Filter 2';
};

subtest 'Chomp newlines and record separators' => sub {
   $io = io( $PROGRAM_NAME )->chomp; my $seen = 0;

   for ($io->slurp) { $seen = 1 if (m{ [\n] }mx) }

   ok !$seen, 'Slurp chomps newlines'; $io->close; $seen = 0;

   for ($io->chomp->separator( 'io' )->getlines) { $seen = 1 if (m{ io }mx) }

   ok !$seen, 'Getlines chomps record separators';
   $io->getlines;
};

subtest 'Alternative state parameters' => sub {
   $io = io( $PROGRAM_NAME ); $io->all;

   ok !$io->is_open, 'Autocloses';

   $io = io( $PROGRAM_NAME, { autoclose => 0 } ); $io->all;

   ok $io->is_open, 'Does not autoclose';
};

subtest 'Create and remove a directory subtree' => sub {
   $dir = catdir( qw(t output subtree) );
   io( $dir )->mkpath; ok   -e $dir, 'Make path';
   $dir = catdir( qw(t output) );
   io( $dir )->rmtree; ok ! -e $dir, 'Remove tree';
   io( $dir )->mkdir;  ok   -e $dir, 'Make directory';
   io( $dir )->rmdir;  ok ! -e $dir, 'Remove directory';
};

subtest 'Setting assert creates path to file' => sub {
   $dir = catdir( qw( t output newpath ) );
   ok ! -e catfile( $dir, 'hello.txt' ), 'Non existant file';
   ok ! -e $dir, 'Non existant directory';
   $io = io( [ $dir, 'hello.txt' ] )->assert;
   ok ! -e $dir, 'Assert does not create directory';
   $io->println( 'Hello' );
   ok -d $dir, 'Writing file creates directory';
   is io()->assert_dirpath( $dir ), $dir, 'Assert directory returns path';
   eval { io()->assert_dirpath( catfile( qw( t default.json ) ) ) };
   like $EVAL_ERROR, qr{ mkdir }imx, 'Assert directory fails if a file exists';
   eval { $io->assert( sub { not $_->exists } ) };
   like $EVAL_ERROR, qr{ \Qassertion failure\E }mx, 'Assert with subroutine';
   is $io->assert( sub { $_->exists } ), $io, 'Assert with sub true';
};

subtest 'Prints with and without newlines' => sub {
   $io = io( [ qw( t output print.t ) ] );
   is $io->print( 'one' )->print( 'two' )->close->slurp, 'onetwo', 'Print 1';
   $io = io( [ qw( t output print.t ) ] );
   is $io->print( "one\n" )->print( "two\n" )->close->slurp, "one\ntwo\n",
      'Print 2';
   $io = io( [ qw( t output print.t ) ] );
   is $io->println( 'one' )->println( 'two' )->close->slurp, "one\ntwo\n",
      'Print 3';
};

subtest 'Appends with and without newlines' => sub {
   $io = io( [ qw( t output print.t ) ] );
   is $io->append( 'three' )->close->slurp, "one\ntwo\nthree", 'Append';
   is $io->appendln( 'four' )->close->slurp, "one\ntwo\nthreefour\n",
      'Append with line feed';
   is $io->close->assert_open( 'r' )->append( 'five' )->close->slurp,
      "one\ntwo\nthreefour\nfive", 'Append when file open for reading';
   is $io->close->assert_open( 'w' )->append( 'six' )->close->slurp,
      "six", 'Append when file open for writing';
   is $io->close->assert_open( 'r' )->appendln( 'seven' )->close->slurp,
      "sixseven\n", 'Append when file open for reading';
   is $io->close->assert_open( 'w' )->appendln( 'eight' )->close->slurp,
      "eight\n", 'Append when file open for writing';
};

subtest 'Gets a single line' => sub {
   $io = io( [ qw( t output print.t ) ] );
   $io->binary->utf8->print( 'öne' );
   is $io->getline, 'öne', 'Getline utf8';
   $io->reset->binmode( ':raw' )->print( 'öne' );
   is $io->getline( $RS ), 'öne', 'Getline utf8 - raw';
   # TODO: Make tests of these
   $io->getline;
   $io->getline;
   $io->assert_open( 'r' )->binmode( ':crlf' );
   $io = io( [ qw( t output print.t ) ] )->binmode( ':crlf' );
   $io->assert_open( 'r' )->binary->binary;
};

subtest 'Create and detect empty subdirectories and files' => sub {
   $io = io( catdir( qw(t output empty) ) );
   ok $io->mkdir, 'Make a directory';
   ok $io->is_empty, 'The directory is empty';
   ok $io->empty, 'The directory is empty - deprecated';

   my $path = catfile( qw(t output file) ); $io = io( $path ); $io->touch( 0 );

   ok -e $path, 'Touch a file into existance';
   is_mswin or is $io->stat->{mtime}, 0, 'Sets modidification date/time';
   ok $io->empty, 'The file is empty';
};

# Cwd
$io = io()->cwd;

is "${io}", Cwd::getcwd(), 'Current working directory';

subtest 'Tempfile/seek' => sub {
   my @lines = io( $PROGRAM_NAME )->chomp->slurp; $io = io( 't' );
   my $temp  = $io->tempfile;

   $temp->println( @lines ); $temp->seek( 0, 0 );

   my $text = $temp->slurp || q();

   ok length $text == $size,
      'Creates a tempfile seeks to the start and slurps content';
   is blessed( $io->delete_tmp_files ), 'File::DataClass::IO',
      'Delete tmp files';
   is blessed( $io->delete_tmp_files( '%6.6d....' ) ), 'File::DataClass::IO',
      'Delete tmp files - non default template';

   $temp = io->tempfile;
   ok $temp->pathname, 'Default temporary file';
};

subtest 'Tell' => sub {
   my $io = io $PROGRAM_NAME; $io->getline;

   is $io->tell, 20, 'Tells at end of first line';
   $io->seek( 0, 0 );
   is $io->tell, 0, 'Tells at start of file';
   $io->close;
   $io->seek( 0, 0 );
   is $io->tell, 0, 'Tells at start of file when file closed';
};

subtest 'Buffered reading/writing' => sub {
   my $outfile = catfile( qw( t output out.pm ) );

   ok ! -f $outfile,   'Non existant output file';

   my $input = io( [ qw(lib File DataClass IO.pm) ] )->open->block_size( 4096 );

   ok ref $input,      'Open input';

   my $output = io( $outfile )->open( 'w' );

   ok ref $output,     'Open output';

   if (is_mswin) { $input->binary; $output->binary; }

   my $buffer; $input->buffer( $buffer ); $output->buffer( \$buffer );

   ok defined $buffer, 'Define buffer';

   $output->write while ($input->read);

   ok !length $buffer, 'Empty buffer';
   ok $output->close,  'Close output';
   ok -s $outfile,     'Exists output file';
   ok $input->stat->{size} == $output->stat->{size}, 'File sizes match';

   my $bs = $input->_block_size; $input->block_size;

   ok $input->_block_size == $bs, 'Cannot set block size to undef';
};

subtest 'Digest' => sub {
   my $io = io( [ 't', 'other.json' ] );

   is $io->hexdigest, $io->hexdigest( 'SHA-256' ), 'Default digest';
   is $io->hexdigest( { block_size => 4 } ),
      $io->hexdigest( 'SHA-256', { block_size => 1024 } ),
      'Digest - block size';
};

SKIP: {
   is_ntfs
      and skip 'Heads/Tails too flakey 29a2bb0c-6bf4-1014-974a-4394dad81770', 1;

   subtest 'Heads / Tails' => sub {
      is scalar @{ [ io( $PROGRAM_NAME )->head ] }, 10, 'Default head lines';
      like( (io( $PROGRAM_NAME )->head( 3 ))[ -1 ], qr{ Test::More }mx,
            'Third line' );
      is scalar @{ [ io( $PROGRAM_NAME )->tail( undef, "\n" ) ] }, 10,
            'Default tail lines';
      like( (io( $PROGRAM_NAME )->tail( 3, "\n" ))[ 0 ], qr{ perl }mx,
            'Second last line' );
   };

   subtest 'Getline / getlines backwards' => sub {
      like io( $PROGRAM_NAME )->backwards->getline, qr{ End }mx,
         'Getline backwards';

      my @lines = io( $PROGRAM_NAME )->backwards->getlines;

      like $lines[ 0 ], qr{ End }mx, 'Getlines backwards';
   };
};

subtest 'Creates a file using atomic write' => sub {
   my $atomic_file = catfile( qw( t output B_atomic ) );
   my $outfile     = catfile( qw( t output atomic ) );

   $io = io( $outfile )->atomic->lock->println( 'x' );
   ok  -f $atomic_file, 'Atomic file exists';
   ok !-e $outfile,     'Atomic outfile does not exist'; $io->close;
   ok !-e $atomic_file, 'Renames atomic file';
   ok  -f $outfile,     'Writes atomic file';

   $atomic_file = catfile( qw( t output X_atomic ) );
   $io = io( $outfile )->atomic->atomic_infix( 'X_*' )->print( 'x' );
   ok  -f $atomic_file, 'Atomic file exists - infix'; $io->close;
   ok !-e $atomic_file, 'Renames atomic file - infix';

   $atomic_file = catfile( qw( t output atomic.tmp) );
   $io = io( $outfile )->atomic->atomic_suffix( '.tmp' )->print( 'x' );
   ok  -f $atomic_file, 'Atomic file exists - suffix'; $io->close;
   ok !-f $atomic_file, 'Renames atomic file - suffix';

   my $io = io( $outfile )->atomic_infix( undef );

   is $io->_atomic_infix, 'B_*', 'Default atomic infix';
   $io->atomic_suffix( undef );
   is $io->_atomic_infix, 'B_*', 'Default atomix suffix';
   io( $outfile )->delete;
   $io = io( $outfile )->atomic->lock( LOCK_NONBLOCKING )->println( 'x' );
   io( $outfile )->close;
};

subtest 'Substitution' => sub {
   $io = io [ qw( t output substitute ) ];
   $io->println( qw( line1 line2 line3 ) );
   $io->substitute( 'line2', 'changed' );
   is( ($io->chomp->getlines( $RS ))[ 1 ], 'changed',
       'Substitutes one value for another' );
   $io->close;
   $io->substitute( 'line2' );
   is( ($io->chomp->getlines( $RS ))[ 1 ], undef, 'Substitutes null string' );
   $io->substitute( undef, 'nonono' );
   $io->substitute( q(), 'nonono' );
};

subtest 'Copy / Move' => sub {
   my $all = $io->close->all; my $to = io [ qw( t output copy ) ];

   $io->close; $io->copy( $to );
   is $to->all, $all, 'Copies a file - object target';
   $to->unlink; $io->copy( [ qw( t output copy ) ] );
   is $to->all, $all, 'Copies a file - constructs target';
   $to->unlink; $io->copy( Path::Tiny::path( "${to}" ) );
   is $to->all, $all, 'Copies a file - foreign object target';
   $io = $to; $to = io [ qw( t output object_target ) ]; $io = $io->move( $to );
   is $io->all, $all, 'Moves a file - object target';
   $to = [ qw( t output constructs_target ) ]; $io = $io->move( $to );
   is $io->all, $all, 'Moves a file - constructs target';
   $to = Path::Tiny::path( io( [ qw( t output foreign_object ) ] )->pathname );
   $io = $io->move( $to );
   is $io->all, $all, 'Moves a file - foreign object target';
};

SKIP: {
   is_ntfs and skip 'Unix ownership and permissions not applicable', 1;

   subtest 'Ownership' => sub {
      $io = io( [ qw( t output print.t ) ] );

      my $uid = $io->stat->{uid}; my $gid = $io->stat->{gid};

      eval { $io->chown( undef, $gid ) };
      like $EVAL_ERROR, qr{ \Qnot specified\E }mx,
         'Uid must be defined in chown';
      eval { $io->chown( $uid, undef ) };
      like $EVAL_ERROR, qr{ \Qnot specified\E }mx,
         'Gid must be defined in chown';
      is blessed( $io->chown( $uid, $gid ) ), 'File::DataClass::IO', 'Chown';
      eval { $io->chown( 65.534, $gid ) };
      $EFFECTIVE_USER_ID != 0 and
         like $EVAL_ERROR, qr{ \Qchown failed\E }mx, 'Chown failure';
   };

   subtest 'Permissions' => sub {
      $io = io();
      ok !$io->is_executable, 'Not executable - no name';
      ok !$io->is_link, 'Not a link - no name';
      ok !$io->is_readable, 'Not readable - no name';
      ok !$io->is_writable, 'Not writable - no name';
      $io = io( [ qw( t output print.t ) ] ); $io->print( 'one' );
      ok  $io->is_readable,   'Readable';
      ok  $io->is_writable,   'Writable';
      ok !$io->is_executable, 'Not executable';
   };

   subtest 'Changes permissions of existing file' => sub {
      $io->chmod( 0400 );
      is( (sprintf "%o", $io->stat->{mode} & 07777), '400', 'Chmod 400' );
      $io->chmod();
      is( (sprintf "%o", $io->stat->{mode} & 07777), '640', 'Chmod default' );
      $io->chmod( 0777 );
      is( (sprintf "%o", $io->stat->{mode} & 07777), '777', 'Chmod 777' );
   };

   subtest 'More permissions' => sub {
      ok $io->is_executable, 'Executable';
      $io->perms( 0 )->chmod;
      is( (sprintf "%o", $io->stat->{mode} & 07777), '0', 'Chmod 0' );
   };

   subtest 'Creates files with specified permissions' => sub {
      my $path = catfile( qw( t output print.pl ) );

      $io = io( $path, 'w', oct q(0400) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(400), 'Create 400' );
      $io->unlink;
      $io = io( $path, 'w', oct q(0440) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(440), 'Create 440' );
      $io->unlink;
      $io = io( $path, 'w', oct q(0600) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(600), 'Create 600' );
      $io->unlink;
      $io = io( $path, 'w', oct q(0640) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(640), 'Create 640' );
      $io->unlink;
      $io = io( $path, 'w', oct q(0644) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(644), 'Create 644' );
      $io->unlink;
      $io = io( $path, 'w', oct q(0664) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(664), 'Create 664' );
      $io->unlink;
      $io = io( $path, 'w', oct q(0666) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(666), 'Create 666' );
      $io->unlink;
      $io = io( $path )->perms( oct q(0640) )->println( 'x' );
      is( (sprintf "%o", $io->stat->{mode} & 07777), q(640),
          'Create using prefered syntax' );
      $io->unlink;
   };
}

subtest 'Predicates' => sub {
   is io()->is_dir, 0, 'Unspecified name is not a dir';
   is io()->is_file, 0, 'Unspecified name is not a file';
   is io( 'not_found' )->is_file, 0, 'Non-existant name is not a file';
   is io()->exists, 0, 'Unspecified name does not exist';
};

SKIP: {
   $Config{d_symlink} or skip 'No symlink support', 1;

   subtest 'Iterators and follow / not follow symlinks' => sub {
      my $wd       = tempd;
      my @tree     = qw( aaaa.txt bbbb.txt cccc/dddd.txt cccc/eeee/ffff.txt
                         gggg.txt );
      my @shallow  = qw( aaaa.txt bbbb.txt cccc gggg.txt pppp qqqq.txt );
      my @follow   = qw( aaaa.txt bbbb.txt cccc gggg.txt pppp qqqq.txt
                         cccc/dddd.txt cccc/eeee cccc/eeee/ffff.txt
                         pppp/ffff.txt );
      my @nofollow = qw( aaaa.txt bbbb.txt cccc gggg.txt pppp qqqq.txt
                         cccc/dddd.txt cccc/eeee cccc/eeee/ffff.txt );

      $_->touch for (map { io( $_ )->assert_filepath } @tree);

      CORE::symlink io( [ 'cccc', 'eeee' ] ), io( 'pppp' );
      CORE::symlink io( [ 'aaaa.txt'     ] ), io( 'qqqq.txt' );

      subtest 'Follow' => sub {
         my $dir = io( '.' )->deep; my @files = ();

         for my $f (map { $_->relative( $dir ) } $dir->all) {
            push @files, "${f}";
         }

         cmp_deeply( [ sort @files ], [ sort @follow ],
                     'Follow symlinks - deep' ) or diag explain \@files;
      };

      subtest 'No follow' => sub {
         my $dir = io( '.' )->deep->no_follow; my @files;

         for my $f (map { $_->relative( $dir ) } $dir->all) {
            push @files, "${f}";
         }

         cmp_deeply( [ sort @files ], [ sort @nofollow ],
                     "Don't follow symlinks" ) or diag explain \@files;
      };

      subtest 'Follow - iterator' => sub {
         my $io = io( '.' ); my $iter = $io->iterator; my @files;

         while (my $f = $iter->()) { push @files, $f->relative( $io )->name }

         cmp_deeply( [ sort @files ], [ sort @shallow ],
                     'Follow symlinks - shallow' ) or diag explain \@files;

         $io = io( '.' )->deep; $iter = $io->iterator; @files = ();

         while (my $f = $iter->()) { push @files, $f->relative( $io )->name }

         cmp_deeply( [ sort @files ], [ sort @follow ],
                     'Follow symlinks - deep' ) or diag explain \@files;
      };

      subtest 'No Follow - iterator' => sub {
         my $io = io( '.' )->deep->no_follow; my $iter = $io->iterator;
         my @files;

         while (my $f = $iter->()) { push @files, $f->relative( $io )->name }

         cmp_deeply( [ sort @files ], [ sort @nofollow ],
                     "Don't follow symlinks" ) or diag explain \@files;
      };

      subtest 'Follow - iterator with filter' => sub {
         my $io = io( '.' )->deep->filter( sub { m{ ffff.txt }mx } );

         my $iter = $io->iterator; my @files;

         while (my $f = $iter->()) { push @files, $f->relative( $io )->name }

         cmp_deeply( [ sort @files ],
                     [ 'cccc/eeee/ffff.txt', 'pppp/ffff.txt', ],
                       'Follow symlinks with filter' ) or diag explain \@files;
      };
   };
}

subtest 'Visit' => sub {
   my $io = io( [ 't', 'mydir' ] ); my $count = 0;

   my $state = $io->visit( sub {
      $count++; $count == 1 ? undef : $count == 9 ? \0 : \1 }, {
         recurse => 1, follow_symlinks => 1 } );
   is $count, 9, 'Visit';
};

subtest 'Proxied IO::Handle methods' => sub {
   my $buf = q(); $io = io $PROGRAM_NAME;

   is $io->sysread( $buf, 18 ), 18, 'Sysread byte count';
   like $buf, qr{ boilerplate }mx, 'Sysread buffer';
   is refaddr $io->autoflush, refaddr $io, 'Autoflush returns self';
   $io = io [ 't', 'output', 'proxy_test' ]; $io->touch; eval { $io->truncate };
   is $EVAL_ERROR->class, 'InvocantUndefined', 'Throw without handle';
   is $io->syswrite( 'byte me', 2, 5 ), 2, 'Syswrite byte count';
   is $io->getc, 'm', 'Getc';
   like $io->fileno, qr{ \d+ }mx, 'Fileno';
   ok !$io->eof, 'Not EOF'; $io->getc;
   ok  $io->eof, 'EOF';
   $io->close->unlink;
   $io = io; $io->fdopen( 2 , 'w' );
   ok $io->is_open, 'Fdopen is open';
   (undef, $buf) = capture { $io->print( 'test' )->close };
   is $buf, 'test', 'Proxy fdopen';
};

# Cleanup
io( [ 't', 'output' ] )->rmtree;

done_testing;

# Local Variables:
# coding: utf-8
# mode: perl
# tab-width: 3
# End:
