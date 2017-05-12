#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Click for earlier rates'],
     keep_headers => 1,
     slice_columns => 0);
  $te->parse($content);
  my $ts = $te->first_table_found;
  if (! $ts) {
    _errormsg ($quotes, $symbol_list, 'rates table not found in HTML');
    return;
  }

  # Desired figures are in last column.
  # But on a bank holiday a column will have "BANK HOLIDAY", one letter per
  # row, so skip that if necessary, identified by the "B" in BANK in the
  # first row.
  my $col = $ts->columns - 1;
  while ($ts->cell(1,$col) eq 'B') {
    $col--;
    if ($col < 0) {
      _errormsg ($quotes, $symbol_list, 'oops, all "B" columns');
      return;
    }
  }

  # second last column
  my $prevcol = $col-1;
  while ($ts->cell(1,$prevcol) eq 'B') {
    $prevcol--;
    if ($prevcol < 0) {
      _errormsg ($quotes, $symbol_list, 'oops, all "B" columns');
      return;
    }
  }
  if (DEBUG) { print "  col=$col, prevcol=$prevcol\n"; }

  my $date = $ts->cell (0, $col);

  my %want_symbol;
  @want_symbol{@$symbol_list} = (); # hash slice
  my %seen_symbol;

  foreach my $row (@{$ts->rows()}) {
    my $name = $row->[0];
    ($name, my $time) = _name_extract_time ($name);

    my $symbol = $name_to_symbol{lc $name};
    if (! $symbol) { next; }  # unrecognised row
    if (! exists $want_symbol{$symbol}) { next; } # unwanted row

    my $rate = $row->[$col];
    my $prev = $row->[$prevcol];

    $fq->store_date($quotes, $symbol, {eurodate => $date});
    $quotes->{$symbol,'time'}  = $time;
    $quotes->{$symbol,'name'}  = $name;
    $quotes->{$symbol,'last'}  = $rate;
    $quotes->{$symbol,'close'} = $prev;
    if ($symbol ne 'TWI') {
      $quotes->{$symbol,'currency'} = $symbol;
    }
    $quotes->{$symbol,'copyright_url'} = COPYRIGHT_URL;
    $quotes->{$symbol,'success'}  = 1;

    # don't delete AUDTWI from %want_symbol since want to get the last row
    # which is 16:00 instead of the 9:00 one
    $seen_symbol{$symbol} = 1;
  }
