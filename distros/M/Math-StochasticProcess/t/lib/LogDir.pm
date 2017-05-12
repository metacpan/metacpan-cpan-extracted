package LogDir;
use strict;
use warnings;
use Carp;
use File::Spec;
use DirHandle;
use FileHandle;

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{dirname} = "log";
	mkdir $self->{dirname} || croak "error: $!";

	my $dir = DirHandle->new($self->{dirname});
	if (defined $dir) {
		while (defined($_ = $dir->read)) {
			unlink File::Spec->catfile($self->{dirname}, $_);
		}
	}
	
	return $self;
}

sub spawn_file {
	my $self = shift;
	my $name = shift;
	my $logfh = FileHandle->new;
	my $filen = File::Spec->catfile($self->{dirname}, $name);
	open($logfh, ">$filen") or croak "could not open log file: $name";
	return $logfh;
}

1
