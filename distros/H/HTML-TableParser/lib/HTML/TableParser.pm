# --8<--8<--8<--8<--
#
# Copyright (C) 2007 Smithsonian Astrophysical Observatory
#
# This file is part of HTML-TableParser
#
# HTML-TableParser is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package HTML::TableParser;

require 5.8.1;
use strict;
use warnings;

use Carp;
use HTML::Parser;

use HTML::TableParser::Table;

## no critic ( ProhibitAccessOfPrivateData )


our @ISA = qw(HTML::Parser);

our $VERSION = '0.42';

# Preloaded methods go here.

our %Attr =  ( Trim => 0,
	       Decode => 1,
	       Chomp => 0,
	       MultiMatch => 0,
	       DecodeNBSP => 0,
	     );
our @Attr = keys %Attr;

our $Verbose = 0;

sub new
{
  my $class = shift;

  my $reqs = shift;

  my $self = $class->SUPER::new
               (
		api_version => 3,
		unbroken_text => 1,
		start_h  => [ '_start', 'self, tagname, attr, line' ],
		end_h    => [ '_end',   'self, tagname, attr, line' ],
	       );

  croak( __PACKAGE__, ": must specify a table request" )
    unless  defined $reqs and 'ARRAY' eq ref $reqs;

  my $attr = shift || {};

  my @notvalid = grep { ! exists $Attr{$_} } keys %$attr;
  croak ( __PACKAGE__, ": Invalid attribute(s): '", 
	  join(" ,'", @notvalid ), "'" )
    if @notvalid;

  my %attr = ( %Attr, %$attr );

  $self->{reqs} = _tidy_reqs( $reqs, \%attr );

  $self->{Tables} = [ HTML::TableParser::Table->new() ];

  # by default we're not processing anything
  $self->_process(0);

  $self;
}


our @ReqAttr = ( qw( cols colre id idre class obj start end 
		     hdr row warn udata ),
		 keys %Attr );
our %ReqAttr = map { $_ => 1 } @ReqAttr;

# convert table requests into something that HTML::TableParser::Table can
# handle
sub _tidy_reqs
{
  my ( $reqs, $attr ) = @_;

  my @reqs;

  my $nreq = 0;
  for my $req ( @$reqs )
  {
    my %req;

    $nreq++;

    my @notvalid = grep { ! exists $ReqAttr{$_} } keys %$req;
    croak (__PACKAGE__, ": table request $nreq: invalid attribute(s): '",
	   join(" ,'", @notvalid ), "'" )
      if @notvalid;

    my $req_id = 0;


    # parse cols and id the same way
    for my $what ( qw( cols id ) )
    {
      $req{$what} = [];

      if ( exists $req->{$what} && defined $req->{$what} )
      {
	my @reqs;

	my $ref = ref $req->{$what};
	
	if ( 'ARRAY' eq $ref )
	{
	  @reqs = @{$req->{$what}};
	}
	elsif ( 'Regexp' eq $ref  || 
		'CODE' eq $ref ||
		! $ref )
	{
	  @reqs = ( $req->{$what} );
	}
	else
	{
	  croak( __PACKAGE__, 
		 ": table request $nreq: $what must be a scalar, arrayref, or coderef" );
	}
	
	# now, check that we have legal things in there
	my %attr = ();

	for my $match ( @reqs )
	{
	  my $ref = ref $match;
	  croak( __PACKAGE__, 
		 ": table request $nreq: illegal $what `$match': must be a scalar, regexp, or coderef" )
	    unless defined $match && ! $ref || 'Regexp' eq $ref 
	      || 'CODE' eq $ref ;

	  if ( ! $ref && $match eq '-' )
	  {
	    %attr = ( exclude => 1 );
  	    next;
	  }

	  if ( ! $ref && $match eq '--' )
	  {
	    %attr = ( skip => 1 );
	    next;
	  }

	  if ( ! $ref && $match eq '+' )
	  {
	    %attr = ();
	    next;
	  }

	  push @{$req{$what}}, { %attr, match => $match };
	  %attr = ();
	  $req_id++;
	}
      }
    }

    # colre is now obsolete, but keep backwards compatibility
    # column regular expression match?
    if ( defined $req->{colre} )
    {
      my $colre;

      if ( 'ARRAY' eq ref $req->{colre} )
      {
	$colre = $req->{colre};
      }
      elsif ( ! ref $req->{colre} )
      {
	$colre = [ $req->{colre} ];
      }
      else
      {
	croak( __PACKAGE__, 
	       ": table request $nreq: colre must be a scalar or arrayref" );
      }
      
      for my $re ( @$colre )
      {
	my $ref = ref $re;
	
	croak( __PACKAGE__, ": table request $nreq: colre must be a scalar" )
	  unless ! $ref or  'Regexp' eq $ref;
	push @{$req{cols}}, { include => 1, 
			      match => 'Regexp' eq $ref ? $re : qr/$re/ };
	$req_id++;
      }
    }


    croak( __PACKAGE__, 
	   ": table request $nreq: must specify at least one id method" )
      unless $req_id;

    $req{obj} = $req->{obj}
      if exists $req->{obj};

    $req{class} = $req->{class}
      if exists $req->{class};

    for my $method ( qw( start end hdr row warn new ) )
    {
      if ( exists $req->{$method} && 'CODE' eq ref $req->{$method} )
      {
	$req{$method} = $req->{$method};
      }

      elsif ( exists $req{obj} || exists $req{class})
      {
	my $thing = exists $req{obj} ? $req{obj} : $req{class};

	if ( exists $req->{$method} )
	{
	  if ( defined $req->{$method} )
	  {
	    croak( __PACKAGE__, 
		   ": table request $nreq: can't have object & non-scalar $method" )
	      if ref $req->{$method};
	    
	    my $call = $req->{$method};
	    
	    croak( __PACKAGE__, 
		   ": table request $nreq: class doesn't have method $call" )
	      if ( exists $req->{obj} && ! $req->{obj}->can( $call ) )
		|| !UNIVERSAL::can( $thing, $call );
	  }
	  
	  # if $req->{$method} is undef, user must have explicitly
	  # set it so, which is a signal to NOT call that method.
	}
	else
	{
	  $req{$method} = $method
	    if UNIVERSAL::can( $thing, $method );
	}
      }
      elsif( exists $req->{$method} )
      {
	croak( __PACKAGE__, ": invalid callback for $method" );
      }
    }

    # last minute cleanups for things that don't fit in the above loop
    croak( __PACKAGE__, ": must specify valid constructor for class $req->{class}" )
      if exists $req{class} && ! exists $req{new};


    $req{udata} = undef;
    $req{udata} = exists $req->{udata} ? $req->{udata} : undef;

    $req{match} = 0;

    @req{@Attr} = @Attr{@Attr};

    $req{$_} = $attr->{$_}
      foreach grep { defined $attr->{$_} } @Attr;

    $req{$_} = $req->{$_}
      foreach grep { defined $req->{$_} } @Attr;

    push @reqs, \%req;
  }

  \@reqs;
}


sub _process
{
  my ($self, $state) = @_;

  my $ostate = $self->{process} || 0;

  if ( $state )
  {
    $self->report_tags( qw( table th td tr ) );
    $self->handler( 'text'   => '_text',  'self, text, line' );
  }

  else
  {
    $self->report_tags( qw( table  ) );
    $self->handler( 'text' => '' );
  }

  $self->{process} = $state;
  $ostate;
}


our %trans = ( tr => 'row',
	       th => 'header',
	       td => 'column' );

sub _start
{
  my $self = shift;
  my $tagname = shift;

  print STDERR __PACKAGE__, "::start : $_[1] : $tagname \n"
    if $HTML::TableParser::Verbose;

  if ( 'table' eq $tagname )
  {
    $self->_start_table( @_ );
  }

  else
  {
    my $method = 'start_' . $trans{$tagname};

    $self->{Tables}[-1]->$method(@_);
  }
}


sub _end
{
  my $self = shift;
  my $tagname = shift;

  print STDERR __PACKAGE__, "::_end : $_[1]: $tagname \n"
    if $HTML::TableParser::Verbose;

  if ( 'table' eq $tagname )
  {
    $self->_end_table(  @_ );
  }

  else
  {
    my $method = 'end_' . $trans{$tagname};

    $self->{Tables}[-1]->$method(@_);
  }
}


sub _start_table
{
  my ( $self, $attr, $line ) = @_;

  my $otbl = $self->{Tables}[-1];

  my $tbl = HTML::TableParser::Table->new( $self, 
					   $self->{Tables}[-1]->ids,
					   $self->{reqs}, $line );

  print STDERR __PACKAGE__, "::_start_table : $tbl->{id}\n"
    if $HTML::TableParser::Verbose;

  $self->_process( $tbl->process );

  push @{$self->{Tables}}, $tbl;
}


sub _end_table
{
  my ( $self, $attr, $line ) = @_;


  my $tbl = pop @{$self->{Tables}};

  print STDERR __PACKAGE__, "::_end_table : $tbl->{id}\n"
    if $HTML::TableParser::Verbose;

  # the first table in the list is our sentinel table.  if we're about
  # to delete it, it means that we've hit one too many </table> tags
  # we delay the croak until after the pop so that the verbose error
  # message prints something nice. no harm anyway as we're about to
  # keel over and croak.

  croak( __PACKAGE__, 
	 ": $line: unbalanced <table> and </table> tags; too many </table> tags" )
    if 0 == @{$self->{Tables}};

  undef $tbl;

  $self->_process( $self->{Tables}[-1]->process );
}


sub _text
{
  my ( $self, $text, $line ) = @_;

  $self->{Tables}[-1]->text( $text );
}




1;
__END__

=pod


=head1 NAME

HTML::TableParser - Extract data from an HTML table

=head1 SYNOPSIS

  use HTML::TableParser;

  @reqs = (
	   {
	    id => 1.1,                    # id for embedded table
	    hdr => \&header,              # function callback
	    row => \&row,                 # function callback
	    start => \&start,             # function callback
	    end => \&end,                 # function callback
	    udata => { Snack => 'Food' }, # arbitrary user data
	   },
	   {
	    id => 1,                      # table id
	    cols => [ 'Object Type',
		      qr/object/ ],       # column name matches
	    obj => $obj,                  # method callbacks
	   },
	  );

  # create parser object
  $p = HTML::TableParser->new( \@reqs, 
		   { Decode => 1, Trim => 1, Chomp => 1 } );
  $p->parse_file( 'foo.html' );


  # function callbacks
  sub start {
    my ( $id, $line, $udata ) = @_;
    #...
  }

  sub end {
    my ( $id, $line, $udata ) = @_;
    #...
  }

  sub header {
    my ( $id, $line, $cols, $udata ) = @_;
    #...
  }

  sub row  {
    my ( $id, $line, $cols, $udata ) = @_;
    #...
  }

=head1 DESCRIPTION

B<HTML::TableParser> uses B<HTML::Parser> to extract data from an HTML
table.  The data is returned via a series of user defined callback
functions or methods.  Specific tables may be selected either by a
matching a unique table id or by matching against the column names.
Multiple (even nested) tables may be parsed in a document in one pass.

=head2 Table Identification

Each table is given a unique id, relative to its parent, based upon its
order and nesting. The first top level table has id C<1>, the second
C<2>, etc.  The first table nested in table C<1> has id C<1.1>, the
second C<1.2>, etc.  The first table nested in table C<1.1> has id
C<1.1.1>, etc.  These, as well as the tables' column names, may
be used to identify which tables to parse.

=head2 Data Extraction

As the parser traverses a selected table, it will pass data to user
provided callback functions or methods after it has digested
particular structures in the table.  All functions are passed the
table id (as described above), the line number in the HTML source
where the table was found, and a reference to any table specific user
provided data.

=over 8

=item Table Start

The B<start> callback is invoked when a matched table has been found.

=item Table End

The B<end> callback is invoked after a matched table has been parsed.

=item Header

The B<hdr> callback is invoked after the table header has been read in.
Some tables do not use the B<E<lt>thE<gt>> tag to indicate a header, so this
function may not be called.  It is passed the column names.

=item Row

The B<row> callback is invoked after a row in the table has been read.
It is passed the column data.

=item Warn

The B<warn> callback is invoked when a non-fatal error occurs during
parsing.  Fatal errors croak.

=item New

This is the class method to call to create a new object when
B<HTML::TableParser> is supposed to create new objects upon table
start.

=back

=head2 Callback API

Callbacks may be functions or methods or a mixture of both.
In the latter case, an object must be passed to the constructor.
(More on that later.)

The callbacks are invoked as follows:

  start( $tbl_id, $line_no, $udata );

  end( $tbl_id, $line_no, $udata );

  hdr( $tbl_id, $line_no, \@col_names, $udata );

  row( $tbl_id, $line_no, \@data, $udata );

  warn( $tbl_id, $line_no, $message, $udata );

  new( $tbl_id, $udata );

=head2 Data Cleanup

There are several cleanup operations that may be performed automatically:

=over 8

=item Chomp

B<chomp()> the data

=item Decode

Run the data through B<HTML::Entities::decode>.

=item DecodeNBSP

Normally B<HTML::Entitites::decode> changes a non-breaking space into
a character which doesn't seem to be matched by Perl's whitespace
regexp.  Setting this attribute changes the HTML C<nbsp> character to
a plain 'ol blank.

=item Trim

remove leading and trailing white space.

=back

=head2 Data Organization

Column names are derived from cells delimited by the B<E<lt>thE<gt>> and
B<E<lt>/thE<gt>> tags. Some tables have header cells which span one or
more columns or rows to make things look nice.  B<HTML::TableParser>
determines the actual number of columns used and provides column
names for each column, repeating names for spanned columns and
concatenating spanned rows and columns.  For example,  if the
table header looks like this:

 +----+--------+----------+-------------+-------------------+
 |    |        | Eq J2000 |             | Velocity/Redshift |
 | No | Object |----------| Object Type |-------------------|
 |    |        | RA | Dec |             | km/s |  z  | Qual |
 +----+--------+----------+-------------+-------------------+

The columns will be:

  No
  Object
  Eq J2000 RA
  Eq J2000 Dec
  Object Type
  Velocity/Redshift km/s
  Velocity/Redshift z
  Velocity/Redshift Qual

Row data are derived from cells delimited by the B<E<lt>tdE<gt>> and 
B<E<lt>/tdE<gt>> tags.  Cells which span more than one column or row are
handled correctly, i.e. the values are duplicated in the appropriate
places.

=head1 METHODS

=over 8

=item new

   $p = HTML::TableParser->new( \@reqs, \%attr );

This is the class constructor.  It is passed a list of table requests
as well as attributes which specify defaults for common operations.
Table requests are documented in L</Table Requests>.

The C<%attr> hash provides default values for some of the table
request attributes, namely the data cleanup operations ( C<Chomp>,
C<Decode>, C<Trim> ), and the multi match attribute C<MultiMatch>,
i.e.,

  $p = HTML::TableParser->new( \@reqs, { Chomp => 1 } );

will set B<Chomp> on for all of the table requests, unless overridden
by them.  The data cleanup operations are documented above; C<MultiMatch>
is documented in L</Table Requests>.

B<Decode> defaults to on; all of the others default to off.

=item parse_file

This is the same function as in B<HTML::Parser>.

=item parse

This is the same function as in B<HTML::Parser>.

=back


=head1 Table Requests

A table request is a hash used by B<HTML::TableParser> to determine
which tables are to be parsed, the callbacks to be invoked, and any
data cleanup.  There may be multiple requests processed by one call to
the parser; each table is associated with a single request (even if
several requests match the table).

A single request may match several tables, however unless the
B<MultiMatch> attribute is specified for that request, it will be used
for the first matching table only.

A table request which matches a table id of C<DEFAULT> will be used as
a catch-all request, and will match all tables not matched by other
requests.  Please note that tables are compared to the requests in the
order that the latter are passed to the B<new()> method; place the
B<DEFAULT> method last for proper behavior.


=head2 Identifying tables to parse

B<HTML::TableParser> needs to be told which tables to parse.  This can
be done by matching table ids or column names, or a combination of
both.  The table request hash elements dedicated to this are:

=over 8

=item id

This indicates a match on table id.  It can take one of these forms:

=over 8

=item exact match

  id => $match
  id => '1.2'

Here C<$match> is a scalar which is compared directly to the table id.

=item regular expression

  id => $re
  id => qr/1\.\d+\.2/

C<$re> is a regular expression, which must be constructed with the
C<qr//> operator.

=item subroutine

  id => \&my_match_subroutine
  id => sub { my ( $id, $oids ) = @_ ; 
           $oids[0] > 3 && $oids[1] < 2 }

Here C<id> is assigned a coderef to a subroutine which returns
true if the table matches, false if not.  The subroutine is passed
two arguments: the table id as a scalar string ( e.g. C<1.2.3>) and the
table id as an arrayref (e.g. C<$oids = [ 1, 2, 3]>).

=back

C<id> may be passed an array containing any combination of the
above:

  id => [ '1.2', qr/1\.\d+\.2/, sub { ... } ]

Elements in the array may be preceded by a modifier indicating
the action to be taken if the table matches on that element.
The modifiers and their meanings are:

=over 8

=item C<->

If the id matches, it is explicitly excluded from being processed
by this request.

=item C<-->

If the id matches, it is skipped by B<all> requests.

=item C<+>

If the id matches, it will be processed by this request.  This
is the default action.

=back

An example:

  id => [ '-', '1.2', 'DEFAULT' ]

indicates that this request should be used for all tables,
except for table 1.2.

  id => [ '--', '1.2' ]

Table 2 is just plain skipped altogether.

=item cols

This indicates a match on column names.  It can take one of these forms:

=over 8

=item exact match

  cols => $match
  cols => 'Snacks01'

Here C<$match> is a scalar which is compared directly to the column names.
If any column matches, the table is processed.

=item regular expression

  cols => $re
  cols => qr/Snacks\d+/

C<$re> is a regular expression, which must be constructed with the
C<qr//> operator.  Again, a successful match against any column name
causes the table to be processed.

=item subroutine

  cols => \&my_match_subroutine
  cols => sub { my ( $id, $oids, $cols ) = @_ ;
                ... }

Here C<cols> is assigned a coderef to a subroutine which returns
true if the table matches, false if not.  The subroutine is passed
three arguments: the table id as a scalar string ( e.g. C<1.2.3>), the
table id as an arrayref (e.g. C<$oids = [ 1, 2, 3]>), and the column
names, as an arrayref (e.g. C<$cols = [ 'col1', 'col2' ]>).  This
option gives the calling routine the ability to make arbitrary
selections based upon table id and columns.

=back

C<cols> may be passed an arrayref containing any combination of the
above:

  cols => [ 'Snacks01', qr/Snacks\d+/, sub { ... } ]

Elements in the array may be preceded by a modifier indicating
the action to be taken if the table matches on that element.
They are the same as the table id modifiers mentioned above.

=item colre

B<This is deprecated, and is present for backwards compatibility only.>
An arrayref containing the regular expressions to match, or a scalar
containing a single reqular expression

=back

More than one of these may be used for a single table request. A
request may match more than one table.  By default a request is used
only once (even the C<DEFAULT> id match!). Set the C<MultiMatch>
attribute to enable multiple matches per request.

When attempting to match a table, the following steps are taken:

=over 8

=item 1

The table id is compared to the requests which contain an id match.
The first such match is used (in the order given in the passed array).

=item 2

If no explicit id match is found, column name matches are attempted.
The first such match is used (in the order given in the passed array)

=item 3

If no column name match is found (or there were none requested),
the first request which matches an B<id> of C<DEFAULT> is used.

=back

=head2 Specifying the data callbacks

Callback functions are specified with the callback attributes
C<start>, C<end>, C<hdr>, C<row>, and C<warn>.  They should be set to
code references, i.e.

  %table_req = ( ..., start => \&start_func, end => \&end_func )

To use methods, specify the object with the C<obj> key, and
the method names via the callback attributes, which should be set
to strings.  If you don't specify method names they will default to (you
guessed it) C<start>, C<end>, C<hdr>, C<row>, and C<warn>.

  $obj = SomeClass->new();
  # ...
  %table_req_1 = ( ..., obj => $obj );
  %table_req_2 = ( ..., obj => $obj, start => 'start',
                             end => 'end' );

You can also have B<HTML::TableParser> create a new object for you
for each table by specifying the C<class> attribute.  By default
the constructor is assumed to be the class B<new()> method; if not,
specify it using the C<new> attribute:

  use MyClass;
  %table_req = ( ..., class => 'MyClass', new => 'mynew' );

To use a function instead of a method for a particular callback,
set the callback attribute to a code reference:

  %table_req = ( ..., obj => $obj, end => \&end_func );

You don't have to provide all the callbacks.  You should not use both
C<obj> and C<class> in the same table request.

B<HTML::TableParser> automatically determines if your object
or class has one of the required methods.  If you wish it I<not>
to use a particular method, set it equal to C<undef>.  For example

  %table_req = ( ..., obj => $obj, end => undef )

indicates the object's B<end> method should not be called, even
if it exists.

You can specify arbitrary data to be passed to the callback functions
via the C<udata> attribute:

  %table_req = ( ..., udata => \%hash_of_my_special_stuff )

=head2 Specifying Data cleanup operations

Data cleanup operations may be specified uniquely for each table. The
available keys are C<Chomp>, C<Decode>, C<Trim>.  They should be
set to a non-zero value if the operation is to be performed.

=head2 Other Attributes

The C<MultiMatch> key is used when a request is capable of handling
multiple tables in the document.  Ordinarily, a request will process
a single table only (even C<DEFAULT> requests).
Set it to a non-zero value to allow the request to handle more than
one table.


=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius (djerius@cpan.org)

=head1 SEE ALSO

L<HTML::Parser>, L<HTML::TableExtract>.

=cut
