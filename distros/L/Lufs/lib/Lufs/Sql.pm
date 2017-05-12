package Lufs::Sql;

use strict;
use warnings;
use DBIx::Simple;
use Class::DBI::Pg;

{
	package Lufs::Sql::DBI::Node;

	use base 'Class::DBI::Pg';

	__PACKAGE__->set_db(Main => 'dbi:Pg:dbname=lufs;host=bonham', '', '', {AutoCommit => 1});
	__PACKAGE__->set_up_table('node');
	__PACKAGE__->autoupdate(1);

	sub dbx {
		my $self = shift;
		$self->{dbx} ||= DBIx::Simple->connect($self->db_Main);
	}

	sub parent_node {
		my $self = shift;
		$self->retrieve($self->parent);
	}

	sub is_root {
		my $self = shift;
		! $self->name  && $self->parent_node->ino == $self->ino
	}

	sub readdir {
		my $self = shift;
		my $dir = shift;
		grep { ! $_->is_root } $self->search(parent => $self->ino);
	}

	sub abs_path {
		my $self = shift;
		($self->dbx->query("SELECT abs_path(ino) FROM node WHERE ino = ?", $self->ino)->list)[0];
	}
	
	sub absolute_name {
		my $self = shift;
		my $n = $self;
		my (@nm, $ret);
		while (length$n->name) {
			push @nm, $n;
			$n = $n->parent_node;
		}
		for (reverse @nm) {
			$ret .= sprintf "/%s", $_->name;
		}
		$ret;
	}

	sub create_blob {
		my $self = shift;
		my $dbh = $self->db_Main;
		$dbh->{AutoCommit} = 0;
		my $oid = $dbh->func($dbh->{'pg_INV_WRITE'}, 'lo_creat');
		$self->update(content => $oid);
		$dbh->{AutoCommit} = 1;
		$oid;
	}

	sub unlink_blob {
		my $self = shift;
		$self->db_Main->{AutoCommit} = 0;
		$self->db_Main->func($self->content, 'lo_unlink');
		$self->db_Main->{AutoCommit} = 1;
	}

	sub write_blob {
		my $self = shift;
		my $dbh = $self->db_Main;
		my $id = $self->content;
		my ($offset, $count, $data) = @_;
		
		$dbh->{AutoCommit} = 0;
		
		my $lobj_fd = $dbh->func($id, $dbh->{'pg_INV_WRITE'}, 'lo_open');

		$dbh->func($lobj_fd, $offset, 0, 'lo_lseek');
		
		my $len = $dbh->func($lobj_fd, $data, $count, 'lo_write');
		
		die "Errors writing lo\n" if $len != length($data);

		$dbh->func($lobj_fd, 'lo_close');
	 
		$dbh->{AutoCommit} = 1;
			return $len;
	}

	sub read_blob {
		my $self = shift;
		my $dbh = $self->db_Main;
		my ($offset, $len) = @_;
		my $id = $self->content;

		$dbh->{AutoCommit} = 0;

		my $lobj_fd = $dbh->func($id, $dbh->{'pg_INV_READ'}, 'lo_open');
		
		$dbh->func($lobj_fd, $offset, 0, 'lo_lseek');

		$len = $dbh->func($lobj_fd, $_[-1], $len, 'lo_read');

		$dbh->func($lobj_fd, 'lo_close') or die "Problems closing lo object\n";

		$dbh->{AutoCommit} = 1;
		   
		$self->update(atime => time());
		$self->parent_node->update(atime => time());
		return $len;
	}

	sub blob_size {
		my $self = shift;
		($self->dbx->query("SELECT sum(length(data)) from pg_catalog.pg_largeobject where loid = ?", $self->content)->list)[0];
	}

	sub mtime {
		my $self = shift;
		my ($date) = $self->dbx->query("SELECT mtime FROM node WHERE ino = ?", $self->ino)->list;
		int(($self->dbx->query(sprintf("SELECT EXTRACT(EPOCH FROM TIMESTAMP WITH TIME ZONE '%s')", $date))->list)[0]);
	}

	sub atime {
		my $self = shift;
		my ($date) = $self->dbx->query("SELECT atime FROM node WHERE ino = ?", $self->ino)->list;
		int(($self->dbx->query(sprintf("SELECT EXTRACT(EPOCH FROM TIMESTAMP WITH TIME ZONE '%s')", $date))->list)[0]);
	}

	sub ctime {
		my $self = shift;
		my ($date) = $self->dbx->query("SELECT ctime FROM node WHERE ino = ?", $self->ino)->list;
		int(($self->dbx->query(sprintf("SELECT EXTRACT(EPOCH FROM TIMESTAMP WITH TIME ZONE '%s')", $date))->list)[0]);
	}
}

sub init {
	my $self = shift;
	$self->{config} = shift;
	1;
}

sub readdir {
	my $self = shift;
	my $dir = shift;
	$dir =~ s{^(/)\.?(?:\/|$)}{$1};
	my $n = Lufs::Sql::DBI::Node->retrieve(1);
	for (split/\//, $dir) {
		$n = $n->retrieve(name => $_, parent => $n->ino);
	}
	unless ($n) { return 0 }
	push @{$_[-1]}, map $_->name, $n->readdir;
	$self->{_abs} = $dir;
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
	return $relstat;
}

sub lookup_db {
	my $self = shift;
	my $node = shift;
	my $n  = Lufs::Sql::DBI::Node->retrieve(1);
	for (split/\//, $node) {
		return unless $n;
		$n = $n->retrieve(name => $_, parent => $n->ino);
	}
	$n;
}
		
sub stat {
	my $self = shift;
	my $file = shift;
	my $node = $self->lookup($file);
	my $n = $self->lookup_db($node);
	unless ($n) { return 0 }
	for my $key (qw/ino mode nlink uid gid rdev size atime mtime ctime blksize blocks/) {
		$_[-1]->{"f_$key"} = $n->$key;
	}
	return 1;
}

sub setattr {
	my $self  = shift;
	my $node = $self->lookup_db($self->lookup(shift)) or return 0;
	my $attr = shift;
	for my $key (qw/mode size atime mtime ctime blksize blocks/) {
		my $val = $attr->{"f_$key"};
		if (defined $val) {
			$node->$key($val);
		}
	}
#	my ($from, $to) = ($attr->{"f_$key"}, $node->$key);
#		if ("$from" ne "$to") {
#			print STDERR "attempt to CHATTR '$key FROM '$from' to '$to'\n";
#		}
#	}
	return 1;
}

sub readlink {
	my $self = shift;
	my $file = shift;
	my $node = $self->lookup_db($self->lookup($file));
	return 0;
}


sub open {
	my $self = shift;
	my $file = shift;
	my $node = $self->lookup_db($self->lookup($file)) or return 0;
	$node->ino > 0;	
}

sub release {
	my $self = shift;
	my $node = $self->lookup_db($self->lookup($_[0]));	
	my $sz = $node->blob_size;
	$node->size($sz);
	my $rest = $node->size % $node->blksize;
	$node->blocks($rest ? (($node->size-$rest)/$node->blksize) + 1 : $node->size/$node->blksize);
	$node->ctime(time());
	$node->atime(time());
	$node->parent_node->update(ctime => time(), atime => time());


	1;
}

sub read {
	my $self = shift;
	my $file = shift;
	my $node = $self->lookup_db($self->lookup($file)) or return 0;
	$node->read_blob(@_);
}

sub write {
	my $self = shift; 
	my $file = shift;
	my $node = $self->lookup_db($self->lookup($file)) or return 0;
	$node->write_blob(@_);

}

sub create {
	my $self = shift;
	my $node = $self->lookup($_[0]);
	my @dus = split/\//, $node;
	my $file = pop@dus;
	$node = join('/', @dus);
	my $parent = $self->lookup_db($node);
	my $n = $parent->create(
		{
			name => $file,
			mode => 33188,
			parent => $parent->ino,
			blksize => 2048,
		}
	);
	my $blob = $n->create_blob;
	$n->content($blob);
	$parent->ctime(time());
	$parent->atime(time());
	1;
}

sub mkdir {
	my $self = shift;
	my $node = $self->lookup($_[0]);
	my @dus = split/\//, $node;
	my $file = pop@dus;
	$node = join('/', @dus);
	my $parent = $self->lookup_db($node);
	my $n = $parent->create(
		{
			name => $file,
			mode => 16877,
			parent => $parent->ino,
			size => 4096,
		}
	);
	$parent->ctime(time());
	$parent->atime(time());
	$n->ino;
}

sub rmdir {
	my $self = shift;
	my $node = $self->lookup_db($self->lookup(shift));
	my $parent = $node->parent_node;
	$node->delete;
	$parent->ctime(time());
	$parent->atime(time());
	return 1;
}

sub unlink {
	my $self = shift;
	my $node = $self->lookup_db($self->lookup(shift));
	my $parent = $node->parent_node;
	$node->delete;
	$parent->ctime(time());
	$parent->atime(time());
	return 1;
}

1;

