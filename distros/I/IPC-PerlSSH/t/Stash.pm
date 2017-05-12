package t::Stash;

use IPC::PerlSSH::Library;

init 'our %pad;';

func put => 'our %pad; $pad{$_[0]} = $_[1]';

func get => 'our %pad; $pad{$_[0]}';

1;
