use Evo 'Test::More; Evo::Internal::Exception';
use Evo 'Fcntl; File::Spec; File::Temp';

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

like exception { $fs->sysopen(my $fh, '/foo', 'BAD'); }, qr/bad mode BAD/i;

OPEN_BY_FILE: {
  ok $fs->sysopen(my $fh, 'foo', 'w');
  $fs->syswrite($fh, 'hello');
  ok $fs->sysopen($fh, 'foo', 'r'), $fh;
  $fs->sysread($fh, \my $buf, 100);
  is $buf, 'hello';
  $fs->close($fh);
  $fs->unlink('foo');
}


OPEN_RELATIVE: {
  my $buf;
  _write('foo', 'hello');
  $fs->sysopen(my $fh, 'foo', 'r');
  $fs->close($fh);
  $fs->unlink('foo');
}


OPEN_R: {
  like exception { $fs->sysopen(my $fh, '/foo', 'r') }, qr/No such file.+$0/;

  my $buf;
  _write('/foo', 'hello');
  $fs->sysopen(my $fh, '/foo', 'r');
  $fs->sysread($fh, \$buf, 100);
  is $buf, 'hello';

  local $SIG{__WARN__} = sub { };
  like exception { $fs->syswrite($fh, 'hello') }, qr/Can't write.+$0/;
  $fs->close($fh);
  $fs->unlink('/foo');

}

OPEN_R_PLUS: {
  like exception { $fs->sysopen(my $fh, '/foo', 'r+') }, qr/No such file.+$0/;

  my $buf;
  _write('/foo', 'hello');
  $fs->sysopen(my $fh, '/foo', 'r+');
  $fs->syswrite($fh, "12");
  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \$buf, 100);
  is $buf, '12llo';

  $fs->close($fh);
  $fs->unlink('/foo');
}

OPEN_W: {
  my $mode = 'w';

  # create
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  is _slurp('/foo'), 'hello';

  # truncate
  $fs->sysopen($fh, '/foo', $mode);
  $fs->syswrite($fh, '12');
  is _slurp('/foo'), '12';

  # not for read
  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($fh, \my $buf, 100) }, qr/Can't read.+$0/;

  $fs->close($fh);
  $fs->unlink('/foo');
}

OPEN_WX: {
  my $mode = 'wx';
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  is _slurp('/foo'), 'hello';

  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($fh, \my $buf, 100) }, qr/Can't read.+$0/;

  # exists
  like exception { $fs->sysopen(my $fh, '/foo', $mode) }, qr/File exists.+$0/;
  $fs->close($fh);
  $fs->unlink('/foo');
}

OPEN_W_PLUS: {
  my $buf;
  my $mode = 'w+';

  # create
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \$buf, 100);
  is $buf, 'hello';

  # truncate
  $fs->sysopen($fh, '/foo', $mode);
  $fs->syswrite($fh, '12');
  is _slurp('/foo'), '12';

  $fs->close($fh);
  $fs->unlink('/foo');
}

OPEN_WX_PLUS: {
  my $buf;
  my $mode = 'wx+';

  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \$buf, 100);
  is $buf, 'hello';

  # exists
  like exception { $fs->sysopen($fh, '/foo', $mode) }, qr/File exists.+$0/;
  $fs->close($fh);
  $fs->unlink('/foo');
}


A: {

  my $mode = 'a';

  # create
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  is _slurp('/foo'), 'hello';

  # reopen append
  $fs->sysopen($fh, '/foo', $mode);
  $fs->sysseek($fh, 0);    # ignored
  $fs->syswrite($fh, 'foo');
  is _slurp('/foo'), 'hellofoo';

  # not for read
  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($fh, \my $buf, 100) }, qr/Can't read.+$0/;

  $fs->close($fh);
  $fs->unlink('/foo');
}

AX: {
  my $mode = 'ax';

  # create
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  $fs->sysseek($fh, 0);    # ignored
  $fs->syswrite($fh, 'foo');
  is _slurp('/foo'), 'hellofoo';

  # not for read
  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($fh, \my $buf, 100) }, qr/Can't read.+$0/;

  # exists
  like exception { $fs->sysopen($fh, '/foo', $mode) }, qr/File exists.+$0/;
  $fs->close($fh);
  $fs->unlink('/foo');
}


A_PLUS: {
  my $buf;
  my $mode = 'a+';

  # create
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');

  # reopen append
  $fs->sysopen($fh, '/foo', $mode);
  $fs->sysseek($fh, 0);    # ignored
  $fs->syswrite($fh, 'foo');
  is _slurp('/foo'), 'hellofoo';

  # read
  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \$buf, 100);
  is $buf, 'hellofoo';

  $fs->close($fh);
  $fs->unlink('/foo');
}

AX_PLUS: {

  my $buf;
  my $mode = 'ax+';

  # create
  $fs->sysopen(my $fh, '/foo', $mode);
  $fs->syswrite($fh, 'hello');
  $fs->sysseek($fh, 0);    # ignored
  $fs->syswrite($fh, 'foo');
  is _slurp('/foo'), 'hellofoo';

  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \$buf, 100);
  is $buf, 'hellofoo';

  # exists
  like exception { $fs->sysopen(my $fh, '/foo', $mode) }, qr/File exists.+$0/;
  $fs->close($fh);
  $fs->unlink('/foo');
}


OPEN_R: {
  eval { $fs->open('/foo/bar.txt', 'r'); };
  eval { $fs->open('/foo/bar.txt', 'r+'); };
  ok !$fs->exists('/foo/bar.txt');

  my $fh = $fs->open('/foo/bar.txt', 'w');
  $fs->close($fh);
  ok $fs->exists('/foo/bar.txt');
  $fs->close($fh);
}

done_testing;
