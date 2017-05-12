package HTML::Dashboard;

use 5.008008;
use strict;
use warnings;

use Carp;

our $VERSION = '0.03';

# ============================================================

# Test:
# - escape of \t and \n in as_text
# - DB access stuff (incl DB errors)

# ------------------------------------------------------------

my ( $HI, $MED, $LOW ) = ( 300, 200, 100 );

sub new {
  my $arg = shift;
  my $class = $arg; # Always create through class name, not instance

  # Check _init_data_defaults below for meaning of individual variables...
  my $self = bless { data     => [],
		     first    => undef,
		     last     => undef,
		     records  => undef,
		     pagesize => undef,
		     captions => [],
		     view     => [],
		     sortrank => [],
		     comparator => undef,
		     format   => {} }, $class;

  # If triggers are set, these will be stored in the following instance
  # variables as multi-hash, keyed on column (==0 for row triggers) and
  # priority. The value is an array-ref, containing the trigger sub and
  # a key, which can be used to find the corresponding formatting options
  # in $self->{opts}.
  # Fired_col_triggers is set by _find_triggered_columns - since the 
  # format of the ENTIRE col may depend on the entry of a single cell
  # in this col, col triggers must be evaluated ahead of time, and can
  # not be applied row by row, as is possible for cell and row triggers.
  # If a col trigger fired, its key will be stored in fired_col_triggers.
  $self->{ ROW_TRIGGERS }  = undef;
  $self->{ COL_TRIGGERS }  = undef;
  $self->{ CELL_TRIGGERS } = undef;
  $self->{ fired_col_triggers } = undef;

  # For each HTML tag (or Pseudo-tag, such as first_row), there is a hash,
  # containing HTML/CSS formatting arguments. A hash is used, so that
  # formatting commands from different (pseudo-)tags can be blended easily.
  # For instance, if a command for <tr...> has been set, as well as for
  # even_row, we want to blend both of them together for even rows. Hashes
  # can do this conveniently, using the following idiom:
  #     %tr = ( %tr, %{ $self->{opts}{even_row} } )
  #
  # The value of each $self->{opts}{...} is a hash-ref. Permissible keys
  # into this hash-ref are "html" (or "color"), "class", and "style", eg
  #     $self->{opts}{table}{html} = "border='1'"
  # For key "html", the value must be a string which can be inserted
  #   directly into the corresponding HTML tag.
  # For key "color", the value must be a legal HTML color specification,
  #   ie. either in #rrggbb format or one of the recognized color names.
  # For key "class", the value must be the name of a CSS class.
  # For key "style", the value must be a string which can be given directly
  #   as value to a <... style="..."> argument of the corresponding HTML tag.
  #
  # The _glue() function is responsible for final formatting of these opts.
  $self->{opts}{ table } = {};
  $self->{opts}{ tr } = {};
  $self->{opts}{ th } = {};
  $self->{opts}{ td } = {};

  $self->{opts}{ first_row } = {};
  $self->{opts}{ odd_row   } = {};
  $self->{opts}{ even_row  } = {};
  $self->{opts}{ last_row  } = {};

  $self->{opts}{ first_col } = {};
  $self->{opts}{ odd_col   } = {};
  $self->{opts}{ even_col  } = {};
  $self->{opts}{ last_col  } = {};

  for my $i ( qw( ROW COL CELL ) ) {
    for my $j ( $HI, $MED, $LOW ) {
      $self->{opts}{ $i . "_TRIGGERS_" . $j } = {};
    }
  }

  # Defaults formats:
  $self->_set_options( 'odd_row', '#eeeeee' );
  $self->_set_options( 'table', 'border="1"' );

  return $self;
}

# For debugging purposes...
sub dump_opts {
  my $self = shift;

  my $out = '';

  $out .= "First:     " . $self->{first} . "\n";
  $out .= "Last:      " . $self->{last} . "\n";
  $out .= "Records:   " . $self->{records} . "\n";
  $out .= "Pagesize:  " . $self->{pagesize} . "\n";
  $out .= "Pagecount: " . $self->get_pagecount() . "\n";
  $out .= "\n";
  $out .= "Captions:  " . join( ' | ', @{ $self->{captions} } ) . "\n";
  $out .= "View:      " . join( ', ', @{ $self->{view} } ) . "\n";

  for my $field ( keys %{ $self->{opts} } ) {
    my @keys = keys %{ $self->{opts}{$field} };
    if( scalar @keys == 0 ) { next; }

    $out .= "\n=== $field ===\n";
    for my $key ( @keys ) {
      $out .= "       $key [ " . $self->{opts}{$field}{$key} . " ]\n";
    }
  }
  return $out;
}

# All of these instance variables can only be set once the data is known.
sub _init_data_defaults {
  my ( $self, $first ) = @_;

  # Index of first data record:
  $self->{first} = $first;

  # Index of last data record:
  $self->{last} = scalar( @{ $self->{data} } ) - 1;

  # Number of records in data set (not counting captions)
  $self->{records}  = 1 + $self->{last} - $self->{first};

  # Number of records in page - defaults to all
  unless( $self->{pagesize} ) {
    $self->{pagesize} = $self->{records};
  }

  # Column indices selected for view - defaults: all in natural order
  unless( @{ $self->{view} } ) {
    $self->{view} = [ 0..( scalar @{ $self->{data}[0] } - 1 ) ];
  }

  # Row indices in sort order - default: natural order
  $self->{sortrank} = [ $self->{first}..$self->{last} ];


  # Further variables referred to in the constructor are:
  # captions   : an array, containing strings to be used as col captions
  # comparator : a sub-ref, used for sorting (cf. set_sort() and _sort_rank() )
  # format     : a hash-ref, keyed on the column, which will receive the
  #              output of the formatter. The value is an array-ref, containing
  #              the formatter sub-ref, and an indicator whether the sub-ref
  #              is a formatter (single argument) or collater (row argument).
}

# -----

sub set_data_without_captions {
  my ( $self, $data ) = @_;
  unless( $data && ref( $data ) eq 'ARRAY' ) { carp "Not an array ref!" }

  $self->{data} = $data;

  $self->_init_data_defaults( 0 );
}

sub set_data_with_captions {
  my ( $self, $data ) = @_;
  unless( $data && ref( $data ) eq 'ARRAY' ) { carp "Not an array ref" }

  $self->{data} = $data;

  $self->set_captions( @{ $data->[0] } );

  $self->_init_data_defaults( 1 );
}

# -----

sub get_query { my $self = shift; return $self->{sql} }

sub set_query_without_captions {
  my ( $self, $dbh, $sql ) = @_;
  $self->{sql} = $sql;

  $self->{data} = $dbh->selectall_arrayref( $sql );

  $self->_init_data_defaults( 0 );
}

sub set_query_with_captions {
  my ( $self, $dbh, $sql ) = @_;
  $self->{sql} = $sql;

  $self->{data} = $dbh->selectall_arrayref( $sql );

  $self->set_captions( @{ $self->{data}[0] } );

  $self->_init_data_defaults( 1 );
}

# -----

# UNIMPLEMENTED!
#
# The idea is to provide a way to set an SQL query, without executing it.
# Later, the query can be executed (using exec_query), while supplying
# values for bind variables.

sub prepare_query_without_captions { }
sub prepare_query_with_captions { }
sub exec_query { } # Takes query parameters

# -----

sub set_sort {
  my ( $self, $sub ) = @_;
  $self->{comparator} = $sub;
}

sub _sort_rank {
  my $self = shift;

  unless( $self->{comparator} ) { return; }

  $self->{sortrank} =
    [ sort { $self->{comparator}( $self->{data}[$a], $self->{data}[$b] ) }
      @{ $self->{sortrank} } ];
}

# -----

# UNIMPLEMENTED!
#
# When there are subsequent rows, which have identical entries in some
# columns it can be neat to neat to suppress (leave blank) the repeated 
# entries. These functions would take the col indices of the cols to be
# monitored for repeating behaviour and suppress them during output.

sub set_skip_repeats { }
sub get_skip_repeats { }

# ------------------------------------------------------------

sub set_view { my ( $self, @cols ) = @_; $self->{view} = \@cols; }
sub get_view { my $self = shift; return $self->{view}; }

sub set_captions { my ( $self, @caps ) = @_; $self->{captions} = \@caps; }
sub get_captions { my $self = shift; return $self->{captions}; }

# Setting pagesize to undef, 0, or a negative value turns off pagination
sub set_pagesize {
  my ( $self, $arg ) = @_;

  if( defined $arg && $arg > 0 ) {
    $self->{pagesize} = $arg;
  } else {
    $self->{pagesize} = $self->{records};
  }
}

sub get_pagesize { my $self = shift; return $self->{pagesize}; }

sub get_pagecount {
  my $self = shift;

  if( !defined $self->{pagesize} ) { return 1; } # No pagination: 1 page

  my $full = int( $self->{records}/$self->{pagesize} ); # Count of full pages
  my $frac = $self->{records} % $self->{pagesize}; # Records on last partial pg

  return $full + ( $frac ? 1 : 0 );
}

# ------------------------------------------------------------

# Takes a hash-ref - the slice of $self->{opts} for the selected HTML element
# and glues them together into a string which can be directly embedded
# into an HTML tag.
# In doing so, it makes sure that 'color' options are properly embedded
# into the 'style' argument, etc.

sub _glue {
  my ( $self, $args ) = @_;

  my $out = exists $args->{html} ? $args->{html} . ' ' : '';
  $out .= exists $args->{class} ? 'class="' . $args->{class} .'" ' : '';

  if(       exists $args->{color} &&  exists $args->{style} ) {
    $out .= 'style="' . $args->{style} . '; ';
    $out .= 'background-color: ' . $args->{color} . '" ';

  } elsif( !exists $args->{color} && exists $args->{style} ) {
    $out .= 'style="' . $args->{style} . '" ';

  } elsif(  exists $args->{color} && !exists $args->{style} ) {
    $out .= 'style="background-color: ' . $args->{color} . ';" ';
  }

  return $out;
}

# For pagination: finds the index of the first row to display and the
# index of the first row NOT to display, in other words, use the following
# loop to display:   for( $i=$from; $i<$upto; $i++ )

sub _find_range_for_page {
  my ( $self, $page ) = @_;

  # Find the range of rows to plot:
  my ( $from, $upto ) = ( 0, $self->{records} );

  if( defined $page ) {
    if( $page < 0 || $page > $self->get_pagecount() ) {
      carp "Out of bounds page $page requested - returning all rows.";

    } elsif( defined $self->{pagesize} ) { # only do pagination if switched on
      $from = $page * $self->get_pagesize();
      $upto = $from + $self->get_pagesize();

      if( $upto > $self->{records} ) {
	$upto = $self->{records}; # Fractional last page
      }
    }
  }

  return ( $from, $upto );
}

sub _check_consistency {
  my $self = shift;

  my ( $warn, $fatal ) = ( '', '' );

  my $colcnt = 0;
  if( $self->{records} < 1 ) {
    $warn .= "Empty data set\n";
  } else {
    my @colcount = map { scalar @{ $_ } } @{ $self->{data} };
    $colcnt = $colcount[0];
    if( scalar ( grep { $_ != $colcnt } @colcount ) ) {
      $fatal .= "Data not rectangular. Column lengths: ";
      $fatal .= join( ',', @colcount ) . "\n";
    }
  }

  if( @{ $self->{captions} } && $colcnt &&
      scalar @{ $self->{captions} } != scalar @{ $self->{data}[0] } ) {
    $fatal .= "Number of captions not equal to number of columns\n";
  }

  if( scalar ( grep { $_ < 0 || $_ >= $colcnt } @{ $self->{view} } ) ) {
    $fatal .= "Illegal index in view\n";
  }

  if( $fatal )   { croak "$warn $fatal"; }
  elsif( $warn ) { carp  "$warn"; }
}

# ------------------------------------------------------------
# Output Routines
#
# Tables are built up outside in (table->row->cell->contents).
# For each element, all opts are collected and all rules and
# triggers are evaluated. This leads to a fully formed HTML tag.
# Then the subsequent element (ie after <tr> come all the <td>, etc)
# is evaluated in a similar fashion. 

# -----

# Convention (for the following routines):
# $row, $col   : the indices of the 'true' row or col in the full data set
# $prow, $vcol : the indices of the row in the current page or the column
#                    in the current view
# ------------------------------------------------------------

sub as_text {
  my ( $self, $page ) = @_;

  $self->_check_consistency();

  my ( $from, $upto ) = $self->_find_range_for_page( $page );

  $self->_sort_rank();

  my $body = '';
  if( @{ $self->{captions} } ) {
    # Array slice of @captions, indexed by @view...
    $body .= join( "\t", @{ $self->{captions} }[ @{ $self->{view} } ] ) . "\n";
  }

  my ( $prow, $vcol, $row, $col ) = ( 0, 0, 0, 0 );
  foreach my $idx ( $from..$upto-1 ) {
    $row = $self->{sortrank}[$idx];

    $vcol = 0;
    foreach my $col ( @{ $self->{view} } ) {
      my $token = $self->_content( $prow, $vcol, $row, $col );
      $token =~ s/([\t\n\\])/\\$1/g; # Escape newline, tab, and backslash
      $body .= "$token\t";
      $vcol += 1;
    }
    chop $body; # remove the last tab, then replace with newline
    $body .= "\n";

    $prow += 1;
  }
  # The last newline is NOT chopped - text ends with a newline.

  return $body;
}

sub as_HTML {
  my ( $self, $page ) = @_;

  $self->_check_consistency();

  my ( $from, $upto ) = $self->_find_range_for_page( $page );

  $self->_sort_rank();
  $self->_find_triggered_columns();


  # Find options - only simple options for table-tag:
  my %table = %{ $self->{opts}{table} };

  # Build the body of the table:
  my ( $prow, $body ) = ( 0, '' );
  foreach my $idx ( $from..$upto-1 ) {
    my $row = $self->{sortrank}[$idx];
    $body .= $self->_row( $prow++, $row );
  }

  # Build output:
  my $out = "\n\n";
  $out .= "<!-- Table generated by HTML::Dashboard - www.cpan.org -->\n";
  $out .= '<table ' . $self->_glue( \%table ) . ">\n";
  $out .= $self->_caption() . "\n";
  $out .= $body . "\n";
  $out .= "</table>\n\n";

  return $out;
}

# Returns a fully formed caption row: <tr><th>....</tr>
sub _caption {
  my ( $self ) = @_;

  unless( @{ $self->{captions} } ) { return ''; }

  my %tr = %{ $self->{opts}{tr} };
  my %th = %{ $self->{opts}{th} };
  my $th = '<th ' . $self->_glue( \%th ) . '>';

  my $out = '<tr ' . $self->_glue( \%tr ) . '>';
  foreach my $col ( @{ $self->{view} } ) {
    $out .= $th . $self->{captions}[$col] . '</th>';
  }
  $out .= '</tr>';
  return $out . "\n";
}

sub _row {
  my ( $self, $prow, $row ) = @_;

  # Build options:
  my %tr = %{ $self->{opts}{tr} };

  # Odd/Even Row
  if( $prow %2 == 0 ) { %tr = ( %tr, %{ $self->{opts}{even_row} } ); }
  else                { %tr = ( %tr, %{ $self->{opts}{odd_row} } ); }

  # First/Last Row
  if( $prow == 0 ) {
    %tr = ( %tr, %{ $self->{opts}{first_row} } ); # First row
  } elsif( $prow == $self->{pagesize} - 1 ) {
    %tr = ( %tr, %{ $self->{opts}{last_row} } );  # Last row
  }

  # Triggers: Hi->Med->Low
  if( exists $self->{ROW_TRIGGERS} ) {
    for my $prio ( sort { $b <=> $a } keys %{ $self->{ROW_TRIGGERS}{0} } ) {
      my ( $trig, $key ) = @{ $self->{ROW_TRIGGERS}{0}{$prio} };

      if( $trig->( $self->{data}[$row], $prow, $row ) ) {
	%tr = ( %tr, %{ $self->{opts}{$key} } );
	last;
      }
    }
  }

  # Build column body:
  my ( $vcol, $body ) = ( 0, '' );
  foreach my $col ( @{ $self->{view} } ) {
    $body .= $self->_cell( $prow, $vcol++, $row, $col );
  }

  my $out = '<tr ' . $self->_glue( \%tr ) . '>' . $body . "</tr>\n";

  return $out;
}

sub _cell {
  my ( $self, $prow, $vcol, $row, $col ) = @_;

  my %td = %{ $self->{opts}{td} };


  # Even/odd column
  if( $vcol %2 == 0 ) { %td = ( %td, %{ $self->{opts}{even_col} } ); }
  else                { %td = ( %td, %{ $self->{opts}{odd_col} } ); }

  # First/last column
  if( $vcol == 0 )    {
    %td = ( %td, %{ $self->{opts}{first_col} } );   # First column
  } elsif( $vcol == scalar( @{ $self->{view} } )-1 ) {
    %td = ( %td, %{ $self->{opts}{last_col} } );    # Last column
  }


  # Cell triggers
  my $flag = 0;
  if( exists $self->{CELL_TRIGGERS}{ $col } ) {
    for my $prio ( sort { $b <=> $a } keys %{ $self->{CELL_TRIGGERS}{$col} } ){
      my ( $trig, $key ) = @{ $self->{CELL_TRIGGERS}{ $col }{ $prio } };

      if( $trig->( $self->{data}[$row][$col], $vcol, $col ) ) {
	%td = ( %td, %{ $self->{opts}{$key} } );
	$flag = 1;
	last;
      }
    }
  }


  # Col triggers - only if no cell triggers have fired!
  if( !$flag && exists $self->{fired_col_triggers}{ $col } ) {
    my $key = $self->{fired_col_triggers}{ $col };
    %td = ( %td, %{ $self->{opts}{ $key } } );
  }


  return join '', '<td ', $self->_glue( \%td ), '>',
                  $self->_content( $prow, $vcol, $row, $col ), '</td>';
}

sub _content {
  my ( $self, $prow, $vcol, $row, $col ) = @_;

  if( exists $self->{format}{$col} ) {
    my ( $format, $type ) = @{ $self->{format}{$col} };

    if( $type eq 'format' ) {
      return $format->( $self->{data}[$row][$col] );
    } else {
      return $format->( @{ $self->{data}[$row] } );
    }
  }

  return $self->{data}[$row][$col];
}

# ------------------------------------------------------------

sub _get_options {
  my ( $self, $opt ) = @_; # $opt must be: first_col, or odd_row, etc

  # Worry about notfound? 

  # Return value is always: undef or a hash-ref: key/value (?)

  return $self->{opts}{$opt};
}

sub _set_options {
  my ( $self, $opt, $arg, $val ) = @_;

  # Decide if one or two arguments are present...
  if( !defined $val ) { # One argument - figure out the 'key', arg is 'val'
    my %html = ( table => 1, tr => 1, th => 1, td => 1 );
    my $field = exists $html{$opt} ? 'html' : 'color';

    $self->{opts}{$opt}{$field} = $arg;

  } elsif( $arg eq 'class' || $arg eq 'style' ) { # Two args: key and val
    $self->{opts}{$opt}{$arg} = $val;

  } else {
    carp "Illegal arguments - ,$opt, ,$arg, ,$val,";
  }
}

# ------------------------------------------------------------
# Arguments:
# $htmlargs   ||   class => $class   ||   style => $style

sub set_table { my $s = shift; return $s->_set_options( 'table', @_ ); }
sub set_tr    { my $s = shift; return $s->_set_options( 'tr', @_ ); }
sub set_th    { my $s = shift; return $s->_set_options( 'th', @_ ); }
sub set_td    { my $s = shift; return $s->_set_options( 'td', @_ ); }

sub get_table { my $s = shift; return $s->_get_options( 'table' ); }
sub get_tr    { my $s = shift; return $s->_get_options( 'tr' ); }
sub get_th    { my $s = shift; return $s->_get_options( 'th' ); }
sub get_td    { my $s = shift; return $s->_get_options( 'td' ); }

# ------------------------------------------------------------
# Arguments:
# $color   ||   class => $class   ||   style => $style

sub get_first_row { my $s = shift; return $s->_get_options( 'first_row' ); }
sub get_odd_row   { my $s = shift; return $s->_get_options( 'odd_row' ); }
sub get_even_row  { my $s = shift; return $s->_get_options( 'even_row' ); }
sub get_last_row  { my $s = shift; return $s->_get_options( 'last_row' ); }

sub get_first_col { my $s = shift; return $s->_get_options( 'first_col' ); }
sub get_odd_col   { my $s = shift; return $s->_get_options( 'odd_col' ); }
sub get_even_col  { my $s = shift; return $s->_get_options( 'even_col' ); }
sub get_last_col  { my $s = shift; return $s->_get_options( 'last_col' ); }

# -----

sub set_first_row { my $s = shift;  $s->_set_options( 'first_row', @_ ); }
sub set_odd_row   { my $s = shift;  $s->_set_options( 'odd_row',   @_ ); }
sub set_even_row  { my $s = shift;  $s->_set_options( 'even_row',  @_ ); }
sub set_last_row  { my $s = shift;  $s->_set_options( 'last_row',  @_ ); }

sub set_first_col { my $s = shift;  $s->_set_options( 'first_col', @_ ); }
sub set_odd_col   { my $s = shift;  $s->_set_options( 'odd_col',   @_ ); }
sub set_even_col  { my $s = shift;  $s->_set_options( 'even_col',  @_ ); }
sub set_last_col  { my $s = shift;  $s->_set_options( 'last_col',  @_ ); }

# ------------------------------------------------------------
# Arguments:
# $col, $sub,   $color   ||   class => $class   ||   style => $style

sub _set_trigger {
  my ( $self, $elem, $prio, $col, $sub, @args ) = @_;

  my $trig = join '_', $elem, 'TRIGGERS';
  my $key  = join '_', $trig, $prio;

  $self->{ $trig }{ $col }{ $prio } = [ $sub, $key ];
  $self->_set_options( $key, @args );
}

# sub set_row_trigger { my ( $self, $prio, $sub, @args ) = @_; }
sub set_row_trigger {
  my ( $self, $prio, @args ) = @_;
  $self->_set_trigger( 'ROW', $prio, 0, @args );
}
sub set_row_hi  { my $self = shift; $self->set_row_trigger( $HI,  @_ ); }
sub set_row_med { my $self = shift; $self->set_row_trigger( $MED, @_ ); }
sub set_row_low { my $self = shift; $self->set_row_trigger( $LOW, @_ ); }

# sub set_col_trigger { my ( $self, $prio, $col, $sub, @args ) = @_; }
sub set_col_trigger { my $self = shift; $self->_set_trigger( 'COL', @_); }
sub set_col_hi  { my $self = shift; $self->set_col_trigger( $HI,  @_ ); }
sub set_col_med { my $self = shift; $self->set_col_trigger( $MED, @_ ); }
sub set_col_low { my $self = shift; $self->set_col_trigger( $LOW, @_ ); }

# sub set_cell_trigger { my ( $self, $prio, $col, $sub, @args ) = @_; }
sub set_cell_trigger { my $self = shift; $self->_set_trigger( 'CELL', @_); }
sub set_cell_hi  { my $self = shift; $self->set_cell_trigger( $HI,  @_ ); }
sub set_cell_med { my $self = shift; $self->set_cell_trigger( $MED, @_ ); }
sub set_cell_low { my $self = shift; $self->set_cell_trigger( $LOW, @_ ); }


sub _find_triggered_columns {
  my $self = shift;

  unless( exists $self->{COL_TRIGGERS} ) { return; }

  my $vcol = -1;
  for my $col ( @{ $self->{view} } ) {
    $vcol += 1;

    unless( exists $self->{COL_TRIGGERS}{ $col } ) { next; }

    # Low->Med->Hi : higher priority clobbers earlier results!
    for my $prio ( sort { $a <=> $b } keys %{ $self->{COL_TRIGGERS}{$col} } ) {
      my ( $trig, $key ) = @{ $self->{COL_TRIGGERS}{$col}{$prio} };

      foreach my $idx ( 0..$self->{records} ) {
	my $row = $self->{sortrank}[$idx];
	if( $trig->( $self->{data}[$row][$col], $vcol, $col ) ) {
	  $self->{fired_col_triggers}{$col} = $key;
	  last;
	}
      }
    }
  }
}

# ------------------------------------------------------------
# Arguments:
# $col, $sub

# For each column, a formatting function can be set. The function is called
# for each cell in the column. The return value of the function is used as
# printable content of the cell.
# A 'format' function receives as argument the raw value of the cell.
# A 'collate' function receives as argument the entire row as an array.
#
# Examples:
# format:
#    sub { substr $_[0], 0, 3 } prints only first three chars of cell val
# collate:
#   sub { $_[0] . '=' . $_[1] } concates first and second column value

sub set_format {
  my ( $self, $col, $sub ) = @_;
  $self->{format}{$col} = [ $sub, 'format' ];
}

sub set_collate {
  my ( $self, $col, $sub ) = @_;
  $self->{format}{$col} = [ $sub, 'collate' ];
}

1;

__END__


=head1 NAME

HTML::Dashboard - Spreadsheet-like formatting for HTML tables, with data-dependent coloring and highlighting: formatted reports

=head1 SYNOPSIS

  use HTML::Dashboard;

  my $dash = HTML::Dashboard->new();

  $dash->set_data_without_captions( [ [ 'A', 2, 'foo' ],
                                      [ 'B', 0, 'bar' ],
                                      [ 'C', 1, 'baz' ],
                                      [ 'D', 8, 'mog' ],
                                      [ 'E', 4, 'duh' ] ] );

  $dash->set_captions( qw( Code Number Name ) );
  $dash->set_cell_low( 1, sub { $_[0] < 1 }, 'lime' );
  $dash->set_cell_hi(  1, sub { $_[0] > 5 },
                       style => "background-color: red; font-weight: bold" );

  print $dash->as_HTML();

=head1 DESCRIPTION

This module tries to achieve spreadsheet-like formatting for HTML tables.

Rather than having to build up an HTML table from data, row by row and
cell by cell, applying formatting rules at every step, this module allows
the user to specify a set of simple rules with the desired formatting
options. The module will evaluate the rules and apply the formatting
options as necessary.

The following features are supported:

=over 4

=item *

User-defined formatting of first, last, even, and odd rows or columns.

=item *

Conditional formatting, based on the contents of each cell.

=item *

Sorting (on any column or combination of columns, with user defined sort-order).

=item *

Pagination of the data set.

=item *

Definition of "views", i.e. restriction of the set of columns shown.

=item *

User-defined column captions.

=item *

On-the-fly formatting and collating of the data.

=back

As an example, the code in the synopsis above yields the following HTML
table (only visible in HTML):

=begin html

<center>
<!-- Table generated by HTML::Dashboard - www.cpan.org -->
<table border="1" >
<tr ><th >Code</th><th >Number</th><th >Name</th></tr>
<tr ><td >A</td><td >2</td><td >foo</td></tr>
<tr style="background-color: #eeeeee;" ><td >B</td><td style="background-color: lime;" >0</td><td >bar</td></tr>
<tr ><td >C</td><td >1</td><td >baz</td></tr>
<tr style="background-color: #eeeeee;" ><td >D</td><td style="background-color: red; font-weight: bold" >8</td><td >mog</td></tr>
<tr ><td >E</td><td >4</td><td >duh</td></tr>
</table>
</center>

=end html

More examples can be found on the author's project page:
http://www.beyondcode.org/projects/dashboard/gallery.html

Please read the Rationale section below to understand the purpose
of this module.


=head1 PUBLIC MEMBER FUNCTIONS

=head2 Constructor

=over 4

=item HTML::Dashboard->new()

Constructs a new dashboard object. By default, this generates an HTML
table with C<border='1'> and sets the background color of all even rows
to light grey (#eeeeee). These defaults can be overridden (cf. below).

=back

=head2 Setting Data

=over 4

=item $dash->set_data_without_captions( $data )

=item $dash->set_data_with_captions( $data )

Takes a I<reference> to an array of I<array references> of rows
(i.e. a two-dimensional array). All rows I<must> contain the same
number of columns.

Use C<set_data_without_captions> if the array contains only data,
without captions. Use C<set_data_with_captions> if the array contains
captions in the first row (as is common, e.g., for data returned from
database queries). Captions can be specified or overridden using
C<set_captions> (cf. below).

The data set is only accessed by reference, i.e. it is I<not> copied.
This should be advantageous for large data sets, but will lead to
strange results if the data set changes after having been set, but
before any one of the output routines is called.

=back


=begin NOT_IMPLEMENTED

=head2 Setting and Using Database Queries

=over 4

=item $dash->get_query { my $self = shift; return $self->{sql} }

=item $dash->set_query_without_captions {

=item $dash->set_query_with_captions {

=item $dash->prepare_query_without_captions { }

=item $dash->prepare_query_with_captions { }

=back

=end NOT_IMPLEMENTED


=head2 Output

=over 4

=item $dash->as_text()

=item $dash->as_text( $page )

Returns the data as tab-delimited text string, after content formatters (or
collaters), sorting, views, and pagination have been applied. No other
formatting directives (e.g. odd/even rows, or hi/med/low triggers)
are applied. The string will include captions (if they have been set).

In the resulting text string, columns are separated by tabs (\t),
rows are separated by single newlines (\n). Tabs, newlines, and 
backslashes in the data are escaped through a preceding backslash (\).

=back

=over 4

=item $dash->as_HTML()

=item $dash->as_HTML( $page )

Returns the data as a single HTML string. The string contains an HTML
table, from the opening C<E<lt>tableE<gt>> to the closing C<E<lt>/tableE<gt>>
tag.

No HTML-escaping of data (i.e. of cell content) is performed. If required, 
specify an appropriate formatter for the data to perform any conversions.

=back

Both functions can be called with an optional integer argument. If no
argument is supplied, all rows are returned. If an integer argument in
the range

  0 <= $page < $dash->pagecount()

is supplied, only the rows in the specified page (plus captions, if any)
are returned. If a page outside the legal range is specified, a warning
is emitted and all rows are returned. (Do not forget to call
C<$dash-E<gt>set_pagesize(...)> before using this feature. By default,
the pagesize is set to infinity, i.e. all rows are returned.)


=head2 Captions, Pagination, Views, Sorting

=over 4

=item $dash->set_captions( @captions )

=item $array_ref = $dash->get_captions()

Sets captions for the columns. The captions will be rendered on every
page (if pagination is used), using C<E<lt>thE<gt>> tags.
The number of captions provided I<must> match the number of columns in
the data.
If captions have been set explicitly using this function, these captions
will be used, even if the data itself contains captions in the first row
(i.e. if the data has been set using C<set_data_with_captions()>).

=back

=over 4

=item $dash->set_pagesize( $rows_per_page )

=item $rows_per_page = $dash->get_pagesize()

=item $pages = $dash->get_pagecount()

Restricts the number of data rows per page (i.e. not counting captions).
Setting the pagesize to anything but a positive integer turns pagination
I<off>, so that all rows will be returned.

=back

=over 4

=item $dash->set_view( @column_indices )

=item $array_ref = $dash->get_view()

The set of columns shown can be restricted using C<set_view()>. This
function takes an array of column indices (0..$num_of_cols) to be shown.
Defaults to all columns.

=back

=over 4

=item $dash->set_sort( sub { ... } )

Sets a comparator routine which will be used to sort the rows before
rendering them. The comparator routine will be given two rows (as
array references) and must return "an integer less than, equal to, or
greater than 0", depending on how the rows are to be ordered (cf. Camel,
entry on C<sort>). Entire rows are passed to the comparator, before views
(if any) are applied.

B<Note that the comparator will be called as a regular routine!> This
implies in particular that the comparator must parse C<@_> itself -
arguments will not be passed through the "global" variables C<$a> and
C<$b> as for the C<sort> built-in.

Example:

  $dash->set_sort( sub { my ( $x, $y ) = @_; $x->[0] <=> $y->[0] } )

This sorts the rows numerically on the contents of the first column.

=back


=head2 Formatting Options

There are three groups of formatting options:

=over 4

=item *

Options applied to plain HTML tags (i.e. the C<< <table> >>, C<< <tr> >>,
C<< <th> >>, and C<< <td> >> tags).

=item *

Options to generate "striped reports" (i.e. tables, where the formatting
is dependent on the row- or column-index).

=item *

Options which are only applied when a data-dependent condition is fulfilled.

=back

The last group is more complicated, because not only do the actual formatting
options have to be set, but also the "trigger" and the range of table cells
to which it is supposed to be applied.

Formatting options can be set using three different ways:

=over 4

=item 1

Single argument: e.g. C<< $dash->set_table( "border='1'" ) >> or
C<< $dash->set_first_row( 'red' ) >>.

=item 2

As explicit CSS style directive: e.g.
C<< $dash->set_th( style => 'font-size: x-large' ) >> or
C<< $dash->set_even_row( style => 'background-color: yellow' ) >>.


=item 3

By naming a CSS class: e.g.
C<< $dash->set_td( class => 'highlighted' ) >> or
C<< $dash->set_even_col( class => 'evencol' ) >>. (Obviously, the
class set in this way should be defined in a stylesheet referenced
by the HTML page containing the dashboard.)

=back

When using the "style" and "class" methods, a "style" or "class"
argument is included into the appropriate HTML tags, and set to the
supplied value. Note that repeated calls to these functions are
additive, I<not> exclusive. In other words, the following two code
samples are equivalent:

  $dash->set_even_row( style => 'background-color: yellow' );
  $dash->set_even_row( style => 'font-size: x-large' );

is equivalent to:

  $dash->set_even_row( style => 'background-color: yellow; font-size: x-large' );

(The module will supply semicolons between different style directives
when merging the results from repeated calls.)

To erase previous style directives, assign C<undef> explicitly:
C<< $dash->set_even_row( style => undef ) >>.

The single-argument version is intended as a short-cut and has a
slightly different meaning, depending on the group of formatting
option it is applied to. When applied to a direct HTML option (i.e.
when used with C<set_table()>, C<set_tr()>, C<set_th()>, or C<set_td()>),
the argument is pasted unmodified into the corresponding HTML tag.
When used with any other option, the argument is interpreted as the
I<desired background color> for the cell, row, or column. The specified
background color will be applied as an explicit "style" argument, I<not>
as a "bgcolor" argument. In other words, the following calls are (almost)
equivalent:

  $dash->set_first_row( 'cyan' );
  $dash->set_first_row( style => 'background-color: cyan' );


It is legal to set conflicting formatting options and will not prevent
generation of HTML output. However, no guarantees are made about the
appearance of the dashboard in the browser in this case.

B<In the following, C<[format]> always stand for formatting
options in any one of the three legal syntax variants as discussed above!>


=head3 General HTML Options

=over 4

=item $dash->set_table( C<[format]> )

=item $dash->set_tr( C<[format]> )

=item $dash->set_th( C<[format]> )

=item $dash->set_td( C<[format]> )

=back

=over 4

=item $hash_ref = $dash->get_table()

=item $hash_ref = $dash->get_tr()

=item $hash_ref = $dash->get_th()

=item $hash_ref = $dash->get_td()

If set, these options are always included into all tags. This is mostly
useful to style the entire table, or cells in the header row.

=back

=head3 Striped Reports

=over 4

=item $dash->set_first_row( C<[format]> )

=item $dash->set_odd_row( C<[format]> )

=item $dash->set_even_row( C<[format]> )

=item $dash->set_last_row( C<[format]> )

=back

=over 4

=item $hash_ref = $dash->get_first_row()

=item $hash_ref = $dash->get_odd_row()

=item $hash_ref = $dash->get_even_row()

=item $hash_ref = $dash->get_last_row()

=back

=over 4

=item $dash->set_first_col( C<[format]> )

=item $dash->set_odd_col( C<[format]> )

=item $dash->set_even_col( C<[format]> )

=item $dash->set_last_col( C<[format]> )

=back

=over 4

=item $hash_ref = $dash->get_first_col()

=item $hash_ref = $dash->get_odd_col()

=item $hash_ref = $dash->get_even_col()

=item $hash_ref = $dash->get_last_col()

Options set with these functions are applied to rows or columns as
appropriate. Note that first, last, even, and odd is understood with
reference to the page or the view, I<not> the total data set.

Options for first and last prevail over options for even and odd.
Options for columns prevail over options for rows.

=back

=head3 Conditional Formatting (Triggers)

Formatting options in this group are only applied if a "trigger"
evaluates to true. Therefore, the functions below all take a function
reference as argument, besides the actual formatting options.

All triggers have a "priority" from highest (hi), over intermediate (med)
to lowest (low). If multiple triggers evaluate to true for a certain part
of the dashboard (say, a cell), then only the formatting option with the 
highest priority is applied.

The intended application is to show whether a set of data is "in the
green" or "in the red". Given the prioritization logic of the triggers,
this can be easily achieved, without the need for exclusive bounds or
conditions across the set of triggers, using code like this:

  $dash->set_row_low( sub{ ...; $x < 3  }, 'green' );
  $dash->set_row_med( sub{ ...; $x < 7  }, 'yellow' );
  $dash->set_row_hi(  sub{ ...; $x > 10 }, 'red' );


=over 4

=item $dash->set_row_hi(  sub{ my ( $row_ref ) = @_; ... }, C<[format]> )

=item $dash->set_row_med( sub{ my ( $row_ref ) = @_; ... }, C<[format]> )

=item $dash->set_row_low( sub{ my ( $row_ref ) = @_; ... }, C<[format]> )

If the triggers evaluates to true, the formatting option is applied
to the entire row. The argument to the trigger is an array-ref to
the current row. (Additional arguments: index of row in page, and
index of row in data set.)

=back


=over 4

=item $dash->set_col_hi(  $col, sub{ my ( $cell ) = @_; ... }, C<[format]> )

=item $dash->set_col_med( $col, sub{ my ( $cell ) = @_; ... }, C<[format]> )

=item $dash->set_col_low( $col, sub{ my ( $cell ) = @_; ... }, C<[format]> )

The first argument to this function is the index of the column I<in the
data set> (not in the view!) to which the formatting should be applied.
If the triggers evaluates to true, the formatting option is applied to
all cells in the column. The argument to the trigger is the contents of
the current cell in the specified column.(Additional arguments: the
index in the view and in the data set.)

=back


=over 4

=item $dash->set_cell_hi(  $col, sub{ my ( $cell ) = @_; ... }, C<[format]> )

=item $dash->set_cell_med( $col, sub{ my ( $cell ) = @_; ... }, C<[format]> )

=item $dash->set_cell_low( $col, sub{ my ( $cell ) = @_; ... }, C<[format]> )

The first argument to this function is the index of the column I<in the
data set> (not in the view!) to which the formatting should be applied.
If the triggers evaluates to true, the formatting option is applied to
the current cell only. The argument to the trigger is the contents of
the current cell in the specified column.(Additional arguments: the
index in the view and in the data set.)

=back

Options set with triggers are I<merged> (do not clobber) with options set
for first/last and even/odd. (This allows to have a striped report, and
use triggers to change the text color only.)

Options with high (hi) priority prevail over (clobber) options with 
intermediate (med) priority, which prevail over options with low priority.
Options for cells prevail over options for columns, which prevail over
options for rows.


=head2 Content Formatters

=over 4

=item $dash->set_format( $column, sub { ... } )

=item $dash->set_collate( $column, sub { ... } )

If set, the registered function is called for each row. Its output
is used as contents for the current row's cell in the column with
index C<$column>.

A formatter set with the first function is given the contents of
the data in the current cell, while a collater set with the second
function is given the entire row (as array).

Examples:

  $dash->set_format( 1, sub { my ( $x ) = @_; sprintf( "%.2f", $x ) } )
  $dash->set_collate( 1, sub { my ( $r ) = @_; $r[1] . ':' . $r[2] } )

=back


=begin UNDOCUMENTED

=head2 Undocumented

=over 4

=item $dash->dump_opts()

=item $dash->set_row_trigger()

=item $dash->set_col_trigger()

=item $dash->set_cell_trigger()

=back

=end UNDOCUMENTED


=head1 RATIONALE

It was important to me to define a module that would be easy to use,
with reasonable defaults and a reasonably small API.

In particular, I wanted a solution which would free the user entirely
from having to deal with (i.e. explicitly loop over) individual rows
and cells. Furthermore, the user should not have to specify information
that is already present in the data (such as the number of rows and
columns). Finally, I wanted to free the user from having to address
individual cells (e.g. by their location) to provide formatting
instructions.

All this required a rule-based system --- you specify the high-level
rules, the module makes sure they are applied as necessary.

Below are some further questions that have been asked --- with answers:

Why not just use CSS? Answer: All of this I<is> done through CSS. The
difficulty is deciding to which cells to apply the CSS style directives
(if this is to be done in a data dependent manner). This module does
just that, by inserting the correct CSS "class" arguments into the
appropriate cell tags (etc).

Why not go with a templating solution? Answer: Templates establish the
layout of a table from the outset, which makes it hard to do
cell-content-dependent formatting from within the template. And it is
simply not convenient, and not in the spirit of the thing, to build
templates with lots of conditional code in the template. (I know, having
used eg. C<HTML::Template> quite extensively.) Given the data-dependent
nature of the problem, the table must be built-up row by row and cell
by cell individually, applying triggers and formatters as we go along.
This is what this module does --- and since we are already must touch
each cell individually, we might as well print its HTML as we go along.
Using templates in the implementation would not help.

Why not use Excel, PDF, or what have you? Because I want to deliver
my reports via the web, so I specifically want HTML output. (Duh!)

Why the name? Because I wanted something more specific and tangible
than "FormattedReport" or some such. The name points to the source
of the idea for this module: corporate metrics dashboards. What
managers want to see are the key metrics of the business (sales,
orders, what-have-you), with outliers highlighted to make it easy
to see which metrics are "in the green" and which are "in the red".
This module allows you to do just that. (And more.)

=head1 TO DO

Several ideas:

=over 4

=item *

Instead of setting the actual data, it would be nice to set merely a
query (and a DB handle) and let the dashboard pull its own data from 
the DB.

=item *

When there are subsequent rows, which have identical entries in some
columns it can be neat to suppress (leave blank) the repeated entries
(e.g. C<set_skip_repeats( @skip_cols )> and C<get_skip_repeats()>).

=item *

When setting data using an array-ref, it would be nice to specify an
optional integer parameter C<$extend_by>, which would extend the range
of accessible columns. These new columns would be empty, but could be
used with C<set_collate()> to build new column values on the fly. (This
is never necessary when using a DB query, since one can always include
constants in the C<SELECT> clause.)

=back


=head1 SEE ALSO

I maintain a "gallery" of examples (with code) on my website at:
http://www.beyondcode.org/projects/dashboard/gallery.html

The module HTML::Tabulate seems close in intent to the present
module and may be an alternative. (The API is much larger than the
one for the present module and I am not entirely sure how it works.)

Several modules provide very thin wrappers around the actual
HTML of a table, they include HTML::Table, HTML::EasyTable,
HTML::ElementTable.

To generate tables directly from SQL queries, check out
Class::DBI::Plugin::FilterOnClick.


=head1 AUTHOR

Philipp K. Janert, E<lt>janert at ieee dot orgE<gt>, http://www.beyondcode.org


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Philipp K. Janert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
