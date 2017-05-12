use Evo 'Test::More; File::Temp';
plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';

require Evo::Fs;

COPY_FILE: {
  my $fs = Evo::Fs->new(root => File::Temp->newdir);
  $fs->write('/from/d/f' => 'OK');
  $fs->copy_file('/from/d/f' => '/to/d/f');
  is $fs->read('/to/d/f'), 'OK';
}

COPY_DIR_EXISTING: {
  my $fs = Evo::Fs->new(root => File::Temp->newdir);
  $fs->write_many('/base/child/file' => 'OK');
  $fs->make_tree('/copy/child');
  $fs->copy_dir('/base', 'copy');
  is $fs->read('/copy/child/file'), 'OK';
}


COPY_DIR_NOT_EXISTING: {
  my $fs = Evo::Fs->new(root => File::Temp->newdir);

  $fs->write_many(
    '/base/fbase'  => 'Fbase',
    '/base/d1/f1a' => 'F1a',
    '/base/d1/f1b' => 'F1b',
    '/base/d2/f2a' => 'F2a',
  );
  $fs->mkdir('/base/emptydir');

  $fs->copy_dir('/base', 'copy');


  is $fs->read('/copy/fbase'),  'Fbase';
  is $fs->read('/copy/d1/f1a'), 'F1a';
  is $fs->read('/copy/d1/f1b'), 'F1b';
  is $fs->read('/copy/d2/f2a'), 'F2a';
  ok $fs->stat('/copy/emptydir')->is_dir();
}

COPY_DIR_EXISTING: {
  my $fs = Evo::Fs->new(root => File::Temp->newdir);
  $fs->write_many('/base/l1/l2/file' => 'OK');
  $fs->copy_dir('/base/l1', '/copy/l1');
  is $fs->read('/copy/l1/l2/file'), 'OK';
}

COPY_UPPER: {
  my $tmp = File::Temp->newdir;
  my $root = Evo::Fs->new(root => "$tmp");
  $root->write('files/corpus/file', 'OK');

  my $testing = Evo::Fs->new(root => "$tmp/files/testing");
  $testing->cd('..')->copy_dir('corpus', 'testing');
  is $testing->read('file'), 'OK';
}

done_testing;
