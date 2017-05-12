package HTML::CalendarMonth;
{
  $HTML::CalendarMonth::VERSION = '2.04';
}

use strict;
use warnings;
use Carp;

use HTML::ElementTable 1.18;
use HTML::CalendarMonth::Locale;
use HTML::CalendarMonth::DateTool;

use base qw( Class::Accessor HTML::ElementTable );

my %Objects;

# default complex attributes
my %Calmonth_Attrs = (
  head_m      => 1,     # month heading mode
  head_y      => 1,     # year heading mode
  head_dow    => 1,     # DOW heading mode
  head_week   => 0,     # weak of year
  year_span   => 2,     # default col span of year

  today       => undef, # DOM, if not now
  week_begin  => 1,     # what DOW (1-7) is the 1st DOW?

  historic    => 1,     # if able to choose, use ncal/cal
                        # rather than Date::Calc, which
                        # blindly extrapolates Gregorian

  alias       => {},    # what gets displayed if not
                        # the default item

  month       => undef, # these will get initialized
  year        => undef,

  locale      => 'en_US',
  full_days   => 0,
  full_months => 1,

  datetool    => undef,

  enable_css   => 1,
  semantic_css => 0,

  # internal muckety muck
  _cal      => undef,
  _itoch    => {},
  _ctoih    => {},
  _caltool  => undef,
  _weeknums => undef,

  dow1st   => undef,
  lastday  => undef,
  loc      => undef,

  # deprecated
  row_offset => undef,
  col_offset => undef,
);

__PACKAGE__->mk_accessors(keys %Calmonth_Attrs);

# Class::Accessor overrides

sub set {
  my($self, $key) = splice(@_, 0, 2);
  if (@_ == 1) {
    $Objects{$self}{$key} = $_[0];
  }
  elsif (@_ > 1) {
    $Objects{$self}{$key} = [@_];
  }
  else {
    Carp::confess("wrong number of arguments received");
  }
}

sub get {
  my $self = shift;
  if (@_ == 1) {
    return $Objects{$self}{$_[0]};
  }
  elsif ( @_ > 1 ) {
    return @{$Objects{$self}{@_}};
  }
  else {
    Carp::confess("wrong number of arguments received.");
  }
}

sub _is_calmonth_attr { shift; exists $Calmonth_Attrs{shift()} }

sub _set_defaults {
  my $self = shift;
  foreach (keys %Calmonth_Attrs) {
    $self->$_($Calmonth_Attrs{$_});
  }
  $self;
}

sub DESTROY { delete $Objects{shift()} }

# last dow col, first week row

use constant LDC => 6;
use constant FWR => 2;

# alias

sub item_alias {
  my($self, $item) = splice(@_, 0, 2);
  defined $item or croak "item name required";
  $self->alias->{$item} = shift if @_;
  $self->alias->{$item} || $item;
}

sub item_aliased {
  my($self, $item) = splice(@_, 0, 2);
  defined $item or croak "item name required.\n";
  defined $self->alias->{$item};
}

# header toggles

sub _head {
  # Set/test entire heading (month,year,and dow headers) (does not
  # affect week number column). Return true if either heading active.
  my $self = shift;
  $self->head_m(@_) && $self->head_dow(@_) if @_;
  $self->_head_my || $self->head_dow;
}

sub _head_my {
  # Set/test month and year header mode
  my($self, $mode) = splice(@_, 0, 2);
  $self->head_m($mode) && $self->head_y($mode) if defined $mode;
  $self->head_m || $self->head_y;
}

sub _initialized {
  my $self = shift;
  @_ ? $self->{_initialized} = shift : $self->{_initialized};
}

# circa interface

sub _date {
  # set target month, year
  my $self = shift;
  if (@_) {
    my ($month, $year) = @_;
    $month && defined $year || croak "date method requires month and year";
    croak "Date already set" if $self->_initialized();

    # get rid of possible leading 0's
    $month += 0;
    $year  += 0;

    $month <= 12 && $month >= 1 or croak "Month $month out of range (1-12)\n";
    $year > 0 or croak "Negative years are unacceptable\n";

    $self->month($self->monthname($month));
    $self->year($year);
    $month = $self->monthnum($month);

    # trigger _gencal...this should be the only place where this occurs
    $self->_gencal;
  }
  return($self->month, $self->year);
}

# class factory access

use constant CLASS_HET      => 'HTML::ElementTable';
use constant CLASS_DATETOOL => 'HTML::CalendarMonth::DateTool';
use constant CLASS_LOCALE   => 'HTML::CalendarMonth::Locale';

sub _gencal {
  # generate internal calendar representation
  my $self = shift;

  # new calendar...clobber day-specific settings
  my $itoc = $self->_itoch({});
  my $ctoi = $self->_ctoih({});

  # figure out dow of 1st day of the month as well as last day of the
  # month (uses date calculator backends)
  $self->_anchor_month();

  # row count for weeks in grid
  my $wcnt = 0;

  my ($dowc) = $self->dow1st;
  my $skips  = $self->_caltool->_skips;

  # for each day
  foreach (1 .. $self->lastday) {
    next if $skips->{$_};
    my $r = $wcnt + FWR;
    my $c = $dowc;
    # this is a bootstrap until we know the number of rows in the month.
    $itoc->{$_} = [$r, $c];
    $dowc = ++$dowc % 7;
    ++$wcnt unless $dowc || $_ == $self->lastday;
  }

  $self->{_week_rows} = $wcnt;

  my $row_extent = $wcnt + FWR;
  my $col_extent = LDC;
  $col_extent += 1 if $self->head_week;

  $self->SUPER::extent($row_extent, $col_extent);

  # table can contain the days now, so replace our bootstrap coordinates
  # with references to the actual elements.
  foreach (keys %$itoc) {
    my $cellref = $self->cell(@{$itoc->{$_}});
    $self->_itoc($_, $cellref);
    $self->_ctoi($cellref, $_);
  }

  # week num affects month/year spans
  my $width = $self->head_week ? 8 : 7;

  # month/year headers
  my $cellref = $self->cell(0, 0);
  $self->_itoc($self->month, $cellref);
  $self->_ctoi($cellref, $self->month);
  $cellref = $self->cell(0, $width - $self->year_span);
  $self->_itoc($self->year,  $cellref);
  $self->_ctoi($cellref, $self->year);

  $self->item($self->month)->replace_content($self->item_alias($self->month));
  $self->item($self->year)->replace_content($self->item_alias($self->year));

  if ($self->_head_my) {
    if ($self->head_m && $self->head_y) {
      $self->item($self->year) ->attr('colspan', $self->year_span);
      $self->item($self->month)->attr('colspan', $width - $self->year_span);
    }
    elsif ($self->head_y) {
      $self->item($self->month)->mask(1);
      $self->item($self->year)->attr('colspan', $width);
    }
    elsif ($self->head_m) {
      $self->item($self->year)->mask(1);
      $self->item($self->month)->attr('colspan', $width);
    }
  }
  else {
    $self->row(0)->mask(1);
  }

  # DOW headers
  my $trans;
  my $days = $self->loc->days;
  foreach (0..$#$days) {
    # Transform for week_begin 1..7
    $trans = ($_ + $self->week_begin - 1) % 7;
    my $cellref = $self->cell(1, $_);
    $self->_itoc($days->[$trans], $cellref);
    $self->_ctoi($cellref, $days->[$trans]);
  }
  if ($self->head_dow) {
    grep($self->item($_)->replace_content($self->item_alias($_)), @$days);
  }
  else {
    $self->row(1)->mask(1);
  }

  # week number column
  if ($self->head_week) {
    # week nums can collide with days. Use "w" in front of the number
    # for uniqueness, and automatically alias to just the number (unless
    # already aliased, of course).
    $self->_gen_week_nums();
    my $ws;
    my $row_count = FWR;
    foreach ($self->_numeric_week_nums) {
      $ws = "w$_";
      $self->item_alias($ws, $_) unless $self->item_aliased($ws);
      my $cellref = $self->cell($row_count, $self->last_col);
      $self->_itoc($ws, $cellref);
      $self->_ctoi($cellref, $ws);
      $self->item($ws)->replace_content($self->item_alias($ws));
      ++$row_count;
    }
  }

  # fill in days of the month
  my $i;
  foreach my $r (FWR .. $self->last_row) {
    foreach my $c (0 .. LDC) {
      $self->cell($r,$c)->replace_content($self->item_alias($i))
        if ($i = $self->item_at($r,$c));
    }
  }

  # css classes
  if ($self->enable_css) {
    $self->push_attr(class => 'hcm-table');
    $self->item_row($self->dayheaders)->push_attr(class => 'hcm-day-head')
      if $self->head_dow;
    $self->item($self->year)->push_attr(class => 'hcm-year-head')
      if $self->head_y;
    $self->item($self->month)->push_attr(class => 'hcm-month-head')
      if $self->head_m;
    $self->item($self->week_nums) ->push_attr(class => 'hcm-week-head')
      if $self->head_week;
  }

  if ($self->semantic_css) {
    my $today = $self->today;
    if ($today < 0) {
      $self->item($self->days)->push_attr(class => 'hcm-past');
    }
    elsif ($today == 0) {
      $self->item($self->days)->push_attr(class => 'hcm-future');
    }
    else {
      for my $d ($self->days) {
        if ($d < $today) {
          $self->item($d)->push_attr(class => 'hcm-past');
        }
        elsif ($d > $today) {
          $self->item($d)->push_attr(class => 'hcm-future');
        }
        else {
          $self->item($d)->push_attr(class => 'hcm-today');
        }
      }
    }
  }

  $self;
}

sub default_css {
  my $hbgc = '#DDDDDD';
  my $bc   = '#888888';

  my $str = <<__CSS;
<style type="text/css">
  <!--

  table.hcm-table {
    border: thin solid $bc;
    border-collapse: collapse;
    text-align: right;
  }

  .hcm-table td, th {
    padding-left:  2px;
    padding-right: 2px;
  }

  .hcm-year-head  {
    text-align: right;
    background-color: $hbgc;
  }

  .hcm-month-head {
    text-align: left;
    background-color: $hbgc;
  }

  .hcm-day-head   {
    text-align: right;
    background-color: $hbgc;
    border-bottom: thin solid $bc;
   }

  .hcm-week-head  {
    font-size: small;
    background-color: $hbgc;
    border-left: thin solid $bc;
  }

-->
</style>
__CSS

}

sub _datetool {
  my $self = shift;
  my $ct;
  if (! ($ct = $self->_caltool)) {
    $ct = $self->_caltool(CLASS_DATETOOL->new(
      year     => $self->year,
      month    => $self->month,
      weeknum  => $self->head_week,
      historic => $self->historic,
      datetool => $self->datetool,
    ));
  }
  $ct;
}

sub _anchor_month {
  # Figure out what our month grid looks like.
  # Let HTML::CalendarMonth::DateTool determine which method is
  # appropriate.
  my $self = shift;

  my $month = $self->monthnum($self->month);
  my $year  = $self->year;

  my $tool = $self->_datetool;

  my $dow1st  = $tool->dow1st; # 0..6, starting with Sun
  my $lastday = $tool->lastday;

  # week_begin given as 1..7 starting with Sun
  $dow1st = ($dow1st - ($self->week_begin - 1)) % 7;

  $self->dow1st($dow1st);
  $self->lastday($lastday);

  $self;
}

sub _gen_week_nums {
  # Generate week-of-the-year numbers. The first week is generally
  # agreed upon to be the week that contains the 4th of January.
  #
  # For purposes of shenanigans with 'week_begin', we anchor the week
  # number off of Thursday in each row.

  my $self = shift;

  my($year, $month, $lastday) = ($self->year, $self->monthnum, $self->lastday);

  my $tool = $self->_caltool;
  croak "Oops. " . ref $tool . " not set up for week of year calculations.\n"
    unless $tool->can('week_of_year');

  my $fdow = $self->dow1st;
  my $delta = 4 - $fdow;
  if ($delta < 0) {
    $delta += 7;
  }
  my @ft = $tool->add_days($delta, 1);

  my $ldow = $tool->dow($lastday);
  $delta = 4 - $ldow;
  if ($delta > 0) {
    $delta -= 7;
  }
  my @lt = $tool->add_days($delta, $lastday);

  my $fweek = $tool->week_of_year(@ft);
  my $lweek = $tool->week_of_year(@lt);
  my @wnums = $fweek > $lweek ? ($fweek, 1 .. $lweek) : ($fweek .. $lweek);

  # do we have days above our first Thursday?
  if ($self->row_of($ft[0]) != FWR) {
    unshift(@wnums, $wnums[0] -1);
  }

  # do we have days below our last Thursday?
  if ($self->row_of($lt[0]) != $self->last_row) {
    push(@wnums, $wnums[-1] + 1);
  }

  # first visible week is from last year
  if ($wnums[0] == 0) {
    $wnums[0] = $tool->week_of_year($tool->add_days(-7, $ft[0]));
  }

  # last visible week is from subsequent year
  if ($wnums[-1] > $lweek) {
    $wnums[-1] = $tool->week_of_year($tool->add_days(7, $lt[0]));
  }

  $self->_weeknums(\@wnums);
}

# month hooks

sub row_items {
  # given a list of items, return all items in rows shared by the
  # provided items.
  my $self = shift;
  my %items;
  foreach my $item (@_) {
    my $row = ($self->coords_of($item))[0];
    foreach my $col (0 .. $self->last_col) {
      my $i = $self->item_at($row, $col) || next;
      ++$items{$i};
    }
  }
  keys %items > 1 ? keys %items : (keys %items)[0];
}

sub col_items {
  # return all item cells in the columns occupied by the provided list
  # of items.
  my $self = shift;
  $self->_col_items(0, $self->last_row, @_);
}

sub daycol_items {
  # same as col_items(), but excludes header cells.
  my $self = shift;
  $self->_col_items(FWR, $self->last_row, @_);
}

sub _col_items {
  # given row bounds and a list of items, return all item elements
  # in the columns occupied by the provided items. Does not return
  # empty cells.
  my($self, $rfirst, $rlast) = splice(@_, 0, 3);
  my %items;
  my($item, $row, $col, %i);
  foreach my $item (@_) {
    my $col = ($self->coords_of($item))[1];
    foreach my $row ($rfirst .. $rlast) {
      my $i = $self->item_at($row,$col) || next;
      ++$items{$i};
    }
  }
  keys %items > 1 ? keys %items : (keys %items)[0];
}

sub daytime {
  # return seconds since epoch for a given day
  my($self, $day) = splice(@_, 0, 2);
  $day or croak "must specify day of month";
  croak "day does not exist" unless $self->_daycheck($day);
  $self->_caltool->day_epoch($day);
}

sub week_nums {
  # return list of all week number labels
  my @wnums = map("w$_", shift->_numeric_week_nums);
  wantarray ? @wnums : \@wnums;
}

sub _numeric_week_nums {
  # return list of all week numbers as numbers
  my $self = shift;
  return unless $self->head_week;
  wantarray ? @{$self->_weeknums} : $self->_weeknums;
}

sub days {
  # return list of all days of the month (1..$c->lastday).
  my $self = shift;
  my $skips = $self->_caltool->_skips;
  my @days = grep { !$skips->{$_} } (1 .. $self->lastday);
  wantarray ? @days : \@days;
}

sub dayheaders {
  # return list of all day headers (Su..Sa).
  shift->loc->days;
}

sub headers {
  # return list of all headers (month,year,dayheaders)
  my $self = shift;
  wantarray ? ($self->year, $self->month, $self->dayheaders)
            : [$self->year, $self->month, $self->dayheaders];
}

sub items {
  # return list of all items (days, headers)
  my $self = shift;
  wantarray ? ($self->headers, $self->days)
            : [$self->headers, $self->days];
}

sub last_col {
  # what's the max col of the calendar?
  my $self = shift;
  $self->head_week ? LDC + 1 : LDC;
}

sub last_day_col { LDC }

sub last_row {
  # last row of the calendar
  my $self = shift;
  return ($self->coords_of($self->lastday))[0];
}

*last_week_row = \&last_row;

sub first_week_row { FWR };

sub past_days {
  my $self  = shift;
  my $today = $self->today;
  if ($today < 0) {
    return $self->days;
  }
  elsif ($today == 0) {
    return;
  }
  return(1 .. $today);
}

sub future_days {
  my $self  = shift;
  my $today = $self->today;
  if ($today < 0) {
    return;
  }
  elsif ($today == 0) {
    return $self->days;
  }
  return($today .. $self->last_day);
}

# custom glob interfaces

sub item {
  # return TD elements containing items
  my $self = shift;
  @_ || croak "item(s) must be provided";
  $self->cell(grep(defined $_, map($self->coords_of($_), @_)));
}

sub item_row {
  # return a glob of the rows of a list of items, including empty cells.
  my $self = shift;
  $self->row(map { $self->row_of($_) } @_);
}

sub item_day_row {
  # same as item_row, but excludes possible week number cells
  my $self = shift;
  return $self->item_row(@_) unless $self->head_week;
  my(%rows, @coords);
  for my $r (map { $self->row_of($_) } @_) {
    next if ++$rows{$r} > 1;
    for my $c (0 .. 6) {
      push(@coords, ($r, $c));
    }
  }
  $self->cell(@coords);
}

sub item_week_nums {
  # glob of all week numbers
  my $self = shift;
  $self->item($self->week_nums);
}

sub item_col {
  # return a glob of the cols of a list of items, including empty cells.
  my $self = shift;
  $self->_item_col(0, $self->last_row, @_);
}

sub item_daycol {
  # same as item_col(), but excludes header cells.
  my $self = shift;
  $self->_item_col(2, $self->last_row, @_);
}

sub _item_col {
  # given row bounds and a list of items, return a glob representing
  # the cells in the columns occupied by the provided items, including
  # empty cells.
  my($self, $rfirst, $rlast) = splice(@_, 0, 3);
  defined $rfirst && defined $rlast or Carp::confess "No items provided";
  my(%seen, @coords);
  foreach my $col (map { $self->col_of($_) } @_) {
    next if ++$seen{$col} > 1;
    foreach my $row ($rfirst .. $rlast) {
      push(@coords, $row, $col);
    }
  }
  $self->cell(@coords);
}

sub item_box {
  # return a glob of the box defined by two items
  my($self, $item1, $item2) = splice(@_, 0, 3);
  defined $item1 && defined $item2 or croak "Two items required";
  $self->box($self->coords_of($item1), $self->coords_of($item2));
}

sub all {
  # return a glob of all calendar cells, including empty cells.
  my $self = shift;
  $self->box( 0,0 => $self->last_row, $self->last_col );
}

sub alldays {
  # return a glob of all cells other than header cells
  my $self = shift;
  $self->box( 2, 0 => $self->last_row, 6 );
}

sub allheaders {
  # return a glob of all header cells
  my $self = shift;
  $self->item($self->headers);
}

# transformation Methods

sub coords_of {
  # convert an item into grid coordinates
  my $self = shift;
  croak "undefined value passed to coords_of()" if @_ && ! defined $_[0];
  my $ref = $self->_itoc(@_);
  my @pos = ref $ref ? $ref->position : ();
  @pos ? (@pos[$#pos - 1, $#pos]) : ();
}

sub item_at {
  # convert grid coords into item
  my $self = shift;
  $self->_ctoi($self->cell(@_));
}

sub _itoc {
  # item to grid
  my($self, $item, $ref) = splice(@_, 0, 3);
  defined $item or croak "item required";
  my $itoc = $self->_itoch;
  if ($ref) {
    croak "Reference required" unless ref $ref;
    $itoc->{$item} = $ref;
  }
  $itoc->{$item};
}

sub _ctoi {
  # cell reference to item
  my($self, $refstring, $item) = splice(@_, 0, 3);
  defined $refstring or croak "cell id required";
  my $ctoi = $self->_ctoih;
  if (defined $item) {
    $ctoi->{$refstring} = $item;
  }
  $ctoi->{$refstring};
}

sub row_of {
  my $self = shift;
  ($self->coords_of(@_))[0];
}

sub col_of {
  my $self = shift;
  ($self->coords_of(@_))[1];
}

sub monthname {
  # check/return month...returns name. Accepts month number or string.
  my $self = shift;
  return $self->month unless @_;
  my $loc = $self->loc;
  my @names;
  for my $m (@_) {
    $m = ($m - 1) % 12 if $m && $m =~ /^\d+$/;
    $m = $loc->monthname($m) || croak "month not found " . join(', ', @_);
    return $m if @_ == 1;
    push(@names, $m);
  }
  @names;
}

sub monthnum {
  # check/return month, returns number. Accepts month number or string.
  my $self   = shift;
  my @months = @_ ? @_ : $self->month;
  my $loc = $self->loc;
  my @nums;
  for my $m (@months) {
    $m = ($m - 1) % 12 if $m && $m =~ /^\d+$/;
    $m = $loc->monthnum($m);
    croak "month not found ", join(', ', @_) unless defined $m;
    $m += 1;
    return $m if @_ == 1;
    push(@nums, $m);
  }
  @nums;
}

sub dayname {
  # check/return day...returns name. Accepts 1..7, or Su..Sa
  my $self = shift;
  @_ || croak "day string or num required";
  my $loc = $self->loc;
  my @names;
  for my $d (@_) {
    if ($d =~ /^\d+$/) {
      $d = (($d - 1) % 7) + $self->week_begin - 1;
    }
    $d = $loc->dayname($d) || croak "day not found ", join(', ', @_);
    return $d if @_ == 1;
    push(@names, $d);
  }
  @names;
}

sub daynum {
  # check/return day number 1..7, returns number. Accepts 1..7,
  # or Su..Sa
  my $self = shift;
  @_ || croak "day string or num required";
  my $loc  = $self->loc;
  my @nums;
  for my $d (@_) {
    if ($d =~ /^\d+$/) {
      $d = (($d - 1) % 7) + $self->week_begin - 1;
    }
    $d = $loc->daynum($d);
    croak "day not found ", join(', ', @_) unless defined $d;
    $d += 1;
    return $d if @_ == 1;
    push(@nums, $d);
  }
  @nums;
}

# tests-n-checks

sub _dayheadcheck {
  # test day head names
  my($self, $name) = splice(@_, 0, 2);
  $name or croak "name missing";
  return if $name =~ /^\d+$/;
  $self->daynum($name);
}

sub _daycheck {
  # check if an item is a day of the month (1..31)
  my($self, $item) = splice(@_, 0, 2);
  croak "item required" unless $item;
  # can't just invert _headcheck because coords_of() needs _daycheck,
  # and _headcheck uses coords_of()
  $item =~ /^\d{1,2}$/ && $item <= 31;
}

sub _headcheck {
  # check if an item is a header
  !_daycheck(@_);
}

# constructors/destructors

sub new {
  my $class = shift;
  my %parms = @_;
  my(%attrs, %tattrs);
  foreach (keys %parms) {
    if (__PACKAGE__->_is_calmonth_attr($_)) {
      $attrs{$_} = $parms{$_};
    }
    else {
      $tattrs{$_} = $parms{$_};
    }
  }

  my $self = CLASS_HET->new(%tattrs);
  bless $self, $class;

  # set defaults
  $self->_set_defaults;

  my $month = delete $attrs{month};
  my $year  = delete $attrs{year};
  if (!$month || !$year) {
    my ($nmonth,$nyear) = (localtime(time))[4,5];
    ++$nmonth; $nyear += 1900;
    $month ||= $nmonth;
    $year  ||= $nyear;
  }
  $self->month($month);
  $self->year($year);

  # set overrides
  for my $k (keys %attrs) {
    $self->$k($attrs{$k}) if defined $attrs{$k};
  }

  my $loc = CLASS_LOCALE->new(
    id          => $self->locale,
    full_days   => $self->full_days,
    full_months => $self->full_months,
  ) or croak "Problem creating locale " . $self->locale . "\n";
  $self->loc($loc);

  my $dt = CLASS_DATETOOL->new(
      year     => $self->year,
      month    => $self->month,
      weeknum  => $self->head_week,
      historic => $self->historic,
      datetool => $self->datetool,
  );
  $self->_caltool($dt);

  $self->week_begin($loc->first_day_of_week + 1)
    unless defined $attrs{week_begin};

  my $dom_now = defined $attrs{today} ? $dt->_dom_now(delete $attrs{today})
                                      : $dt->_dom_now;
  $self->today($dom_now);

  my $alias = $attrs{alias} || {};
  if ($self->full_days < 0) {
    my @full   = $self->loc->days;
    my @narrow = $self->loc->narrow_days;
    for my $i (0 .. $#narrow) {
      $alias->{$full[$i]} = $narrow[$i];
    }
  }
  if ($self->full_months < 0) {
    my @full   = $self->loc->months;
    my @narrow = $self->loc->narrow_months;
    for my $i (0 .. $#narrow) {
      $alias->{$full[$i]} = $narrow[$i];
    }
  }
  $self->alias($alias) if keys %$alias;

  # for now, this is the only time this will every happen for this
  # object. It is now 'initialized'.
  $self->_date($month, $year);

  $self;
}

### overrides (our table is static)

sub extent { }
sub maxrow { shift->SUPER::maxrow }
sub maxcol { shift->SUPER::maxcol }

### deprecated

use constant row_offset     => 0;
use constant col_offset     => 0;
use constant first_col      => 0;
use constant first_row      => 0;
use constant first_week_col => 0;
use constant last_week_col  => 6;

###

1;

__END__

=head1 NAME

HTML::CalendarMonth - Generate and manipulate HTML calendar months

=head1 SYNOPSIS

 use HTML::CalendarMonth;

 # Using regular HTML::Element creation
 my $c = HTML::CalendarMonth->new( month => 8, year => 2010 );
 print $c->as_HTML;

 # Full locale support via DateTime::Locale
 my $c2 = HTML::CalendarMonth->new(
   month  => 8,
   year   => 2010,
   locale => 'zu-ZA'
 );
 print $c2->as_HTML;

 # HTML-Tree integration
 my $tree = HTML::TreeBuilder->parse_file('cal.html');
 $tree->find_by_attribute(class => 'hcm-calendar')->replace_with($c);
 print $tree->as_HTML;

 # clean up if you're not done, HTML::Element structures must be
 # manually destroyed
 $c->delete; $c2->delete;

=head1 DESCRIPTION

HTML::CalendarMonth is a subclass of HTML::ElementTable. See
L<HTML::ElementTable(3)> for how that class works, for it affects this
module on many levels. Like HTML::ElementTable, HTML::CalendarMonth is
an enhanced HTML::Element with methods added to facilitate the
manipulation of the calendar table elements as a whole.

The primary interaction with HTML::CalendarMonth is through I<items>
rather than cell coordinates like HTML::ElementTable uses. An I<item> is
merely a string that represents the content of the cell of interest
within the calendar. For instance, the element representing the 14th day
of the month would be returned by C<$c-E<gt>item(14)>. Similarly, the
element representing the header for Monday would be returned by C<$c-
E<gt>item('Mo')>. If the year happened to by 2010, then C<$c-
E<gt>item(2010)> would return the cell representing the year. Since
years and particular months change frequently, it is probably more
useful to take advantage of the C<month()> and C<year()> methods, which
return their respective values. The following is therefore the same as
explicitely referencing the year: C<$c-E<gt>item($c- E<gt>year())>.

Multiple cells of the calendar can be manipulated as if they were a
single element. For instance, C<$c-E<gt>item(15)-E<gt>attr(class =E<gt>
'fancyday')> would alter the class of the cell representing the 15th. By
the same token, C<$c-E<gt>item(15, 16, 17,
23)-E<gt>attr(class =E<gt> 'fancyday')> would do the same thing for all
cells containing the days passed to the C<item()> method.

Underneath, the calendar is still nothing more than a table structure,
the same as provided by the HTML::ElementTable class. In addition to the
I<item> based access methods above, calendar cells can still be accessed
using row and column grid coordinates using the C<cell()> method
provided by the table class. All coordinate-based methods in the table
class are accessible to the calendar class.

The module includes support for week-of-the-year numbering, arbitrary
1st day of the week definitions, and locale support.

Dates that are beyond the range of the built-in time functions of perl
are handled either by the ncal/cal command, Date::Calc, DateTime, or
Date::Manip. The presence of any one of these utilities and modules will
suffice for these far flung date calculations. One of these utilities
(with the exception of 'cal') is also required if you want to use week-of-
year numbering.

Full locale support is offered via DateTime::Locale. For a full list of
supported locale id's, look at HTML::CalendarMonth::Locale->locales().

=head1 METHODS

All arguments appearing in [brackets] are optional, and do not represent
anonymous array references.

=head2 Constructor

=over

=item new()

With no arguments, the constructor will return a calendar object
representing the current month with a default appearance. The initial
configuration of the calendar is controlled by special attributes. Non-
calendar related attributes are passed along to HTML::ElementTable. Any
non-table related attributes left after that are passed to HTML::Element
while constructing the E<lt>tableE<gt> tag. See L<HTML::ElementTable> if
you are interested in attributes that can be passed along to that class.

Special Attributes for HTML::CalendarMonth:

=over

=item month

1-12, or Jan-Dec.  Defaults to current month.

=item year

Four digit representation. Defaults to current year.

=item head_m

Specifies whether to display the month header. Default 1.

=item head_y 

Specifies whether to display the year header. Default 1.

=item head_dow

Specifies whether to display days of the week header. Default 1.

=item head_week

Specifies whether to display the week-of-year numbering. Default 0.

=item locale

Specifies the id of the locale in which to render the calendar. Default
is 'en-US'. By default, this will also control determine which day is
considered to be the first day of the week. See
L<HTML::CalendarMonth::Locale> for more information. If for some reason
you prefer to use different labels than those provided by C<locale>, see
the C<alias> attribute below. NOTE: DateTime::Locale versions 0.92 and
earlier use underscores rather than dashes, e.g. 'en_US'.

=item full_days

Specifies whether or not to use full day names or their abbreviated
names. Default is 0, use abbreviated names. Use -1 for 'narrow' mode,
the shortest (not guaranteed to be unique) abbreviations.

=item full_months

Specifies whether or not to use full month names or their abbreviated
names. Default is 1, use full names. Use -1 for 'narrow' mode, the
shortest (not guaranteed to be unique) abbreviations.

=item alias

Takes a hash reference mapping labels provided by C<locale> to any
custom label you prefer. Lookups, such as C<day('Sun')>, will still use
the locale string, but when the calendar is rendered the aliased value
will appear.

=item week_begin

Specify first day of the week, which can be 1..7, starting with Sunday.
In order to specify Monday, set this to 2, and so on. By default, this
is determined based on the locale.

=item enable_css

Set some handy CSS class attributes on elements, enabled by default.
Currently the classes are:

  hcm-table       Set on the E<lt>tableE<gt> tag of the calendar
  hcm-day-head    Set on the day-of-week E<lt>trE<gt> or E<lt>tdE<gt> tags
  hcm-year-head   Set on the E<lt>tdE<gt> tag for the year
  hcm-month-head  Set on the E<lt>tdE<gt> tag for the month
  hcm-week-head   Set on the E<lt>tdE<gt> tags for the week-of-year

=item semantic_css

Sets some additional CSS class attributes on elements, disabled by
default. The notion of 'today' is taken either from the system clock
(default) or from the 'today' parameter as provided to new(). Currently
these classes are:

  hcm-today    Set on the E<lt>tdE<gt> tag for today, if present
  hcm-past     Set on the E<lt>tdE<gt> tags for prior days, if present
  hcm-future   Set on the E<lt>tdE<gt> tags for subsequent days, if present

=item today

Specify the value for 'today' if different from the local time as
reported by the system clock (the default). If specified as two or less
digits, it is assumed to be one of the days of the month in the current
calendar. If more than two digits, it is assumed to be a epoch time in
seconds. Otherwise it must be given as a string of the form 'YYYY-mm-
dd'. Note that the default value as determined by the system clock uses
localtime rather than gmtime.

=item historic

This option is ignored for dates that do not exceed the range of the built-
in perl time functions. For dates that B<do> exceed these ranges, this
option specifies the default calculation method. When set, if the 'ncal'
or 'cal' command is available on your system, that will be used rather
than the Date::Calc or Date::Manip modules. This can be an issue since
the date modules blindly extrapolate the Gregorian calendar, whereas
ncal/cal will revert to the Julian calendar during September 1752. If
either ncal or cal are not available on your system, this attribute is
meaningless. Defaults to 1.

=back

=back

=head2 Item Query Methods

The following methods return lists of item *symbols* (28, 29, 'Thu',
...) that are related in some way to the provided list of items. The
returned symbols may then be used as arguments to the glob methods
detailed further below.

=over

=item row_items(item1, [item2, ...])

Returns all item symbols in rows shared by the provided item symbols.

=item col_items(item1, [item2, ...])

Returns all item symbols in columns shared by the provided item symbols.

=item daycol_items(col_item1, [col_item2, ...])

Same as col_items(), but the returned item symbols are limited to those
that are not header items (month, year, day-of-week).

=item row_of(item1, [item2, ...])

Returns the row indices of rows containing the provided item symbols.

=item col_of(item1, [item2, ...])

Returns the column indices of columns containing the provided
item symbols.

=item lastday()

Returns the day number (symbol) of the last day of the month.

=item dow1st()

Returns the column index for the first day of the month.

=item days()

Returns a list of all days of the month as numbers.

=item week_nums()

Returns a list of week-of-year numbers for this month.

=item dayheaders()

Returns a list of all day headers (Su..Sa)

=item headers()

Returns a list of all headers (month, year, dayheaders)

=item items()

Returns a list of all item symbols (day number, header values) in
the calendar.

=item last_col()

Returns the index of the last column of the calendar (note that this
could be the week-of-year column if head_week is enabled).

=item last_day_col()

Returns the index of the last column of the calendar containing days of
the month (same as last_col() unless week-of-year is enabled).

=item first_week_row()

Returns the index of the first row of the calendar containing day items
(ie, the first week).

=item last_row()

Returns the index of the last row of the calendar.

=item today()

Returns the day of month for 'today', if present in the current
calendar.

=item past_days()

Returns a list of days prior to 'today'. If 'today' is in a future
month, all days are returned. If 'today' is in a past month, no days
are returned.

=item future_days()

Returns a list of days after 'today'. If 'today' is in a past
month, all days are returned. If 'today' is in a future month, no
days are returned.

=back

=head2 Glob Methods

Glob methods return references that are functionally equivalent to an
individual calendar cell. Mostly, they provide item based analogues to
the glob methods provided in HTML::ElementTable. In methods dealing with
rows, columns, and boxes, the globs include empty calendar cells (which
would otherwise need to be accessed through native HTML::ElementTable
methods). The row and column numbers returned by the item methods above
are compatible with the grid based methods in HTML::ElementTable.

For details on how these globs work, check out L<HTML::ElementTable> and
L<HTML::ElementGlob>.

=over

=item item(item1, [item2, ...])

Returns all cells containing the provided item symbols.

=item item_row(item1, [item2, ...])

Returns all cells in all rows occupied by the provided item symbols.

=item item_day_row(item1, [item2, ...])

Same as item_row() except excludes week-of-year cells, if present.

=item item_col(item1, [item2, ...])

Returns all cells in all columns occupied by the provided item symbols.

=item item_daycol(item1, [item2, ...])

Same as item_col() except limits the cells to non header cells.

=item item_week_nums()

Returns all week-of-year cells, if present.

=item item_box(item1a, item1b, [item2a, item2b, ...])

Returns all cells in the boxes defined by the item pairs provided.

=item allheaders()

Returns all header cells.

=item alldays()

Returns all non header cells, including empty cells.

=item all()

Returns all cells in the calendar, including empty cells.

=back

=head2 Transformation Methods

The following methods provide ways of translating between various item
symbols, coordinates, and other representations.

=over

=item coords_of(item)

Returns the row and column coordinates of the provided item symbol, for
use with the grid based methods in HTML::ElementTable.

=item item_at(row,column)

Returns the item symbol of the item at the provided coordinates, for use
with the item based methods of HTML::CalendarMonth.

=item monthname(monthnum)

Returns the name (item symbol) of the month number provided, where
I<monthnum> can be 1..12.

=item monthnum(monthname)

Returns the number (1..12) of the month name provided. Only a minimal
case-insensitive match on the month name is necessary; the proper item
symbol for the month will be determined from this match.

=item dayname(daynum)

Returns the name (item symbol) of the day of week header for a number of
a day of the week, where I<daynum> is 1..7.

=item daynum(dayname)

Returns the number of the day of the week given the symbolic name for
that day (Su..Sa).

=item daytime(day)

Returns the number in seconds since the epoch for a given day. The day
must be present in the current calendar.

=back

=head2 Other Methods

=over

=item default_css()

Returns a simple style sheet as a string that can be used in an HTML
document in conjunction with the classes assigned to elements when css
is enabled.

=back

=head1 REQUIRES

HTML::ElementTable

=head1 OPTIONAL

Date::Calc, DateTime, or Date::Manip (only if you want week-of-
year numbering or non-contemporary dates on a system without the
I<cal> command)

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998-2015 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

A useful page of examples can be found at
http://www.mojotoad.com/sisk/projects/HTML-CalendarMonth.

For information on iso639 standards for abbreviations for language
names, see http://www.loc.gov/standards/iso639-2/englangn.html

HTML::ElementTable(3), HTML::Element(3), perl(1)

=for Pod::Coverage col_offset row_offset item_alias item_aliased last_week_row
