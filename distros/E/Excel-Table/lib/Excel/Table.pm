package Excel::Table;

=head1 NAME

Excel::Table - Table processing class for Excel worksheets. 

=head1 SYNOPSIS

  use Excel::Table;

  my $xs = Excel::Table->new('dir' => '/cygdrive/c/Users/self/Desktop');

  for ($xs->list_workbooks) {
  	print "workbook [$_]\n";
  }

  $xs->open('mybook.xls');

  my $wb1 = $xs->open_re('foo*bar*');

  for my $worksheet ($wb1->worksheets) {
  	print "worksheet: " . $worksheet->get_name() . "\n";
  }

  $xs->null("this is a null value");
  $xs->force_null(1);	

  $xs->rowid(0);

  $xs->trim(0);

  my @data = $xs->extract('Sheet1');

  for (@data) {
  	printf "rowid [%s] title [%s] max_width [%d] value [%s]\n",
  		$_->[0],
  		$xs->titles->[0],
  		$xs->widths->[0],
  		$data{$_}->[0];
  }

  @data = $xs->extract_hash('Sheet1');

  @data = $xs->select("column1,column2,column3", 'Sheet1');

  @data = $xs->select_hash("column1,column2,column3", 'Sheet1');

  printf "columns %d rows %d title_row %d\n",
  	$xs->columns, $xs->rows, $xs->title_row;

  printf "regexp [%s] pathname [%s] sheet_name [%s]\n",
  	$xs->regexp, $xs->pathname, $xs->sheet_name;

  printf "colid2title(0) = [%s]\n", $xs->colid2title(0);

  printf "title2colid('Foo') = %d\n", $xs->title2colid('Foo');

=head1 DESCRIPTION

"Excel::Table" retrieves worksheets as if they are structured
tables in array-format or optionally in hash-format.

=over 4

=item 1a.  OBJ->dir(EXPR)

Override the directory location in which to look for workbooks.
Defaults to "." (i.e. the current working directory).
This location is critical to the B<list_workbooks>, B<open>,
and B<open_re> methods.

=item 1b.  OBJ->list_workbooks

Returns an array of workbook files in the directory defined by the
B<dir> property.

=item 2a.  OBJ->open(EXPR)

Parses the filename specified by EXPR.  The B<dir> property 
will designate the search path.
Once opened, via this method (or B<open_re>) the
workbook is available for use by the B<extract> method.

=item 2b.  OBJ->open_re(EXPR)

This will search for a file which has a filename matching the regexp EXPR.  
A warning will be issued if multiple matches are found, only the first will
be opened.

=item 3.  OBJ->regexp

Returns the regexp used to search for the workbook on the filesystem.

=item 4.  OBJ->pathname

Returns the pathname of the opened workbook.

=item 5a.  OBJ->extract(EXPR,[TITLE_ROW])

This will extract all data from the worksheet named EXPR.  Data is extracted
into an array and returned.  Format of data is per below:

  [ value1, value2, value3, ... ],
  [ value1, value2, value3, ... ],
  [ value1, value2, value3, ... ],
  ...

The object OBJ will be populated with various properties to assist you to
access the data in the array, including column titles and widths.

A worksheet object is temporarily created in order to populate the array.
Once a worksheet is extracted, the associated worksheet object is destroyed.
This routine can be called again on any worksheet in the workbook.

If the TITLE_ROW argument is specified, then the B<title_row> property will 
also be updated prior to extraction.

=item 5b.  OBJ->extract_hash(EXPR,[TITLE_ROW])

Per the B<extract> method, but returns an array of hashes, with the hash 
keys corresponding to the titles.

=item 5c.  OBJ->select(CLAUSE,EXPR,[TITLE_ROW])

Similar to the B<extract> method, this will extract all rows from the worksheet EXPR, constraining the columns to those specified by the B<clause> argument,
which is a comma-separated string, e.g. "column1,column2,column3".

As with the B<extract> method, the B<titles> and B<widths> properties will
be revised.

=item 5d.  OBJ->select_hash(CLAUSE,EXPR,[TITLE_ROW])

Per the B<select> method, but returns an array of hashes.

=item 6.  OBJ->columns or OBJ->rows

Returns the number of columns or rows available in the sheet extracted via the
B<extract> method.

=item 7a.  OBJ->force_null

Flag which determines if whitespace fields should be
replaced by specific text (see OBJ->null).

=item 7b.  OBJ->null

String to replace whitespace fields with.  Defaults to "(null)".

=item 8.  OBJ->rowid

Flag which determines whether a pseudo-column "rowid" is included in each
tuple.  The value will take the form "999999999"  Defaults to FALSE.  

=item 9.  OBJ->sheet_name

Returns the sheet_name against which data was extracted via B<extract>.

=item 10.  OBJ->trim

Flag which determines if trailing whitespace fields should be trimmed.

=item 11a.  OBJ->title_row

Returns the title row of the worksheet (defaults to zero), following extract.

=item 11b.  OBJ->titles

Returns an array of title fields, the title row number having been defined
as OBJ->title_row.

=item 11c.  OBJ->colid2title(colid)

Converts the column number (colid) to a string column title (i.e. 
the offset within the title_row array).
If no match, then returns undef.

=item 11d.  OBJ->title2colid(REGEXP)

Returns the column number of the title identified by REGEXP.
If no match, then returns undef.

=item 12.  OBJ->widths

Returns an array of maximum lengths of any (non-title) data in each column.

=back

=cut

use strict;
use warnings;

use Data::Dumper;
use Spreadsheet::ParseExcel 0.57;
use Spreadsheet::XLSX;
use File::Basename;

use Carp qw(cluck confess);     # only use stack backtrace within class
use Log::Log4perl qw/ get_logger /;

use vars qw/ @EXPORT $VERSION /;

$VERSION = "1.022";	# update this on new release

#@ISA = qw(Exporter);
#@EXPORT = qw();

# package constants
use constant S_RID => "rowid";
use constant S_NULL => "(null)";
use constant EXT_EXCEL => qw/
	\.xls \.xla \.xlb \.xlc \.xld \.xlk \.xll \.xlm \.xlt
	\.xlv \.xlw \.xls \.xlt
/;	# known extensions for EXCEL file

#	need the Spreadsheet::XLSX module for the following:
use constant EXT_EXCEL_2007 => qw/
	\.xlsx \.xlsm \.xlsb \.xltm \.xlam 
/;	# known extensions for EXCEL 2007 file


# package globals

our $AUTOLOAD;


# package locals
my $n_Objects = 0;	# counter of objects created.

my %attribute = (
	_n_objects => \$n_Objects,
	_xl_vers => undef,
	columns => undef,
	dir => ".",
	_log => get_logger("Excel::Table"),
	null => S_NULL,
	pathname => undef,
	regexp => undef,
	force_null => 0,
	rows => undef,
	rowid => 0,
	sheet_name => undef,
	title_row => 0,		# if title row is zero, first data row is 1
	titles => undef,
	trim => 0,
	widths => undef,
	workbook => undef,
);


#INIT { };


sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or croak("self is not an object");

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully−qualified portion

	unless (exists $self->{_permitted}->{$name} ) {
		confess "no attribute [$name] in class [$type]";
	}

	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}
}


sub new {
	my ($class) = shift;
	#my $self = $class->SUPER::new(@_);
	my $self = { _permitted => \%attribute, %attribute };

	++ ${ $self->{_n_objects} };

	bless ($self, $class);

        my %args = @_;  # start processing any parameters passed
	my ($method,$value);    # start processing any parameters passed
	while (($method, $value) = each %args) {

		confess "SYNTAX new(method => value, ...) value not specified"
			unless (defined $value);

		$self->_log->debug("method [self->$method($value)]");

		$self->$method($value);
	}
	
	return $self;
}


sub _determine_xl_vers {
	my ($self,$pn)=@_;
	$self->_log->logcroak("SYNTAX: _determine_xl_vers(path)")
		unless defined ($pn);
#	return version string or undef for given pathname
	my $extension;
	my @extensions;
	my $retval = undef;

	$self->_log->debug("pn [$pn]");

	@extensions = EXT_EXCEL;
	(undef,undef,$extension) = fileparse($pn,@extensions);
	#$self->_log->debug(sprintf "  extension [%s] \@extensions [%s]", $extension, Dumper(\@extensions));

	$retval = 'xl2003' if ($extension ne "");

	@extensions = EXT_EXCEL_2007;
	(undef,undef,$extension) = fileparse($pn,@extensions);

	$retval = 'xl2007' if ($extension ne "");

	if (defined $retval) {
		$self->_log->debug("pn [$pn] returning [$retval]");
	}

	return $retval;
}


sub list_workbooks {
	my $self = shift;

	my $dn = $self->dir;
	my ($dh,$fn);
	my @workbooks;

	$self->_log->debug("dn [$dn]");

	opendir($dh, $dn) || $self->_log->logcroak("opendir($dn)");

	while ($fn = readdir($dh)) {
		my $pn = File::Spec->catfile($dn, $fn);

		# need to remember just the filename here, not the path because
		# open will use the self->dir property to make the path
		push @workbooks, $fn
			if (defined($self->_determine_xl_vers($pn)));
	}

	closedir $dh;

	$self->_log->debug(sprintf '@workbooks [%s]', Dumper(\@workbooks));

	return @workbooks;
}


sub open {
	my ($self,$fn)=@_;
	$self->_log->logcroak("SYNTAX: open(file)") unless defined ($fn);
	my $pn = File::Spec->catfile($self->dir, $fn);

	# to look for the file in the cwd, is not good behaviour,
	# so dir must be explicit, thus the default to "."

	if (-f $pn) {
		$self->pathname($pn);
	} else {
		$self->_log->logcroak("no such path [$pn]");
	}

	$self->_log->debug("parsing [$pn]");

	$self->{'_xl_vers'} = $self->_determine_xl_vers($pn);

	my $parser;

	if ($self->_xl_vers eq 'xl2007') {
		$parser = Spreadsheet::XLSX->new($pn);

		$self->_log->logcroak("Spreadsheet::XLSX->new($pn) failed")
			unless defined $parser;

		$self->workbook($parser);
	} else {
		$parser = Spreadsheet::ParseExcel->new();
		$self->workbook($parser->Parse($pn));

		$self->_log->logcroak("Parse() failed, error: " . $self->workbook->error())
			unless defined $self->workbook;
	}


	return $self->workbook;
}


sub open_re {
	my $self = shift;
	if (@_) { $self->regexp(shift); } else { $self->_log->logcroak("SYNTAX: open_re(regexp)"); }
	my $re = $self->regexp;
	my $matches = 0;
	my $wb = undef;

	$self->_log->debug(sprintf "regexp [%s]", $self->regexp);
	for ( $self->list_workbooks ) {
		$self->_log->debug("  file [$_]");
		if ($_ =~ /$re/) {
			$self->_log->debug("    FOUND [$_]");
			$wb = $_ unless ($matches++);	# remember first occurence
		}
	}

	unless (defined $wb) {
		$self->_log->logcarp("could not find file matching [$re]");
		return undef;
	}

	$self->_log->logwarn("non-unique match on [$re]")
		if ($matches > 1);

	return $self->open($wb);
}


sub _prepend_rowid {
	my ($self, $ra_columns, $id)=@_;

	my $rowid = ($id == $self->title_row) ? S_RID : sprintf "%09d", $id;

	push @$ra_columns, $rowid;

	return $rowid;
}


sub extract {
	my $self = shift;
	if (@_) { $self->sheet_name(shift); }
	if (@_) { $self->title_row(shift); }

	$self->_log->logcroak("SYNTAX: extract(sheet_name,title_row)")
		unless (defined $self->sheet_name && defined $self->title_row);

	$self->_log->debug(sprintf "opening [%s]", $self->sheet_name);

	my $ws = $self->workbook->worksheet($self->sheet_name);

	my ($minr, $maxr) = $ws->row_range();
	my ($minc, $maxc) = $ws->col_range();

	$self->rows($maxr);
	$self->columns($maxc + 1);

	$self->title_row($minr)		# fix minimum row
		if ($self->title_row < $minr);

	$self->_log->debug(sprintf "sheet_name [%s] minr [%d] maxr [%d] minc [%d] maxc [%d]",
		$self->sheet_name, $minr, $maxr, $minc, $maxc);

	my ($subr,$subc,$value);
	my @data;
	my (@columns,@widths);

	for ($subr = $self->title_row; $subr <= $maxr; $subr++) {

		$self->_prepend_rowid(\@columns, $subr)
			if ($self->rowid);

		for ($subc = $minc; $subc <= $maxc; $subc++) {

			my $cell = $ws->get_cell($subr, $subc);

			if (defined $cell) {
				$value = ($self->trim) ? $self->_trim_whitespace($cell->value) : $cell->value;
			} else {
				$value = undef;
			}

			$value = $self->_resolve_null($value, $self->null)
				if ($self->force_null);

			push @columns, $value;
		}

		# adjust widths, including rowid column
		$subc = 0;
		for $value (@columns) {

			# calculate width, ignoring title_row

			if ($subr == $self->title_row) {
				$widths[$subc] = 0;
			} else {
				$widths[$subc] = length($value)
					if (defined($value) &&
					length($value) > $widths[$subc]);
			}

			$subc++;
		}

		$self->_log->debug(sprintf '@columns [%s]', Dumper(\@columns));
		$self->_log->debug(sprintf '@widths [%s]', Dumper(\@widths));
		
		if ($subr == $self->title_row) {
			$self->titles([ @columns ]);
		} else {
			push @data, [ @columns ];
		}
		@columns = ();
	}
	$self->widths([ @widths ]);

	@widths = $ws = ();

	return @data;
}


sub colid2title {
	my ($self,$colid)=@_;

	$self->_log->logcroak("SYNTAX: colid2title2(colid)")
		unless (defined $colid);

	$self->_log->debug("colid [$colid]");

	return undef
		if ($colid < 0);

	return undef
		unless ($colid < scalar @{ $self->titles });

	return $self->titles->[$colid];
}


sub title2colid {
	my ($self,$title)=@_;

	$self->_log->logcroak("SYNTAX: title2colid(title)")
		unless (defined $title);

	$self->_log->debug("title [$title] ");

	my $tmax = scalar @{ $self->titles };

	for (my $tsub = 0; $tsub < $tmax; $tsub++) {
		if ($self->titles->[$tsub] =~ /$title/) {
			$self->_log->debug("match at colid $tsub");
			return $tsub;
		}
	}
	$self->_log->debug("NO MATCH");

	return undef;
}


sub _trim_whitespace {
	my ($self,$s_value)=@_;

	if (defined $s_value) {
		$self->_log->debug("s_value [$s_value]");

		$s_value =~ s/^[[:cntrl:][:space:]]+//;	# trim leading
		$s_value =~ s/[[:cntrl:][:space:]]+$//;	# trim trailing

		$self->_log->debug("after s_value [$s_value]");
	}

	return $s_value;
}


sub _resolve_null {
	my ($self, $s_value, $s_null)=@_;

	$self->_log->debug(sprintf "s_value [%s] s_null [%s]",
		(defined $s_value) ? $s_value : "not defined",
		(defined $s_null) ? $s_null : "not defined",
		);

	if (defined $s_value) {
		$s_value = $s_null
			if ($s_value eq "");
	} else {
		$s_value = $s_null;
	}

	return $s_value;
}


sub _array_to_hash {
	my $self = shift;
	my @data;

	for my $row (@_) {
		$self->_log->debug(sprintf '$row [%s]', Dumper($row));

		my %data;
		my $unique = 0;
		my $m_value = scalar(@$row);

		for (my $ss_value = 0; $ss_value < $m_value; $ss_value++) {

			my $column = $self->titles->[$ss_value];
			my $value = $row->[$ss_value];

			my $key = (exists $data{$column}) ? $column . $unique++ : $column;
			$data{$key} = $value;
		}

		$self->_log->debug(sprintf 'data [%s]', Dumper(\%data));

		push @data, { %data };

		%data = ();
	}

	return @data;
}


sub extract_hash {
	my $self = shift;

	$self->_log->logcroak("SYNTAX: extract_hash(sheet_name,[title_row])")
		unless (@_ > 0);

	return $self->_array_to_hash($self->extract(@_));
}


sub select_hash {
	my $self = shift;
	my $clause = shift;

	$self->_log->logcroak("SYNTAX: select_hash(clause,[sheet_name,title_row])")
		unless (@_ > 0);

	return $self->_array_to_hash($self->select($clause, @_));
}


sub select {
	my $self = shift;
	my $clause = shift;

	$self->_log->logcroak("SYNTAX: select(clause,[sheet_name,title_row])")
		unless (defined $clause);

	my @pre = $self->extract(@_);
	my (@post, @id);
	my (@columns, @widths);

	$clause = join(',', S_RID, $clause)
		if ($self->rowid);

	for my $column (split(/,/, $clause)) {
		$self->_log->debug("column [$column]");

		my $id = $self->title2colid($column);

		if (defined $id) {
			push @id, $id;
			push @columns, $column;
			push @widths, $self->widths->[$id];
		} else {
			$self->_log->logwarn("invalid column [$column]");
		}
	}

	$self->_log->debug(sprintf '@id [%s]', Dumper(\@id));

	my $f_no_columns = ($self->rowid) ? 1 : 0;

	unless (scalar(@columns) == $f_no_columns) { # no columns, thus no rows
		for my $row (@pre) {
			$self->_log->debug(sprintf 'row [%s]', Dumper($row));

			my @wanted = ();

			for my $id (@id) {
				push @wanted, $row->[$id];
			}

			$self->_log->debug(sprintf '@wanted [%s]', Dumper(\@wanted));

			push @post, [ @wanted ]
				if (scalar(@wanted));	# account for null case
		}
	}

	$self->_log->debug(sprintf '@columns [%s]', Dumper(\@columns));
	$self->_log->debug(sprintf '@widths [%s]', Dumper(\@widths));

	$self->titles([ @columns ]);
	$self->widths([ @widths ]);

	return @post;
}


DESTROY {
	my $self = shift;
	-- ${ $self->{_n_objects} };
};

#END { }

1;

__END__

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2012  Tom McMeekin E<lt>tmcmeeki@cpan.orgE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License,
or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

L<perl>, L<Spreadsheet::ParseExcel>, L<Spreadsheet::XLSX>.

=cut

