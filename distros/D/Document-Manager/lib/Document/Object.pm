
=head1 NAME

Document::Object

=head1 SYNOPSIS

my $doc = new Document::Object;

$doc->state($state);

my $cid = $doc->comment( undef,
			 { author => "Me",
			   subject => "My Subject",
			   text => "Comment to be appended"
			   }
			 );
my @comments = $doc->comment();
my $comment = $doc->comment(42);

my $text = $doc->diff($revA, $revB);

my $wid = $doc->watcher( undef,
			 { name => "Me",
			   email => "myself@mydomain.com"
			   }
			 );

=head1 DESCRIPTION

This class encapsulates information about a generic document and
operations for altering its properties.  A document is assumed to be a
collection of one or more files, with metadata.

=head1 FUNCTIONS

=cut

package Document::Object;

use strict;
use Document::Repository;
use RDF::Simple;

use vars qw($VERSION %FIELDS);
our $VERSION = '0.10';

use fields qw(
	      _repository
	      _doc_id
	      _metadata
	      _error_msg
	      _STATES
	      );

=head2 new(%args)

Creates a new document object.  Accepts the following arguments in %args:

 repository - a valid Document::Repository object

 doc_id - the integer document ID this object represents

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    $self->{'_repository'} = $args{'repository'};
    $self->{'_doc_id'} = $args{'doc_id'};

    # Allowed states
    $self->{'_STATES'} = { 'new' => 1,
			   'open' => 1,
			   'accepted' => 1,
			   'rejected' => 1,
			   'broken' => 1,
			   'retired' => 1
			   };

    return $self;
}

sub _set_error {
    my $self = shift;
    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Returns the most recent error message as a string.  Returns undef or a
blank string if no error has been logged.

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}


=head2 log($comment)

Gets or adds comments in change log.  Returns undef on error.

=cut

sub log {
    my $self = shift;
    my $comment = shift;

    if (! defined $self->{'_repository'}) {
	$self->set_error("Repository not defined in log()\n");
	return undef;
    }

    if (! $self->{_doc_id}) {
	$self->set_error("document id not defined in content()\n");
	return undef;
    }

    if (defined $comment) {
	return $self->{'_repository'}->update("CHANGELOG",
					      $self->{'_doc_id'},
					      $comment,
					      1);
    } else {
	return $self->{'_repository'}->content("CHANGELOG",
					       $self->{'_doc_id'});
    }
}

=head2 content($filename[, $content])

Retrieves the contents of a file in the document from the document
repository, or, if $content is defined, stores the content into the
file.

Returns undef on error and logs an error message that can be retrieved
via get_error().

=cut

sub content {
    my $self = shift;
    my $filename = shift || return undef;
    my $content = shift;

    if (! defined $self->{'_repository'}) {
	$self->set_error("Repository not defined in content()\n");
	warn $self->get_error();
	return undef;
    }

    if (! $self->{_doc_id}) {
	$self->set_error("document id not defined in content()\n");
	warn $self->get_error();
	return undef;
    }

    my $retval;
    if (defined $content) {
	$retval = $self->{'_repository'}->update($filename,
						 $self->{'_doc_id'},
						 $content);
    } else {
	$retval = $self->{'_repository'}->content($filename,
						  $self->{'_doc_id'});
    }
    $self->_set_error($self->{'_repository'}->get_error());
    if (! $retval) {
	warn $self->{'_repository'}->get_error();
    }
    return $retval;
}

# TODO:  Implement a 'dirty' flag to tell if doc has been changed

=head2 state([$state])

Gets or sets the state of the document.  The following states are
valid:

 new
 open
 accepted
 rejected
 broken
 retired

If a state not in this list is used, the function will return undef 
and log an error.

If called with no argument, returns the current state.

=cut

sub state {
    my $self = shift;
    my $state = shift;

    if (defined $state) {
	if (! defined $self->{_STATES}->{$state}) {
	    $self->_set_error("Invalid state '$state'\n");
	    return undef;
	} else {
	    return $self->properties('state', $state);
	}
    } else {
	return $self->properties()->{'state'};
    }
}

sub _metadata() {
    my $self = shift;

    if (! $self->{'_metadata'}) {
	$self->{'_metadata'} = {
	    'title'  => 'unknown',
	    'author' => 'unknown',
	    'date'   => '0000-00-00',
	    'size'   => 0
	};

	# This should probably be replaced by something more sophisticated,
	# however, this'll probably be reasonably efficient for now.
	foreach (split /\n/, $self->content('METADATA')) {
	    s/#.*//;
	    s/^\s+//;
	    s/\s+$//;
	    next unless length;
	    my ($var, $value) = split(/\s*=\s*/, $_, 2);
	    $self->{'_metadata'}->{$var} = $value;
	}
    }

    return $self->{'_metadata'};
}

=head2 get_properties()

Returns a hash of all properties for the document.

=cut

sub get_properties {
    my $self = shift;
    return $self->metadata();
}

=head2 set_properties(%properties)

Updates general properties about the document.  Accepts a hash of
key/value pairs corresponding to properties to set.  Only properties
provided as arguments will be updated; other properties will be left
unchanged.

Returns a hash of all properties for the document.

=cut

sub set_properties {
    my $self = shift;

    if (@_) {
	my %props = @_;
	while (my ($key, $value) = each %props) {
	    $self->_metadata()->{$key} = $value;
	}
	return $self->_store_properties();
    }

    return $self->_metadata();
}

=head2 get_property()

Retrieves the value of one property of the document.

=cut

sub get_property {
    my $self = shift;
    my $prop = shift || return undef;

    return $self->_metadata()->{$prop};
}

# Helper routine to persist the current properties in memories
sub _store_properties {
    my $self = shift;

    my $content = '';
    while (my ($key, $value) = each %{$self->_metadata()}) {
	$content .= "$key = $value\n";
    }
    return $self->content('METADATA', $content);
}

=head2 get_keywords()

Returns an array of the keywords for this document.

=cut

sub get_keywords {
    my $self = shift;
    return split(/\s*;\s*/, $self->_metadata()->{keywords});
}

=head2 set_keywords(@keywords)

Replaces the keywords for the document with those specified.

=cut

sub set_keywords {
    my $self = shift;
    $self->set_properties('keywords', join('; ', @_));
}

=head2 add_keywords

Adds the given keywords to the document.  This does not remove any
existing keywords, but it does check to make sure we're not adding
any that are already included.  All added keywords are changed to
lowercase, have any ';' characters changed into ',' and leading
and trailing space is trimmed off.

=cut

sub add_keywords {
    my $self = shift;
    my %kwds;
    foreach my $k (@_, $self->get_keywords()) {
        $k =~ s/;/,/g;
        $k =~ s/^\s+//;
        $k =~ s/\s+$//;
        $kwds{lc($k)} = 1;
    }
    return $self->set_keywords(sort keys %kwds);
}

=head2 remove_keywords

Deletes the given keywords from the document.  This operates in a case
insensitive manner.

=cut

sub remove_keywords {
    my $self = shift;
    my %kwds;
    foreach my $k ($self->get_keywords()) {
	$kwds{lc($k)} = 1;
    }
    foreach my $k (@_) {
	$k =~ s/;/,/g;
	$k =~ s/^\s+//;
	$k =~ s/\s+$//;
	delete $kwds{lc($k)};
    }
    return $self->set_keywords(sort keys %kwds);
}

=head2 comment([$cid], [$comment])

Gets or sets the comment information for a given comment ID $cid,
or adds a new $comment if $cid is not defined, or returns all of
the comments as an array if neither parameter is specified.

=cut

sub comment {
    my $self = shift;
    my $cid = shift;
    my $comment = shift;

    if (! defined $self->{'_repository'}) {
	$self->set_error("Repository not defined in log()\n");
	return undef;
    }

    if (! $self->{_doc_id}) {
	$self->set_error("document id not defined in content()\n");
	return undef;
    }

    if (defined $cid) {
	if (defined $comment) {
	    return $self->{'_repository'}->update("COMMENTS/$cid",
						  $self->{'_doc_id'},
						  $comment
						  );
	} else {
	    return $self->{'_repository'}->content("CHANGELOG/$cid",
						   $self->{'_doc_id'});
	}
    } else {
	if (defined $comment) {
	    return $self->{'_repository'}->update("COMMENTS/001",
						  $self->{'_doc_id'},
						  $comment
						  );
	} else {
	    my %comments;
	    foreach my $file ($self->{'_repository'}->content("CHANGELOG/",
							      $self->{'_doc_id'})) {
		$comments{$file} = $self->{'_repository'}->content("CHANGELOG/$file",
							      $self->{'_doc_id'});
	    }
	    return \%comments;
	}
    }
    
    return undef;
}

