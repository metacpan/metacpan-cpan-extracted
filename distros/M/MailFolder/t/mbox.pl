use Mail::Folder::Mbox;

$folderdir='../testfolders';

sub okay_if { print(($_[1] ? "ok $_[0]\n" : "not ok $_[0]\n")) }

sub full_folder { return "$folderdir/mbox_1"; }

sub empty_folder { return "$folderdir/mbox_empty"; }

sub seed_folder { return "$folderdir/mbox_seed"; }

sub init_mbox_test {
  my $dir;

  unlink(full_folder());
  system('cp ' . seed_folder() . ' ' . full_folder());
  chmod(0600, full_folder());
  unlink(empty_folder());
  (! -e empty_folder()) ||
    die("can't unlink " . empty_folder() . ": $!\n");
}

init_mbox_test();

1;
