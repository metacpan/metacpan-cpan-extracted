use Evo 'Test::More; Evo::Internal::Exception; File::Temp';
use Evo 'Fcntl; Time::HiRes time';
use English qw( -no_match_vars );

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs;

my $fs = Evo::Fs->new(root => File::Temp->newdir);

sub _write ($path, $what) {
  $fs->sysopen(my $fh, $path, 'w');
  $fs->syswrite($fh, $what);
  $fs->close($fh);
}

sub _slurp ($path) {
  $fs->sysopen(my $fh, $path, 'r');
  my $buf;
  $fs->sysread($fh, \$buf, 100);
  $fs->close($fh);
  $buf;
}

EXISTS_SIZE: {
  ok !$fs->exists('/foo');
  _write('/foo', '123');
  ok $fs->stat('/foo')->is_file;
  $fs->unlink('/foo');
  ok !$fs->exists('/foo');
}

# maybe superfluous
#SYSOPEN_CLOSE: {
#  my $fh = $fs->sysopen('/foo', O_WRONLY | O_CREAT);
#  $fs->syswrite($fh, "123456");
#  $fs->close($fh);
#  is _slurp('/foo'), '123456';
#
#  $fh = $fs->sysopen('/foo', O_WRONLY | O_CREAT);
#  $fs->syswrite($fh, "xxx");
#  $fs->close($fh);
#  is _slurp('/foo'), 'xxx456';
#
#  $fh = $fs->sysopen('/foo', O_WRONLY | O_CREAT | O_TRUNC);
#  $fs->syswrite($fh, "new");
#  $fs->close($fh);
#  is _slurp('/foo'), 'new';
#
#  $fs->unlink('/foo');
#}

READ: {
  _write('/foo', '123456');

  $fs->sysopen(my $fh, '/foo', 'r');
  my $buf = 'xxBAD';
  $fs->sysread($fh, \$buf, 3, 2);
  is $buf, 'xx123';

  $buf = '';
  $fs->sysread($fh, \$buf, 2);
  is $buf, '45';

  # read many
  $fs->close($fh);
  $fs->unlink('/foo');
  _write('/foo', '123456');
  $fs->sysopen($fh, '/foo', 'r');
  is $fs->sysread($fh, \$buf, 1000), 6;

  $fs->close($fh);
  $fs->unlink('/foo');
}

SEEK: {
  # sysseek
  _write('/foo', '123456');

  $fs->sysopen(my $fh, '/foo', 'r');

  like exception { $fs->sysseek($fh, 10, 'BAD') }, qr/bad.+BAD.+$0/i;
  my $buf = '';
  $fs->sysread($fh, \$buf, 100);    # to end
  $fs->sysseek($fh, 0);
  $buf = '';
  $fs->sysread($fh, \$buf, 100);
  is $buf, '123456';


  $buf = '';
  $fs->sysseek($fh, -3, 'cur');
  $fs->sysread($fh, \$buf, 100);
  is $buf, '456';

  $buf = '';
  $fs->sysseek($fh, -2, 'end');
  $fs->sysread($fh, \$buf, 100);
  is $buf, '56';

  $fs->close($fh);
  $fs->unlink('/foo');
}


# different forms of read
# different forms of write
WRITE: {
  $fs->sysopen(my $fh, '/foo', 'w');
  is $fs->syswrite($fh, "123456"), 6;
  is _slurp('/foo'), '123456';
  $fs->close($fh);
  $fs->unlink('/foo');

  $fs->sysopen($fh, '/foo', 'w');
  is $fs->syswrite($fh, "123456", 2), 2;
  is _slurp('/foo'), '12';
  $fs->close($fh);
  $fs->unlink('/foo');

  $fs->sysopen($fh, '/foo', 'w');
  is $fs->syswrite($fh, "123456", 3, 1), 3;
  is _slurp('/foo'), '234';
  $fs->close($fh);
  $fs->unlink('/foo');

  $fs->sysopen($fh, '/foo', 'w');
  is $fs->syswrite($fh, "123456", 1000), 6;
  is _slurp('/foo'), '123456';
  $fs->close($fh);
  $fs->unlink('/foo');
}


STAT: {

  #if ($^O eq 'MSWin32') {
  #  diag "skipping stat on windows";
  #  last STAT;
  #}

  $fs->write("/foo/bar/baz", 'hello');
  my $stat = $fs->stat('/foo/bar/baz');
  ok defined $stat->dev;
  ok defined $stat->ino;
  is $stat->size, 5;
  ok $stat->is_file;
  ok !$stat->is_dir;
  $fs->remove_tree('/foo');

  $fs->mkdir('/somedir');
  $stat = $fs->stat('/somedir');
  ok defined $stat->dev;
  ok defined $stat->ino;
  ok !$stat->is_file;
  ok $stat->is_dir;
  $fs->remove_tree('/somedir');

  # cando
  $fs->sysopen(my $fh, "/foo", 'w', oct 000);
  $stat = $fs->stat('/foo');
  if ($UID) {
    ok !$stat->can_read;
    ok !$stat->can_write;
  }
  ok !$stat->can_exec;
  is $stat->perms, oct 000;
  $fs->close($fh);
  $fs->unlink('/foo');

  $fs->sysopen($fh, "/foo", 'w', oct 700);
  $stat = $fs->stat('/foo');
  ok $stat->can_read;
  ok $stat->can_write;
  ok $stat->can_exec;
  is $stat->perms, oct 700;
  $fs->close($fh);
  $fs->unlink('/foo');
}

UTIMES: {
  _write('/foo', 'hello');
  $fs->utimes('/foo', 1, 2);
  my $stat = $fs->stat('/foo');
  is $stat->atime, 1;
  is $stat->mtime, 2;
}

LOCK: {
  _write('/foo', 'hello');
  $fs->sysopen(my $fh1, '/foo', 'r');
  $fs->sysopen(my $fh2, '/foo', 'r');
  $fs->sysopen(my $fh3, '/foo', 'r+');
  $fs->sysopen(my $fh4, '/foo', 'r+');

  ok $fs->flock($fh1, 'sh');
  ok $fs->flock($fh2, 'sh');

  ok !$fs->flock($fh3, 'ex_nb');

  ok $fs->flock($fh1, 'un');
  ok $fs->flock($fh2, 'un');

  ok $fs->flock($fh3, 'ex_nb');
  $fs->close($fh1);
  $fs->close($fh2);
  $fs->close($fh3);
  $fs->close($fh4);
  $fs->unlink('/foo');
}

SYMLINK: {

  #if ($^O eq 'MSWin32') {
  #  diag "skipping symlink on windows";
  #  last SYMLINK;
  #}

  $fs->write('/foo', 'foo');
  $fs->symlink('/foo', '/link');
  is $fs->read('/link'), 'foo';
  is $fs->stat('/foo')->ino, $fs->stat('/link')->ino;
  ok $fs->is_symlink('/link');
  ok !$fs->is_symlink('/foo');

  like exception { $fs->symlink('/404', '/link') }, qr/exists.+$0/;
  $fs->unlink('/foo');
  $fs->unlink('/link');
}

LINK: {
  $fs->write('/foo', 'foo');
  $fs->link('/foo', '/link');
  is $fs->read('/link'), 'foo';
  is $fs->stat('/foo')->ino, $fs->stat('/link')->ino;
  ok !$fs->is_symlink('/link');
  ok !$fs->is_symlink('/foo');

SKIP: {
    #last SKIP if $^O eq 'MSWin32';
    like exception { $fs->symlink('/404', '/link') }, qr/exists.+$0/;
  }
  $fs->unlink('/foo');
  is $fs->read('/link'), 'foo';
  $fs->unlink('/link');
}

RENAME: {
  $fs->write('/foo', 'foo');
  $fs->rename('/foo', '/bar');
  ok !$fs->exists('/foo');
  is $fs->read('/bar'), 'foo';
  $fs->unlink('/bar');
}


# ---------- dirs
MAKE_TREE_REMOVE_TREE: {
  $fs->make_tree('/bar/p2/p3');
  ok $fs->stat('/bar/p2/p3')->is_dir;
  $fs->remove_tree('/bar', {keep_root => 1});
  ok !$fs->exists('/bar/p2');
  ok $fs->exists('/bar');
  $fs->remove_tree('/bar');
  ok !$fs->exists('/bar');

  # TODO: - test with cur mask
  # $fs->make_tree('/bar/p2/p3', oct 700);
  # is $fs->stat('/bar/p2/p3')->perms, oct 700;
  # $fs->remove_tree('/bar');
}


MKDIR: {
  ok !$fs->exists('/bar');
  $fs->mkdir('/bar');
  ok $fs->stat('/bar')->is_dir;
  $fs->remove_tree('/bar');

  # TODO: - test with cur mask
  # $fs->mkdir('/bar', oct 700);
  # is $fs->stat('/bar')->perms, oct 700;
  # $fs->remove_tree('/bar');
}

# list
$fs->mkdir('/bar');
$fs->sysopen(my $f1, '/bar/f1', 'w');
$fs->sysopen(my $f2, '/bar/f2', 'w');
is_deeply [sort $fs->ls('/bar')], [qw(f1 f2)];

$fs->close($f1);
$fs->close($f2);
$fs->unlink('/bar/f1');
$fs->unlink('/bar/f2');

$fs->remove_tree('/bar');
ok !$fs->exists('/bar');

ERRORS: {
  # exceptions file
  local $SIG{__WARN__} = sub { };
  _write('/existing', 'foo');
  $fs->sysopen(my $fh, '/existing', 'r');

  # flock
  $fs->sysopen($fh, '/existing', 'r');
  like exception { $fs->flock($fh, 'boo') }, qr/flag.+$0/i;

  $fs->sysopen($fh, '/existing', 'r');
  $fs->close($fh);
  like exception { $fs->flock($fh, 'sh') }, qr/bad.+descriptor.+$0/i;

  # utimes
  like exception { $fs->utimes('/not_exists', undef, undef); }, qr/No such.+$0/;


  $fs->mkdir('/existing_dir');
  like exception { $fs->sysopen(my $fh, '/existing_dir', 'w'); }, qr/denied|is a directory.+$0/i;
  like exception { $fs->unlink('/not_exists'); }, qr/No such file.+$0/;
  like exception { $fs->stat('/not_exists'); },   qr/No such file or directory.+$0/;

  # exceptions dir
  like exception { $fs->remove_tree('/not_exists'); }, qr/No such.+directory.+$0/;
  like exception { $fs->ls('/not_exists'); },          qr/No such.+directory.+$0/;

  _write('/not_a_dir', 'foo');
  like exception { $fs->make_tree('/not_a_dir'); }, qr/exists.+$0/i;
  like exception { $fs->mkdir('/not_a_dir') }, qr/exists.+$0/i;
  like exception { $fs->mkdir('/mydir') for 1 .. 2; }, qr/exists.+$0/i;

  $fs->close($fh);
}

done_testing;
