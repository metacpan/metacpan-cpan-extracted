package Lufs::Http;

use Net::HTTP;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Date;
use URI::WithBase;
use Fcntl qw/:DEFAULT :mode/;
use HTML::TokeParser::Simple;
use strict;

sub init {
	my $self = shift;
	$self->{config} = shift;
	$self->{config}{uri} ||= 'http://ftp.student.utwente.nl/';
	$self->{root} = URI->new($self->{config}{uri});
	1;
}

sub mount {
	my $self = shift;
	$self->head->is_success;
}

sub stat {
	my $self = shift;
	my $node = shift;
	$node =~ s{/\.$}{};
	my $resp = $self->head($node);
	if ($resp->code =~ /^[45]/) {
		return 0;
	}
	my $add = $self->_format_statref($node, $resp);

	map {$_[0]->{$_}=$add->{$_}} grep /^f_/, keys %{$add};
	1;
}

sub readlink {
	my $self = shift;
	my $node = shift;
	my $resp = $self->head($node);
	my $stat = $self->_format_statref($node, $resp);
	if (( $stat->{f_mode} & S_IFLNK) == S_IFLNK) {
		my $to = URI->new($resp->header('Location'));
		my $root = $self->{root}->path;
		my $path = $to->path;
		unless ($path =~ s/^\Q$root\E//) { return 0 }
		$_[0] = $path;
		return 1;
	}
	return 0;
}

sub open {
	my $self = shift;
	my $node = shift;
	my $mode = shift;
	if (exists $self->{handles}{$node}) {
		return 0;
	}
	if (($mode & O_WRONLY) == O_WRONLY) {
		return 0;
	}
	my ($h, $resp) = $self->get($node);
	unless ($resp->is_success) { return 0 }
	$self->{handles}{$node} = $h;
	1;
}

sub release {
	my $self = shift;
	my $node = shift;
	delete $self->{handles}{$node};
	1;
}

sub umount {
	my $self = shift;

}

sub read {
	my $self = shift;
	my $node = shift;
	my $offset = shift;
	my $count = shift;
	my $len;
	$_[0] = '';
	my $handle;
	unless ($handle = $self->{handles}{$node}) {
		return -1;
	}
	if ($handle->_rbuf_length) {
		my $buf = ${*$handle}{http_buf};
		$len = length($buf);
		$_[0] = substr($buf, 0, $len);
		${*$handle}{http_buf} = '';
	}
	my $buf;
	my $total = $len;
	while ($total < $count) {
		my $ret = $handle->sysread($buf, $count - $total);
		$_[0] .= substr($buf, 0, $ret) if $ret;
		$total += $ret;
		last if $ret == 0;
	}
	$total;
}

sub write { 0 }

sub readdir {
	my $self = shift;
	my $node = shift;
	my $list = shift;
	$self->{_pwd} = '';
	my ($c, $r) = $self->get($node.'/');
	unless ($r->is_success) { return 0 }
	my $html;
	my %dir;
	while (<$c>) { $html .= $_ }
	my $parser = HTML::TokeParser::Simple->new(\$html) or return 1;
	while ( my $token = $parser->get_token ) {
		if ($token->is_start_tag) {
			my $ref = $token->return_attr->{href} || $token->return_attr->{src};
			next unless $ref;
			my $uri = URI::WithBase->new($ref, $self->{root}.'/')->rel;
#			print STDERR sprintf "REL: '%s' ABS '%s'\n", $uri, $uri->abs;
			# we want only links that to stuff in this dir
			next if $uri->scheme;
			next unless $uri->can('host');
			next if $uri->host;
			next if length($self->{root}->path) and $uri->path =~ /^\//;
			my $path = $uri->path;
			$path =~ s{^\.?/}{};
			my @s = split/\//, $path;
			if (@s > 1) {
				my $d = $s[0];
				my $stat = $self->_statref($d);
				$stat->{_forcedir} = 1;
				$dir{$d}++;
			}
			else {
				$dir{$path}++;
			}
		}
	}
	push @$list, keys %dir;
	$self->{_pwd} = $node;
	return 1;
}

sub head {
	my $self = shift;
	my $path = $self->base_uri($_[0]);
	my $c = Net::HTTP->new(Host => $self->{root}->host);
	$c->write_request(HEAD => $path);
	my($code, $mess, %h) = $c->read_response_headers;
	$self->TRACE('HEAD', $path, $code, $mess, \%h);
	HTTP::Response->new($code, $mess, HTTP::Headers->new(%h));
}

sub get {
	my $self = shift;
	my $path = $self->base_uri($_[0]);
	my $c = Net::HTTP->new(Host => $self->{root}->host);
	$c->write_request(GET => $path);
	my($code, $mess, %h) = $c->read_response_headers;
	$self->TRACE('GET', $path, $code, $mess, \%h);
	($c,HTTP::Response->new($code, $mess, HTTP::Headers->new(%h)));
}

sub _format_statref {
	my $self = shift;
	my $node = shift;
	my $resp = shift;
	my $ref = $self->_statref($node);
	$ref->{f_ino} = $self->inode($node);
	if ($self->{_forcedir}) {
		print STDERR "FORCE DIR voor $node\n";
		$ref->{f_mode} |= S_IFDIR;
	}
	elsif ($resp->is_redirect) {
		my $to = URI->new($resp->header('Location'))->path;
		my $from = $self->base_uri($node);
		if ($to eq $from.'/') {
			$ref->{f_mode} |= S_IFDIR;
		}
		else {
			$ref->{f_mode} |= S_IFLNK;
		}
	}
	elsif ((split/\//, $node)[-1] =~ /\.\w+/) {
		$ref->{f_mode} |= S_IFREG;
	}
	else {
		$ref->{f_mode} |= S_IFREG;
		#$ref->{f_mode} |= S_IFDIR;
	}
	if ($resp->code != 403) {
		$ref->{f_mode} |= 0755;
	}
	$ref->{f_size} = $resp->header('Content-Length') || ~1;
	if ($resp->header('Date')) {
		$ref->{f_mtime} = str2time($resp->header('Date'));
	}
	if ($node eq '/' || $node eq '') {
		$ref->{f_mode} = S_IFDIR;
	}
	if (($ref->{f_mode} & S_IFDIR) == S_IFDIR) {
		$ref->{f_mode} |= 0755;
		$ref->{f_size} = 4096;
	}
	$ref;
}

sub base_uri {
	my $self = shift;
	my $node = shift;
	if ($node !~ /^\//) { $node = "$self->{_pwd}/$node" }
	my $u = $self->{root}->path. '/' . $node;
	$u =~ s{/+}{/}g;
	$u;
}

sub inode {
	my $self = shift;
	my $node = $self->base_uri($_[0]);
	if (exists $self->{_inodes}{$node}) {
		return $self->{_inodes}{$node};
	}
	else {
		return $self->{_inodes}{$node} = ++$self->{_maxino};
	}
}

sub _statref {
	my $self = shift;
	my $ino = $self->inode($_[0]);
	$self->{_stat}{$ino} ||= { f_ino => $ino};
}

1;

