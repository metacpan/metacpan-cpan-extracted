# $Id: Folder.pm,v 1.14 2002/03/03 13:16:04 joern Exp $

package JaM::Folder;

use strict;
use Carp;
use Data::Dumper;

sub dbh 		{ shift->{dbh}				}

sub id			{ my $s = shift; $s->{id}
		          = shift if @_; $s->{id}		}
sub folder_id		{ my $s = shift; $s->{id}
		          = shift if @_; $s->{id}		}
sub name		{ my $s = shift; $s->{name}
		          = shift if @_; $s->{name}		}
sub sibling_id		{ my $s = shift; $s->{sibling_id}
		          = shift if @_; $s->{sibling_id}	}
sub leaf		{ my $s = shift; $s->{leaf}
		          = shift if @_; $s->{leaf}		}
sub path		{ my $s = shift; $s->{path}
		          = shift if @_; $s->{path}		}
sub selected_mail_id	{ my $s = shift; $s->{selected_mail_id}
		          = shift if @_; $s->{selected_mail_id}	}
sub mail_sum		{ my $s = shift; $s->{mail_sum}
		          = shift if @_; $s->{mail_sum}		}
sub mail_read_sum	{ my $s = shift; $s->{mail_read_sum}
		          = shift if @_; $s->{mail_read_sum}	}
sub status		{ my $s = shift; $s->{status}
		          = shift if @_; $s->{status}	}
sub opened		{ my $s = shift; $s->{opened}
		          = shift if @_; $s->{opened}		}
sub sort_column		{ my $s = shift; $s->{sort_column}
		          = shift if @_; $s->{sort_column}	}
sub sort_direction	{ my $s = shift; $s->{sort_direction}
		          = shift if @_; $s->{sort_direction}	}
sub show_max		{ my $s = shift; $s->{show_max}
		          = shift if @_; $s->{show_max}		}
sub show_all		{ my $s = shift; $s->{show_all}
		          = shift if @_; $s->{show_all}		}
sub undeletable		{ my $s = shift; $s->{undeletable}
		          = shift if @_; $s->{undeletable}	}
sub ignore_reply_to	{ my $s = shift; $s->{ignore_reply_to}
		          = shift if @_; $s->{ignore_reply_to}	}

my $FOLDERS;
my $DBH;

sub init {
	my $type = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};
	return 1 if $FOLDERS;
	$FOLDERS = $type->query ( dbh => $dbh, init => 1 );
	$DBH = $dbh;
	1;
}

sub by_id {
	my $type = shift;
	my ($folder_id) = @_;
	confess "not initialized" unless $FOLDERS;
	confess "unknown folder id '$folder_id'"
		if not exists $FOLDERS->{$folder_id};
	return $FOLDERS->{$folder_id};
}

sub by_path {
	my $type = shift;
	my ($path) = @_;
	confess "not initialized" unless $FOLDERS;

	my $result = $type->query (
		where => 'path=?',
		params => [ $path ]
	);

	my ($ret) = values %{$result};
	return $ret;
}

sub all_folders {
	my $type = shift;
	confess "not initialized" unless $FOLDERS;
	return $FOLDERS;
}

sub query {
	my $type = shift;
	my %par = @_;
	my  ($dbh, $where, $params, $no_cache, $init) =
	@par{'dbh','where','params','no_cache','init'};

	confess "not initialized" if not $FOLDERS and not $init;

	$dbh ||= $DBH;
	$where = "where $where" if $where;

	my %folders;

	if ( not $no_cache and $FOLDERS ) {
		my $ar = $dbh->selectcol_arrayref (
			"select id
			 from   Folder
			 $where", {}, @{$params}
		);
		@folders{@{$ar}} = @$FOLDERS{@{$ar}};

	} else {
		my $sth = $dbh->prepare (
			"select id, name, parent_id, leaf,
				path, selected_mail_id, mail_sum, status,
				mail_read_sum, opened, sort_column,
				sort_direction, sibling_id, show_max,
				show_all, undeletable, ignore_reply_to
			 from   Folder
			 $where"
		);

		$sth->execute (@{$params}) if $params;
		$sth->execute              if not $params;

		my ($id, $name, $parent_id, $leaf,
		    $path, $selected_mail_id, $mail_sum, $status,
		    $mail_read_sum, $opened, $sort_column,
		    $sort_direction, $sibling_id, $show_max,
		    $show_all, $undeletable, $ignore_reply_to);

		$sth->bind_columns (\(
		    $id, $name, $parent_id, $leaf,
		    $path, $selected_mail_id, $mail_sum, $status,
		    $mail_read_sum, $opened, $sort_column,
		    $sort_direction, $sibling_id, $show_max,
		    $show_all, $undeletable, $ignore_reply_to, 
		));

		while ( $sth->fetch ) {
			my $self = {
				dbh    	            => $dbh,
				id	            => $id,
				name	            => $name,
				parent_id           => $parent_id,
				sibling_id          => $sibling_id,
				leaf	            => $leaf,
				path	            => $path,
				selected_mail_id    => $selected_mail_id,
				mail_sum            => $mail_sum,
				mail_read_sum       => $mail_read_sum,
				status		    => $status,
				opened	            => $opened,
				sort_column         => $sort_column,
				sort_direction      => $sort_direction,
				show_max	    => $show_max,
				show_all	    => $show_all,
				undeletable	    => $undeletable,
				ignore_reply_to	    => $ignore_reply_to,
			};
			$folders{$id} = bless $self, $type;
		}
	}
	
	return \%folders;
}

sub create {
	my $type = shift;
	my %par = @_;
	my  ($dbh, $name, $parent, $sibling) =
	@par{'dbh','name','parent','sibling'};

	confess "not initialized" unless $FOLDERS;
	$dbh ||= $DBH;

	my $parent_id  = $parent->id;
	my $sibling_id = $sibling ? $sibling->id : 99999;
	my $path = $parent->path."/$name";
	$path =~ s!/+!/!g;

	$dbh->do (
		"insert into Folder
		 (name, parent_id, sibling_id, leaf, path)
		 values
		 (?, ?, ?, ?, ?)", {},
		 $name, $parent_id, $sibling_id, 1, $path
	);
	
	my $id = $dbh->{mysql_insertid};

	my $self = $type->query (
		dbh => $dbh,
		where => "id=?",
		params => [ $id ],
		no_cache => 1,
	)->{$id};

	$FOLDERS->{$id} = $self;
	
	return $self;
}

sub save {
	my $self = shift;
	
	confess "not initialized" unless $FOLDERS;

	my $parent_id = $self->parent_id;
	my $path;
	if ( $parent_id ) {
		$path = (ref $self)->by_id($parent_id)->path."/";
	} else {
		$path = "/";
	}

	$path .= $self->name;
	$path =~ s!/+!/!g;
	$self->path($path);

	$self->dbh->do (
		"update Folder set
			sibling_id=?, name=?, parent_id=?, leaf=?,
			path=?, selected_mail_id=?, mail_sum=?,
			mail_read_sum=?, opened=?, sort_column=?,
			sort_direction=?, show_max=?, show_all=?,
			status=?, undeletable=?, ignore_reply_to = ?
		 where id=?", {},
		 $self->{sibling_id}, $self->{name},
		 $self->{parent_id}, $self->{leaf}, $self->{path},
		 $self->{selected_mail_id}, $self->{mail_sum},
		 $self->{mail_read_sum}, $self->{opened},
		 $self->{sort_column}, $self->{sort_direction},
		 $self->{show_max}, $self->{show_all}, $self->{status},
		 $self->{undeletable}, $self->{ignore_reply_to},
		 $self->{id}
	);

	1;
}

sub recalculate_folder_stati {
	my $type = shift;
	my %par = @_;
	my  ($dbh) = @par{'dbh'};
	
	confess "not initialized" unless $FOLDERS;
	$dbh ||= $DBH;

	my $sth = $dbh->prepare (	
		"select f1.id, sum(f2.mail_sum-f2.mail_read_sum)
		 from   Folder f1, Folder f2
		 where  f2.path like concat(f1.path,'/%')
		 group by 1"
	);
	$sth->execute;

	my ($ar, $old_status, $new_status, $folder);

	while ( $ar = $sth->fetchrow_arrayref ) {
		$folder = $type->by_id($ar->[0]);
		$old_status = $folder->status;
		$new_status = ($ar->[1] ? 'N' : 'R');
		$new_status = 'NC' if $new_status eq 'N' and $folder->mail_sum == $folder->mail_read_sum;
		if ( $old_status ne $new_status ) {
			$folder->status($new_status);
			$folder->save;
		}
	}
	
	$sth->finish;

	1;
}

sub mark_all_read {
	my $self = shift;

	confess "not initialized" unless $FOLDERS;

	$self->dbh->do (
		"update Mail set status='R' where folder_id=?", {},
		$self->id
	);
	
	$self->mail_read_sum ( $self->mail_sum );
	$self->save;

	1;
}

sub get_first_child_folder_id {
	my $self = shift;
	
	confess "not initialized" unless $FOLDERS;

	my ($folder_id) = $self->dbh->selectrow_array (
		"select Folder.id
		 from   Folder left outer join Folder Sibling
		 	  on Folder.id = Sibling.sibling_id
		 where  Sibling.sibling_id is NULL and
		 	Folder.parent_id=?", {}, $self->id
	);
	
	return $folder_id;
}

sub get_last_child_folder_id {
	my $self = shift;
	
	confess "not initialized" unless $FOLDERS;

	my ($folder_id) = $self->dbh->selectrow_array (
		"select id
		 from   Folder
		 where  parent_id=? and sibling_id=99999", {},
		$self->id
	);
	
	return $folder_id;
}

sub sibling_of_id {
	my $self = shift;

	confess "not initialized" unless $FOLDERS;

	my ($id) = $self->dbh->selectrow_array (
		"select id
		 from   Folder
		 where  sibling_id = ?", {}, $self->id
	);
	
	return $id;
}

sub childs {
	my $self = shift;
	
	return (ref $self)->query (
		where => 'parent_id=?',
		params => [ $self->id ]
	);
}

sub descendants {
	my $self = shift;
	
	my $path = $self->path;
	$path = $path.'/%';

	return (ref $self)->query (
		where => "path like '$path'"
	);
}

sub parent_id {
	my $self = shift;
	my ($value) = @_;
	return $self->{parent_id} if not @_;

	# this computes a the new path
	$self->{parent_id} = $value;
	$self->save;

	# get direct childs
	my $childs = $self->childs;
	
	# compute new path of the childs
	foreach my $child ( values %{$childs} ) {
		# save computes the correct path
		$child->save;
		# do the same for the childs of this child
		$child->parent_id($self->id);
	}
	
	return $value;
}

sub delete_content {
	my $self = shift;
	
	my $desc = $self->descendants;
	my @desc_ids = keys %{$desc};
	
	my $delete_mail_folder_ids = join (',', @desc_ids, $self->id);
	my $delete_folder_ids      = join (',', @desc_ids);

	my ($cnt) = $self->dbh->do (
		"delete from Mail where folder_id in ($delete_mail_folder_ids)"
	);
	
	if ( $delete_folder_ids ) {
		# first delete associated filters
		require JaM::Filter::IO;

		my $filter_ids = $self->dbh->selectcol_arrayref (
			"select id
			 from   IO_Filter
			 where  folder_id in ($delete_folder_ids)"
		);

		my $filter;
		foreach my $filter_id ( @{$filter_ids} ) {
			$filter = JaM::Filter::IO->load (
				dbh => $self->dbh,
				filter_id => $filter_id
			);
			$filter->delete;
		}
	
		# now the folders themselves
		$cnt = $self->dbh->do (
			"delete from Folder where id in ($delete_folder_ids)"
		);
	
		delete @$FOLDERS{@desc_ids};
	}
	
	$self->mail_sum(0);
	$self->mail_read_sum(0);
	$self->leaf(1);
	$self->save;
	
	my %desc_ids;
	@desc_ids{@desc_ids} = (1) x @desc_ids;
	return \%desc_ids;
}

1;
