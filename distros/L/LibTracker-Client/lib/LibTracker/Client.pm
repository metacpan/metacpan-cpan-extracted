package LibTracker::Client;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# This allows declaration	use LibTracker::Client ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
	DATA_DATE
	DATA_NUMERIC
	DATA_STRING
	DATA_STRING_INDEXABLE
	SERVICE_APPLICATIONS
	SERVICE_APPOINTMENTS
	SERVICE_BOOKMARKS
	SERVICE_CONTACTS
	SERVICE_CONVERSATIONS
	SERVICE_DEVELOPMENT_FILES
	SERVICE_DOCUMENTS
	SERVICE_EMAILATTACHMENTS
	SERVICE_EMAILS
	SERVICE_FILES
	SERVICE_FOLDERS
	SERVICE_HISTORY
	SERVICE_IMAGES
	SERVICE_MUSIC
	SERVICE_OTHER_FILES
	SERVICE_PLAYLISTS
	SERVICE_PROJECTS
	SERVICE_TASKS
	SERVICE_TEXT_FILES
	SERVICE_VFS_DEVELOPMENT_FILES
	SERVICE_VFS_DOCUMENTS
	SERVICE_VFS_FILES
	SERVICE_VFS_FOLDERS
	SERVICE_VFS_IMAGES
	SERVICE_VFS_MUSIC
	SERVICE_VFS_OTHER_FILES
	SERVICE_VFS_TEXT_FILES
	SERVICE_VFS_VIDEOS
	SERVICE_VIDEOS
) ],
	'services' => [ qw(
	SERVICE_APPLICATIONS
	SERVICE_APPOINTMENTS
	SERVICE_BOOKMARKS
	SERVICE_CONTACTS
	SERVICE_CONVERSATIONS
	SERVICE_DEVELOPMENT_FILES
	SERVICE_DOCUMENTS
	SERVICE_EMAILATTACHMENTS
	SERVICE_EMAILS
	SERVICE_FILES
	SERVICE_FOLDERS
	SERVICE_HISTORY
	SERVICE_IMAGES
	SERVICE_MUSIC
	SERVICE_OTHER_FILES
	SERVICE_PLAYLISTS
	SERVICE_PROJECTS
	SERVICE_TASKS
	SERVICE_TEXT_FILES
	SERVICE_VFS_DEVELOPMENT_FILES
	SERVICE_VFS_DOCUMENTS
	SERVICE_VFS_FILES
	SERVICE_VFS_FOLDERS
	SERVICE_VFS_IMAGES
	SERVICE_VFS_MUSIC
	SERVICE_VFS_OTHER_FILES
	SERVICE_VFS_TEXT_FILES
	SERVICE_VFS_VIDEOS
	SERVICE_VIDEOS
) ],
	'metadata' => [ qw(
	DATA_DATE
	DATA_NUMERIC
	DATA_STRING
	DATA_STRING_INDEXABLE

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&LibTracker::Client::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('LibTracker::Client', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

LibTracker::Client - Perl interfce to libtrackerclient

=head1 SYNOPSIS

  use LibTracker::Client qw(:all);

  my $name = LibTracker::Client->service_name(0);
  my $type = LibTracker::Client->service_type($name);
  die "zero somehow is not equal to zero" if( $type != 0 );

  my $tracker = LibTracker::Client->get_instance();

  print "Tracker version : ", $tracker->get_version();
  print "Tracker status : ", $tracker->get_status();

  my $main_only = 0;
  my $s = $tracker->get_services( $main_only );
  while ( my ($key, $val) = each %{$s} ) {
      print "$key : $val\n";
  }

  # searching text and displaying results with snippets
  my $searchtext = shift;
  my $r = $tracker->search_text(0, SERVICE_FILES, $searchtext, 0, 100);

  foreach my $result ( @{$r} ) {
    my $snippet = $tracker->get_snippet(SERVICE_FILES, $result, $searchtext);
    print "$result : $snippet\n";
  }

  undef $tracker;

=head1 DESCRIPTION

Tracker is a tool designed to extract information and metadata about your
personal data so that it can be searched easily and quickly.

By using Tracker, you no longer have to remember where you've left your
files. To locate a file you only need to remember something about it, such
as a word in the document or the artist of the song. This is because as well
as searching for files in the traditional way, by name and location, Tracker
searches files' contents and metadata.

Tracker is available from http://www.gnome.org/projects/tracker/

libtrackerclient is the Tracker client library. This module implements the
Perl interface to libtrackerclient.

=head1 INTERFACE

=head2 STATIC METHODS

=over

=item service_name()

  args:
    servicetype(int) : Service Type Id

Converts the service type to the corresponding name.

=back

=over

=item service_type()

  args:
    servicename(string) : Service Name

Converts the service name to the corresponding type.

=back

=over

=item get_instance()

  args:
    none

Establishes a connection to trackerd and returns an instance of this class.
Returns undef on failure. The connection to trackerd is persistent and is
disconnected only when the returned refrence goes out of scope, is undef-ed,
or is otherwise DESTROYed.

=back

=head2 INSTANCE METHODS

=over

=item get_version()

  args:
    none

Gets the tracker version. Returns undef on failure.

=back

=over

=item get_status()

  args:
    none

Gets the tracker status. Returns undef on failure.

=back

=over

=item get_services()

  args:
    mainonly(int) : gets only the main services is this is TRUE

Returns a hashref containing the tracker services. I could only get a reference to an empty hash each time I tried, so I don't really know what this does. It is however, included for completeness.

=back

=over

=item get_metadata()

  args:
    servicetype(int) : The tracker service type
    id(string)       : The path of the document for which
                       metadata is requested
    keys(arrayref)   : Reference to an array containing
                       metdata fields.

Returns a hashref with the requested metadata. If the call succeeds, the keys
of the hashref are the keys supplied in the array, and the vlues are the
corresponding values. Returns undef on failure. The call will fail even if
one of the requested keys turns out to be invalid. A list of valid fields
can be obtained with a call to F<get_registered_metadata_classes()>.

=back

=over

=item set_metadata()

  args:
    servicetype(int) : The tracker service type
    id(string)       : The path of the document for which
                       metadata is requested
    data(hashref)    : Reference to a hash containing
                       metdata fields and values.

Returns the number of metadata fields set on success. This would always be
equal to the number of keys in the data hash passed to it. Returns undef on
failure. The call will fail even if one of the supplied metadata fields
turns out to be invalid.

A list of valid metadata fields can be obtained with a call to
F<get_registered_metadata_classes()>.

=back

=over

=item register_metdata_type()

  args:
    name(string)     : The name of the metadata type to register
    type(int)        : The type. One of the DATA_* constants.

Registers the new metadata type. Does not return anything. Croaks on
failure. A metadata type is the metadata field from F<get_metadata()> and
F<set_metadata()>.

=back

=over

=item get_metadata_type_details()

  args:
    name(string)    : The name of the metadata type

Returns a reference blessed into LibTracker::Client::MetaDataTypeDetails on
success. Returns undef on failure.

=back

=over

=item get_registered_metadata_classes()

  args:
    none

Returns a reference to an array containing the names of the registered
metadata classes. Returns undef on failure.

=back

=over

=item get_registered_metadata_types()

  args:
    classname(string)    : Class name

Returns a reference to an array containing the names of the registered
metadata types for the given class. Returns undef on failure.

=back

=over

=item get_writeable_metadata_types()

  args:
    classname(string)    : Class name

Returns a reference to an array containing the names of the writeable
metadata types for the given class. Returns undef on failure.

=back

=over

=item get_all_keywords()

  args:
    servicetype(int)    : The service type to get keywords for

Returns a reference to an array containing all the tags for the given service
type. Returns undef on failure.

=back

=over

=item get_keywords()

  args:
    servicetype(int)    : service type
    id(string)          : the path of the file to get the
                          keywords for

Returns a reference to an array containing the tags for the given path.
Returns undef on failure.

=back

=over

=item add_keywords()

  args:
    servicetype(int)    : service type
    id(string)          : the path of the file to set the
                          keywords for
    values(arrayref)    : keywords to add.

Adds the given keywords to the specified path. On success, returns the
number of keywords added, which is ALWAYS equal to the number of keywords
given. Returns undef on failure.

=back

=over

=item remove_keywords()

  args:
    servicetype(int)    : service type
    id(string)          : the path of the file to remove the
                          keywords from
    values(arrayref)    : keywords to remove.

Removes the given keywords from the specified path. On success, returns the
number of keywords removed, which is ALWAYS equal to the number of keywords
given. Returns undef on failure.

=back

=over

=item remove_all_keywords()

  args:
    servicetype(int)    : service type
    id(string)          : the path of the file to remove the
                          keywords from

Removes all the keywords from the specified path. On success, returns a TRUE
value. Returns undef on failure.

=back

=over

=item search_keywords()

  args:
    lqi(int)            : the live query id
    servicetype(int)    : service type
    keywords(arrayref)  : keywords to search for
    offset(int)         : return results from this pos
    maxhits(int)        : number of hits to return

Searches for the specified keywords with the given parameters. On success,
returns a reference to an array containing the results. Returns undef on
failure.

=back

=over

=item search_text()

  args:
    lqi(int)            : the live query id
    servicetype(int)    : service type
    searchtext(string)  : text to search for
    offset(int)         : return results from this pos
    maxhits(int)        : number of hits to return

Searches for the specified text with the given parameters. On success,
returns a reference to an array containing the results. Returns undef on
failure.

=back

=over

=item get_snippet()

  args:
    servicetype(int)    : service type
    path(string)        : the path to get the snippet from
    searchtext(string)  : text to search for

Returns a snippet matching the searchtext in the specified file. The search
text is enclosed in HTML bold tags. Returns undef on failure.

=back

=over

=item search_metadata()

  args:
    servicetype(int)    : service type
    field(string)       : the field to search
    searchtext(string)  : text to search for
    offset(int)         : return results from this pos
    maxhits(int)        : number of hits to return

Searches for the specified text in the specified field. Returns a maximum of
maxhits results starting from the given offset. On success, returns a
reference to an array containing the results. Returns undef on failure.

=back

=over

=item get_suggestion()

  args:
    searchtext(string)  : text to search for
    maxdist(int)        : maximum distance (fuzziness)

Given the search text, returns a close enough suggestion which would yield
search results. Close enough is decided by the maxdist parameter. Returns
undef on failure.

=back

=over

=item get_files_by_service()

  args:
    lqi(int)            : live query id
    servicetype(int)    : service type
    offset(int)         : return results from this pos
    maxhits(int)        : number of hits to return

Returns an arrayref containing the files for the specified service type. A
maximum of maxhits files are returned, starting at the given offset. Returns
undef on failure.

=back

=head2 EXPORT

None by default.

=head2 Exportable constants

  DATA_DATE
  DATA_NUMERIC
  DATA_STRING
  DATA_STRING_INDEXABLE
  SERVICE_APPLICATIONS
  SERVICE_APPOINTMENTS
  SERVICE_BOOKMARKS
  SERVICE_CONTACTS
  SERVICE_CONVERSATIONS
  SERVICE_DEVELOPMENT_FILES
  SERVICE_DOCUMENTS
  SERVICE_EMAILATTACHMENTS
  SERVICE_EMAILS
  SERVICE_FILES
  SERVICE_FOLDERS
  SERVICE_HISTORY
  SERVICE_IMAGES
  SERVICE_MUSIC
  SERVICE_OTHER_FILES
  SERVICE_PLAYLISTS
  SERVICE_PROJECTS
  SERVICE_TASKS
  SERVICE_TEXT_FILES
  SERVICE_VFS_DEVELOPMENT_FILES
  SERVICE_VFS_DOCUMENTS
  SERVICE_VFS_FILES
  SERVICE_VFS_FOLDERS
  SERVICE_VFS_IMAGES
  SERVICE_VFS_MUSIC
  SERVICE_VFS_OTHER_FILES
  SERVICE_VFS_TEXT_FILES
  SERVICE_VFS_VIDEOS
  SERVICE_VIDEOS


=head1 SEE ALSO

The tracker project home at http://www.gnome.org/projects/tracker/

LibTracker::Client specific communication with the author :
ltcp@theoldmonk.net

LibTracker::Client homepage at http://www.theoldmonk.net/ltcp/

=head1 AUTHOR

Devendra Gera, E<lt>gera@theoldmonk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Devendra Gera

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

