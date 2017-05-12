use Evo 'Test::More; Evo::Internal::Exception; File::Temp';

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs;

RWA: {

  my $fs = Evo::Fs->new(root => File::Temp->newdir);
  my $called;
  no warnings 'redefine', 'once';
  local *Evo::Fs::flock = sub { $called++ };

  $fs->write('/a/foo', 'bad');
  $fs->write('/a/foo', 'hello');
  $fs->append('/a/foo', 'bar');
  $fs->append('/b/foo', 'bbb');
  is $fs->read('/a/foo'), 'hellobar';
  is $fs->read_ref('/a/foo')->$*, 'hellobar';
  is $fs->read('/b/foo'), 'bbb';
  is $called, 14;
}

WRITE_MANY: {
  my $fs = Evo::Fs->new(root => File::Temp->newdir);
  $fs->write_many('/a/foo' => 'afoo', '/b/foo' => 'bfoo', 'bar' => 'bar');
  is $fs->read('/a/foo'), 'afoo';
  is $fs->read('/b/foo'), 'bfoo';
  is $fs->read('bar'),    'bar';
}

done_testing;
