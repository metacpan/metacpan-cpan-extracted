
=head1 NAME

Document::Repository

=head1 SYNOPSIS

my $repository = new Document::Repository;

my $doc_id = $repository->add($filename);

my $filename = $repository->get($doc_id, $dir);

$repository->put($doc_id, $filename, $filename, $filename)
    or die "couldn't put $filename";

$repository->delete($doc_id)
    or die "couldn't delete $doc_id";

=head1 DESCRIPTION

This module implements a repository of documents, providing general
access to add/get/delete documents.  This module is not intended to be
used directly; for that see Document::Manager.  This acts as a general
purpose backend.

A document is a collection of one or more files that are checked out,
modified, and checked back in as a unit.  Each revision of a document is
numbered, and documents can be reverted to older revisions if needed.  A
document can also have an arbitrary set of metadata associated with it.

=head1 FUNCTIONS

=cut

package Document::Repository;

use strict;
use File::Copy;
use File::Path;
use File::Spec::Functions qw(:ALL);


use vars qw(%FIELDS);

use fields qw(
              _repository_dir
              _repository_permissions
              _next_id
              _error_msg
	      _debug
              );


=head2 new($confighash)

Establishes the repository interface object.  You must pass it the
location of the repository, and optionally can indicate what permissions
to use (0600 is the default).

If the repository already exists, indicate where Document::Repository
should start its numbering (e.g., you may want to store this info
in a config file or something between invokations...)

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    while (my ($field, $value) = each %args) {
	if (exists $FIELDS{"_$field"}) {
	    $self->{"_$field"} = $value;
	    if ($args{debug} && $args{debug}>3 && defined $value) {
		warn 'Setting Document::Repository::_'.$field." = $value\n";
	    }
	}
    }

    # Specify defaults
    $self->{_repository_dir} ||= '/var/dms';
    $self->{_repository_permissions} ||= '0700';
    $self->{_next_id} = 1;
    $self->{_debug} ||= 0;

    # If caller has requested doing initialization, do that as well
    if ($args{create_new_repository}) {
	$self->_init($self->{_repository_dir}, 
		     $self->{_repository_permissions});
    }

    # Verify everything is sane...
    if (! -d $self->{_repository_dir} ) {
	$self->dbg("Repository directory '" . $self->{_repository_dir} . "' does not exist\n", 1);
    }
    if (! -x $self->{_repository_dir} ) {
	$self->dbg("Repository directory '" . $self->{_repository_dir} . "' is not accessible\n", 1);
    }

    # Determine what the next id is based on the maximum document id number
    foreach my $doc_id ($self->documents()) {
	last if (! $doc_id);
	$self->dbg("Found document id '$doc_id'\n", 4);

	if ($doc_id >= $self->{_next_id}) {
	    $self->{_next_id} = $doc_id + 1;
	}
    }

    if ($self->{_debug} > 4 or 1==1) {
	warn "Document::Repository settings:\n";
	warn "  debug                  = $self->{_debug}\n";
	warn "  repository_dir         = $self->{_repository_dir}\n";
	warn "  repository_permissions = $self->{_repository_permissions}\n";
	warn "  next_id                = $self->{_next_id}\n";
    }

    return $self;
}

# Establishes a new directory for a document repository.
# Basically just does a mkdir after validating the inputs.
sub _init {
    my $self = shift;
    my $dir = shift;
    my $perms = shift;

    if (! $dir) {
	$self->_set_error("Undefined repository dir '$dir' specified to _init()");
	return undef;
    }

    if (-d $dir && ! -x $dir) {
	$self->_set_error("Repository dir '$dir' exists but is not accessible");
	return undef;
    }

    if (-f $dir && ! -d $dir) {
	$self->_set_error("New repository '$dir' exists as a file, not as a dir");
	return undef;
    }

    if (! -d $dir) {
	eval { mkpath([$dir], 0, oct($perms)) };
	if ($@) {
	    $self->_set_error("Error creating repository '$dir':  $@");
	    return undef;
	}
    }
}

sub _set_error {
    my $self = shift;
    $self->{_error_msg} = shift;
}

=head2 get_error()

Retrieves the most recent error message

=cut

sub get_error {
    my $self = shift;
    return $self->{_error_msg} || '';
}

sub dbg {
    my $self = shift;
    my $message = shift || return undef;
    my $thresh = shift || 1;

    warn $message if ($self->{_debug} >= $thresh);
}

=head2 repository_path($doc_id)

Returns a path to the location of the document within the repository
repository. 

=cut

sub repository_path {
    my $self = shift;
    my $doc_id = shift || return undef;
    $self->_set_error('');

    my $repo = $self->{_repository_dir};

    # Verify the repository exists
    if (! $repo) {
	$self->_set_error("Document repository dir is not defined");
	return undef;
    } elsif (! -d $repo) {
	$self->_set_error("Document repository '$repo' does not exist");
	return undef;
    } elsif (! -x $repo) {
	$self->_set_error("Document repository '$repo' cannot be accessed by this user");
	return undef;
    }

    # Millions subdir
    if ($doc_id > 999999) {
        $repo = catdir($repo,
		       sprintf("M%03d", int($doc_id/1000000)));
    }

    # Thousands subdir
    if ($doc_id > 999) {
        $repo = catdir($repo,
		       sprintf("k%03d", int($doc_id/1000)%1000));
    }

    # Ones subdir
    $repo = catdir($repo,
		   sprintf("%03d", $doc_id % 1000));

    if (-d $repo && ! -x $repo) {
	$self->_set_error("Document directory '$repo' exists but is inaccessible\n");
	return undef;
    }

    return $repo;
}

=head2 current_revision($doc_id, [$doc_path])

Returns the current (latest & highest) revision number for the document,
or undef if there is no revisions for the document or if the document
does not exist.

You must specify the $doc_id to be looked up.  Optionally, the $doc_path
may be given (saves the lookup time if you have already calculated it).

=cut

sub current_revision {
    my $self = shift;
    my $doc_id = shift || return undef;
    my $doc_path = shift || $self->repository_path($doc_id);
    my $rev_number;

    # Get the current revision number by looking for highest numbered
    # file or directory if the document already exists
    if (! defined $rev_number && -d $doc_path) {
	if (! opendir(DIR, $doc_path)) {
	    $self->_set_error("Could not open document directory '$doc_path' ".
			      "to find the max revision number: $!");
	    return undef;
	}
	my @files = sort { $a <=> $b } grep { /^\d+$/ } readdir(DIR);
	$self->dbg("Revisions for '$doc_id' are:  @files\n", 2);
	$rev_number = pop @files;
	closedir(DIR);
    }
    return $rev_number;
}


=head2 add(@filenames)

Adds a new document of revision 001 to the repository by adding its
files.  Establishes a new document ID and returns it.

If you wish to simply register the document ID without actually
uploading files, @filenames can be left undefined.

Returns undef on failure.  You can retrieve the error message by
calling get_error().

=cut

sub add {
    my $self = shift;
    my @filenames = @_;

    my $revision = 1;
    $self->_set_error('');

    my $doc_id = $self->{_next_id};

    if (! $doc_id) {
	$self->_set_error("next_id not defined");
	return undef;
    }

    my $repo = $self->repository_path($doc_id);

    if (! $repo) {
	$self->_set_error("Directory in repository could not be created\n");
	return undef;
    } elsif (-e $repo) {
	# Problem...  This document should not already exist...
	$self->_set_error("Document '$doc_id' already exists in the repository");
	return undef;
    }

    $self->dbg("Creating path '$repo' as $self->{_repository_permissions}\n", 2);
    eval { mkpath([$repo], 0, oct($self->{_repository_permissions})) };
    if ($@) {
	$self->_set_error("Error creating '$repo' for doc id '$doc_id':  $@");
	return undef;
    }

    $self->{_next_id}++;

    if (@filenames) {
	$self->put($doc_id, @filenames) || return undef;
    }

    return $doc_id;
}


=head2 put($doc_id, @filenames)

Adds a new revision to a document in the repository.  All files must
exist.

Returns the revision number created, or undef on failure.  You can
retrieve the error message by calling get_error().

=cut

sub put {
    my $self = shift;
    my $doc_id = shift || '';
    my @filenames = @_;

    my $doc_path = $self->repository_path($doc_id) || return undef;
    my $revision = ($self->current_revision($doc_id, $doc_path) || 0) + 1;
    $self->dbg("Adding revision '$revision' for doc id '$doc_id'\n");

    my $rev_path = catdir($doc_path,
			  sprintf("%03d", $revision));
    if (-e $rev_path) {
	# Problem...  This revision should not already exist...
	$self->_set_error("Revision '$revision' for doc id '$doc_id' already exists in the repository");
	return undef;
    }

    $self->dbg("Creating path '$rev_path' as $self->{_repository_permissions}\n", 2);
    eval { mkpath([$rev_path], 0, oct($self->{_repository_permissions})) };
    if ($@) {
	$self->_set_error("Error making path '$rev_path' to repository:  $@");
	return undef;
    }

    foreach my $filename (@filenames) {
	next unless defined $filename;
	if (! -e $filename) {
	    $self->_set_error("File '$filename' does not exist.");
	    return undef;
	}
	my ($vol,$dirs,$base_filename) = splitpath( $filename );

	# Install the file into the repository
	if (! copy($filename, catfile($rev_path, $base_filename)) ) {
	    $self->_set_error("Error copying '$filename' to repository: $!");
	    return undef;
	}
    }

    return $revision;
}

=head2 get($doc_id, $revision, $destination, [$copy_function], [$select_function])

Retrieves a copy of the document specified by $doc_id of the given
$revision (or the latest, if not specified), and places it at
$location (or the cwd if not specified).  

See files() for a description of the optional \&select_function.

The document is copied using the routine specified by $copy_function.
This permits overloading the behavior in order to perform network
copying, tarball dist generation, etc.

If defined, $copy_function must be a reference to a function that
accepts two parameters: an array of filenames (with full path) to be
copied, and the $destination parameter that was passed to get().  The
caller is allowed to define $destination however desired - it can be a
filename, URI, hash reference, etc.  $copy_function should return a 
list of the filenames actually copied.

If $copy_function is not defined, the default behavior is simply to call
the File::Copy routine copy($fn, $destination) iteratively on each file
in the document, returning the number of files

Returns a list of files (or the return value from $copy_function), or
undef if get() encountered an error (such as bad parameters).  The error
message can be retrieved via get_error().

=cut

sub get {
    my $self = shift;
    my $doc_id = shift || '';
    my $revision = shift || '';
    my $destination = shift || '';
    my $copy_function = shift || '';
    my $select_function = shift;

    if (! $destination) {
	$self->_set_error("No destination specified for get()");
	return undef;
    }

    my @files = $self->files($doc_id, $revision, $select_function, 1);

    $self->dbg("Retrieving document files (@files)\n",2);

    if ($copy_function) {
	return &$copy_function(\@files, $destination);
    } else {
	foreach my $filename (@files) {
	    next unless defined $filename;
	    if (! copy($filename, $destination)) {
		$self->_set_error("Could not copy '$filename' for document '$doc_id': $!");
		return undef;
	    } 
	}
    }
    return @files;
}

=head2 content( $filename, $doc_id [, $revision] )

Retrieves the contents of a file within the given document id.

If the specified filename is actually a directory, returns an array of
the files in that directory, instead.

Returns undef and sets an error (retrievable via get_error() if there is
any problem.

=cut
sub content {
    my $self = shift;
    my $filename = shift || return undef;
    my $doc_id = shift || return undef;
    my $revision = shift;

    my $doc_path = $self->repository_path($doc_id) || return undef;

    # Default $revision to current revision if not specified
    $revision ||= $self->current_revision($doc_id, $doc_path);

    my $file = catfile($doc_path,
		       sprintf("%03d", $revision),
		       $filename);
    if (-d $file) {
	my @files;
	opendir(DIR, $file) or return undef;
	while (defined(my $dir_content = readdir(DIR))) {
	    push @files, $dir_content;
	}
	return @files;
    }

    if (! -e $file) {
	return undef;
    }

    if (! open(FILE, "< $file")) {
	$self->_set_error("Could not open file '$file': $?\n");
	return undef;
    }

    # Open the file and read in the content from it
    my $content = '';
    while (<FILE>) {
	$content .= $_;
    }
    close(FILE);

    return $content;
}

=head2 update( $filename, $doc_id, $content[, $append] )

This routine alters a file within the repository without creating a new 
revision number to be generated.  This is not intended for regular use
but instead for adding comments, updating metadata, etc.

By default, update() replaces the existing file.  If $append is defined,
however, update() will append $content onto the end of the file (such as
for logs).  Note that no separation characters are inserted, so make sure
to add newlines and record delimiters if you need them.

Returns a true value if the file was successfully updated, or undef on 
any error.  Retrieve the error via get_error();

=cut
sub update {
    my $self = shift;
    my $filename = shift || return undef;
    my $doc_id = shift || return undef;
    my $content = shift;
    my $append = shift;

    if (! defined $content) {
	$self->_set_error("Undefined content not allowed\n");
	return undef;
    }

    my $doc_path = $self->repository_path($doc_id) || return undef;

    # Default $revision to current revision if not specified
    my $revision = $self->current_revision($doc_id, $doc_path);

    my $file = catfile($doc_path,
		       sprintf("%03d", $revision),
		       $filename);

    my $w = ($append)? ">>" : ">";
    if (! open(FILE, "$w $file")) {
	$self->_set_error("Could not open '$file' for writing:  $?\n");
	return undef;
    }
    print FILE $content;
    return close(FILE);    
}

# Recursively iterates through the document repository, running the
# given function '$func' against document ids it finds.
sub _iterate_doc_ids {
    my $self = shift;
    my $dir = shift;
    my $func = shift;
    my $prefix = shift || '';

    if (! opendir(DIR, $dir)) {
	$self->_set_error("Could not open directory '$dir': $!\n");
	return undef;
    }
    while (defined(my $subdir = readdir DIR)) {
	if ($subdir =~ /^\d+$/) {
	    # This is a document subdir, so we process
	    if (! &$func("$prefix$subdir")) {
		$self->_set_error("Error running function while iterating '$subdir'");
		return undef;
	    }
	} elsif ($subdir =~ /^[Mk](\d+)$/) {
	    # This is a thousands (k) or millions (M) dir, so it contains
	    # additional subdirs for documents within it.  We recurse into
	    # this directory and continue processing...
	    if (! $self->_iterate_doc_ids(catdir($dir,$subdir), $func, $1)) {
		$self->_set_error("Error descending into '$subdir'");
		return undef;
	    }
	}
    }
    close(DIR);
    
    return 1;
}

=head2 documents()

Returns a list of document ids in the system.

Note that if you have a lot of documents, this list could be huge, but
it's assumed you know what you're doing in this case...

=cut

sub documents {
    my $self = shift;

    my $repo = $self->{_repository_dir};
    $self->dbg("Getting list of documents from '$repo'\n", 4);

    our @documents = ();

    sub get_doc_ids { 
	my $doc_id = shift;
	warn "Got document '$doc_id'\n";
	push @documents, $doc_id; 
    }
    if (! $self->_iterate_doc_ids($repo, \&get_doc_ids)) {
	warn "Error iterating doc ids\n";
	# Error msg will already be set by _iterate_doc in this case
	return undef;
    }

    return @documents;
}

=head2 revisions()

Lists the revisions for the given document id

=cut

sub revisions {
    my $self = shift;
    my $doc_id = shift;

    my $repo = $self->repository_path($doc_id) || return undef;
    if (! defined $repo) {
	$self->dbg("Repository undefined:  $repo->get_error()", 2);
	return undef;
    } 
    $self->dbg("Getting revisions from '$repo'\n", 4);

    # Retrieve all of the valid revisions of this document
    my @revisions;
    if (!opendir(DIR, $repo)) {
	$self->_set_error("Could not open repository '$repo': $!");
	return undef;
    }
    @revisions = grep { /^\d+$/ } readdir(DIR);
    $self->dbg("Retrieved revisions: @revisions\n", 4);
    closedir(DIR);

    return @revisions;
}


=head2 files($doc_id, $revision, [\&selection_function], [$with_path])

Lists the files for the given document id and revision (or the latest
revision if not specified.)

The optional \&selection_function allows customized constraints to be
placed on what files() returns.  This function must accept a file path
and return true if the file should be selected for the list to return.

The optional $with_path argument allows control over whether to return
files with their path prepended or not.

=cut

sub files {
    my $self = shift;
    my $doc_id = shift;
    my $revision = shift;
    my $select_function = shift;
    my $with_path = shift;

    my $doc_path = $self->repository_path($doc_id) || return undef;

    # Default $revision to current revision if not specified
    $revision ||= $self->current_revision($doc_id, $doc_path);

    my $rev_path = catdir($doc_path,
                          sprintf("%03d", $revision));

    $self->dbg("Getting files from '$rev_path'\n", 4);

    if (! opendir(DIR, $rev_path)) {
	$self->_set_error("Could not open '$rev_path' to get files: $!");
	return undef;
    }

    my @files = ();
    while (defined(my $filename = readdir DIR)) {
	$self->dbg("Considering file '$filename'\n",3);
	my $file_path = catfile($rev_path, $filename);
	if ($filename =~ /^\./ ) {
	    $self->dbg("Skipping '$filename' since it is a hidden file\n",4);
	    next;
	} elsif (! -f $file_path) {
	    $self->dbg("Skipping '$filename' since it is not a valid file\n",4);
	    next;
	}

	if (defined $select_function) {
	    $self->dbg("Applying custom selection function\n", 4);
	    next unless (&$select_function($file_path));
	}
	$self->dbg("Selecting file '$filename' to get\n", 3);
	if ($with_path) {
	    push @files, $file_path;
	} else {
	    push @files, $filename;
	}
    }
    closedir(DIR);

    return @files;
}

=head2 stats()

Returns a hash containing statistics about the document repository as a
whole, including the following:

* num_documents
* num_revisions
* disk_space
* num_files
* next_id

=cut

sub stats {
    my $self = shift;
    my %stats;

    my $repo = $self->{_repository_dir};

    # Number of documents
    my @doc_ids = $self->documents();
    $stats{num_documents} = scalar @doc_ids;

    # Num revisions
    $stats{num_revisions} = 0;
    foreach my $doc_id (@doc_ids) {
	$stats{num_revisions} += ($self->revisions($doc_id) || 0);
    }

    # Disk space used
    $stats{disk_space} = `du -s $repo`;

    # Number of files
    $stats{num_files} = `find $repo -type f | wc -l`;

    # Next document ID number
    $stats{next_id} = $self->{_next_id};

    return \%stats;
}


1;
