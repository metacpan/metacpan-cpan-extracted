package LCC;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::ISA = qw();
$LCC::VERSION = '0.03';

# Use the internal modules that we always need

use LCC::Documents ();
use LCC::Backend ();
use LCC::UNS ();

# Use the external modules that we always need

use IO::File ();
use IO::Socket ();

# Make sure that a true value is returned from -use-

1;

#-------------------------------------------------------------------------

# Following subroutines are for instantiating objects

#-------------------------------------------------------------------------

#  IN: 1 reference to hash with method value pairs
# OUT: 1 instantiated LCC object

sub new {

# Find out what class we need to be blessing
# If we're not trying to make a LCC object
#  Warn the user it shouldn't be done and return

  my $class = shift;
  if ($class ne 'LCC') {
    warn "Can only call 'new' on LCC itself\n";
    return;
  }

# Create the object and bless the object
# Set any parameters if they are specified
# Save version information in the object
# Return something that we can work with

  my $self = bless {},$class;
  $self->Set( shift ) if $_[0];
  $self->_variable( qw(version 1.0) );
  return $self;
} #new

#-------------------------------------------------------------------------

# Create the Backend to be used (only once during lifetime of LCC object)
#  IN: 1 instantiated LCC object
#      2 (optional) type of backend (e.g. 'Storable' or 'DBI')
#      3 source specification (filename for Storable, $dbh for DBI)
#      4 (optional) ref to hash with parameters
# OUT: 1 instantiated LCC::Backend::xxx object

# or:

# Obtain existing Backend object
#  IN: 1 instantiated LCC object
# OUT: 1 instantiated LCC::Backend::xxx object

sub Backend {

# Obtain the object
# If we already have a Backend object
#  Add error if we're trying to create a new one
#  Return the existing Backend object

  my $self = shift;
  if (exists $self->{'Backend'}) {
    $self->_add_error( "Can only create Backend once" ) if @_;
    return $self->{'Backend'};
  }

# Obtain the type of backend
# If it is not a known type of backend
#  Move the type back into the parameters (it needs to be deduced)

  my $type = shift;
  unless ($type =~ m#^(?:DBI|Storable|textfile)$#) {
    unshift( @_,$type );

#  If we have an object of some kind
#   If it is a DBI database handle
#    Set to use DBI
#   Else (unknown type of object)
#    Reset type (will cause error later)

    if (my $ref = ref($type)) {
      if ($ref eq 'DBI::db') {
        $type = 'DBI';
      } else {
        $type = '';
      }

#  Else (not an object)
#   If Storable is available
#    Assume user wants Storable
#   Else
#    Assume user wants plain textfiles

    } else {
      if (defined($Storable::VERSION)) {
        $type = 'Storable';
      } else {
        $type = 'textfile';
      }
    }
  }

# Add error if we don't have a type by now
# Return the result of the object creation, saving it in the LCC on the fly

  $self->_add_error( "Unable to determine type of Backend" ) unless $type;
  return $self->{'Backend'} = "LCC::Backend::$type"->_new( $self,@_ );
} #Backend

#-------------------------------------------------------------------------

# Create a new set of documents to be checked
#  IN: 1 instantiated LCC object
#      2 (optional) storage type documents
#        allowed are: DBI, filesystem, module and queue
#      3 (optional) source specification (depending on type of storage)
#      4 (optional) ref to hash with parameters
# OUT: 1 instantiated LCC::Documents::xxx object

sub Documents {

# Obtain the object
# Obtain the storage type of documents
# If it is not a known type of storage
#  Move the type back into the parameters (it needs to be deduced)

  my $self = shift;
  my $type = shift || '';
  unless ($type =~ m#^(?:DBI|filesystem|module|queue)$#) {
    unshift( @_,$type );

#  If we have an object of some kind
#   If it is a DBI database handle
#    Set to use DBI
#   Elseif it is a queue object
#    Set to use queue
#   Else (unknown type of object)
#    Set type to module
#  Else (not an object)
#   Assume wants documents stored on filesystem

    if (my $ref = ref($type)) {
      if ($ref eq 'DBI::db') {
        $type = 'DBI';
      } elsif ($ref eq 'threads::shared::queue') {
        $type = 'queue';
      } else {
        $type = 'module';
      }
    } else {
      $type = 'filesystem';
    }
  }

# Add error if we don't have a type by now
# Save the result of the object creation
# Return the last object created

  $self->_add_error( "Unable to determine storage type of Documents" )
   unless $type;
  push( @{$self->{'Documents'}},"LCC::Documents::$type"->_new( $self,@_ ) );
  return $self->{'Documents'}->[-1];
} #Documents

#-------------------------------------------------------------------------

#  IN: 1 instantiated LCC object
#      2 server:port specification
# OUT: 1 instantiated LCC::UNS object

sub UNS { $_[0]->{'UNS'} ||= 'LCC::UNS'->_new( @_ ) } #UNS

#-------------------------------------------------------------------------

# Inheritable methods

#-------------------------------------------------------------------------

# OUT: 1..N errors accumulated so far and removed from object if in list context

sub Errors {

# Obtain the object
# Create the name of the field
# Initialize the list of errors

  my $self = shift;
  my $name = ref($self).'::Errors';
  my @error;

# If there are errors
#  Obtain them
#  Delete them from the object if we're returning the content of the errors
# Return whatever we found

  if (exists $self->{$name}) {
    @error = @{$self->{$name}};
    delete( $self->{$name} ) if wantarray;
  }
  return @error;
} #Errors

#-------------------------------------------------------------------------

#  IN: 1..N names of methods to apply to object
# OUT: 1..N values returned by the methods

sub Get {

# Obtain the object
# Initialize the list of values
# Allow for non-strict references

  my $self = shift;
  my @value;
  no strict 'refs';

# If were supposed to return something
#  For all of the methods specified
#   Execute the method and return its value
#  Return the list of values

  if (defined(wantarray)) {
    foreach my $method (@_) {
      push( @value,scalar($self->$method()) );
    }
    return @value;
  }

# Obtain the namespace of the caller
# For all of the methods specified
#  Call the method and put the result in the caller's namespace

  my $namespace = caller().'::';
  foreach my $method (@_) {
    ${$namespace.$method} = $self->$method();
  }
} #Get

#-------------------------------------------------------------------------

#  IN: 1 new setting for PrintError (default: no change)
# OUT: 1 current/old setting for PrintError

sub PrintError {

# Obtain the object
# Return now if just returning

  my $self = shift;
  return $self->_variable( 'PrintError' ) unless @_;

# Obtain the value
# If it is 'cluck'
#  Load the 'Carp' module
#  Set the reference to the cluck routine if Carp is available
# Handle as normal setting from here on

  my $value = shift;
  if ($value eq 'cluck') {
    eval( 'use Carp ();' );
    $SIG{__WARN__} = \&Carp::cluck if defined(&Carp::cluck);
  }
  return $self->_variable( 'PrintError',$value,@_ );
} #PrintError

#-------------------------------------------------------------------------

#  IN: 1 new setting for RaiseError (default: no change)
# OUT: 1 current/old setting for RaiseError

sub RaiseError { 

# Obtain the object
# Return now if just returning

  my $self = shift;
  return $self->_variable( 'RaiseError' ) unless @_;

# Obtain the value
# If it is 'confess'
#  Load the 'Carp' module
#  Set the reference to the confess routine if Carp is available
# Handle as normal setting from here on

  my $value = shift;
  if ($value eq 'confess') {
    eval( 'use Carp ();' );
    $SIG{__DIE__} = \&Carp::confess if defined(&Carp::confess);
  }
  return $self->_variable( 'RaiseError',$value,@_ );
} #RaiseError

#-------------------------------------------------------------------------

#  IN: 1 reference to a hash or list with values keyed to method names

sub Set {

# Obtain the object
# Obtain the reference
# Obtain the type of reference
# Allow for non-strict references

  my $self = shift;
  my $ref = shift;
  my $type = ref($ref);
  no strict 'refs';

# If we have a hash reference
#  For all of the methods specified
#   Execute the method with the given parameters

  if ($type eq 'HASH') {
    foreach my $method (keys %{$ref}) {
      $self->$method( ref($ref->{$method}) eq 'ARRAY' ?
       @{$ref->{$method}} : $ref->{$method} );
    }

# Elseif we have a list reference
#  While there are methods to be handled
#   Obtain the parameters
#   Execute the method with the given parameters

  } elsif ($type eq 'ARRAY') {
    while (my $method = shift( @{$ref} )) {
      my $parameters = shift( @{$ref} );
      $self->$method( ref($parameters) eq 'ARRAY' ?
       @{$parameters} : $parameters );
    }

# Else (we don't know what to do with it)
#  Add error

  } else {
   $self->_add_error( "Cannot handle value of type '$type'" );
  }
} #Set

#-------------------------------------------------------------------------

# Methods for the LCC object only

#-------------------------------------------------------------------------

#  IN: 1 instantiated LCC object
# OUT: 1..N ID's of new/changed documents (# of documents in scalar context)

sub check {

# Obtain the object
# Add error if there is no Backend
# Obtain local copy of backend
# Add error if unclear what kind of update must be done
# Add error if there are no Documents to check

  my $self = shift;
  $self->_add_error( "Must have a Backend first before checking" )
   unless exists( $self->{'Backend'} );
  my $backend = $self->{'Backend'};
  $self->_add_error( "Unclear whether 'complete' or 'partial' update" )
   unless exists( $backend->{'old'} );
  $self->_add_error( "No Documents to be checked" )
   unless exists( $self->{'Documents'} ) and @{$self->{'Documents'}};

# Obtain local copy of list of documents
# Obtain local copy of old ID's
# Obtain local copy of new ID's
# Obtain local copy of URL information
# Create a reference to an empty subroutine doing nothing

  my $documents = $self->{'Documents'} || [];
  my $old = $backend->{'old'};
  my $new = $backend->{'new'} ||= {};
  my $url = $backend->{'url'} ||= {};

# Obtain ordinal of first Documents to check
# Obtain ordinal if the Documents after the last one now
# Loop for all the documents that we need to do now
#  Create local copy of Documents object for this iteration

  my $first = $self->{'_next_documents'} || 0;
  my $next = $self->{'_next_documents'} = @{$documents};
  for (my $i = $first; $i < $next; $i++) {
    my $thistime = $documents->[$i];

#  Obtain the browse URL code reference
#  Obtain the conceptual URL code reference
#  Obtain the fetch URL code reference

    my $burl = $thistime->browse_url || $thistime->_browse_url;
    my $curl = $thistime->conceptual_url || $thistime->_conceptual_url;
    my $furl = $thistime->fetch_url || $thistime->_fetch_url;

#  While there are document to be fetched
#   Create the string for the list
#   Reloop if there was no change

    while (my ($id,@list) = $thistime->next_document) {
      my $list = join( "\0",@list );
      next if $list eq $old->{$id};

#   Add error if we did this one already and reloop
#   Add this document to the list to be done
#   Add URL information for this document ID

      $self->_add_error( "Document with ID '$id' was already added" ), next
       if exists( $new->{$id} );
      $new->{$id} = $list;
      $url->{$id} = {
       burl => $burl->( $id ),
       curl => $curl->( $id ),
       furl => $furl->( $id ),
      };
    }
  }

# Return indicating how many new documents there are now

  return keys %{$backend->{'new'}};
} #check

#-------------------------------------------------------------------------

#  IN: 1 instantiated LCC object

sub complete { shift->_backend_method( 'complete',@_ ) } #complete

#-------------------------------------------------------------------------

#  IN: 1 instantiated LCC object
#      2 (optional) flag to force partial document set

sub partial { shift->_backend_method( 'partial',@_ ) } #partial

#-------------------------------------------------------------------------

#  IN: 1 instantiated LCC object

sub update { shift->_backend_method( 'update',@_ ) } #update

#-------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 reference to hash with provider credentials (id and password)
#      3 handle to write XML to or reference to list of handles to write to
#        (default: just return the resulting XML)
# OUT: 1 resulting XML

sub update_notification_xml {

# Obtain the object
# Obtain the credentials
# Obtain the handles to write to
# Initialize the XML

  my $self = shift;
  my $credentials = shift;
  my @handle = ref($_[0]) eq 'ARRAY' ? @{(shift)} : shift;

# Create a local copy to the backend
# Create the type of set we're working with

  my $backend = $self->{'Backend'};
  my $set = keys %{$backend->{'old'}} ? 'partial' : 'complete';

# Start the XML
# Send it to the handles (if appropriate)
  
  my $xml = <<EOD;
<lococa:notify>
 <init>
  <provider id="$credentials->{'id'}" password="$credentials->{'password'}"/>
 </init>
 <set set="$set">
EOD
  print $_ $xml foreach @handle;

# Create local copy of list of new documents
# Create local copy of URL info of new documents
# While there are documents to be processed
#  Obtain the constituent parts
#  Initialize the line for this document

  my $new = $backend->{'new'} || {};
  my $url = $backend->{'url'} || {};
  while (my ($id,$value) = each %{$new}) {
    my ($mtime,$length,$md5,$mimetype,$subtype) = split( m#\0#,$value );
    my $line = "  <url";

#  If there is URL info (there should be, really)
#   Foreach of the special fields
#    Reloop if no specific info
#    Add field to this documents XML

    if (my $urlid = $url->{$id} || '') {
      foreach (qw(curl burl furl)) {
        next unless $urlid->{$_} || '';
        $line .= qq( $_="$urlid->{$_}");
      }
    }

#  Add the constituent parts if applicable

    $line .= qq( mtime="$mtime") if $mtime || '';
    $line .= qq( len="$length") if $length || '';
    $line .= qq( md5="$md5") if $md5 || '';
    $line .= qq( mimetype="$mimetype") if $mimetype || '';
    $line .= qq( subtype="$subtype") if $subtype || '';

#  Finish off this line
#  Print the line to each appropriate handle
#  Add the line to the XML

    $line .= "/>\n";
    print $_ $line foreach @handle;
    $xml .= $line;
  }

# Create the finish up XML
# Send it to the handles (if appropriate)
# Return the final XML if appropriate

  my $last = <<EOD;
 </set>
</lococa:notify>
EOD
  print $_ $last foreach @handle;
  return $xml.$last if defined( wantarray );
} #update_notification_xml

#-------------------------------------------------------------------------

#  IN: 1 instantiated LCC object
# OUT: 1 current setting for version of LCC

sub version { shift->_variable( 'version' ) } #version

#-------------------------------------------------------------------------

# Following subroutines are for internal use only

#-------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 name of method to execute on Backend
#      3..N parameters to be passed

sub _backend_method {

# Obtain object
# Add error if we don't have a backend yet
# Obtain the method name
# Perform the complete method on the Backend object

  my $self = shift;
  $self->_add_error( "Must have a Backend first" )
   unless exists( $self->{'Backend'} );
  my $method = shift;
  $self->{'Backend'}->$method( @_ );
} #_backend_method

#------------------------------------------------------------------------

#  IN: 1 class to create object in
#      2 LCC object
#      3 reference to hash with method/value pairs
# OUT: 1 instantiated LCC::xxxxx object

sub _new {

# Create an empty object and bless it
# Inherit anything that needs to be inherited
# Set any fields that are specified
# Return the object

  my $self = bless {},shift;
  $self->_inherit( shift );
  $self->Set( shift ) if $_[0];
  return $self;
} #_new

#-------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 object to inherit from
# OUT: 1 object itself

sub _inherit {

# Obtain the objects to work on

  my ($self,$parent) = @_;

# For names of all of the fields that we need to copy
#  Copy the value

  foreach (qw(
   PrintError
   RaiseError
    )) {
    $self->{$_} ||= $parent->{$_} if exists $parent->{$_};
  }
  return $self;
} #_inherit

#-------------------------------------------------------------------------

#  IN: 1 error message to add
# OUT: 1 object itself (for handy oneliners)

sub _add_error {

# Obtain the object
# Save whatever was specified as an error
# Save the error on the list
# Show the warning if we're supposed to

  my $self = shift;
  my $message = shift;
  push( @{$self->{ref($self).'::Errors'}},$message );
  warn "$message\n" if $self->{'PrintError'} || '';

# If we're to die on errors
#  If it is a code reference
#   Execute it, passing the message as a parameter
#  Else
#   Eval what we had as a value
#  Die now if we hadn't died already
  
  if (my $action = $self->{'RaiseError'} || '') {
    if (ref($action) eq 'CODE') {
      &{$action}( $message );
    } else {
      eval( $action );
    }
    die "$message\n";
  }

# Return the object again

  return $self;
} #_add_error

#-------------------------------------------------------------------------

#  IN: 1 server:port or port specification
#      2..N any other parameters to IO::Socket::INET
# OUT: 1 socket (undef if error)

sub _socket {

# Obtain the object
# Obtain the server:port specification
# Set the default host if only a port number specified

  my $self = shift;
  my $serverport = shift;
  $serverport = "localhost:$serverport" if $serverport =~ m#^\d+$#;

# Attempt to open a socket there
# Set error if failed
# Return whatever we got

  my $socket = IO::Socket::INET->new( $serverport,@_ );
  $self->_add_error( "Error connecting to socket: $@" )
   unless $socket;
  return $socket;
} #_socket

#-------------------------------------------------------------------------

# The following methods are for setting and obtaining values

#-------------------------------------------------------------------------

#  IN: 1 name of field in hash
#      2 new value (default: no change)
# OUT: 1 current/old value

sub _variable {

# Obtain the parameters
# Obtain the current value
# Set the new value if there is a new value specified
# Return the current/old value

  my ($self,$name) = @_;
  my $value = $self->{$name};
  $self->{$name} = $_[2] if @_ > 2;
  return $value;
} #_variable

#-------------------------------------------------------------------------

# subroutines for standard Perl features

#-------------------------------------------------------------------------

# Debugging tools

#-------------------------------------------------------------------------

#  IN: 1..N variables to be dumped also, apart from object itself
# OUT: 1 Dumper output (if Data::Dumper available)

sub Dump {

# Obtain the object
# Attempt to get the Data::Dumper module if not availabl already
# If the module is available
#  Return the result of the dump if we're expecting something
#  Output the result the dump as a warning (in void context)

  my $self = shift;
  eval 'use Data::Dumper ();' unless defined( $Data::Dumper::VERSION );
  if (defined( $Data::Dumper::VERSION )) {
    return Data::Dumper->Dump( [$self,@_] ) if defined( wantarray );
    warn Data::Dumper->Dump( [$self,@_] );
  }
}

#-------------------------------------------------------------------------

__END__

=head1 NAME

LCC - Content Provider Modules for the Local Content Cache system

=head1 SYNOPSIS

 use LCC;                         # basic support

 use LCC::Backend::textfile;      # if using the textfile Backend
 use LCC::Backend::Storable;      # if using the Storable Backend
 use LCC::Backend::DBI::mysql;    # if using the DBI Backend with mysql
 use LCC::Backend::DBI;           # if using the DBI Backend with other driver

 use LCC::Documents::filesystem;  # if using info of documents in filesystem
 use LCC::Documents::DBI;         # if using info of documents in DBI database
 use LCC::Documents::module;      # if using info of documents through module
 use LCC::Documents::queue;       # if using info of documents through queue

 # Create basic access to module

 my $lcc = LCC->new( {RaiseError => 1} );

 # Create status persistency backend

 $lcc->Backend;                      # default file, Storable || textfile
 $lcc->Backend( '/root/LCC.gz' );    # specific file, Storable || textfile
 $lcc->Backend( 'textfile','/root/LCC.gz' ); # force flat textfiles
 $lcc->Backend( 'Storable','/root/LCC.gz' ); # force Storable

 my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
 $lcc->Backend( $dbh );                      # DBI with default table
 $lcc->Backend( 'DBI',$dbh );                # force DBI, default table
 $lcc->Backend( [$dbh,'table'] );            # DBI with specific table
 $lcc->Backend( 'DBI',[$dbh,'table'] );      # force DBI, specific table

 # Specify type of update

 $lcc->complete;      # force complete update, regardless of UNS
 $lcc->partial;       # partial update, UNS may force complete
 $lcc->partial( 1 );  # force partial update, regardless of UNS

 # Create document set specification

 $lcc->Documents;     # assume filesystem, use current directory
 $lcc->Documents( '/usr/local/apache/htdocs' );  # assume filesystem
 $lcc->Documents( 'filesystem','/htdocs' );      # force 'filesystem'

 my $dbh = DBI->connect( $data_source, $username, $auth, \%attr );
 my $sth = $dbh->prepare( "SELECT id,mtime FROM table" );
 $lcc->Documents( $sth );                        # assume DBI
 $lcc->Documents( 'DBI',$sth );                  # force 'DBI'

 my $object = Module->new;
 $lcc->Documents( $object );          # assume module
 $lcc->Documents( 'module',$object ); # force 'module'
 $lcc->Documents( $object,{method => 'next_document'} ); # set alternate method

 my $queue = threads::shared::queue->new;
 $lcc->Documents( $queue );                      # assume queue
 $lcc->Documents( 'queue',$queue );              # force 'queue'

 # Set conversion methods

 my $documents = $lcc->Documents;
 $documents->fetch_url( sub {"http://server.com/$_[0].html"} );
 $documents->browse_url( sub {"http://server.com/f.html?$_[0].html"} );
 $documents->conceptual_url( sub {$_[0]} );

 # Check for changed documents in this set
 #  Create Update Notification XML
 #  Update the backend

 if ($lcc->check) {
   print $lcc->update_notification_xml({id => 'name', password => 'password'});
   $lcc->update;
 }

=head1 DESCRIPTION

Provides the Content Provider Modules for the Local Content Cache system
as found on http://lococa.sourceforge.net .

See the LCC::Overview documentation for a introduction of the Local Content
Caching system and an overview of how these Perl modules interact.  Although
that documentation is not required reading before looking at any of the other
documentation, it is B<highly recommended> that you do.

=head1 BASIC DISTRIBUTION

The following modules are part of the distribution:

 LCC				base module
 LCC::Backend			base class for storing local status
 LCC::Backend::DBI		Backend using DBI for permanent storage
 LCC::Backend::DBI::mysql	Backend using mysql for permanent storage
 LCC::Backend::Storable		Backend using Storable for permanent storage
 LCC::Backend::textfile		Backend using a textfile for permanent storage
 LCC::Documents			base class for checking document information
 LCC::Documents::DBI		Document information stored in a database
 LCC::Documents::filesystem	Documents stored on a file system
 LCC::Documents::module		Document information accessible by a Perl module
 LCC::Documents::queue		Documents accessible by a threads::shared::queue
 LCC::Overview			Overview of interaction between modules
 LCC::UNS			setup connection to Update Notification Server

The following scripts are part of the distribution:

=head1 SETUP METHODS

The following methods are available for setting up the LCC object itself.

=head2 new

 $lcc = LCC->new( {method => value} );

The creation of the LCC object itself is done by calling the class method
"new" on the LCC package.  The "new" class method accepts one input
parameter: a reference to a hash or list of method-value pairs as handled by
the L<Set> method.
writes the Hitlist XML to the B<file> specified by the third input parameter.

=head1 INHERITED METHODS

The following methods are inherited from the LCC object whenever any of
the sub-objects are made.  This means that any setting in the LCC object
of these methods, will automatically be activated in the sub-objects, that are
created B<after> calling any of these methods, in the same manner.

=head2 PrintError

 $PrintError = $lccobject->PrintError;
 $lccobject->PrintError( true | false | 'cluck' );

Sometimes you want your program to let you immediately know when there is an
error.  You can do this by calling the "PrintError" method with a
true value.  Each time an error occurs, a warning will be printed to STDERR
informing you of the error that occurred.  Check out the L<RaiseError> method
for letting your program stop with execution immediately when an error has
occurred.  Check out the L<Errors> method when you want to examine errors
completely under program control.

As a special debugging feature, it is also possible to specify the keyword
'cluck'.  If specified, it attempts to load the standard Perl module "Carp".
If that is successful, then it sets the $SIG{__WARN__} handler to call the
"Carp::cluck" subroutine.  This causes a stack-trace to be shown to the
developer when a warning occurs, either from an internal error or because
anything else executes a -warn- statement.

=head2 RaiseError

 $RaiseError = $lccobject->RaiseError;
 $lccobject->RaiseError( true | false | 'confess' );

Sometimes you want to have a program stop as soon as something goes wrong.
By calling the "RaiseError" method with a true value, you are telling the
module to immediately stop the program with an error message as soon as
anything goes wrong.  Check out L<PrintError> to have each error
output a warning on STDERR instead.  Check out L<Errors> if you want to
examine for errors completely under your control.

As a special debugging feature, it is also possible to specify the keyword
'confess'.  If specified, it attempts to load the standard Perl module "Carp".
If that is successful, then it sets the $SIG{__DIE__} handler to call the
"Carp::confess" subroutine.  This causes a stack-trace to be shown to the
developer when an error occurs, either from an internal error or because
anything else executes a -die- statement.

=head1 OBJECT CREATION METHODS

The modules of the LCC family do B<not> contain "new" methods that can
be called directly.  Instead, if you want to create e.g. an LCC::HTML
object, you call the (instance) method "HTML" on an instantiated LCC
object, e.g. "$html = $lcc->HTML;".

Here only the parameters for the object creation are documented.  Any
additional methods are documented in the documentation of the module itself.

=head2 Backend

 $lcc->Backend;                   # use default textfile or Storable
 $lcc->Backend( 'type',$source ); # specify type and source
 $backend = $lcc->Backend;        # obtain local copy of object

The Backend method can be used to create the backend (way to store the status
of the documents) or to obtain the LCC::Backend::xxx object that was previously
created.

The first (optional) input parameter specifies the type of backend to be
used.  Currently the following settings are supported:

 - textfile  store the status of the backend in a flat textfile
 - Storable  store the status of the backend in a Storable file
 - DBI       store the status of the backend in a DBI-supported database

If the first input parameter is omitted, then "Storable" will be assumed if
the Storable module is already loaded.  Else, "textfile" will be assumed.

The second input parameter is optional when the type is "textfile" or
"Storable": a file in the form "LCC.(type)" in the current directory will then
be assumed.

If specified, the function of the second input parameter depends on the type
(implicitely) specified.  In the case of:

 - textfile  it is the absolute filename to store the status in
 - Storable  it is the absolute filename to store the status in
 - DBI       it is a DBI database handle

If the second input parameter is a filename, then the extension ".gz" causes
the file to be written in gzipped format, which takes up less disk space and
may be faster in some cases.

This method returns the LCC::Backend::xxx object that was created.  Please note
that the object is not a LCC::Backend object, but rather a

 - textfile   LCC::Backend::textfile
 - Storable   LCC::Backend::Storable
 - DBI        LCC::Backend::DBI(::driver)?

object that inherits from LCC::Backend.

=head2 Documents

 $lcc->Documents;                   # assume 'filesystem' and current directory
 $lcc->Documents( 'type',$source ); # specify type and source
 $documents = $lcc->Documents;      # obtain local copy of object

The Documents method can be used to create an access to the information of a
(new) set of documents or to obtain the lastly created LCC::Documents::xxx
object.

The first (optional) input parameter specifies the type of information of a set
of documents.  Currently the following settings are supported:

 - filesystem  documents are files in a filesystem, inspect filesystem for info
 - DBI         document information accessible through a DBI-statement handle
 - module      document information accessible by calling a method of an object
 - queue       document information accessible by a threads::shared::queue

If the first input parameter is omitted, then "filesystem" will be assumed.

The second input parameter is optional when the type is "filesystem": in that
case the current directory will be assumed.

If specified, the function of the second input parameter depends on the type
(implicitely) specified.  In the case of:

 - filesystem  top directory from which to look for files using File::Find
 - DBI         DBI statement handle
 - module      an instantiated object, call method "next_document"
 - queue       an instantiated threads::shared::queue object

All but the "filesystem" type expect information to be returned as a list
containing fields for id, mtime, length, md5, mimetype and subtype.  All but
the id and mtime fields are optional.  A queue if supposed to contain
references to lists with these values, rather than the lists themselves.

This method returns the LCC::Documents::xxx object that was created.  Please
note that the object is not a LCC::Documents object, but rather a

 - filesystem   LCC::Documents::filesystem
 - DBI          LCC::Documents::DBI
 - module       LCC::Documents::module
 - queue        LCC::Documents::queue

object that inherits from LCC::Documents.

=head2 UNS

 $uns = $lcc->UNS( server:port | server );

Create a "LCC::UNS" object.

=head1 OTHER METHODS

The following methods are specific for the LCC object.

=head2 check

 if ($lcc->check) {
 # there are files for which a UN should be sent
 }

Check all the L<Documents> that have been previously specified against the
L<Backend> and set up the information to create the L<update_notification_xml>
from.

Returns the document ID's that will be in the Update Notification.  Can be used
in a scalar context to indicate whether an Update Notification should be done.

=head2 complete

 $lcc->complete;

Force a complete Update Notification to be created by
L<update_notification_xml>.

=head2 partial

 $lcc->partial;        # allow UNS to override
 $lcc->partial( 1 );   # force partial update always, regardless of UNS

Indicate that a partial Update Notification should be created by
L<update_notification_xml>.

The option input parameter indicates whether a partial update should be forced
even if the Update Notification Server has indicated that a L<complete> update
is requested.

=head2 update

 $lcc->update;

Update the status in the L<Backend>.  This method should be called whenever
the Update Notification has been successful, so that a subsequent L<partial>
update will only include documents that have been changed since this Update
Notification.

=head2 update_notification_xml

 $credentials = {id => 'name', password = 'password'};
 $lcc->update_notification_xml( $credentials,*STDOUT ); # print
 $lcc->update_notification_xml( $credentials,[$handle,*STDERR] ); # file + warn
 $xml = $lcc->update_notification_xml( $credentials );  # returned in var

Create the XML for the Update Notification for the given credentials and either
send this to one or more handles or return it.

The first input parameter is a reference to a hash in which the credentials
(the id and password that will give you access to the Update Notification
Server) are stored.

The (optional) second input parameter is either a handle or a reference to a
list of handles to which the XML that is created, will be sent.  The XML will
only be returned if no handles are specified.

=head2 

=head1 CONVENIENCE METHODS

The following methods are inheritable from the LCC module.  They are
intended to make life easier for the developer, and are specifically intended
to be used within user scripts such as templates.

=head2 Get

 ($encoding,$xml) = $lccobject->Get( qw(encoding xml) );
 $lccobject->Get( qw(encoding xml) ); # sets global vars $encoding and $xml

Sometimes you want to obtain the values returned by many methods from the
same object.  The "Get" method allows you to do just that: you specify the
names of the methods to be executed on the object and the values from the
method calls (without parameters) are either returned in the same order, or
they are used to set global variables with the same name as the method.

If you are interested in calling multiple methods with parameters on the same
object, and you are B<not> interested in the return values, then you should
call the L<Set> method.

=head2 Set

 $lccobject->Set( {
  methodname1	=> $value1,
  methodname2	=> $value2,
  methodname2	=> [parameter1,parameter2],
 } );

It is often a hassle for the developer to call many methods to set parameters
on the same object.  To reduce this hassle, the "Set" method was developed.
Instead of doing:

 $lccobject->methodname1( $value1 );
 $lccobject->methodname2( $value2 );
 $lccobject->methodname2( $parameter1,$parameter2 );

you can do this in one go as specified above.

The "Set" method accepts either a reference to a hash (as specified by B<{ }>)
or a reference to a list (as specified by B<[ ]>).  The reference to hash
method is preferable if the order in which the methods are executed, is not
important.  If the order in which the methods are supposed to be excuted B<is>
important, then you should use the reference to a list method, e.g.:

 $lccobject->Set( [
  methodname1	=> $value1,
  methodname2	=> [],	                    # no parameters to be passed
  methodname2	=> [parameter1,parameter2], # more than 1 parameter
 ] );

Please note that if there is one parameter to the method, you can specify it
directly.  If there are more than one parameter to be passed to the method,
then you must specify them as a reference to a list by putting them between
square brackets, i.e. "[" and "]".  If no parameters need to be passed to the
method, you can specify this as a reference to an empty list, i.e. "[]".

The "Set" method disregards any values that were returned by the methods.  If
you are interested in the values that are returned by multiple methods, you
can use the L<Get> method.

Please note that the "Set" method is used internally in almost all object
creation methods to allow you to immediately specify the options to be activated
for that object.

=head1 DEBUGGING METHODS

=head2 Dump

 @info = $lccobject->Dump;
 $lccobject->Dump;          # Data::Dumper->Dump output on object as warning

The "Dump" method is a quick-and-dirty interface to the Data::Dumper standard
Perl module.  When it is invoked, it will attempt to load the Data::Dumper
module.  If that is successful, it will create a dump of the object.  If the
method is called in a void context, the dump will be printed as a warning to
STDERR.  Else it will be returned by the "Dump" method.

No action will be performed if the Data::Dumper module can not be loaded.

=head2 Errors

 if ($lccobject->Errors) {     # does not remove errors in scalar context
 @error = $lccobject->Errors;  # returns errors, removes them from object

If an error occurs in the LCC family of modules, they are only reported
"internally" as information added to the object.  To find out whether there are
any errors, you can call the "Errors" method in scalar context: it will then
tell you how many errors there are.  To find out what the errors exactly are,
you can call the "Errors" method in list context: this then also has the
side-effect of removing the error information from the object, effectively
resetting the error history of the object.

If you want your program to stop as soon as an error occurs, call the
L<RaiseError> method beforehand.  If you want your program to also output a
warning to STDERR each time an error occurs, call the L<PrintError>
method beforehand.

=head1 EXAMPLES

=head2 using textfile and filesystem

 # Load only the necessary modules

 use LCC;
 use LCC::Backend::textfile;     # only textfile module is needed
 use LCC::Documents::filesystem; # only filesystem module is needed

 # Create basic access to module, let errors cause a die

 my $lcc = LCC->new( {RaiseError => 1} );

 # Create the default backend

 $lcc->Backend( '/usr/local/apache/LCC.status' );

 # Perform a partial update
 
 $lcc->partial;

 # Specify which documents to be checked and the server name to prefix

 $lcc->Documents( '/usr/local/apache/htdocs' )->server( 'www.server.com' );

 # If there are new files
 #  Print the Update Notification XML to STDOUT
 #  Update the status to the backend

 if ($lcc->check) {
   print $lcc->update_notification_xml( {id => 'name',password => 'password} );
   $lcc->update;
 }

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

maintained by LNATION, <email@lnation.org>

Please report bugs to <email@lnation.org>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://lococa.sourceforge.net and the other LCC::xxx modules.

=cut
