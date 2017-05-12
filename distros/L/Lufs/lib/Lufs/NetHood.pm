package Lufs::NetHood;

use Fcntl qw/:mode/;

use strict;

sub init {
	my $self = shift;
	$self->{config} = shift;
	$self->{config}{smbdir} ||= './../../../campus';
	$self->{config}{netdb} ||= '/var/cache/nethood.pd';
	$self->read_db;
	1;
}

sub read_db {
	my $self = shift;
	open(DB,"< $self->{config}{netdb}") or return;
	my $ret;
	{
		my $VAR1;
		eval join('', <DB>);
		if ($@) {
			print STDERR "ERROR READING DB: $@\n";
			$ret = 0;
		}
		elsif (ref($VAR1)&& keys%{$VAR1}) {
			$self->{net} = $VAR1;
			$ret = 1;
		}
		$self->{lastdb} = -C $self->{config}{netdb};
	}
	close DB;
	$ret;
}

sub db_updated {
	my $self = shift;
	if (-C $self->{config}{netdb} != $self->{lastdb}) {
		print STDERR "db updated, reload\n";
		return 1;
	} 0
}


sub readdir {
	my $self = shift;
	my $dir = shift;
	if ($self->db_updated) { $self->read_db }
	$dir =~ s{^(/)(?:\.?(?:\/|$)?)}{$1};
	if ($dir eq '/') {
		push @{$_[-1]}, keys %{$self->{net}};
		$self->{abs} = '';
		return 1;
	}
	$self->{_abs} = $dir;
	my $host = (split/\//, $dir)[1];
	push @{$_[-1]}, $self->list_shares($host);
	return 1;
}

sub lookup {
	my $self = shift;
	my $name = shift;
	my $relstat = $name;
	if ($relstat !~ /^\//) {
		$relstat =~ s{^\./*}{};
		$relstat = $self->{_abs}.'/'.$relstat;
	}
	elsif ($relstat eq '/.') { return "" }
	$relstat =~ s{/+}{/}g;
	$relstat =~ s{/$}{};
	$relstat =~ s{^/}{};
	return $relstat;
}

sub _drr {
	my $ref = shift;
	$ref->{f_ino} = 1;
	$ref->{f_mode} = S_IFDIR | 0755;
	$ref->{f_nlink} = 1;
	$ref->{f_uid} = 0;
	$ref->{f_gid} = 0;
	$ref->{f_rdev} = 0;
	$ref->{f_size} = 2048;
	$ref->{f_atime} = time;
	$ref->{f_mtime} = time;
	$ref->{f_ctime} = time;
	$ref->{f_blksize} = 512;
	$ref->{f_blocks} = 4;
}

sub _lnk {
	my $ref = shift;
	$ref->{f_ino} = int(rand(10000));
	$ref->{f_mode} = 41471;
	$ref->{f_nlink} = 1;
	$ref->{f_uid} = 1;
	$ref->{f_gid} = 1;
	$ref->{f_rdev} = 0;
	$ref->{f_atime} = time;
	$ref->{f_mtime} = time;
	$ref->{f_ctime} = time;
	$ref->{f_blksize} = 512;
	$ref->{f_blocks} = 8;
}

sub stat {
	my $self = shift;
	my $raw = shift;
	my $node = $self->lookup($raw);	
	if ($node eq '') {
		# DIR
		_drr($_[-1]);
		return 1;
	}
	elsif ($node =~ m/\// == 1) {
		my ($host, $share) = split/\//, $node;
		print STDERR "SHARE='$share', HOST='$host', RETURN SYMLINK\n";
		# SYMLINK
		_lnk($_[-1]);
		my $target;
		unless ($self->readlink($raw, $target)) {
			$_[-1]->{f_size} = 0;
		} else {
			$_[-1]->{f_size} = length($target);
		}
		return 1;
	}
	# DIR
	_drr($_[-1]);
	return 1;
}

sub readlink {
	my $self = shift;
	my ($host, $share) = split/\//, $self->lookup(shift);
	my $ip = $self->get_ip($host);
	my $str = sprintf "%s/${host}${ip}_${share}", $self->{config}{smbdir};
	$_[0] = $str;
	return length($str);
}

sub list_shares { 
	my $self = shift;
	if ($self->db_updated) { $self->read_db }
	my $s = $self->{net}{uc($_[0])} or return;
	eval {@{$s->{shares}} };
}

sub get_ip {
	my $self = shift;
	my $ip = $self->{net}{$_[0]}{ip};
	if (length$ip) { $ip = "_$ip" }
	$ip
}

1;

