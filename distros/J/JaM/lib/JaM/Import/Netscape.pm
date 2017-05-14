#!/usr/local/bin/perl

package JaM::Import::Netscape;

use Carp;
use strict;
use File::Find;
use Data::Dumper;
use FileHandle;
use JaM::Drop;
use JaM::Folder;

sub dbh 		{ shift->{dbh}				}
sub abort_file 		{ shift->{abort_file}			}

sub nsmail_dir		{ my $s = shift; $s->{nsmail_dir}
		          = shift if @_; $s->{nsmail_dir}	}

sub folder_progress_callback	{ my $s = shift; $s->{folder_progress_callback}
		         	  = shift if @_; $s->{folder_progress_callback} }

sub mail_progress_callback	{ my $s = shift; $s->{mail_progress_callback}
		         	  = shift if @_; $s->{mail_progress_callback}   }

sub new {
	my $type = shift;
	my %par = @_;
	my ($dbh, $abort_file) = @par{'dbh','abort_file'};

	my $self = {
		dbh	   => $dbh,
		abort_file => $abort_file,
		nsmail_dir => "$ENV{HOME}/nsmail",
	};

	JaM::Folder->init ( dbh => $dbh );
	
	return bless $self, $type;
}

sub nsmail_folders {
	my $self = shift;
	
	return $self->{nsmail_folders} if defined $self->{nsmail_folders};
	
	my $nsmail_dir = $self->nsmail_dir;
	confess "$nsmail_dir not found" if not -d $nsmail_dir;

	my @folders;
	find ( 	sub {
			my $file = "$File::Find::dir/$_";
			return if not -f $file;
			return if $file =~ m!/\.!;
			return if $_ eq 'Outbox';
			$file =~ s/^$nsmail_dir//;
			my $name = $file;
			$name =~ s/\.sbd//g;
			push @folders, {
				name => $name,
				file => $file,
			};
			1;
		},
		$nsmail_dir
	);
	
	@folders = sort {$a->{name} cmp $b->{name} } @folders;
	
	return $self->{nsmail_folders} = \@folders;
}

sub create_folders {
	my $self = shift;
	
	my $callback = $self->folder_progress_callback;
	my $folders = $self->nsmail_folders;
	my $dbh = $self->dbh;

	my ($name, $parent_object, $leaf, $parent, $full_name, $folder_object);

	my $i = 0;
	my %parent_folders;
	my %folder_exists;

	my $abort_file = $self->abort_file;

	foreach my $folder ( @{$folders} ) {
		last if -f $abort_file;

		$full_name = $folder->{name};
		$folder_object = JaM::Folder->by_path($full_name);

		if ( $folder_object ) {
			$parent_folders{$full_name} = $folder_object;
			$folder_exists{$full_name}  = $folder_object;
			++$i;
			next;
		}
		
		($parent, $name) = ($full_name =~ m!^(.*)/([^/]+)$!);
		$parent_object = $parent_folders{$parent} || JaM::Folder->by_id(1);
		$leaf = 1;
		$leaf = 0 if $i+1<@{$folders} and $folders->[$i+1]->{name} =~ m!^$full_name/!;

		if ( $folder_exists{$parent} ) {
			$folder_exists{$parent}->leaf(0);
			$folder_exists{$parent}->save;
		}

		my $new_folder = JaM::Folder->create (
			name   => $name,
			parent => $parent_object,
		);
		$new_folder->sibling_id(-1);
		$new_folder->leaf($leaf);
		$new_folder->path($full_name);
		$new_folder->save;

		&$callback ($full_name) if $callback;

		$parent_folders{$full_name} = $new_folder;

		++$i;
	}
	
	$self->build_sibling_relation (
		parent_object => JaM::Folder->by_id(1)
	);
	
	1;
}

sub build_sibling_relation {
	my $self = shift;
	my %par = @_;
	my ($parent_object) = @par{'parent_object'};
	
	my $dbh = $self->dbh;
	
	my $childs = JaM::Folder->query (
		dbh => $dbh,
		where => "parent_id=?",
		params => [ $parent_object->id ]
	);
	
	foreach my $child ( values %{$childs} ) {
		if ( not $child->leaf ) {
			$self->build_sibling_relation (
				parent_object => $child
			);
		}

		if ( $child->sibling_id == -1 ) {
			my $last_child_id = $parent_object->get_last_child_folder_id;

			if ( $last_child_id ) {
				my $last_child = JaM::Folder->by_id ( $last_child_id );
				$last_child->sibling_id($child->id);
				$last_child->save;
			}
			$child->sibling_id(99999);
			$child->save;
		}
	}
}

sub import_folders {
	my $self = shift;
	
	my $folders = $self->nsmail_folders;
	my $nsmail_dir = $self->nsmail_dir;

	my $fh = FileHandle->new;

	my $abort_file = $self->abort_file;
	my $dropper = JaM::Drop->new (
		fh  => $fh,
		dbh => $self->dbh,
		abort_file => $abort_file,
	);

	$dropper->progress_callback($self->mail_progress_callback);

#	$JaM::Drop::VERBOSE = 1;

	foreach my $folder ( @{$folders} ) {
		my $folder_id = JaM::Folder->by_path($folder->{name})->id;
		my $filename = "$nsmail_dir$folder->{file}";
		next if -s $filename == 0;

		$dropper->folder_id ($folder_id);

		if ( open ($fh, $filename) ) {
			$dropper->drop_mails;
			close $fh;
		} else {
			warn "can't read $filename";
		}
		
		last if -f $abort_file;
	}

	1;	
}

1;
