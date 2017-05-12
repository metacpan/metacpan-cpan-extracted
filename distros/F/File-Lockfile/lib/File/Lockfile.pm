package File::Lockfile;

use strict;
use warnings;

use version; our $VERSION = qv('1.0.5');

require Class::Data::Inheritable;
use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(qw/lockfile/);

sub new {
	my ($class, $filename, $dir) = @_;
	$class->lockfile(join("/", $dir, $filename));
	return bless {}, $class;
}

sub write {
	my $fh;
	open $fh, '>', __PACKAGE__->lockfile or die("Can't write lockfile: ".__PACKAGE__->lockfile.": $!");
	print $fh $$;
	close $fh;
}

sub remove {
	unlink __PACKAGE__->lockfile;	
}

sub check {
	my ($class, $lockfile) = @_;
	
	$lockfile = __PACKAGE__->lockfile unless $lockfile;
	
	if ( -s $lockfile ) {
		my $fh;
		open $fh, '<', $lockfile or die("Can't open lockfile for reading: ".__PACKAGE->lockfile.": $!");
		my $pid = <$fh>;
		my $running = kill 0, $pid;
		return $pid if $running;
	}
	return undef;
}

1;
