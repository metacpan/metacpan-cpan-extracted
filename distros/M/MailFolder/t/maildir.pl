use Mail::Folder::Maildir;

$folderdir='../testfolders';

sub okay_if { print(($_[1] ? "ok $_[0]\n" : "not ok $_[0]\n")) }

sub full_folder { return "$folderdir/maildir_1"; }

sub empty_folder { return "$folderdir/maildir_empty"; }

sub seed_folder { return "$folderdir/maildir_seed"; }

sub init_maildir_test {
  my $dir;

  for $dir ($folderdir, seed_folder()) {
    (-e $dir) || die("$dir doesn't exist\n");
    (-d $dir) || die("$dir isn't a directory\n");
    (-r $dir) || die("$dir isn't readable\n");
  }
  chmod(0755, full_folder());
  system('rm -rf ' . full_folder() . ' ' . empty_folder());
  mkdir(full_folder(), 0700);
  for (qw(cur new tmp)) {
    mkdir(full_folder() . "/$_", 0700);
  }
  system('cp ' . seed_folder() . "/cur/[0-9]* " . full_folder() . "/cur");
}

init_maildir_test();

1;
