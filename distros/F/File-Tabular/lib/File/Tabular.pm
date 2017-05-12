package File::Tabular;

# TODO : -optimize _getField (could probably dispense with 
#                             "mkRecord", call $self->..)
#        -BUG : preMatch/postMatch won't work on explicit field searches
#        -optimize: postpone preMatch/postMatch until display time
#        -escaping fieldSep : make it optional

#        - synopsis : example of file cloning with select (e.g. year=2004)



our $VERSION = "0.72"; 

use strict;
use warnings;
no  warnings 'uninitialized';
use locale;
use Carp;
# use Carp::Assert; # dropped because not really needed and not in Perl core
use Fcntl ':flock';
use Hash::Type;
use Search::QueryParser 0.92;
use File::Temp;

=head1 NAME

File::Tabular - searching and editing flat tabular files

=head1 SYNOPSIS

  use File::Tabular;
  my $f = new File::Tabular($filename);

  my $row = $f->fetchrow;
  print $row->{field1}, $row->{field2};

  $row = $f->fetchrow(where => 'someWord');
  $row = $f->fetchrow(where => 'field1 > 4 AND field2 >= "01.01.2001"');
  $row = $f->fetchrow(where => qr/some\s+(complex\s*)?(regex|regular expression)/i);

  $f->rewind;
  my $rows = $f->fetchall(where => 'someField =~ ^[abc]+');
  print $_->{someField} foreach @$rows;

  $f->rewind;
  $rows = $f->fetchall(where => '+field1:someWord -field2:otherWord',
                       orderBy => 'field3, field6:num, field5:-alpha');

  $f->rewind;
  my $hashRows = $f->fetchall(where   => 'foo AND NOT bar',
                              key     => 'someField');
  print $hashRows->{someKey}{someOtherField};

  # open for updates, and remember the updates in a journal file
  $f = new File::Tabular("+<$filename", {journal => ">>$journalFile"});

  # updates at specific positions (line numbers)
  $f->splices(4  => 2, undef,	# delete 2 lines from position 4
              7  => 1, {f1 => $v1, f2 => $v2, ...}, # replace line 7
              9  => 0, { ...},   # insert 1 new line at position 9
              22 => 0, [{...}, {...}, ...] # insert several lines at pos. 22
              ...
              -1 => 0, [{...}, {...}, ...] # append at the end
           );

  # shorthand to add new data at the end
  $f->append({f1 => $v1, f2 => $v2, ...});
  # same thing, but use the "Hash::Type" associated to the file
  $f->append($f->ht->new($v1, $v2, ...)); 


  $f->clear;			# removes all data (but keeps the header line)

  # updates at specific keys, corresponding to @keyFields
  $f->writeKeys({key1 => {f1 => $v1, f2 => $v2, ...}, # add or update
                 key2 => undef,                       # remove 
                 ...
                 }, @keyFields);


  # replay the updates on a backup file
  my $bck = new File::Tabular("+<$backupFile");
  $bck->playJournal($journalFile);

  # get info from associated filehandle
  printf "%d size, %d blocks", $f->stat->{size}, $f->stat->{blocks};
  my $mtime = $f->mtime;
  printf "time last modified : %02d:%02d:%02d", @{$mtime}{qw(hour min sec)};

=head1 DESCRIPTION

A I<tabular file> is a flat text file containing data organised
in rows (records) and columns (fields).

This module provides database-like functionalities for managing
tabular files : retrieving, searching, writing, autonumbering, journaling.
However, unlike other modules like L<DBD::CSV|DBD::CSV>, it doesn't try
to make it look like a database : rather, the API was designed
specifically for work with tabular files. 
Instead of SQL, search queries are specified in a web-like
fashion, with support for regular expressions and cross-field
searches. Queries are compiled internally into perl closures
before being applied to every data record, which makes it
quite fast.

Write operations take a list of modifications as argument;
then they apply the whole list atomically in a single rewrite
of the data file.

Here are some of the reasons why you might choose to 
work with a tabular file rather than a regular database :

=over

=item *

no need to install a database system (not even buy one)!

=item * 

easy portability and data exchange with external tools 
(text editor, spreadsheet, etc.)

=item *

search queries immediately ready for a web application

=item *

good search performance, even with several thousand records

=back


On the other hand, tabular files will probably be inappropriate if you
need very large volumes of data, complex multi-table data models or
frequent write operations.



=head1 METHODS

=over

=item C<< new (open1, open2, ..., {opt1 => v1, opt2 => v2, ...}) >>

Creates a new tabular file object. 
The list of arguments C<open1, open2, ...> is  fed directly to
L<perlfunc/open> for opening the associated file. 
Can also be a reference to an already opened filehandle.

The final hash ref is a collection of optional parameters, taken
from the following list :

=over

=item fieldSep

field separator : any character except '%' ('|' by default).
Escape sequences like C<\t> are admitted.

=item recordSep

record separator ('\n' by default).

=item fieldSepRepl

string to substitute if fieldSep is met in the data.
(by default, url encoding of B<fieldSep>, i.e. '%7C' )

=item recordSepRepl

string to substitute if recordSep is met in the data 
(by default, url encoding of B<recordSep>, i.e. '%0A' )


=item autoNumField

name of field for which autonumbering is turned on (none by default).
This is useful to generate keys : when you write a record, the
character '#' in that field will be replaced by a fresh number,
incremented automatically.  This number will be 1 + the
largest number read I<so far> (it is your responsability to read all
records before the first write operation).

=item autoNum

initial value of the counter for autonumbering (1 by default).

=item autoNumChar

character that will be substituted by an autonumber when
writing records ('#' by default).


=item flockMode

mode for locking the file, see L<perlfunc/flock>. By default,
this will be LOCK_EX if B<open1> contains 'E<gt>' or
'+E<lt>', LOCK_SH otherwise.

=item flockAttempts

Number of attempts to lock the file,
at 1 second intervals, before returning an error.
Zero by default.
If nonzero, LOCK_NB is added to flockMode;
if zero,  a single locking attempt will be made, blocking
until the lock is available.

=item headers

reference to an array of field names.
If not present, headers will be read from the first line of
the file.

=item printHeaders

if true, the B<headers> will be printed to the file.
If not specified, treated as 'true' if
B<open1> contains 'E<gt>'.

=item journal

name of journaling file, or reference to a list of arguments for
L<perlfunc/open>. The journaling file will log all write operations.
If specified as a simple file name, it will be be opened in
'E<gt>E<gt>' mode.

A journal file can then be replayed through method L</playJournal> 
(this is useful to recover after a crash, by playing the journal
on a backup copy of your data).

=item rxDate

Regular expression for matching a date.
Default value is C<< qr/^\d\d?\.\d\d?\.\d\d\d?\d?$/ >>.
This will be used by L</compileFilter> to perform appropriate comparisons.

=item date2str

Ref to a function for transforming dates into strings 
suitable for sorting (i.e. year-month-day).
Default is :

 sub {my ($d, $m, $y) = ($_[0] =~ /(\d\d?)\.(\d\d?)\.(\d\d\d?\d?)$/);
      $y += ($y > 50) ? 1900 : 2000 if defined($y) && $y < 100;
      return sprintf "%04d%02d%02d", $y, $m, $d;}

=item rxNum

Regular expression for matching a number.
Default value is C<< qr/^[-+]?\d+(?:\.\d*)?$/ >>.
This will be used by L</compileFilter> to perform appropriate comparisons.

=item preMatch/postMatch

Strings to insert before or after a match when filtering rows
(will only apply to search operator ':' on the whole line, i.e.
query C<< "foo OR bar" >> will highlight both "foo" and "bar", 
but query C<< "~ 'foo' OR someField:bar" >>
will not highlight anything; furthermore, a match-all 
request containing just '*' will not highlight anything either).

=item avoidMatchKey

If true, searches will avoid to match on the first field. So a request
like C<< $ft->fetchall(where => '123 OR 456') >> will not find
the record with key 123, unless the word '123' appears somewhere
in the other fields. This is useful when queries come from a Web
application, and we don't want users to match a purely technical
field. 

This search behaviour will not apply to regex searches. So requests like
C<< $ft->fetchall(where => qr/\b(123|456)\b/) >> 
or 
C<< $ft->fetchall(where => ' ~ 123 OR ~ 456') >> 
will actually find the record with key 123.

=back

=cut

############################################################
# CONSTANTS
############################################################

use constant BUFSIZE => 1 << 21; # 2MB, used in copyData

use constant DEFAULT => {
  fieldSep      => '|',
  recordSep     => "\n",
  autoNumField  => undef, 			
  autoNumChar   => '#', 			
  autoNum       => 1, 			
  lockAttempts  => 0,
  rxNum         => qr/^[-+]?\d+(?:\.\d*)?$/,
  rxDate        => qr/^\d\d?\.\d\d?\.\d\d\d?\d?$/,
  date2str      => sub {my ($d, $m, $y) = 
			  ($_[0] =~ /(\d\d?)\.(\d\d?)\.(\d\d\d?\d?)$/);
		        $y += ($y > 50) ? 1900 : 2000 
			  if defined($y) && $y < 100;
		        return sprintf "%04d%02d%02d", $y, $m, $d;},
  preMatch      => '',
  postMatch     => '',
  avoidMatchKey => undef
};


use constant {
 statType => Hash::Type->new(qw(dev ino mode nlink uid gid rdev size 
				atime mtime ctime blksize blocks)),
 timeType => Hash::Type->new(qw(sec min hour mday mon year wday yday isdst))
};


############################################################
# METHODS
############################################################

sub new {
  my $class = shift;
  my $args = ref $_[-1] eq 'HASH' ? pop : {};

  # create object with default values
  my $self = bless {};
  foreach my $option (qw(fieldSep recordSep autoNumField autoNumChar autoNum  
                         rxDate rxNum date2str preMatch postMatch 
                         avoidMatchKey)) {
    $self->{$option} = $args->{$option} || DEFAULT->{$option};
  }

  # eval to expand escape sequences, for example if fieldSep is given as '\t' 
  foreach my $option (qw(fieldSep recordSep)) {
    $self->{$option} = eval qq{qq{$self->{$option}}};
  }

  # field and record separators
  croak "can't use '%' as field separator" if $self->{fieldSep} =~ /%/;
  
  $self->{recordSepRepl} = $args->{recordSepRepl} || 
                           urlEncode($self->{recordSep});
  $self->{fieldSepRepl} = $args->{fieldSepRepl} || 
                           urlEncode($self->{fieldSep});
  $self->{rxFieldSep} = qr/\Q$self->{fieldSep}\E/;


  # open file and get lock
  _open($self->{FH}, @_) or croak "open @_ : $! $^E";
  my $flockAttempts =  $args->{flockAttempts} || 0;
  my $flockMode =  $args->{flockMode} ||
    $_[0] =~ />|\+</ ? LOCK_EX : LOCK_SH;
  $flockMode |= LOCK_NB if $flockAttempts > 0;
  for (my $n = $flockAttempts; $n >= 1; $n--) {
    last if flock $self->{FH}, $flockMode; # exit loop if flock succeeded
    $n > 1 ? sleep(1) : croak "could not flock @_: $^E";
  };

  # setup journaling
  if (exists $args->{journal}) { 
    my $j = {}; # create a fake object for _printRow
    $j->{$_} = $self->{$_} foreach qw(fieldSep recordSep 
				      fieldSepRepl recordSepRepl);
    _open($j->{FH}, ref $args->{journal} eq 'ARRAY' ? @{$args->{journal}}
	                                            : ">>$args->{journal}")
      or croak "open journal $args->{journal} : $^E";
    $self->{journal} = bless $j;
  }

  # field headers
  my $h = $args->{headers} || [split($self->{rxFieldSep}, $self->_getLine, -1)];
  $self->{ht} = new Hash::Type(@$h);
  $self->_printRow(@$h) if 
    exists $args->{printHeaders} ? $args->{printHeaders} : ($_[0] =~ />/);

  # ready for reading data lines
  $self->{dataStart} = tell($self->{FH});
  $. = 0;	# setting line counter to zero for first dataline


  # create a closure which takes a (already chomped) line and returns a record
  my %tmp; # copy some attributes of $self in order to avoid a cyclic ref
  $tmp{$_} = $self->{$_} foreach qw/rxFieldSep fieldSepRepl fieldSep ht/;
  $self->{mkRecord} = sub {
     my @vals = split $tmp{rxFieldSep}, $_[0], -1;
     s/$tmp{fieldSepRepl}/$tmp{fieldSep}/g foreach @vals;
     return $tmp{ht}->new(@vals);
   };

  return $self;
}


sub _open { # stupid : because of 'open' strange prototyping, 
            # cannot pass an array directly
  my $result = (ref $_[1] eq 'GLOB') ? $_[0] = $_[1]                         : 
               @_ > 3                ? open($_[0], $_[1], $_[2], @_[3..$#_]) :
               @_ > 2                ? open($_[0], $_[1], $_[2])             : 
                                       open($_[0], $_[1]);
  binmode($_[0], ":crlf") if $result; # portably open text file, see PerlIO
  return $result;
}




sub _getLine { 
  my $self = shift;
  local $/ = $self->{recordSep};
  my $line = readline $self->{FH};
  if (defined $line) {
    chomp $line;
    $line =~ s/$self->{recordSepRepl}/$self->{recordSep}/g;
  }
  return $line;
}


sub _printRow { # Internal function to print a data row and automatically deal with 
                # autonumbering, if necessary. 
  my ($self, @vals) = @_;

  if ($self->{autoNumField}) { # autoNumbering
    my $ix = $self->{ht}{$self->{autoNumField}} - 1;
    if ($vals[$ix] =~ s/$self->{autoNumChar}/$self->{autoNum}/) {
      $self->{autoNum} += 1;
    } 
    elsif ($vals[$ix] =~ m/(\d+)/) {
      $self->{autoNum} = $1 + 1 if $1 + 1 > $self->{autoNum};
    } 
  }

  s/\Q$self->{fieldSep}\E/$self->{fieldSepRepl}/ foreach @vals;
  my $line = join $self->{fieldSep}, @vals;
  $line =~ s/\Q$self->{recordSep}\E/$self->{recordSepRepl}/g;
  my $fh = $self->{FH};
  print $fh $line, $self->{recordSep};
}


=item C<< fetchrow(where => filter) >>

returns the next record matching the (optional) filter.  If there is
no filter, just returns the next record.  

The filter is either a code reference generated by L</compileFilter>,
or a string which will be automatically fed as argument to
L</compileFilter>; this string can contain just a word, a regular
expression, a complex boolean query involving field names and
operators, etc., as explained below.

=cut

# _getField($r, $fieldNumber) 
# Internal method for lazy creation of a record from a line.
# Will be called only when a specific field is required.
# See creation of $r in method 'fetchrow' just below.

sub _getField {  tied(%{$_[0]->{record} ||= $_[0]->{mkRecord}($_[0]->{line})})->[$_[1]]; }


sub fetchrow {
  my $self = shift;
  my $filter = undef;

  # accept fetchrow(where=>filter) or fetchrow({where=>filter}) or fetchrow(filter)
  my @args = ref $_[0] eq 'HASH' ? @{$_[0]} : @_;
  if (@args) {
    shift @args if $args[0] =~ /^where$/i;
    croak "fetchrow : invalid number of arguments" if @args != 1;
    $filter = $args[0];
    $filter = $self->compileFilter($filter) if $filter and not ref $filter eq 'CODE';
  }

  while (my $line = $self->_getLine) {

    # create structure $r for _getField
    my $r = {line => $line, record => undef, mkRecord => $self->{mkRecord}};

    next if $filter and not $filter->($r);

    $r->{record} ||= $self->{mkRecord}($r->{line});

    if ($self->{autoNumField}) {
      my ($n) = $r->{record}{$self->{autoNumField}} =~ m/(\d+)/;
      $self->{autoNum} = $n+1 if $n and $n+1 > $self->{autoNum};
    }
    return $r->{record};
  }
  return undef;
}

=item C<< fetchall(where => filter, orderBy => cmp) >>

=item C<< fetchall(where => filter, key => keySpecif) >>

finds all next records matching the (optional) filter.
If there is no filter, finds all remaining records.

The filter is either a code reference generated by L</compileFilter>,
or a string which will be automatically fed as argument to
L</compileFilter>.

The return value depends on context and on arguments :

=over

=item * 

if no B<key> parameter is given, and we are in a scalar context, then
C<fetchall> returns a reference to an array of records.

The optional B<orderBy> parameter can be a field name, a ref to a list
of field names, a string like C<"field1: -alpha, field2:-num, ...">,
or, more generally, a user-provided comparison function;
see L<Hash::Type/cmp> for a fully detailed explanation.

Otherwise, the resulting array is in data source order.

=item * 

if no B<key> parameter is given, and we are in a list context, then
C<fetchall> returns a pair : the first item is a reference to an array
of records as explained above ; the second item is a reference to an
array of line numbers corresponding to those records (first data line
has number 0).  These line numbers might be useful later
if you update the records through the L</splices> method.
No B<orderBy> is allowed if C<fetchall> is called in
list context.

=item * 

if a B<key> parameter is given, 
then C<fetchall> returns a reference to a hash, whose 
values are the retrieved records, and whose keys
are built according to the B<keySpecif> argument.
This must be either a single field name (scalar), or
a a list of field names (ref to an array of scalars).
Values corresponding to those field names will form the
key for each entry of the hash;
if necessary, multiple values are joined together 
through L<$;|perlvar/$;>.
No B<orderBy> argument is allowed, because hashes have no ordering.

=back

=cut

sub fetchall { 
  my $self = shift;
  my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

  croak "fetchall in list context : not allowed with 'orderBy' or 'key' arg"
    if wantarray and ($args{orderBy} or $args{key});

  croak "fetchall : args 'orderBy' and 'key' not allowed together"
    if $args{orderBy} and $args{key};

  my @k = !$args{key} ? () : ref $args{key}  ? @{$args{key}} : ($args{key});

  my $filter = $args{where};
  $filter = $self->compileFilter($filter) if $filter and not ref $filter eq 'CODE';

  if (@k) {			# will return a hash of rows 
    croak "fetchall : 'orderBy' not allowed  with 'key'" if $args{orderBy};
    croak "fetchall in list context : not allowed with 'key'" if wantarray;
    my $rows = {};
    while (my $row = $self->fetchrow($filter)) {
      $rows->{join($;, @{$row}{@k})} = $row; 
    }
    return $rows;
  }
  else {			# will return an array of rows
    my ($rows, $line_nos) = ([], []);
    while (my $row = $self->fetchrow($filter)) {
      push @$rows, $row;  
      push @$line_nos, $. - 1 if wantarray; 
    }

    if ($args{orderBy}) {
      croak "fetchall in list context : not allowed with 'orderBy'" if wantarray;
      my $tmp = ref $args{orderBy};
      my $cmpFunc = $tmp eq 'ARRAY' ? $self->{ht}->cmp(@{$args{orderBy}}) :
	            $tmp eq 'CODE'  ? $args{orderBy} :
	                              $self->{ht}->cmp($args{orderBy});
      $rows = [sort $cmpFunc @$rows];
    }
    return wantarray ? ($rows, $line_nos) : $rows;    
  }
}



=item C<< rewind >>

Rewinds the file to the first data line (after the headers)

=cut

sub rewind {
  my $self = shift;
  seek $self->{FH}, $self->{dataStart}, 0;
  $. = 0;
}



=item C<< ht >>

Returns the instance of L<Hash::Type|Hash::Type> associated with 
the file.

=cut

sub ht { my $self = shift; $self->{ht}; }



=item C<< headers >>

returns the list of field names

=cut

sub headers { my $self = shift; $self->ht->names; }

=item C<< stat >>

returns a hash ref corresponding to a call of 
L<stat|perlfunc/stat> on the associated filehandle.
Keys of the hash have names as documented in
L<stat|perlfunc/stat>. Ex:

     printf "%d size, %d blocks", $f->stat->{size}, $f->stat->{blocks};

=cut


sub stat  {my $self = shift; statType->new(stat($self->{FH}));}


=item C<< atime >>, C<< mtime >>, C<< ctime >>

each of these methods returns a hash ref corresponding to a call of 
L<localtime|perlfunc/localtime> on the last access time, last modified
time, or last inode change time of the associated filehandle
(see L<stat|perlfunc/stat> for explanations).
Keys of the hash have names as documented in
L<localtime|perlfunc/localtime>. Ex:

  my $mtime = $f->mtime;
  printf "time last modified : %02d:%02d:%02d", @{$mtime}{qw(hour min sec)};

=cut

sub atime {my $self = shift; timeType->new(localtime(($self->stat->{atime})));}
sub mtime {my $self = shift; timeType->new(localtime(($self->stat->{mtime})));}
sub ctime {my $self = shift; timeType->new(localtime(($self->stat->{ctime})));}

=item C<< splices >>

  splices(pos1 => 2, undef,           # delete 2 lines
          pos2 => 1, row,             # replace 1 line
          pos3 => 0, [row1, row2 ...] # insert lines
              ...
          -1   => 0, [row1, ...     ] # append lines
           );

           # special case : autonum if pos== -1


Updates the data, in a spirit similar to
L<perlfunc/splice> (hence the name of the method).  The whole file is
rewritten in an atomic operation, deleting, replacing or appending
data lines as specified by the "splice instructions".  Returns the
number of "splice instructions" performed.

A splice instruction is a triple composed of :

=over

=item 1

a position (line number) that specifies
the place where modifications will occur.
Line numbers start at 0.
Position -1 means end of data.

=item 2

a number of lines to delete (might be zero).

=item 3

a ref to a hash or to a list of hashes containing new data to 
insert (or C<undef> if there is no new data).

=back

If there are several splice instructions, their positions must be
sorted in increasing order (except of course position -1,
meaning "end of data", which must appear last).

Positions always refer to line numbers in the original file, before
any modifications. Therefore, it makes no sense to write

  splices(10 => 5, undef,
          12 => 0, $myRow)

because after deleting 5 rows at line 10, we cannot insert a new
row at line 12.

The whole collection of splice instructions 
may also be passed as an array ref instead of a list.

If you intend to fetch rows again after a B<splice>, you
must L<rewind> the file first.

=cut



sub splices {
  my $self = shift;
  my $args = ref $_[0] eq 'ARRAY' ? $_[0] : \@_;
  my $nArgs = @$args;
  croak "splices : number of arguments must be multiple of 3" if $nArgs % 3;

  my $TMP = undef;	# handle for a tempfile

  my $i;
  for ($i=0; $i < $nArgs; $i+=3 ) {
    my ($pos, $del, $lines) = @$args[$i, $i+1, $i+2];

    $self->_journal('SPLICE', $pos, $del, $lines);

    if ($pos == -1) { # we want to append new data at end of file
      $TMP ?  # if we have a tempfile ...
	     copyData($TMP, $self->{FH}) # copy back all remaining data
	   : seek $self->{FH}, 0, 2;     # otherwise goto end of file
      $pos = $.; # sync positions (because of test 12 lines below)
    }
    elsif (           # we want to put data in the middle of file and ..
           not $TMP and $self->stat->{size} > $self->{dataStart}) { 
      $TMP = new File::Temp or croak "no tempfile: $^E";
      binmode($TMP, ":crlf");

      $self->rewind;
      copyData($self->{FH}, $TMP);
      $self->rewind; 
      seek $TMP, 0, 0;
    }

    croak "splices : cannot go back to line $pos" if $. > $pos;

    local $/ = $self->{recordSep};

    while ($. < $pos) { # sync with tempfile
      my $line = <$TMP>;
      croak "splices : no such line : $pos ($.)" unless defined $line;
      my $fh = $self->{FH};
      print $fh $line;
    }

    while ($del--) {  # skip lines to delete from tempfile
      my $line = <$TMP>;
      croak "splices : no line to delete at pos $pos" unless defined $line;
    }

    $lines = [$lines] if ref $lines eq 'HASH'; # single line
    $self->_printRow(@{$_}{$self->headers}) for @$lines;
  }
  copyData($TMP, $self->{FH}) if $TMP; # copy back all remaining data
  truncate $self->{FH}, tell $self->{FH};
  $self->_journal('ENDSPLICES');
  return $i / 3;
}



=item C<< append(row1, row2, ...) >>

This appends new records at the end of data, i.e. it is
a shorthand for 

  splices(-1 => 0, [row1, row2, ...])

=cut


sub append {
  my $self = shift;
  my $args = ref $_[0] eq 'ARRAY' ? $_[0] : \@_;
  $self->splices([-1 => 0, $args]);
}


=item C<< clear >>

removes all data (but keeps the header line)

=cut

sub clear {
  my $self = shift;
  $self->rewind;
  $self->_journal('CLEAR');
  truncate $self->{FH}, $self->{dataStart};
}



=item C<< writeKeys({key1 => row1, key2 => ...}, @keyFields) >>

Rewrites the whole file, applying modifications as specified
in the hash ref passed as first argument. Keys in this hash 
are compared to keys built from the original data, 
according to C<@keyFields>. Therefore, C<row1> may replace
an existing row, if the key corresponding to C<key1> was found ;
otherwise, a new row is added. If C<row1> is C<undef>, the
corresponding row is deleted from the file.

C<@keyFields> must contain the name of one or several
fields that build up the primary key. For each data record, the 
values corresponding to those fields are taken and 
joined together through L<$;|perlvar/$;>, and then compared to
C<key1>, C<key2>, etc.

If you intend to fetch rows again after a B<writeKeys>, you
must L<rewind> the file first.

=cut

sub writeKeys {
  my $self = shift;
  my $lstModifs = shift;
  my %modifs = %$lstModifs;

  croak 'writeKeys : missing @keyFields'  if not @_;

  # clone object associated with a temp file
  my $clone = bless {%$self}; 
  $clone->{journal} = undef;
  $clone->{FH} = undef;  
  $clone->{FH} = new File::Temp or croak "no tempfile: $^E";
  binmode($clone->{FH}, ":crlf");

  seek $self->{FH}, 0, 0; # rewind to start of FILE (not start of DATA)
  copyData($self->{FH}, $clone->{FH});
  $self->rewind;
  $clone->rewind;

  $self->_journal('KEY', $_, $modifs{$_}) foreach keys %modifs;
  $self->_journal('ENDKEYS', @_);

  while (my $row = $clone->fetchrow) {
    my $k = join($; , @{$row}{@_});
    my $data = exists $modifs{$k} ? $modifs{$k} : $row;
    $self->_printRow(@{$data}{$self->headers}) if $data;
    delete $modifs{$k};
    #TODO : optimization, exit loop and copyData if no more items in %modifs
  }

  # add remaining values (new keys)
  $self->_printRow(@{$_}{$self->headers}) foreach grep {$_} values %modifs;  

  truncate $self->{FH}, tell $self->{FH};
}


sub _journal { # ($op, @args, \details)
               # Internal function for recording an update operation in a journal.
               # The journal can then be replayed through method L</playJournal>.
  my $self = shift;
  return if not $self->{journal}; # return if no active journaling 

  my @t = localtime;
  $t[5] += 1900;
  $t[4] += 1;
  my $t = sprintf "%04d-%02d-%02d %02d:%02d:%02d", @t[5,4,3,2,1,0];

  my @args = @_;
  my $rows = [];
  for (ref $args[-1]) { # last arg is an array of rows or a single row or none
    /ARRAY/ and do {($rows, $args[-1]) = ($args[-1], scalar(@{$args[-1]}))};
    /HASH/  and do {($rows, $args[-1]) = ([$args[-1]], 1)};
  }

  $self->{journal}->_printRow($t, 'ROW', @{$_}{$self->headers}) foreach @$rows;
  $self->{journal}->_printRow($t, @args);
}


=item C<< playJournal(open1, open2, ...) >>

Reads a sequence of update instructions from a journal file
and applies them to the current tabular file.
Arguments C<open1, open2, ...> will be passed to L<perl open|perlfunc/open>
for opening the journal file ; in most cases, just give the filename.

The journal file must contain a sequence of instructions
as encoded by the automatic journaling function of this module ;
to activate journaling, see the C<journal> parameter of the
L</new> method.

=cut


sub playJournal {
  my $self = shift;
  croak "cannot playJournal while journaling is on!" if $self->{journal};
  my $J;
  _open($J, @_) or croak "open @_: $^E";

  my @rows = ();
  my @splices = ();
  my @writeKeys = ();

  local $/ = $self->{recordSep};

  while (my $line = <$J>) {
    chomp $line;

    $line =~ s/$self->{recordSepRepl}/$self->{recordSep}/g;
    my ($t, $ins, @vals) = split $self->{rxFieldSep}, $line, -1;
    s/$self->{fieldSepRepl}/$self->{fieldSep}/g foreach @vals;

    for ($ins) {
      /^CLEAR/   and do {$self->clear; next };
      /^ROW/     and do {push @rows, $self->{ht}->new(@vals); next};
      /^SPLICE/  and do {my $nRows = pop @vals;
			carp "invalid number of data rows in journal at $line"
			  if ($nRows||0) != @rows;
		        push @splices, @vals, $nRows ? [@rows] : undef;
		        @rows = ();
		        next };
      /^ENDSPLICES/ and do {$self->splices(@splices); 
			    @splices = (); 
			    next};
      /^KEY/     and do {my $nRows = pop @vals;
			 carp "invalid number of data rows in journal at $line"
			  if ($nRows||0) > 1;
			 push @writeKeys, $vals[0], $nRows ? $rows[0] : undef;
			 @rows = ();
			 next };
      /^ENDKEYS/ and do {$self->writeKeys({@writeKeys}, @vals); 
			 @writeKeys = (); 
			 next};
    }
  }
}



=item C<< compileFilter(query [, implicitPlus]) >>

Compiles a query into a filter (code reference) that can be passed to
L</fetchrow> or L</fetchall>.

The query can be 

=over

=item *

a regular expression compiled through C<< qr/.../ >>. The regex will be applied
to whole data lines, and therefore covers all fields at once.
This is the fastest way to filter lines, because it avoids systematic
splitting into data records. 

=item *

a data structure resulting from a previous call to 
C<Search::QueryParser::parse>

=item *

a string of shape C<< K_E_Y : value >> (without any spaces before
or after ':'). This will be compiled into
a regex matching C<value> in the first column.
The special spelling is meant to avoid collision with a real field 
hypothetically named 'KEY'.

=item *

a string that will be analyzed through C<Search::QueryParser>, and
then compiled into a filter function. The query string can contain
boolean combinators, parenthesis, comparison operators,  etc., as 
documented in L<Search::QueryParser>. The optional second argument
I<implicitPlus> is passed to C<Search::QueryParser::parse> ;
if true, an implicit '+' is added in front of every
query item (therefore the whole query is a big AND).

Notice that in addition to usual comparison operators, 
you can also use regular expressions
in queries like

  +field1=~'^[abc]+' +field2!~'foobar$'

The query compiler needs to distinguish between word and non-word
characters ; therefore it is important to C<use locale> in your
scripts (see L<perllocale>). The compiler tries to be clever about a
number of details :

=over

=item looking for complete words 

Words in queries become regular expressions enclosed by C<\b> (word
boundaries) ; so a query for C<foo OR bar> will not match C<foobar>.

=item supports * for word completion

A '*' in a word is compiled into regular expression C<\w*> ;
so queries C<foo*> or C<*bar> will both match C<foobar>.

=item case insensitive, accent-insensitive

Iso-latin-1 accented characters are translated into character
classes, so for example C<hétaïre> becomes C<qr/h[ée]ta[ïi]re/i>.
Furthermore, as shown in this example, the C<i> flag is turned
on (case-insensitive). Therefore this query will also match
C<HETAIRE>.

=item numbers and dates in operators

When compiling a subquery like C<< fieldname >= 'value' >>, the compiler
checks the value against C<rxNum> and C<rxDate> (as specified in the
L</new> method). Depending on these tests, the subquery is translated
into a string comparison, a numerical comparison, or a date
comparison (more precisely, C<< {date2str($a) cmp date2str($b)} >>).


=item set of integers

Operator C<#> means comparison with a set of integers; internally
this is implemented with a bit vector. So query
C<Id#2,3,5,7,11,13,17> will return records where
field C<Id> contains one of the listed integers. 
The field name may be omitted if it is the first
field (usually the key field).

=item pre/postMatch

Words matched by a query can be highlighted; see
parameters C<preMatch> and C<postMatch> in the L</new> method.

=back

=back

=cut


sub compileFilter {
  my $self = shift;
  my $query = shift;
  my $implicitPlus = shift;

  return $self->_cplRegex($query) if ref $query eq 'Regexp';

  unless (ref $query eq 'HASH') { # if HASH, query was already parsed
    $query = Search::QueryParser->new->parse($query, $implicitPlus);
  }

  my $code = $self->_cplQ($query);
  eval 'sub {no warnings "numeric"; (' .$code. ') ? $_[0] : undef;}' 
    or croak $@;
}


sub _cplRegex {
  my $self = shift;
  my $regex = shift;
  return eval {sub {$_[0]->{line} =~ $regex}};
}


sub _cplQ {
  my $self = shift;
  my $q = shift;

  my $mandatory = join(" and ", map {$self->_cplSubQ($_)} @{$q->{'+'}});
  my $exclude   = join(" or ",  map {$self->_cplSubQ($_)} @{$q->{'-'}});
  my $optional  = join(" or ",  map {$self->_cplSubQ($_)} @{$q->{''}});

  croak "missing positive criteria in query" if not ($mandatory || $optional);
  my $r = "(" . ($mandatory || $optional) . ")";
  $r .= " and not ($exclude)" if $exclude;
  return $r;
}


sub _cplSubQ {
  my $self = shift;
  my $subQ = shift;

  for ($subQ->{op}) {

    # Either a list of  subqueries...
    /^\(\)$/ 
      and do {# assert(ref $subQ->{value} eq 'HASH' and not $subQ->{field}) 
	      #   if DEBUG;
	      return $self->_cplQ($subQ->{value}); };

    # ...or a comparison operator with a word or list of words. 
    # In that case we need to do some preparation for the source of comparison.

    # assert(not ref $subQ->{value} or ref $subQ->{value} eq 'ARRAY') if DEBUG;

    # Data to compare : either ...
    my $src = qq{\$_[0]->{line}}; # ... by default, the whole line ;
    if ($subQ->{field}) {         # ... or an individual field.
      if ($subQ->{field} eq 'K_E_Y') { # Special pseudo field (in first position) :
	$subQ->{op} = '~';	       # cheat, replace ':' by a regex operation.
	$subQ->{value} = "^$subQ->{value}(?:\\Q$self->{fieldSep}\\E|\$)";
      }
      else {
	my $fieldNum = $self->ht->{$subQ->{field}} or
	  croak "invalid field name $subQ->{field} in request";
	$src = qq{_getField(\$_[0], $fieldNum)};
      }
    }

    /^:$/
      and do {my $s = $subQ->{value};

	      my $noHighlights =            # no result highlighting if ...
		$s eq '*'                   # .. request matches anything
	        || ! ($self->{preMatch} || $self->{postMatch}) 
		                            # .. or no highlight was requested
		|| $subQ->{field};          # .. or request is on specific field

	      $s =~ s[\*][\\w*]g;             # replace star by \w* regex
	      $s =~ s{[\[\]\(\)+?]}{\Q$&\E}g; # escape other regex chars
	      $s =~ s[\s+][\\s+]g;            # replace spaces by \s+ regex


	      $s =~ s/ç/[çc]/g;
	      $s =~ s/([áàâä])/[a$1]/ig;
	      $s =~ s/([éèêë])/[e$1]/ig;
	      $s =~ s/([íìîï])/[i$1]/ig;
	      $s =~ s/([óòôö])/[o$1]/ig;
	      $s =~ s/([úùûü])/[u$1]/ig;
	      $s =~ s/([ýÿ])/[y$1]/ig;

	      my $wdIni = ($s =~ /^\w/) ? '\b' : '';
	      my $wdEnd = ($s =~ /\w$/) ? '\b' : '';
	      my $lineIni = "";
	      $lineIni = "(?<!^)" if $self->{avoidMatchKey} and not $subQ->{field};
	      $s = "$lineIni$wdIni$s$wdEnd";

	      return $noHighlights ? "($src =~ m[$s]i)" :
		"($src =~ s[$s][$self->{preMatch}\$&$self->{postMatch}]ig)";
	      };



    /^#$/   # compare source with a list of numbers
      and do {
        my $has_state = eval "use feature 'state'; 1"; # true from Perl 5.10
        my $decl = $has_state ? "use feature 'state'; state \$numvec" 
                              : "my \$numvec if 0"; # undocumented hack

        # build a block that at first call creates a bit vector; then at 
        # each call, the data source is compared with the bit vector
        return qq{
          do {
            $decl;
            no warnings qw/uninitialized numeric/;
            \$numvec or do {
              my \$nums = q{$subQ->{value}};
              vec(\$numvec, \$_, 1) = 1 for (\$nums =~ /\\d+/g);
            };
            vec(\$numvec, int($src), 1);
          }
        };
      };


    # for all other ops, $subQ->{value} must be a scalar
    # assert(not ref $subQ->{value}) if DEBUG; 

    (/^(!)~$/ or /^()=?~$/)  and return "$1($src =~ m[$subQ->{value}])";

    # choose proper comparison according to datatype of $subQ->{value}
    my $cmp = ($subQ->{value} =~ $self->{rxDate}) ? 
                  "(\$self->{date2str}($src) cmp q{" . 
		    $self->{date2str}($subQ->{value}) . "})" :
	      ($subQ->{value} =~ $self->{rxNum})  ? 
		  "($src <=> $subQ->{value})" :
               # otherwise
                  "($src cmp q{$subQ->{value}})";

    /^=?=$/       and return "$cmp == 0";
    /^(?:!=|<>)$/ and return "$cmp != 0";
    /^>$/         and return "$cmp > 0";
    /^>=$/        and return "$cmp >= 0";
    /^<$/         and return "$cmp < 0";
    /^<=$/        and return "$cmp <= 0";
    croak "unexpected op $_ ($subQ->{field} / $subQ->{value})";
  }
}

############################################################
# utility functions
############################################################

sub urlEncode {
  my $s = shift;
  return join "", map {sprintf "%%%02X", ord($_)} split //, $s;
}

sub copyData { # copy from one filehandle to another
  my ($f1, $f2) = @_;
  my $buf;
  while (read $f1, $buf, BUFSIZE) {print $f2 $buf;}
}

=back

=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat ge chE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
