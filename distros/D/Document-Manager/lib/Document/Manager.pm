
=head1 NAME

Document::Manager - A web service for managing documents in a central
repository.

=head1 SYNOPSIS

my $dms = new Document::Manager;

$dms->checkout($dir, $doc_id, $revision);

$dms->add();
$dms->checkin();
$dms->query();
$dms->revert();
$dms->lock();
$dms->unlock();
$dms->properties();
$dms->stats();

print $dms->get_error();

=head1 DESCRIPTION

B<Document::Manager> provides a simple interface for managing a
collection of revision-controlled documents.  A document is a collection
of one or more files that are checked out, modified, and checked back in
as a unit.  Each revision of a document is numbered, and documents can
be reverted to older revisions if needed.  A document can also have an
arbitrary set of metadata associated with it.

=head1 FUNCTIONS

=cut

package Document::Manager;
@Document::Manager::ISA = qw(WebService::TicketAuth::DBI);

use strict;
use Config::Simple;
use WebService::TicketAuth::DBI;
use Document::Repository;
use Document::Object;
use MIME::Base64;
use File::stat;
use File::Spec::Functions;
use DBI;
use SVG::Metadata;

use vars qw($VERSION %FIELDS);
our $VERSION = '0.35';

our $CONF = "/etc/webservice_dms/dms.conf";

use base 'WebService::TicketAuth::DBI';
use fields qw(
	      repo_dir
              repository
              _error_msg
	      _debug
	      _dbh
              );


=head2 new()

Creates a new document manager object.  

=cut

sub new {
    my $class = shift;
    my Document::Manager $self = fields::new($class);

    # Load up configuration parameters from config file
    my %config;
    my $errormsg = '';
    if (! Config::Simple->import_from($CONF, \%config)) {
        $errormsg = "Could not load config file '$CONF': " .
            Config::Simple->error()."\n";
    }

    $self->SUPER::new(%config);

    if (defined $config{'repo_dir'}) {
	$self->{'repo_dir'} = $config{'repo_dir'};
    }

    $self->{repository} = new Document::Repository( repository_dir => $self->{'repo_dir'} );

    if (! $self->{repository}) {
	$self->_set_error("Could not connect to repository\n");
	warn "Error:  Could not establish connection to repository\n";
    }

    return $self;
}

sub _repo {
    my $self = shift;

    if (! defined $self->{repository}) {
	$self->{'repository'} = 
	    new Document::Repository( repository_dir => $self->{'repo_dir'} );
    }
    return $self->{'repository'};
}

# Internal routine for setting the error message
sub _set_error {
    my $self = shift;
    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Retrieves the most recent error message

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}

=head2 checkout()

Checks out a copy of the document specified by $doc_id, placing
a copy into the directory specified by $dir.  By default it will
return the most recent revision, but a specific revision can be
retrieved by specifying $revision.

Returns the filename(s) copied into $dir on success.  If there is an
error, it returns undef.  The error message can be retrieved via
get_error().

=cut

sub checkout {
    my $self = shift;
    my $dir = shift;
    my $doc_id = shift;
    my $revision = shift;
    $self->_set_error('');

    if (! $doc_id || $doc_id !~ /^\d+/) {
	$self->_set_error("Invalid doc_id specified to checkout()");
	return undef;
    }

    if (! $dir || ! -d $dir) {
	$self->_set_error("Invalid dir specified to checkout()");
	return undef;
    }

    return $self->_repo()->get($doc_id, $revision, $dir);
}

=head2 add()

Takes a hash of filenames => content pairs, and inserts each into the
dms as a separate document.  The documents are scanned for valid RDF
metadata which, if present, will be made available for use in the
system.  [Note that for metadata, currently only SVG documents are
supported.]

Returns the new ID number of the document added, or undef if failed.

=cut

sub add {
    my $self = shift;

    my (%files) = (@_);
    my @doc_ids;
    my $doc_id;
    my ($sec, $min, $hr, $day, $month, $year) = (gmtime)[0..5];
    my $now = sprintf("%04s-%02s-%02s %02s:%02s:%02s",
		      $year+1900, $month+1, $day, $hr, $min, $sec);
    foreach my $filename (keys %files) {
	my $content = $files{$filename};
	next unless $content;
	($filename) = (File::Spec->splitpath($filename))[2];
	my $local_filename = catfile('/tmp', $filename);
	my $decoded = decode_base64($content);
	if (! open(FILE, ">$local_filename") ) {
	    warn "Error:  Could not open file '$local_filename' for writing: $!\n";
	    next;
	}
	binmode(FILE);
	print FILE $decoded;
	if (! close(FILE) ) {
	    warn "Error:  Could not close file '$local_filename':  $!\n";
	}

	$doc_id = $self->_repo()->add($local_filename);
	if ($doc_id) {
	    push @doc_ids, $doc_id;
	} else {
	    $self->_set_error($self->_repo()->get_error());
	}

	# Generate metadata
	my %properties;
	# TODO:  Determine file type.  For now assume SVG
	my $format = 'svg';

	# Based on file type, extract metadata
	if ($format eq 'svg') {
	    my $svgmeta = new SVG::Metadata;
	    if (! $svgmeta->parse($local_filename) ) {
		$self->_set_error($svgmeta->errormsg());
		warn $svgmeta->errormsg()."\n";
	    }
	    $properties{title}         = $svgmeta->title();
	    $properties{author}        = $svgmeta->author();
	    $properties{creator}       = $svgmeta->creator();
	    $properties{creator_url}   = $svgmeta->creator_url();
	    $properties{owner}         = $svgmeta->owner();
	    $properties{owner_url}     = $svgmeta->owner_url();
	    $properties{publisher}     = $svgmeta->publisher();
	    $properties{publisher_url} = $svgmeta->publisher_url();
	    $properties{license}       = $svgmeta->license();
	    $properties{license_date}  = $svgmeta->license_date();
	    $properties{description}   = $svgmeta->description();
	    $properties{language}      = $svgmeta->language();
	    $properties{keywords}      = join('; ', $svgmeta->keywords());
	}

	$properties{title} ||= $filename;

	my $inode = stat($local_filename);

	$properties{state} = 'new';
	$properties{size}  = $inode->size;
	$properties{date}  = $now;
	$properties{mimetype} = `file -bi $local_filename`;  # TODO:  PApp::MimeType?
	chomp $properties{mimetype};

	if (! $self->properties($doc_id, %properties) ) {
	    warn "Error:  ".$self->get_error()."\n";
	}

	# Remove the temporary file
	unlink($local_filename);
    }

    return $doc_id;
}

=head2 checkin()

Commits a new revision to the document.  Returns the document's new
revision number, or undef if failed.

=cut

sub checkin {
    my $self = shift;
    my $doc_id = shift;
    my @files = @_;

    # Given a valid document id,
    if (! $doc_id || $doc_id != /^\d+/) {
	$self->_set_error("Invalid doc_id specified to checkout()");
	return undef;
    }

    my $new_revision = $self->_repo()->put($doc_id, @files);

    # TODO log / trigger notifications
    return $new_revision;
}

=head2 query()

Returns a list of documents with property constraints meeting certain
conditions.  

Note: Currently this function is unimplemented, and simply returns a
list of all document IDs.

=cut

sub query {
    my $self = shift;

    # Pass in a function pointer we'll use for determine matching docs
    # Could we cache properties?  Store in a database?  Or is that higher level?
    # Return list of matching documents

    my @objs = $self->_repo()->documents();

# SELECT id FROM document WHERE $criteria
# $criteria could be:  keywords, author, latest N

    return \@objs;
}


=head2 properties()

Gets or updates the properties for a given document id.  Returns undef 
on error, such as if an invalid document id is given.

=cut

sub properties {
    my $self = shift;
    my $doc_id = shift;

    # Given a valid document id
    if (! $doc_id || ($doc_id !~ /^\d+/)) {
	$self->_set_error("Invalid doc_id specified to properties()");
	print "Document id '$doc_id' provided to properties()\n";
	return undef;
    }

    # Retrieve the properties for this document
    my $doc = new Document::Object(repository => $self->_repo(),
				   doc_id     => $doc_id);
    if (@_ > 1) {
	return $doc->set_properties(@_);
    } else {
	return $doc->get_properties();
    }
}

=head2 stats()

Returns a hash containing statistics about the document repository as a
whole, including the following:

* Stats from Document::Repository::stats()
* Number of pending documents
* Number of documents new today
* Number of authors

Note:  Currently this is unimplemented.

=cut

sub stats {
    my $self = shift;

    my $stats = $self->_repo()->stats();

    $stats->{num_pending_docs}   = 0;  # TODO
    $stats->{num_new_today_docs} = 0;  # TODO
    $stats->{num_authors}        = 0;  # TODO

    return $stats;
}

=head2 state(doc_id[, state[, comment]])

Gets or sets the state of document in the system.  Returns undef if the 
specified doc_id does not exist, or does not have a valid state set.

The following states are allowed:

 new
 open
 accepted
 rejected
 broken
 retired

=cut

sub state {
    my $self = shift;
    my $doc_id = shift;
    my $state = shift;
    my $comment = shift;

    if (! $doc_id) {
	$self->_set_error("No doc_id specified to Document::Manager::state\n");
	return undef;
    }

    my $doc = new Document::Object(repository => $self->_repo(),
				   doc_id     => $doc_id);
    $state = $doc->state($state);
    if (! $state) {
	$self->_set_error($doc->get_error());
	return undef;
    }

    if (defined $comment) {
	$doc->log($comment);
    }

    return $state;
}

sub metrics_pending_docs {
    my $self = shift;
    return 'Unimplemented';
}

sub metrics_new_docs_today {
    my $self = shift;
    return 'Unimplemented';
}

sub metrics_new_docs_this_month {
    my $self = shift;
    return 'Unimplemented';
}

sub metrics_authors {
    my $self = shift;
    return 'Unimplemented';
}

=head2 keyword_add($doc_id, @keywords)

Adds a given keyword or list of keywords to the document's metadata.
Returns undef if the keywords could not be added; the error can be
retrieved from get_error().

Leading and trailing spaces are stripped.  Any ';' characters in the
keywords will be converted to ',' characters.  The keywords are also
lowercased.

Note: Currently this does not add the keywords to the original SVG file,
only the metadata in the document system.

=cut

sub keyword_add {
    my $self = shift;
    my $doc_id = shift;
    my @keywords = @_;

    if (! defined $doc_id) {
	$self->_set_error("No doc_id specified to Document::Manager::keyword_add\n");
	return undef;
    }

    if (@keywords < 1) {
	$self->_set_error("No keywords specified to Document::Manager::keyword_add\n");
	return undef;
    }

    my $doc = new Document::Object(repository => $self->_repo(),
				   doc_id     => $doc_id);

    # Ensure we have the unique union of keywords
    my $retval = $doc->add_keywords(@keywords);

    $doc->log("Added keywords: @keywords\n");

    return $retval;
}

=head2 keyword_remove()

Removes one or more keywords from the document metadata, if present.

Note:  Currently this does not actually alter the SVG file itself.

=cut

sub keyword_remove {
    my $self = shift;
    my $doc_id = shift;

    my $doc = new Document::Object(repository => $self->_repo(),
				   doc_id     => $doc_id);

    my $retval = $doc->remove_keywords(@_);

    $doc->log("Removed keywords:  @_\n");
    return $retval;
}

1;
