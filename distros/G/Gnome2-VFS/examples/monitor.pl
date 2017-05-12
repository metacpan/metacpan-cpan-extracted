
use strict;
use warnings;
use Gnome2::VFS -init;

push @ARGV, "file:///tmp" unless @ARGV;
foreach my $dir (@ARGV) {
	print STDERR "creating monitor $dir... ";
	my($res,$handle)= Gnome2::VFS::Monitor->add ($dir, 'directory', \&dir_cb );
	print STDERR "$res\n";
}

Glib::MainLoop->new->run;

sub dir_cb {
	my $self= shift;
	my($dir, $file, $event)= @_;
	print STDERR "$event: $file in $dir\n";
}

