package t::Math;

use IPC::PerlSSH::Library;

func( sum => 'my $t = 0; $t += $_ for @_; $t' );

1;
