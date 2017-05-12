package Db::GTM;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Db::GTM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.27';

require XSLoader;
XSLoader::load('Db::GTM', $VERSION);

# TODO:
#  get_alldata/stats -> kludge?

sub journal   { return undef; }  # Journaling handled automatically by GT.M

1;
__END__

=head1 NAME

Db::GTM - Perl extension to interface with GT.M global data

=head1 SYNOPSIS

  use Db::GTM;
  my($db) = new GTMDB("SPZ"); # Create connection to node ["SPZ"]

  # Basic database node storage/retrieval
  $db->set(1000);             # sets node ["SPZ"]         = 1000
  $db->set("foo",50);         # sets node ["SPZ","foo"]   = 50
  $db->set("foo",6,1012);     # sets node ["SPZ","foo",6] = 1012
  $db->set("foo",9,$$);       # sets node ["SPZ","foo",9] = PID
  $db->set("foo",6,"bar",5);  # sets node ["SPZ","foo",6,"bar"] = 5

  $db->get("foo",6);          # should be 1012

  # Iterating through the database
  $db->next("foo",6);         # should be scalar 9
  $db->prev("foo",9);         # should be scalar 6
  $db->prev("foo",6);         # should be undefined
  $db->children("foo");       # should be list: (6,9)
  $db->query("foo",6);        # should be list: ("foo",6,"bar");

  # Copying nodes
  $db->merge("foo",6,undef,"foo",12); 
     # copies ["SPZ","foo",6] and subscripts into ["SPZ","foo",12]

  $db->clobber("foo",6,undef,"foo",12); # copies [foo,6] over to [foo,12]
     # makes ["SPZ","foo",12] a clone of ["SPZ","foo",6]
  
  # Deleting nodes
  $db->kill("foo",6);         # Kills node ["SPZ","foo",6] 
                              #   and      ["SPZ","foo",6,"bar"]
  $db->kv("foo",12);          # Kills node ["SPZ","foo",12] only
  $db->ks("foo",12);          # Kills node ["SPZ","foo",12,"bar"]
                              #   and any other subscripts...

=head1 ABSTRACT

  This module attempts to allow access to the GT.M globals database from
  PERL.  GT.M is a fast and flexible hierarchical database system.

  This module documents Db::GTM module version $VERSION

=head1 DESCRIPTION

  This module provides access to a GT.M database by presenting it as a
  PERL module.  Since GT.M is a hierarchical database (also known as 
  an Object-Oriented database), each node of the database is treated
  as a list.

  Instead of having a simple key like 'JoeSmith' to reference your data, 
  you can have a list; like ('Joe Smith','Address','Street Number').  

  Each connection to the database ties it to one primary node (A single
  GT.M global) and will invisibly attempt to limit subsequent 
  stores/retrieves to this main node.  You probably won't notice this 
  limitation if you use the module normally.  This allows you to treat a 
  single GT.M datastore as if it were multiple databases.

=head2 SETTING UP A CONNECTION

  Create a connection to GT.M with the new() function.  Pass new() the 
  name of the main node ("Global") you wish to link to.  You may link
  to a subscript if you wish.

  Example:
     my $dblink1 = new GTMDB("Clients");
     my $dblink2 = new GTMDB("Clients","auto dealerships");

  In the first instance, all subsequent database access will be 
  invisibly restricted to the GTM database node "Clients".  In the 
  second, it will be further restricted to the sub-node:
    "auto dealerships".

  The following two statements would return identical results:
    $addr = $dblink1->get("auto dealerships","ACME AUTO","Address");
    $addr = $dblink2->get("ACME AUTO","Address");

  WARNING: There are special restrictions for the first element of the
    main node.  It MUST start with an upper or lowercase letter, the
    rest of the element MUST contain only alphanumeric characters, and
    the full name of the 1st element SHOULD be 1-8 characters long.

  On failure, new() will return 'undef' and print an error to STDERR

=head3 STORING AND RETRIEVING DATA
  
  Once a connection is made, you can store data with the set() function
  and retrieve it with get().

  $status = set(@nodename,$value);   # Returns nonzero on failure
  $value  = get(@nodename);

  Example:
    $dblink2->set("ACME AUTO","Address","123 Any Street");
    my $addr = $dblink2->get("ACME AUTO","Address");

  To find out what sibling nodes are adjacent to a given one:
    $scalar = next(@node);     # next node element at same depth
    $scalar = prev(@node);     # previous node element at same depth

  To get children (sub-nodes) of the current node:
    $scalar = first(@node);    # first child node
    $scalar = last(@node);     # last child node

    (@list) = children(@node); # all node elements below given one
    (@nodename) = query(@node);    # next node element at any depth

  You do not have to specify valid data nodes for these operations.  You
  can ask for the node that would have been next/prior to a nonexistant
  node.

  Example:
   $dblink2->set("ACME AUTO",103309);
   $dblink2->set("ACME AUTO","Address","123 Any Street");
   $dblink2->set("SMITH AUTO",103306);
   $dblink2->set("SMITH AUTO","Address","456 Other Street");

   $nxt  = $dblink2->next("ACME AUTO");             # Should be "SMITH AUTO"
   $nxt  = $dblink2->next("BUBBA GUMP AUTO CO.");   # Should be "SMITH AUTO"
   $prv  = $dblink2->prev("SMITH AUTO");            # Should be "ACME AUTO"
   @dlrs = $dblink2->children();  # Should be ("ACME AUTO","SMITH AUTO")
   @data = $dblink2->children("ACME AUTO");         # Should be ("Address")
   @nxt  = $dblink2->query("ACME AUTO");  # Should be ("ACME AUTO","Address")

  COLLATING ORDER NOTE: 
   Data nodes are not stored randomly, as in a hash.  They are stored in
   the MUMPS standard collating order.  All numeric nodes come first, sorted
   from lowest to highest.  Then all string nodes are sorted in ASCII order.

   If the following set operations were performed:
     $dblink2->set(5.5,   "foo"); 
     $dblink2->set(-1000, "bar");
     $dblink2->set(12.362,"baz"); 
     $dblink2->set(1,     "boo");
     $dblink2->set(3,     "Foo"); 
     $dblink2->set("x",   "Bar");
     $dblink2->set("1A",  "Baz"); 
     $dblink2->set("SPZ", "Boo");

  $dblink2->children() would return the list:
    (-1000,1,3,5.5,12.362,"1A","SPZ","x")

=head3 CLONING AND MERGING NODES

  These two functions do bulk data transfers:

  $status = merge(@srcnode,undef,@dstnode);   # Returns nonzero on failure
  $status = clobber(@srcnode,undef,@dstnode); # Returns nonzero on failure

  The first function merges the contents of the source node into the 
  destination node (including all sub-nodes).  Sub-nodes in the destination
  will be overwritten if they conflict with sub-nodes in the source.  Nodes
  that are unique to the destination will be left alone.

  In clobber(), nodes that are unique to the destination will be destroyed.

  Since both node names are lists, put an 'undef' between them to separate
  them.  

  Example:

    $dblink1->set("vendors","ACME Sprocket Co.","Address","999 Main Street");
    $dblink1->merge("auto dealerships",undef,"vendors");
    $dblink1->get("vendors","ACME AUTO"); # Should be 103309

  If you wish to merge/clobber from one database link to another, use the
  functions 

    $status = &GTM::merge($src,$dst);   # Returns nonzero on failure
    $status = &GTM::clobber($src,$dst); # Returns nonzero on failure

  $src or $dst can be either a database object ($dblink1) or a MUMPS-Global
  name.  The node() function returns the MUMPS-Global name of a child
  node of a database link.

  Example:
 
   # Copies everything in dblink1 into dblink2
   &GTM::merge($dblink1,$dblink2);   

   # Copies everything in dblink1's sub-node "vendors" into dblink2
   &GTM::merge($dblink1->node("vendors"),$dblink2);

=head3 DELETING NODES

  $status = kill(@node);    # Destroys node and all sub-nodes
  $status = kv(@node);      # Destroys specified node only
  $status = ks(@node);      # Destroys sub-nodes only

  All return nonzero on failure.

  Example:
    $dblink2->set("BUBBA GUMP AUTO CO.",103009);
    $dblink2->set("BUBBA GUMP AUTO CO.","Address","789 Someother Ave.");
    $dblink2->set("CRAZY EDDIE USED CARS",103009);
    $dblink2->set("CRAZY EDDIE USED CARS","Address","999 Emporium Ave.");
    $dblink2->set("PAY-AND-SPRAY",103009);
    $dblink2->set("PAY-AND-SPRAY","Address","400 Sunset Bvd");

    $dblink2->kill("BUBBA GUMP AUTO CO."); # destroys "Address" sub-node too
    $dblink2->ks("CRAZY EDDIE USED CARS"); # destroys ONLY the 'Address' record
    $dblink2->kv("PAY-AND-SPRAY");         # leaves 'Address' record intact
    $dblink2->kill();  # destroys the "auto dealerships" node and all subnodes

=head3 TRANSACTIONS 

  GT.M and Db::GTM support the concept of "transactions".  All database
  changes made during a transaction are linked, meaning that either they
  are all processed successfully or none of them are.  If there is a
  fatal error or system crash in the middle of the transaction set, none
  of the set/kill operations will take effect.

  $status = $dblink->txnstart();   # Begin a transaction
  $status = $dblink->txnabort();   # Abort a transaction, make no changes
  $status = $dblink->txncommit();  # Save all set/kills made during txn

  Example:
    $status = $dblink->txnstart();
    $dblink->set($acctno,"CHECKING","BALANCE",($oldChkBal - $transferAmt));
    $dblink->set($acctno,"SAVINGS","BALANCE", ($oldSavBal + $transferAmt));
    $status = $dblink->txncommit();

  From the time you initiate txnstart(), all sets/kills are queued until
  you do either txncommit() or txnabort().  

  Note that if you have multiple GTMDB objects and only do a txnstart()
  with one of them, then the others will behave normally (their writes
  will take effect immediately).

  Also note that until a txncommit() is performed, everyone who views 
  the data that has been set since a txnstart() will see the OLD data,
  not the stuff that is in the process of being written.

=head3 LOCKING

  $status = $dblink->lock(@name,$seconds);   # Lock a database node
  $status = $dblink->unlock(@name);          # Unlock something locked prior

  seconds: the last parameter to lock() is the number of seconds to
    wait to get a lock before giving up.  This is important as GT.M
    reserves the use of signals for itself and using SIGALRM may 
    cause problems.

    Specifying a seconds count of 0 will make the locking attempt 
    fail immediately if another lock exists.
  
    Specifying a seconds count of -1 will make the locking attempt
    wait forever for a conflicting lock to be released.  This can 
    lead to deadlock, so use with caution.

  If you specify a global name, you MUST specify a seconds count.
  Bad things will happen to you if you don't.

  In order to work gracefully with other processes that are attempting
  to update data in the GTM datastore, you can request locks on database
  nodes.  Locks are advisory (meaning that it's possible to write to a
  "locked" node if you don't bother to ask for your lock first).  Locks
  are automatically released when your process exits.

  Lock on a higher-level resources conflict with lower-level ones.

  Examples:
    (Process 1)  $db = new GTMDB("TOPNODE");
                 $db->lock("MYNODE","A",0);  # Lock (TOPNODE.MYNODE.A)

    (Process 2)  $db = new GTMDB("TOPNODE");
                 $db->lock("MYNODE",0);      # Lock (TOPNODE.MYNODE)
                 # Fails because process 1 has a conflicting lock

  Note that you can always get locks to resources that you have previously
  locked, or lock a lower level resource.

=head2 FUNCTION LIST

  Conventions: 

    When a function takes '@name' as a parameter, or returns it as output,
    @name is a list that makes up the name of a database node.  Any node
    can store data as well as have child nodes.  See the examples above
    for explicit usage.  If unspecified, functions that operate on @name
    will operate on the main node linked to during new()

    When a function returns '$status', anything nonzero indicates failure

  $db_obj = new GTMDB(@name);          # Returns a link to a database node
  $db_obj = &GTMDB::new(@name);        # Same
  @name   = $db_obj->getprefix();      # Returns the name of the main node

  $scalar = $db_obj->get(@name);       # Returns data stored at a node
  $scalar = $db_obj->exists(@name);    # True if node has data or sub-nodes
  $scalar = $db_obj->haschildren(@name); # True if node has sub-nodes
  $db_obj = $db_obj->sub(@name);       # Returns a link to a sub-node

  $status = $db_obj->set(@name,$val);  # Sets data at node to $value

  $scalar = $db_obj->next(@name);      # Returns next node at same level
  $scalar = $db_obj->prev(@name);      # Returns previous node at same level
  $scalar = $db_obj->first(@name);     # Returns first child node
  $scalar = $db_obj->last(@name);      # Returns last child node
  @name   = $db_obj->query(@name);     # Returns next data node at any depth
  @list   = $db_obj->children(@name);  # Returns all immediate child nodes
 
  $status = $db_obj->kill(@name);      # Destroys node and all subnodes
  $status = $db_obj->ks(@name);        # Destroys all sub-nodes only
  $status = $db_obj->kv(@name);        # Destroys current node only

  $status = $dblink->txnstart();       # Begin a transaction
  $status = $dblink->txnabort();       # Abort a transaction, make no changes
  $status = $dblink->txncommit();      # Save all set/kills made during txn

  $status = $dblink->lock(@name,$seconds);   # Lock a database node
  $status = $dblink->unlock(@name);          # Unlock locked database node

  $status = $db_obj->merge(@srcname [ ,undef,@dstname ]); 
      # Copies nodes in @srcname into @dstname, overwriting collisions 
      # if unspecified, @dstname is assumed to be the main node
   
  $status = $db_obj->clobber(@srcname [ ,undef,@dstname ]); 
      # Makes @dstname an exact clone of @srcname

  $db_obj->clobber() and $db_obj->merge() can take another $db_obj as a source.

  $gvn  = $db_obj->list2gvn(@name);     
    # Returns the MUMPS-Global name that is the combination of the main
    # node name + the specified one.
  
  @name = $db_obj->gvn2list($GVN);      # Converts a MUMPS-Global name to list

  @name = &GTM::gvn2list($GVN);         # Converts a MUMPS-Global name to list
  $gvn  = &GTM::list2gvn(@name);        # Converts a list into a MUMPS Global

  # The functions &GTM::merge / &GTM::clobber can be used to copy the
  # contents of one DB object into another.  They take either database
  # objects or GVNs (such as those returned by list2gvn()) as arguments

  $status = &GTM::merge  ([ $gvn OR $src_db_obj ],[ $GVN OR $dst_db_obj ]);
  $status = &GTM::clobber([ $gvn OR $src_db_obj ],[ $GVN OR $dst_db_obj ]);

=head2 USING GTM AS A TIED HASH OR SCALAR

  Although PERL's native support of hierarchical databases is somewhat
  limited, you can use this module to tie a node of a GTM database to
  a hash or scalar value.

    # Ties the PERL hash variable %spzhash to the GTM node ["SPZ","foo"]
    my(%spzhash); tie %spzhash, 'GTMDB', "SPZ", "foo";
    
    # Ties the PERL scalar variable $spzsclar to the node ["SPZ","foo","bar"]
    my($spzsclr); tie $spzsclr, 'GTMDB', "SPZ", "foo", "bar";
    my($spzlink) = new GTMDB("SPZ","foo");

    # Sets ["SPZ","foo","bar"] to 6
    $spzhash{"bar"} = 6;     # Equivalent to $spzlink->set("bar",6); 
    $spzsclr = 6;            # Also equivalent...
    exists $spzhash{"bar"};  # True if "bar" has data or child nodes
    keys %spzhash;           # A list of all child-nodes of ["SPZ","foo"]
    %spzhash = ();           # Equivalent to $spzlink->kill();
   
  As a special note, the 'keys' and 'each' keywords will always return
  the keys presorted in the mumps collating order.  If you want to use
  'tie' to store a simple flat-file hash this works fine.  

  Multidimensional support, or accessing child nodes is trickier:

    $spzhash{"bar","baz"} = 6; # Equivalent to $spzlink->set("bar","baz",6);
    keys $spzhash{"bar"};      # Syntax error

    @node = ("bar","baz");     # Danger Will Robinson...
    $spzhash{@node} = 6;       # Does $spzlink->set(2,6);

  If you wanted to get child nodes of ["SPZ","foo","bar"] this way, do:

    my %spzbarhash; tie %spzbarhash, 'GTMDB', "SPZ", "foo", "bar";
    keys $spzbarhash; untie %spzbarhash;

  To convert a list to a scalar for purposes of setting a hash variable:

    $spzhash{join($;,@node)}; # $; is a PERL special variable

=head2 EXPORT

None by default.


=head2 KNOWN BUGS AND WARNINGS

  The FIRST name in a node should always start with a letter, can contain
  only letters and numbers, and should ideally be 1-8 characters long.  Names
  longer than 8 characters are unsupported by the MUMPS ANSI standard, but
  should still work in GTM.

  Node elements cannot be empty.  ["SPZ","","bar"] is an invalid node name.

  Using double-quotes in a nodename probably won't work right now.  This 
  should be fixed eventually. ["SPZ","\"","bar"] won't work.  

  Using the NULL (0x00) or FS (0x1c) character in a nodename will probably 
  cause problems or fail.  

  GTM v4.4-003 adjusts the terminal settings, and traps SIGINT (generated 
  by CTRL+C) during initialization.  Since these would be unexpected, this
  package compensates by saving & restoring the signal handler, and 
  restoring the terminal settings when it exits.  If the program is killed
  by SIGKILL or SIGSTOP, it will be unable to do this.  You can restore the
  terminal settings by using the UNIX command '$ stty sane'

=head1 SEE ALSO

  GT.M Documentation: 
    http://sourceforge.net/projects/sanchez-gtm/

  MUMPS documentation:
    ANSI language standard: 'ISO/IEC 11756:1999'
    Book: 'M[UMPS] by Example', by Ed de Moel
    Website: http://freem.vmth.ucdavis.edu/

  Sanchez tech bulletin TB5-027 ("GT.M Callins on UNIX: Invoking M from C")

=head1 FILES AND ENVIRONMENT VARIABLES

  /usr/local/gtm/xc/calltab.ci

    This is the default location for the file that tells GT.M how to
    handle call-ins.  If it is located somewhere else, it is currently
    necessary to specify it's location with the env. variable 'GTMCI'

  extapi.m

    This is the MUMPS side of the interface between PERL and GT.M.  This
    collection of M routines should be stored somewhere GT.M can find it
    when the program runs.

=head2 Environment Variables

  GTMCI       = location of the 'calltab.ci' file
  gtmgbldir   = location of the globals file
  gtmroutines = folder locations of the routines and routine object files
  gtm_dist    = folder containing the GT.M distribution and executable

=head1 AUTHOR

Steven Zeck, E<lt>spzeck@ucdavis.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Steven Zeck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
