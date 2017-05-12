package Lufs::Mux;

use strict;
# strict aint no country i ever heard of
# they speak english in strict?

use Cwd;
use File::Basename;
use base 'Lufs::Local';
use Fcntl;

sub init {
	my $self = shift;
	$self->{config} = shift;
	$self->{dirs} = [map { s{/?$}{/};$_ } split/;/, $self->{config}{dirs}];
	1;
}


sub readdir {
	my $self = shift;
	my $dir = shift;
	my $reldir = $dir;
	if ($reldir !~ /^/) {
		$reldir =~ s{^\.?/+}{};
		$reldir = $self->{_abs}.'/'.$reldir;
	}
	for ($self->dirs) {
		my $c = "$_/$reldir";
		if (-d $c) {
			$self->SUPER::readdir($c, @_);
		}
	}
	my %files;
	map { $files{$_}++ } @{$_[-1]};
	@{$_[-1]} = keys%files;
	$self->{_abs} = $dir;
	1;
}

sub dirs {
	my $self = shift;
	if (@{$self->{dirs}}) {
		return @{$self->{dirs}};
	}
	qw{/mnt/doos /mnt/bonham /data};
}

sub lookup {
	my $self = shift;
	my $name = shift;
	my $relstat = $name;
	if ($relstat !~ /^\//) {
		$relstat =~ s{^\./*}{};
		$relstat = $self->{_abs}.'/'.$relstat;
	}
	for ($self->dirs) {
		my $c = "$_/$relstat";
		$c =~ s{/+}{/}g;
		if (-e $c) {
			return $c;
		}
	}
	return;	
}

sub stat {
	my $self = shift;
	my $file = shift;
	my $node = $self->lookup($file);
	return 0 unless defined $node;
	$self->SUPER::stat($node,@_);
}

sub open {
	my $self = shift;
	my $mode = $_[-1];
#	if ( (( $mode & O_RDWR) == O_RDWR) || (( $mode & O_WRONLY ) == O_WRONLY) ) {
#		print STDERR "NO WRITE SUPPORT ON MUXFS!\n";
#		return 0;
#	}
	my $node = $self->lookup(shift);
	return 0 unless defined $node;
	$self->SUPER::open($node, @_);
}

sub release {
	my $self = shift;
	my $node = $self->lookup(shift);
	return 0 unless defined $node;
	$self->SUPER::release($node, @_);
}

sub read {
	my $self = shift;
	my $node = $self->lookup(shift);
	return 0 unless defined $node;
	$self->SUPER::read($node, @_);
}

sub readlink { 0 }
sub write { 0 }
sub create { 0 }
sub touch { 0 }
sub mkdir { 0 }
sub rmdir { 0 }
sub rename { 0 }
sub link { 0 }
sub symlink { 0 }

1;


