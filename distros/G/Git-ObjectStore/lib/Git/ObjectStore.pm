package Git::ObjectStore;
$Git::ObjectStore::VERSION = '0.007';
use strict;
use warnings;

use Git::Raw;
use Git::Raw::Object;
use Carp;
use File::Spec::Functions qw(catfile);


# ABSTRACT: abstraction layer for Git::Raw and libgit2




sub new
{
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{'author_name'} = 'ObjectStore';
    $self->{'author_email'} = 'ObjectStore@localhost';

    foreach my $arg (qw(repodir branchname)) {
        if ( defined( $args{$arg} ) ) {
            $self->{$arg} = $args{$arg};
        } else {
            croak('Mandatory argument missing: ' . $arg);
        }
    }

    foreach my $arg (qw(writer author_name author_email)) {
        if ( defined( $args{$arg} ) ) {
            $self->{$arg} = $args{$arg};
        }
    }

    if ( $self->{'writer'} and $args{'goto'} ) {
        croak('Cannot use goto in writer mode');
    }

    my $branchname = $self->{'branchname'};
    my $repodir = $self->{'repodir'};

    if ( not -e $repodir . '/config' ) {
        if( $self->{'writer'} ) {
            Git::Raw::Repository->init($repodir, 1);
        } else {
            croak($repodir . ' does not contain a bare Git repository');
        }
    }

    my $repo = $self->{'repo'} = Git::Raw::Repository->open($repodir);
    my $objdir = catfile($repodir, 'objects');

    # We do not use loose backend, so we explicitly exclude it from ODB.
    {
        my $odb = Git::Raw::Odb->new();
        $odb->add_backend(Git::Raw::Odb::Backend::Pack->new($objdir), 10);
        $repo->odb($odb);
    }

    if ( $self->{'writer'} ) {

        my $refname = 'refs/heads/' . $branchname;

        # in-memory store that will write a single pack file for all objects
        $self->{'packdir'} = catfile($objdir, 'pack');
        my $mempack = $self->{'mempack'} = Git::Raw::Mempack->new;
        $repo->odb->add_backend($mempack, 99);

        my $branch = Git::Raw::Branch->lookup($repo, $branchname, 1);

        if( defined($branch) )
        {
            # If previous run of the writer crashed, we have a reference that
            # points to nonexistent commit, because mempack was not written.
            eval { $branch->peel('commit') };
            if( $@ )
            {
                $branch = undef;
                Git::Raw::Reference->lookup($refname, $repo)->delete();
            }
        }
        
        if ( not defined($branch) ) {
            # This is a fresh repo, create the branch
            my $builder = Git::Raw::Tree::Builder->new($repo);
            my $tree = $builder->write();
            my $me = $self->_signature();
            my $commit = $repo->commit("Initial empty commit in $branchname",
                                       $me, $me, [], $tree, $refname);
            $self->{'created_init_commit'} = $commit;
            $branch = Git::Raw::Branch->lookup($repo, $branchname, 1);
        }

        croak('expected a branch') unless defined($branch);

        # in-memory index for preparing a commit
        my $index = Git::Raw::Index->new();

        # assign the index to our repo
        $repo->index($index);

        # initiate the index with the top of the branch
        my $commit = $branch->peel('commit');
        $index->read_tree($commit->tree());

        # memorize the index for quick write access
        $self->{'gitindex'} = $index;

        $self->{'current_commit_id'} = $commit->id();

    } else {
        # open the repo for read-only access
        my $commit;
        if ( defined($args{'goto'}) ) {
            # read from a specified commit
            $commit = Git::Raw::Commit->lookup($repo, $args{'goto'});
            croak('Cannot lookup commit ' . $args{'goto'})
                unless defined($commit);
        } else {
            # read from the top of the branch
            my $branch = Git::Raw::Branch->lookup($repo, $branchname, 1);
            $commit = $branch->peel('commit');
        }

        # memorize the tree that we will read
        $self->{'gittree'} = $commit->tree();

        $self->{'current_commit_id'} = $commit->id();
    }

    return $self;
}


sub _signature
{
    my $self = shift;
    return Git::Raw::Signature->now
        ($self->{'author_name'}, $self->{'author_email'});
}



sub created_init_commit
{
    my $self = shift;
    return $self->{'created_init_commit'};
}




sub repo
{
    my $self = shift;
    return $self->{'repo'};
}





sub read_file
{
    my $self = shift;
    my $filename = shift;

    if ( $self->{'writer'} ) {
        my $entry = $self->{'gitindex'}->find($filename);
        if ( defined($entry) ) {
            return $entry->blob()->content();
        } else {
            return undef;
        }
    } else {
        my $entry = $self->{'gittree'}->entry_bypath($filename);
        if ( defined($entry) ) {
            return $entry->object()->content();
        } else {
            return undef;
        }
    }
}



sub file_exists
{
    my $self = shift;
    my $filename = shift;

    if ( $self->{'writer'} ) {
        return defined($self->{'gitindex'}->find($filename));
    } else {
        return defined($self->{'gittree'}->entry_bypath($filename));
    }
}


sub current_commit_id
{
    my $self = shift;
    return $self->{'current_commit_id'};
}



sub write_and_check
{
    my $self = shift;
    my $filename = shift;
    my $data = shift;

    croak('write_and_check() is called for a read-only ObjectStore object')
        unless $self->{'writer'};

    my $prev_blob_id = '';
    if( defined(my $entry = $self->{'gitindex'}->find($filename)) ) {
        $prev_blob_id = $entry->blob()->id();
    }

    my $entry = $self->{'gitindex'}->add_frombuffer($filename, $data);
    my $new_blob_id = $entry->blob()->id();

    return ($new_blob_id ne $prev_blob_id);
}



sub write_file
{
    my $self = shift;
    my $filename = shift;
    my $data = shift;

    croak('write_file() is called for a read-only ObjectStore object')
        unless $self->{'writer'};

    $self->{'gitindex'}->add_frombuffer($filename, $data);
    return;
}



sub delete_file
{
    my $self = shift;
    my $path = shift;

    croak('delete_file() is called for a read-only ObjectStore object')
        unless $self->{'writer'};
    $self->{'gitindex'}->remove($path);
    return;
}



sub create_commit
{
    my $self = shift;
    my $msg = shift;

    croak('create_commit() is called for a read-only ObjectStore object')
        unless $self->{'writer'};

    if( not defined($msg) ) {
        $msg = scalar(localtime(time()));
    }

    my $branchname = $self->{'branchname'};
    my $repo = $self->{'repo'};
    my $index = $self->{'gitindex'};

    my $branch = Git::Raw::Branch->lookup($self->{'repo'}, $branchname, 1);
    my $parent = $branch->peel('commit');

    # this creates a new tree object from changes in the index
    my $tree = $index->write_tree();

    if( $tree->id() eq $parent->tree()->id() ) {
        # The tree identifier has not changed, hence there are no
        # changes in content
        return 0;
    }

    my $me = $self->_signature();
    my $commit = $repo->commit
        ($msg, $me, $me, [$parent], $tree, $branch->name());

    # re-initialize the index
    $index->clear();
    $index->read_tree($tree);

    $self->{'current_commit_id'} = $commit->id();

    return 1;
}



sub write_packfile
{
    my $self = shift;

    croak('write_packfile() is called for a read-only ObjectStore object')
        unless $self->{'writer'};

    my $repo = $self->{'repo'};
    my $tp = Git::Raw::TransferProgress->new();
    my $indexer = Git::Raw::Indexer->new($self->{'packdir'}, $repo->odb());

    $indexer->append($self->{'mempack'}->dump($repo), $tp);
    $indexer->commit($tp);
    $self->{'mempack'}->reset;
    return;
}



sub create_commit_and_packfile
{
    my $self = shift;
    my $msg = shift;

    if( $self->create_commit($msg) ) {
        $self->write_packfile();
        return 1;
    } elsif ( defined($self->{'created_init_commit'}) ) {
        $self->write_packfile();
    }

    return 0;
}



sub recursive_read
{
    my $self = shift;
    my $path = shift;
    my $callback = shift;
    my $no_content = shift;
    
    croak('recursive_read() is called for a read-write ObjectStore object')
        if $self->{'writer'};

    if( $path eq '' )
    {
        foreach my $entry ($self->{'gittree'}->entries()) {
            $self->_do_recursive_read
                ($entry, $entry->name(), $callback, $no_content);
        }
    } else {
        my $entry = $self->{'gittree'}->entry_bypath($path);
        if( defined($entry) ) {
            $self->_do_recursive_read($entry, $path, $callback, $no_content);
        }
        else
        {
            croak("No such path in the branch: $path");
        }
    }
    return;
}


sub _do_recursive_read
{
    my $self = shift;
    my $entry = shift;  # Git::Raw::Tree::Entry object
    my $path = shift;
    my $callback = shift;
    my $no_content = shift;

    $entry->type();

    if( $entry->type() == Git::Raw::Object->TREE ) {
        # this is a subtree, we read it recursively
        foreach my $child_entry ($entry->object()->entries()) {
            $self->_do_recursive_read
                ($child_entry, $path . '/' . $child_entry->name(), $callback);
        }
    } else {
        if( $no_content ) {
            &{$callback}($path);
        } else {
            &{$callback}($path, $entry->object()->content());
        }
    }

    return;
}





sub read_updates
{
    my $self = shift;
    my $old_commit_id = shift;
    my $cb_updated = shift;
    my $cb_deleted = shift;
    my $no_content = shift;

    my $old_commit = Git::Raw::Commit->lookup($self->{'repo'}, $old_commit_id);
    croak("Cannot lookup commit $old_commit_id") unless defined($old_commit);
    my $old_tree = $old_commit->tree();

    my $new_tree = $self->{'gittree'};

    my $diff = $old_tree->diff
        (
         {
          'tree' => $new_tree,
          'flags' => {
                      'skip_binary_check' => 1,
                     },
         }
        );

    my @deltas = $diff->deltas();
    foreach my $delta (@deltas) {

        my $path = $delta->new_file()->path();

        if( $delta->status() eq 'deleted') {
            &{$cb_deleted}($path);
        } else {
            if( $no_content ) {
                &{$cb_updated}($path);
            } else {
                my $entry = $new_tree->entry_bypath($path);
                &{$cb_updated}($path, $entry->object()->content());
            }
        }
    }

    return;
}







1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::ObjectStore - abstraction layer for Git::Raw and libgit2

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  use Git::ObjectStore;

  ### Writer example ###
  my $store = new Git::ObjectStore('repodir' => $dir,
                                   'branchname' => $bname,
                                   'writer' => 1);

  # write the documents into the store
  my $is_changed = $store->write_and_check('docs/001a', \$doc1text);
  $store->write_file('docs/001b', \$doc2text);

  # documents can be read from the writer object
  my $doc = $store->read_file('docs/001c');

  # check if a document exists and delete it
  if( $store->file_exists('docs/001d') ) {
      $store->delete_file('docs/001d');
  }

  # once the changes are finished, create commit and write it to disk
  $store->create_commit_and_packfile();

  ### Reader example ###
  my $store = new Git::ObjectStore('repodir' => $dir,
                                   'branchname' => $bname);

  # checking existance or reading individual files
  $store->file_exists('docs/001d') and print "file exists\n";
  my $doc = $store->read_file('docs/001c');

  # read all files in a directory and its subdirectories
  my $cb_read = sub {
      my ($path, $data) = @_;
      print("$path: $data\n");
  };
  $store->recursive_read('docs', $cb_read);

  # Check if there are changes and read the updates
  my $cb_updated = sub {
      my ($path, $data) = @_;
      print("Updated $path: $data\n");
  };
  my $cb_deleted = sub {
      my ($path) = @_;
      print("Deleted $path\n");
  };
  if( $store->current_commit_id() ne $old_commit_id ) {
      $store->read_updates($old_commit_id, $cb_updated, $cb_deleted);
  }

=head1 DESCRIPTION

This module provides an abstraction layer on top of L<Git::Raw>, a Perl
wrapper for F<libgit2>, in order to use a bare Git repository as an
object store. The objects are written into a mempack, and then flushed
to disk, so thousands of objects can be created without polluting your
filesystem and exhausting its inode pool.

=head1 METHODS

=head2 new(%args)

Creates a new object. If F<repodir> is empty or does not exist, the
method (in writer mode only) initializes a new bare Git repository. If
multiple processes may call this method simultaneously, it is up to you
to provide locking and prevent the race condition.

Mandatory arguments:

=over 4

=item *

C<repodir>: the directory path where the bare Git repository is located.

=item *

C<branchname>: the branch name in the repository. Multiple L<Git::ObjectStore> objects can co-exist at the same time in multiple or the same process, but the branch names in writer objects need to be unique.

=back

Optional arguments:

=over 4

=item *

C<writer>: set to true if this object needs to write new files into the repository. Writing is always done at the top of the branch.

=item *

C<goto>: commit identifier where the read operations will be performed. This argument cannot be combined with writer mode. By default, reading is performed from the top of the branch.

=item *

C<author_name>, C<author_email>: name and email strings used for commits.

=back

=head2 created_init_commit()

If a C<Git::ObjectStore> object is created in writer mode and the branch
did not exist, the C<new()> method creates an empty initial commit in
this branch. This method returns the initial commit ID, or undef if the
branch already existed.

=head2 repo()

This method returns a L<Git::Raw::Repository> object associated with
this store object.

=head2 read_file($path)

This method reads a file from a given path within the branch. It returns
undef if the file is not found. In writer mode, the file is checked
first in the in-memory mempack. The returned value is the file content
as a scalar.

=head2 file_exists($path)

This method returns true if the given file extsis in the branch. In
reader mode, it also returns true if path is a directory name.

=head2 current_commit_id()

Returns the current commit identifier. This can be useful for detecting
if there are any changes in the branch and retrieve the difference.

=head2 write_and_check($path, $data)

This method writes the data scalar to the repository under specified
file name. It returns true if the data differs from the previous version
or a new file is created. It returns false if the new data is identical
to what has been written before. The data can be a scalar or a reference
to scalar.

=head2 write_file($path, $data)

This method is similar to C<write_and_check>, but it does not compare
the content revisions. It is useful for massive write operations where
speed is important.

=head2 delete_file($path)

This method deletes a file from the branch. It throws an error if the
file does not exist in the branch.

=head2 create_commit([$msg])

This method checks if any new content is written, and creates a Git
commit if there is a change. The return value is true if a new commit
has been created, or false otherwise. An optional argument can specify
the commit message. If a message is not specified, current localtime is
used instead.

=head2 write_packfile()

This method writes the contents of mempack onto the disk. This method
must be called after one or several calls of C<create_commit()>, so that
the changes are written to persistent storage.

=head2 create_commit_and_packfile([$msg])

This method combines C<create_commit()> and C<write_packfile>. The
packfile is only written if there is a change in the content. The method
returns true if any changes were detected. If it's a new branch and it
only contains the empty initial commit, a packfile is written and the
method returns false.

=head2 recursive_read($path, $callback, $no_content)

This method is only supported in reader mode. It reads the directories
recursively and calls the callback for every file it finds. The callback
arguments are the file name and scalar content. If called with string as
path, all files in the branch are traversed. If the third argument is a
true value, the method does not read the object contents, and the
callback is only called with one argument.

=head2 read_updates($old_commit_id, $callback_updated,
$callback_deleted, $no_content)

This method is only supported in reader mode. It compares the current
commit with the old commit, and executes the first callback for all
added or updated files, and the second callback for all deleted
files. The first callback gets the file name and scalar content as
arguments, and the second callback gets only the file name. If the
fourth argument is true, the update callback is called only with rhe
file name.

=head1 AUTHOR

Stanislav Sinyagin <ssinyagin@k-open.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stanislav Sinyagin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
