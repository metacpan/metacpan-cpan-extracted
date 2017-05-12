#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::FMTEYEWTK - POD containing in-depth discussion
of FlatFile::DataStore.

=head1 VERSION

Discusses FlatFile::DataStore version 1.03.

=head1 SYNOPSYS

 man FlatFile::DataStore
 man FlatFile::DataStore::Tutorial
 man FlatFile::DataStore::FMTEYEWTK

or

 perldoc FlatFile::DataStore
 perldoc FlatFile::DataStore::Tutorial
 perldoc FlatFile::DataStore::FMTEYEWTK

or

 http://search.cpan.org/dist/FlatFile-DataStore/

=head1 DESCRIPTION

=head2 Overview

This discussion only contains POD, so don't do this:

 use FlatFile::DataStore::FMTEYEWTK;  # don't do this

Instead, simply read the POD (as you are doing). Also please read
the docs for FlatFile::DataStore, which is essentially the reference
manual, and for FlatFile::DataStore::Tutorial.

This discussion is intended to augment those docs with
longer explanations for the design of the module, more usage
examples, and other materials that will hopefully help you make
better use of it.

=head1 DISCUSSION

=head2 Overview

FlatFile::DataStore implements a simple flatfile datastore.  When you
create (store) a new record, it is appended to the flatfile.  When you
update an existing record, the existing entry in the flatfile is
flagged as updated, and the updated record is appended to the
flatfile.  When you delete a record, the existing entry is flagged as
deleted, and a "delete record" is I<appended> to the flatfile.

The result is that all versions of a record are retained in the data
store, and running a history will return all of them.  Another result
is that each record in the datastore represents a transaction: create,
update, or delete.

=head2 Data Store Files and Directories

There are four types of files that make up a datastore:

 uri file     (1)         ... essentially the configuration file
 key file(s)  (1 or more) ... index(es) into the data file(s)
 data file(s) (1 or more) ... where the records are stored
 toc file(s)  (1 or more) ... table of contents file(s)

Key files act as an index into the data files.  The different versions
of the records in the data files act as linked lists:

 - the first version of a record links just to it's successor
 - a second, third, etc., versions link to their successors and predecessors
 - the final (current) version links just to its predecessor

A key file entry always points to the final (current) version of a
record. It may have a pointer to a previous version, but it will never
have a pointer to a "next" version, because there isn't one.

Each record is stored with a I<preamble>, which is a fixed-length
string of fields containing:

 - crud indicator        (flag for created, updated, deleted, oldupd, olddel)
 - transaction indicator (flag for created, updated, deleted)
 - transaction number    (incremented when any record is touched)
 - date                  (of the "transaction")
 - key number            (record key sequence number)
 - record length         (in bytes)
 - user data             (for out-of-band* user-defined data)
 - "this" file number    (linked list pointers ...)
 - "this" seek position
 - "prev" file number
 - "prev" seek position
 - "next" file number
 - "next" seek position

*That is, data about the record not stored in the record.

The formats and sizes of these fixed-length fields may be configured
when the datastore is first defined, and will determine certain
constraints on the size of the datastore.  For example, if the file
number is base-10 and 2 bytes in size, then the datastore may have
up to 99 data files.  And if the seek position is base-10 and 9 bytes
in size, then each data file may contain up to 1 Gig of data.

Number bases larger than base-10 (up to base-36 for file numbers and up
to base-62 for other numbers) may be used to help shorten the length of
the preamble string.

Again, a datastore will have the following files:

 - uri  file,    contains the uri, which defines the configuration parameters
                 after initialization, it contains a generic serialized datastore object
                 ('generic' because the object does not include the 'dir' attribute)
 - toc  file(s), contain information about the datastore and each data file
 - key  file(s), contain pointers to every current record version
 - data file(s), contain all the versions of all the records

If the datastore is small, it might have only one toc, key, and/or
data file.

If C<dirlev> (see below) is 0 or undefined, the toc, key, or data files
will reside at the same level as the uri file, e.g.,

    - name.uri
    - name.toc     (or name.1.toc if C<tocmax> is set)
    - name.key     (or name.1.key if C<keymax> is set)
    - name.1.data  (the file number (e.g., 1) is always present
                   and always starts with 1, or 01, or 001, etc.)

If C<dirlev> is 1, the directory structure follows the following scheme
(note that like file numbers, directory numbers start at 1, not at 0):

    - dir
        - name.uri
        - name
            - toc1
                - name.1.toc
                - name.2.toc
                - etc.
            - toc2
            - etc.
            - key1
                - name.1.key
                - name.2.key
                - etc.
            - key2
            - etc.
            - data1
                - name.1.data
                - name.2.data
                - etc.
            - data2
            - etc.

If C<dirlev> is 2, the scheme will look something like this:

    - dir
        - name.uri
        - name
            - toc1
                - 1
                    - name.1.toc,
                    - name.2.toc,
                    - etc.
                - 2
                    - ...
                - etc.
            - toc2
            - etc.
            - key1
                - 1
                    - name.1.key,
                    - name.2.key,
                    - etc.
                - 2
                    - ...
                - etc.
            - key2,
            - etc.
            - data1
                - 1
                    - name.1.data
                    - name.2.data,
                    - etc.
                - 2
                    - ...
                - etc.
            - data2,
            - etc.

Since a C<dirlev> of 2 can accommodate millions of data files,
it's unlikely you'll need a level of 3 or more.

If C<tocmax> is not defined, there will never be more than one toc
file and so the name will be C<name.toc> instead of, e.g., C<name.1.toc>.

If C<keymax> is not defined, there will never be more than one key
file and so the name will be C<name.key> instead of, e.g., C<name.1.key>.

Different datastores may coexist in the same top-level directory--they
just have to have different names.

To retrieve a record, one must know the data file number and the seek
position into that data file, or the record's key sequence number (the
order it was added to the datastore).  With a sequence number, the
file number and seek position can be looked up in a key file, so these
sequence numbers are called "key numbers" or C<keynum>.

Methods support the following actions:

 - create
 - retrieve
 - update
 - delete
 - history

Scripts supplied in the distribution perform:

 - validation of a datastore
 - migration of datastore records to newly configured datastore
 - comparison of pre-migration and post-migration datastores

=head2 Motivation

Several factors motivated the development of this module:

 - the desire for simple, efficient reading and writing of records
 - the desire to handle any number and size of records
 - the desire to identify records using sequence numbers
 - the need to retain previous versions of records and to view update history
 - the ability to store any sort of data: binary or text in any encoding
 - the desire for a relatively simple file structure
 - the desire for the data to be reasonably easily read by a human
 - the ability to easily increase the datastore size (through migration)

The key file makes it easy and efficient to retrieve the current
version of a record--you just need the record's key sequence number.
Other retrievals via file number and seek position (e.g., gotten from a
history list) are also fast and easy.

Because the size and number of data files is configurable, the data
store should scale up to large numbers of (perhaps large) records --
while still retaining efficient reading and writing.

(In the extreme case that a record is too large for a single file,
users might break up the record into parts, store them as multiple data
store records and store a "directory" record to guide the reassembly.
While that's outside the scope of this module, that sort of scheme is
accommodated by the fact that the datastore doesn't care if the record
data is not a complete unit of a known format.)

When a record is created, it is assigned a key sequence number (keynum)
that persistently identifies that record for the life of the data
store.  This should help user-developed indexing schemes that employ,
e.g., bit maps, to remain correct.

Since a record links to it's predecessors, it's easy to get a history
of that record's changes over time.  This can facilitate recovery and
reporting.

Since record retrieval is by seek position and record length in bytes,
any sequence of bytes may be stored and retrieved.  Disparate types of
data may be stored in the same datastore.

Outside of the record data itself, the datastore file structure uses
ascii characters for the key file, toc file, and preambles.  It appends
a record separator, typically a newline character, after each record.
This is intended to make the file structure relatively simple and more
easily read by a human--to aid copying, debugging, disaster recovery,
simple curiosity, etc.

Migration scripts are included in the module distribution.  If your
initial configuration values prove too small to accommodate your data,
you can configure a new datastore with larger values and migrate all
the records to the new datastore.  All of the transaction and sequence
numbers remain the same; the record data and user data are identical;
and interfacing with the new datastore vs. the old one should be
completely transparent to programs using the FlatFile::DataStore
module.

=head2 CRUD cases

 Create: no previous preamble required or allowed
    - create a record object (with no previous)
    - write the record
    - return the record object
 Retrieve:
    - read a data record
    - create a record object (with a preamble, which may become a previous)
    - return the record object
 Update: previous preamble required (and it must not have changed)
    - create a record object (with a previous preamble)
    - write the record (updating the previous in the datastore)
    - return the record object
 Delete: previous preamble required (and it must not have changed)
    - create a record object (with a previous preamble)
    - write the record (updating the previous in the datastore)
    - return the record object

Some notes about the "previous" preamble:

In order to protect data from conflicting concurrent updates, you may
not update or delete a record without first retrieving it from the data
store.  Supplying the previous preamble along with the new record data
is proof that you did this.  Before the new record is written, the
supplied previous preamble is compared with what's in the datastore,
and if they are not exactly the same, it means that someone else
retrieved and updated/deleted the record between the time you read it
and the time you tried to update/delete it.

So unless you supply a previous preamble and unless the one you supply
matches exactly the one in the datastore, your update/delete will not
be accepted--you will have to re-retrieve the new version of the record
(getting a more recent preamble) and apply your updates to it.

=head2 Scaling to infinity (and beyond)

Past experience designing datastores suggests that once a design is in
place, you will always want to throw a lot more data at it that you
thought you were going to.

So in this module, I want to make an extra effort to accommodate all the
data anyone might want to put in a datastore.  For that reason, any
file that increases in size as data is stored (toc file, key file, data
file) may be split into multiple files.  Logically, these are one entity:
the toc files are one table of contents, the key files are one index,
the data files make up a single datastore.  But by allowing them to be
split up, the file sizes can be kept manageable.

Similarly, since the number of files increases, and too many files in a
single directory can be problematic for a number of reasons, the module
accommodates multiple directories for these files.  That is, as the
number of data files grows, they can be stored in multiple data
directories.  As the number of key files grows, and as the number of
toc files grows, they can be stored in multiple key and toc
directories.

To keep things simpler, the specs for the data file number can be
applied to the toc files, the key files, and also to the toc, key, and
data directories.  That is, if the datastore designer specifies that
the data file number should be two base-36 characters (so he can
accommodate up to 1295 files), that should be more than sufficient to
use for toc's, key's, and dir's.

But some additional parameters are needed:

 - dirmax,  the maximum number of files per directory
 - dirlev,  the number of directory levels for data, toc, and key files
 - tocmax,  the maximum number of entries per toc file
 - keymax,  the maximum number of entries per key file
 - datamax, the maximum size in bytes of any data file
   (was once called C<maxfilesize>, in case you ever saw that)

The C<dirmax> and C<dirlev> parms are available for handling big data
stores.  If C<dirmax> is set, C<dirlev> defaults to 1, but may be set
higher.  The C<dirmax> parm will determine when a new directory is
created to hold more data, key, or toc files.

The C<dirlev> parm indicates how many directory levels to maintain.  A
level of 1 will accommodate C<dirmax> * C<dirmax> files.  A level of 2,
C<dirmax> * C<dirmax> * C<dirmax> files, etc.  It's unlikely you'll
need a C<dirlev> higher than 1 so if C<dirmax> is needed at all, just
setting it and letting C<dirlev> default to 1 is the most likely case.

The C<tocmax> and C<keymax> parms will determine when a new toc or key
file is created to hold more entries.  The C<datamax> parm will
determine when a new data file is created: when storing a record would
cause the size of the data file to exceed that number, a new data file
is created for it, and subsequent records are stored there.

=head2 Toc file structure

The toc file will have a total line at the top and a detail line for
each data file below that.

The fields in these lines are as follows:

 -  1. len FN, tocfnum,  last toc file
 -  2. len FN, keyfnum,  last key file
 -  3. len FN, datafnum, last data file
 -  4. len KN, numrecs,  number of non-deleted records
 -  5. len KN, keynum,   last keynum
 -  6. len TN, transnum, last transaction number
 -  7. len TN, create,   number of records with create indicator
 -  8. len TN, oldupd,   number of records with oldupd indicator
 -  9. len TN, update,   number of records with update indicator
 - 10. len TN, olddel,   number of records with olddel indicator
 - 11. len TN, delete,   number of records with delete indicator
 - 12. len RS, recsep    (typically just a newline)

For example:

 1 1 9 00Aa 00Aj 01Bk 00AK 0027 0027 0003 0003\n

FN is filenumlen; KN is keynumlen; TN is transnumlen; RS is recseplen.

The very first line (line number 0) of the toc file is the "top toc"
line.  Fields 1 - 6 have the vital information for the datastore, i.e.,
the current toc file number, the current key file number, the current
data file number, the number of (non-deleted) records in the data
store, the last key sequence number used, and the last transaction
number used.  To get any of these, the module only has to read and
split a single line.

Fields 7 - 11 are there just for kicks, really.  They might aid in
validation or tracking or whatever in the future, but at this time, the
module doesn't read them for anything, it just keeps them up to date.

On the detail lines, all of these values may again be useful for
validation, tracking, data recovery, etc., but the module doesn't (yet)
read them for anything, it just keeps them up to date.

Again, on the total line (the first line -- line 0), these values will
be where the program looks for:

 - last toc file
 - last key file
 - last data file
 - last keynum
 - last transaction number 
 - number of (non-deleted) records

On each transaction, the module will update these on:

 - the last line (because it has details for the current data file)
 - possibly another line (in possibly another toc file)
   (because the transaction may update a preamble in another data file)
 - the first line ("last" numbers and totals) 

Random access by line is accommodated because we know the length of each line and

 - line 0 is the total line
 - line 1 is details for example.1.data
 - line 2 is details for example.2.data
 - etc. 

=head2 defining a datastore

(To be completed.)  See URI Configuration in FlatFile::DataStore.

=head2 designing a program to analyze a datastore definition (uri)

Validation:

 - Are the indicators five unique ascii characters
 - Is the date field 8-yyyymmdd or 4-yymd, or similar
 - Does user field look okay
 - For transnum, keynum, fnums, seeks, are they reasonable
 - For datamax, keymax, tocmax, dirmax, dirlev, are they reasonable

See FlatFile::DataStore::Utils.

Analysis:

 - What is maximum size of each data file (datamax)
 - What is maximum size of a record (datamax-preamble-recsep)
 - What is maximum number of data files
 - What is maximum number of records per keynum
 - What is maximum number of records in various scenarios
   - small records   many per datafile
   - medium records  fewer per datafile
   - large records   few per datafile
   - user-supplied average record size
 - What is maximum number of transactions (creates, updates, deletes)
 - What is maximum size of each keyfile
 - What is maximum number of keyfiles
 - What is maximum size of each tocfile
 - What is maximum number of tocfiles
 - What is maximum disk usage (datamax * max datafiles + key... + toc...)
 - How long would a migration take

See utils/flatfile-datastore.cgi (which is young and rough and doesn't
answer all of the above questions yet).

=head2 validating a datastore

 - Include average record size, biggest record, smallest record, size breakdown

See Flatfile::DataStore::Utils.

=head2 migrating a datastore

See Flatfile::DataStore::Utils and utils/migrate_validate.

=head2 interating over the datastore transactions

See Flatfile::DataStore::Utils.

=head1 FUTURE PLANS

=head2 Indexes

(Probably will use BerkeleyDB for this.)

=head3 Overview

This module provides access to records two ways:

 - via sequence number (keynum--zero-based, i.e., first record is keynum 0)
 - via file number and seek position (useful mainly for history review and recovery)

In order to provide access via other means, we need indexes.

For example, if I implement a datastore where each record can be
identified by a unique id number, I'll want to be able to retrieve a
record using this id number.

In addition, I'll want to be able to perform queries with keywords and
or phrases that will return lists of records that match the queries.

(Note: The scheme outlined below uses flatfiles. BerkeleyDB::Btree
would be a likely alternative. The basic data fields would still be
pertinent, but they would be the keys and the bit strings, the values.)

=head3 Keywords

One plan for keyword indexes would have flatfiles with four fields:

 - index tag
 - keyword
 - occurrence,position
 - bit vector

Examples of index tags might include "kw" for a general keyword index.
"ti" for a title index, "au" for an author index, etc.  They need not
be two-letter tags, but it's a common convention.

Keywords would be any string not containing a space.  Perhaps that's
too restrictive a definition, but it's how we do it currently.

Occurrence and position would be necessary to implement ajacency
operators in queries.  Occurrence refers to a particular occurrence
of a field if a record's fields might have multiple occurrences.
Position refers to the position of the keyword in the field. E.g.,
if a record contained two author fields:

 author: Baxter, Bradley MacKenzie
 author: Frog, Kermit The

the keyword index might have these entries:

 au baxter 1,1 01010101
 au bradley 1,2 01010101
 au frog 2,1 101
 au kermit 2,2 101
 au mackenzie 1,3 01010101
 au the 2,3 101

("01010101" and "101" represent the bit vector field.  In reality,
it would likely be in a compressed form, using, e.g., Data::Bvec.)

The example above shows the keywords normalized to lowercase with
punctuation removed.  This will usually--but not necessarily always--be
needed.

In order to be able to binary search and to browse the indexes, these
index files would need to be in sorted order and kept that way as
records are added, updated, and deleted.

The current plan is to store the bit vector field in a FlatFile
DataStore Lite datastore (since they can get large), and store
the keynum in the index flatfile.  Then we should be able to
use Tie::File to update and splice in changes, keeping the files
sorted.  See directory structure below.

=head3 Phrases

A similar plan for phrase indexes would have flatfiles with three
I<logical> fields similar to the above:

 - index tag
 - phrase (which may contain spaces)
 - bit vector

Examples of index tags might include "_kw", "_ti", "_au", using the
convention of a leading underscore to indicate a phrase index.

Phrases would be any string including spaces, e.g.,

 _au baxter bradley mackenzie  01010101
 _au frog kermit the  101

Occurrence and position are not needed because the phrase is always the
entire contents of a particular occurrence of a field.

Note that there are two spaces after the phrase.  This is so the
file may be generically sorted and correctly handle the following:

 _ti row row row  10101
 _ti row row row 1 boat  10101
 _ti row row row your boat  10101

Without the extra space, the bit string in the first line would
conflict with the terms in the second.  Similarly, binary searches
should return what you expect.

Note: the word "phrase" in this context refers to the phrase that is
created from the entire contents of a field.  This is different from
the concept of a phrase that a user may enter for a keyword search.

The latter is really multiple keywords with an implied ajacency
operator between them.  This type of phrase could match anywhere
in a field.

The former is a complete entity that must match a corresponding
complete entry in the phrase index.  This type of phrase, sometimes
called a "bound phrase", would always match starting from the beginning
of a field.

=head3 Headings

This idea is still nebulous.  It is a response to the shortcomings
of the phrase indexes.  I I<think> it may end up being a datastore
itself that is then keyword (and possibly phrase?) indexed.

=head3 Facets

We want to implement facets, but haven't settled on concrete ideas yet
(other than the way we do them already, which is less than ideal).

=cut

