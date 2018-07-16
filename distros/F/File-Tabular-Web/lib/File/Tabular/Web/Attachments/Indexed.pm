package File::Tabular::Web::Attachments::Indexed;

use base qw/File::Tabular::Web::Attachments/;
use strict;
use warnings;
no warnings 'uninitialized';

use Search::Indexer;
use Search::QueryParser 0.92;
use locale;

#----------------------------------------------------------------------
sub app_initialize {
#----------------------------------------------------------------------
  my $self = shift;

  $self->SUPER::app_initialize;

  # indexed fields are specified as "[fields]upload field=indexed" in config
  my $upld_ref = $self->{app}{upload_fields};
  my @indexed = grep {$upld_ref->{$_} =~ /indexed/} values %$upld_ref;

  @indexed < 2 or die "currently no support for multiple indexed fields";

  $self->{app}{indexed_field} = $indexed[0];
}


#======================================================================
#                 REQUEST HANDLING : SEARCH METHODS                   #
#======================================================================

#----------------------------------------------------------------------
sub words_queried { 
#----------------------------------------------------------------------
  my $self = shift;
  my $all_search = "$self->{search_string_orig} $self->{search_fulltext}";
  return ($all_search =~ m([\w/]+)g);
}


#----------------------------------------------------------------------
sub log_search {
#----------------------------------------------------------------------
  my $self = shift;
  return if not $self->{logger};

  my $msg = sprintf "[%s][%s] $self->{user}", 
    $self->{search_string_orig},
    $self->{search_fulltext};
  $self->{logger}->info($msg);
}


#----------------------------------------------------------------------
sub before_search {
#----------------------------------------------------------------------
  my ($self) = @_;

  $self->SUPER::before_search;


  # searches into the fulltext index are passed through param 'SFT'
  unless($self->{search_fulltext} = $self->param('SFT')) {
    delete $self->{fulltext_result};
    return;
  }

  $self->{app}{indexer} ||= Search::Indexer->new( 
    dir          => $self->{app}{dir},
    preMatch     => $self->{cfg}->get('preMatch'),
    postMatch    => $self->{cfg}->get('postMatch'),
   );

  my $result = $self->{app}{indexer}
                    ->search($self->{search_fulltext}, "implicit_plus");

  # MAYBE add some logging here (time for fulltext search, #docs found)

  if ($result) {                # nonempty results
    $self->{results}{killedWords} = join ", ", @{$result->{killedWords}};
    $self->{results}{regex} = $result->{regex};

    # HACK : build a regex with all document ids, and add that into
    # the search string. Not efficient if the result set is large;
    # will require more clever handling in File::Tabular::compile_query 
    # using some kind of representation for sets of integers (bit vectors
    # or Set::IntSpan::Fast)
    # ASSUMES the document number is the record key, stored in first field
    my $doc_ids       = join ",", keys %{$result->{scores}}
      or return;                # no scores, no results
    $self->{search_string} = "#$doc_ids";
    $self->{search_string} .= " AND ($self->{search_string_orig})" 
      if $self->{search_string_orig};
  }
  $self->{fulltext_result} = $result;

  return $self;
}



#----------------------------------------------------------------------
sub search { # call parent search(), add fulltext scores into results
#----------------------------------------------------------------------
  my ($self, $search_string) = @_;

  $self->SUPER::search($search_string);

  my $fulltext_result = $self->{fulltext_result} or return;

  # merge scores into results 
  $self->{data}->ht->add('score'); # new field for storing 'score'

  foreach my $record (@{$self->{results}{records}}) {
    my $doc_id       = $self->key($record);
    $record->{score} = $fulltext_result->{scores}{$doc_id};
  }
  $self->{orderBy} ||= "score : -num"; # default sorting by decreasing scores
}


#----------------------------------------------------------------------
sub sort_and_slice { 
#----------------------------------------------------------------------
  my ($self) = @_;

  $self->SUPER::sort_and_slice;
  $self->add_excerpts;
}



#----------------------------------------------------------------------
sub add_excerpts { # add text excerpts from attached files
#----------------------------------------------------------------------
  my ($self) = @_;

  $self->{fulltext_result} or return;

  # need new field in the Hash::Type to store the excerpts
  $self->{data}->ht->add('excerpts'); 

  # add excerpts into each displayed record
  my $regex = $self->{results}->{regex};
  foreach my $record (@{$self->{results}{records}}) {
    my $buf = $self->indexed_doc_content($record);
    my $excerpts = $self->{app}{indexer}->excerpts($buf, $regex);
    $record->{excerpts} = join(' / ', @$excerpts);
  }
}



#----------------------------------------------------------------------
sub params_for_next_slice { 
#----------------------------------------------------------------------
  my ($self, $start) = @_;

  return ("SFT=$self->{search_fulltext}",
          $self->SUPER::params_for_next_slice($start));
}



#======================================================================
#                        HANDLING ATTACHMENTS                         #
#======================================================================


#----------------------------------------------------------------------
sub after_add_attachment {
#----------------------------------------------------------------------
  my ($self, $record, $field, $path) = @_;

  if ($field eq $self->{app}{indexed_field}) {
    my $buf  = $self->indexed_doc_content($record);
    delete $self->{app}{indexer};
    my $indexer = Search::Indexer->new(dir       => $self->{app}{dir},
                                       writeMode => 1);
    $indexer->add($self->key($record), $buf);
  }
}

#----------------------------------------------------------------------
sub before_delete_attachment {
#----------------------------------------------------------------------
  my ($self, $record, $field, $path) = @_;

  if ($field eq $self->{app}{indexed_field}) {
    delete $self->{app}{indexer};
    my $indexer = Search::Indexer->new(dir       => $self->{app}{dir},
                                       writeMode => 1);
    $indexer->remove($self->key($record));
  }
}


#----------------------------------------------------------------------
sub indexed_doc_content {
#----------------------------------------------------------------------
  my ($self, $record) = @_;

  # this is the default implementation, MOST PROBABLY INADEQUATE
  # should be overridden in subclasses to perform appropriate
  # conversions from Html, Pdf, Word, etc.

  my $path = $self->upload_fullpath($record, $self->{indexed_field});
  open my $fh, $path or die "open $path: $!";
  local $/;
  my $content = <$fh>; # just return the file content
  return $content;
}




1;

__END__

=head1 NAME

File::Tabular::Web::Attachments::Indexed - Fulltext indexing in documents attached to File::Tabular::Web

=head1 DESCRIPTION

This abstract class adds support for 
fulltext indexing in documents attached to a
L<File::Tabular::Web|File::Tabular::Web> application.

Queries into the fulltext index should be passed under the
C<SFT> ("search full text") parameter, in addition to the 
usual C<S> parameter (search in metadata record). So for
example

  http://my/app.ftw?S=2007&SFT=perl

will search records containing the word "2007" and having an attached
document in which there is the word "perl". Queries can of course be
much more complex, with boolean operators, parentheses, excluded words, etc.
--- see L<Search::Indexer> and L<Query::Parser>.


Indexing requires some mechanism to convert attached documents 
into plain text. This cannot be guessed by the present class,
so you should write a subclass that implements such
conversions; see the L</SUBCLASSING> section below.

=head1 RESERVED FIELD NAMES

Records retrieved from a fulltext search will have two 
additional fields : C<score> (how well the document 
matched the query) and C<excerpts> (strings
of text fragments close to the searched words).
Therefore those field names should not be present
as regular fields in the data file.

=head1 CONFIGURATION

=head2 [fields]

  upload fieldname1
  upload fieldname2 = indexed

Currently only one single upload field can be indexed
within a given application.

=head2 subclassing

This class relies on the L</indexed_doc_content> method 
for converting attached documents into plain text, which
is a prerequisite to perform the indexing. The default
implementation of L</indexed_doc_content> just returns 
the raw file content, so it is most likely inappropriate
to suit your needs; therefore you should write a subclass
that overrides this method, and then associate this subclass
to your application within the configuration file :

  [application]
  class = My::Subclass::Of::File::Tabular::Web::Attachements::Indexed


=head2 Asynchronous indexing

If your uploaded documents are Microsoft Office or OpenOffice
documents, it may be too costly to convert them on the fly, while
answering the HTTP request. A way to deal with this is to 
override the L</after_add_attachment> and 
L</before_delete_attachment> methods : instead of 
performing immediate adds or deletions into the index, 
these method can write indexing requests into an event queue.
A separate process then reads the event queue and 
performs the indexing operations.


=head1 METHODS

=head2 app_initialize

Calls the L<parent method|File::Tabular::Web::Attachments/app_initialize>;
records in C<< $self->{app}{indexed_field} >> which is the name
of the indexed field.

=head2 words_queried

Returns a list of words queried either in the C<S> or C<SFT> parameters.

=head2 log_search

Logs both the C<S> and C<SFT> parameters.

=head2 before_search

Performs the fulltext search, and combines the results
into the usual search string coming from the C<S> parameter.

=head2 search

Calls the L<parent method|File::Tabular::Web/search>
and adds a C<score> field into each record.


=head2 sort_and_slice

Calls the L<parent method|File::Tabular::Web/sort_and_slice>
and adds excerpts of the searched words from attached documents
into each record of the slice.

=head2 add_excerpts

Implementation to find excerpts of searched word within 
attached documents and add them into the result set.

=head2 params_for_next_slice

Returns a string repeating the search parameters, for
generating URLs to the next or previous slice.

=head2 after_add_attachment

Performs the indexing of the attached document

=head2 before_delete_attachment

Removes the document from the index.


=head2 indexed_doc_content

  my $plain_text = $self->indexed_doc_content($record);

Returns the plain text representation of the document attached
to C<$record>. To get to the actual file, your implementation 
can access 

  my $path = $self->upload_fullpath($record, $self->{indexed_field});

