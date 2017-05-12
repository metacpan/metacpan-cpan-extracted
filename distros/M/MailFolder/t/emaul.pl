use Mail::Folder::Emaul;

$folderdir='../testfolders';

sub okay_if { print(($_[1] ? "ok $_[0]\n" : "not ok $_[0]\n")) }

sub full_folder { return "$folderdir/emaul_1"; }

sub empty_folder { return "$folderdir/emaul_empty"; }

sub seed_folder { return "$folderdir/emaul_seed"; }

sub init_emaul_test {
  my $dir;

  for $dir ($folderdir, seed_folder()) {
    (-e $dir) || die("$dir doesn't exist\n");
    (-d $dir) || die("$dir isn't a directory\n");
    (-r $dir) || die("$dir isn't readable\n");
  }
  chmod(0755, full_folder());
  system('rm -rf ' . full_folder() . ' ' . empty_folder());
  mkdir(full_folder(), 0755);
  system('cp ' . seed_folder() . "/[0-9]* " . full_folder());
  system('cp ' . seed_folder() . '/.msg_labels ' . full_folder());
  system('echo 1 >' . full_folder() . '/.current_msg');
  chmod(0644, full_folder() . '/.msg_labels');
}

init_emaul_test();

1;
