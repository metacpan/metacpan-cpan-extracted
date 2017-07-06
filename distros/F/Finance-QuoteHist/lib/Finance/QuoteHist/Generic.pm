package Finance::QuoteHist::Generic;

# http://www.stanford.edu/dept/OOD/RESEARCH/top-ten-faq/how_do_i_find_an_historical_st.html
#
# Shortcut: Use adjusted close price
#
# For the mathematically inclined, one shortcut to determining the value
# after splits is to use the adjusted close price from the historical
# quote tool. For June 2, 1997, it lists a market close price of 33.13
# and an adjusted close price of 1.38. Divide 33.13 by 1.38 and you come
# up with 24.007. Multiply by 1,000 and you come pretty close to the
# 24,000 share figure determined above. Or you could divide 1.38 by
# 33.13, which gives you 0.041654. Divide $33,130 by 0.041654, and you
# get $795K, which is very close to the $808K figure above.

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = "1.22";

use LWP::UserAgent;
use HTTP::Request;
use Date::Manip;

my $CSV_XS_Class = 'Text::CSV_XS';
my $CSV_PP_Class = 'Text::CSV_PP';
my $CSV_Class = $CSV_XS_Class;
eval "use $CSV_Class";
if ($@) {
  $CSV_Class = $CSV_PP_Class;
  eval "use $CSV_Class";
  croak "Could not load either $CSV_XS_Class or $CSV_PP_Class : $@\n" if $@;
}

my $HTE_CLASS;
my $HTE_Class = 'HTML::TableExtract';
sub HTML_CLASS {
  if (!$HTE_CLASS) {
    eval "use $HTE_Class";
    croak $@ if $@;
    $HTE_CLASS = $HTE_Class;
  }
  $HTE_CLASS;
}

my $Default_Target_Mode = 'quote';
my $Default_Parse_Mode  = 'html';
my $Default_Granularity = 'daily';
my $Default_Vol_Pat = qr(vol|shares)i;

my %Default_Labels;
$Default_Labels{quote}{$Default_Parse_Mode} =
  [qw( date open high low close ), $Default_Vol_Pat];
$Default_Labels{dividend}{$Default_Parse_Mode} =
  [qw( date div )];
$Default_Labels{'split'}{$Default_Parse_Mode} =
  [qw( date post pre )];
$Default_Labels{intraday}{$Default_Parse_Mode} =
  [qw( date time high low close ), $Default_Vol_Pat];

my @Scalar_Flags = qw(
  verbose
  quiet
  zthresh
  quote_precision
  attempts
  adjusted
  has_non_adjusted
  env_proxy
  debug
  parse_mode
  target_mode
  granularity
  auto_proxy
  row_filter
  ua_params
);
my $SF_pat = join('|', @Scalar_Flags);

my @Array_Flags = qw(
  symbols
  lineup
);
my $AF_pat = join('|', @Array_Flags);

my @Hash_Flags = qw( ua_params );
my $HF_pat = join('|', @Hash_Flags);

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my(%parms, $k, $v);
  while (($k,$v) = splice(@_, 0, 2)) {
    if ($k eq 'start_date' || $k eq 'end_date' && $v !~ /^\s*$/) {
      $parms{$k} = __PACKAGE__->date_standardize($v);
    }
    elsif ($k =~ /^$AF_pat$/o) {
      if (UNIVERSAL::isa($v, 'ARRAY')) {
        $parms{$k} = $v;
      }
      elsif (ref $v) {
        croak "$k must be passed as an array ref or single-entry string\n";
      }
      else {
        $parms{$k} = [$v];
      }
    }
    elsif ($k =~ /^$HF_pat$/o) {
      if (UNIVERSAL::isa($v, 'HASH')) {
        $parms{$k} = $v;
      }
      else {
        croak "$k must be passed as a hash ref\n";
      }
    }
    elsif ($k eq 'row_filter') {
      croak "$k must be sub ref\n" unless UNIVERSAL::isa($v, 'CODE');
      $parms{$k} = $v;
    }
    elsif ($k =~ /^$SF_pat$/o) {
      $parms{$k} = $v;
    }
  }
  $parms{end_date} ||= __PACKAGE__->date_standardize('today');
  $parms{symbols} or croak "Symbol list required\n";

  my $start_date = delete $parms{start_date};
  my $end_date   = delete $parms{end_date};
  my $symbols    = delete $parms{symbols};

  # Defaults
  $parms{zthresh}          = 30 unless $parms{zthresh};
  $parms{attempts}         = 3  unless $parms{attempts};
  $parms{adjusted}         = 1  unless exists  $parms{adjusted};
  $parms{has_non_adjusted} = 0  unless defined $parms{has_non_adjusted};
  $parms{quote_precision}  = 4  unless defined $parms{quote_precision};
  $parms{auto_proxy}       = 1  unless exists  $parms{auto_proxy};
  $parms{debug}            = 0  unless defined $parms{debug};

  my $self = \%parms;
  bless $self, $class;

  my $ua_params = $parms{ua_params} || {};
  if ($parms{env_proxy}) {
    $ua_params->{env_proxy} = 1;
  }
  elsif ($parms{auto_proxy}) {
    $ua_params->{env_proxy} = 1 if $ENV{http_proxy};
  }
  $self->{ua} ||= LWP::UserAgent->new(%$ua_params);

  if ($self->granularity !~ /^d/i) {
    $start_date = $self->snap_start_date($start_date);
    $end_date   = $self->snap_end_date($end_date);
  }

  $self->start_date($start_date);
  $self->end_date($end_date);
  $self->symbols(@$symbols);

  # These are used for constructing method names for target types.
  $self->{target_order} = [qw(quote split dividend)];
  grep($self->{targets}{$_} = "${_}s", @{$self->{target_order}});

  $self;
}

### User interface stubs

sub quotes    { shift->getter(target_mode => 'quote')->()    }
sub dividends { shift->getter(target_mode => 'dividend')->() }
sub splits    { shift->getter(target_mode => 'split')->()    }
sub intraday  { shift->getter(target_mode => 'intraday')->() }

*intraday_quotes = *intraday;

sub target_worthy {
  my $self = shift;
  my %parms = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;
  # forcing url_maker into a boolean role here, using a dummy symbol
  my $capable = $self->url_maker(
    %parms,
    target_mode => $target_mode,
    parse_mode  => $parse_mode,
    symbol      => 'waggledance',
  );
  my $worthy = $capable && UNIVERSAL::isa($capable, 'CODE');
  if ($self->{verbose}) {
    print STDERR "Seeing if ", ref $self,
                 " can get ($target_mode, $parse_mode) : ",
                 $worthy ? "yes\n" : "no\n";
  }
  $worthy;
}

sub granularities { qw( daily ) }

### Data retrieval

sub ua {
  my $self = shift;
  @_ ? $self->{ua} = shift : $self->{ua};
}

sub fetch {
  # HTTP::Request and LWP::UserAgent Wrangler
  my($self, $request) = splice(@_, 0, 2);
  $request or croak "Request or URL required\n";

  if (! ref $request || ! $request->isa('HTTP::Request')) {
    $request = HTTP::Request->new(GET => $request);
  }

  my $trys = $self->{attempts};
  my $response = $self->ua->request($request, @_);
  $self->{_lwp_success} = 0;
  while (! $response->is_success) {
    last unless $trys;
    $self->{_lwp_status}  = $response->status_line;
    print STDERR "Bad fetch",
       $response->is_error ? ' (' . $response->status_line . '), ' : ', ',
       "trying again...\n" if $self->{debug};
    $response = $self->ua->request($request, @_);
    --$trys;
  }
  $self->{_lwp_success} = $response->is_success;
  return undef unless $response->is_success;
  print STDERR 'Fetch complete. (' . length($response->content) . " chars)\n"
    if $self->{verbose};
  $response->content;
}

sub getter {
  # closure factory to get results for a particular target_mode and
  # parse_mode
  my $self = shift;

  my %parms = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;
  my @column_labels = $self->labels(
    %parms, target_mode => $target_mode, parse_mode  => $parse_mode
  );
  my %extractors = $self->extractors(
    %parms, target_mode => $target_mode, parse_mode  => $parse_mode
  );

  # return our closure
  sub {
    my @symbols = @_ ? @_ : $self->symbols;

    my @rows;

    # cache check
    my @not_seen;
    foreach my $symbol (@symbols) {
      my @r = $self->result_rows($target_mode, $symbol);
      if (@r) {
        push(@rows, @r);
      }
      else {
        push(@not_seen, $symbol);
      }
    }
    return @rows unless @not_seen;

    my $original_target_mode = $self->target_mode;
    my $original_parse_mode  = $self->parse_mode;

    $self->target_mode($target_mode);
    $self->parse_mode($parse_mode);

    my $dcol = $self->label_column('date');
    my(%empty_fetch, %saw_good_rows);
    my $last_data = '';

    my $target_worthy = $self->target_worthy(
      %parms,
      target_mode => $target_mode,
      parse_mode  => $parse_mode
    );
    if (!$target_worthy) {
      # make sure and empty @symbols
      ++$empty_fetch{$_} while $_ = pop @symbols;
    }

    SYMBOL: foreach my $s (@symbols) {
      my $urlmaker = $self->url_maker(
        target_mode => $target_mode,
        parse_mode  => $parse_mode,
        symbol      => $s,
      );
      UNIVERSAL::isa($urlmaker, 'CODE') or croak "urlmaker not a code ref.\n";
      my $so_far_so_good = 0;
      URL: while (my $url = $urlmaker->()) {
        if ($empty_fetch{$s}) {
          print STDERR ref $self,
             " passing on $s ($target_mode) for now, empty fetch\n"
             if $self->{verbose};
          last URL;
        }

        if ($self->{verbose}) {
          my $uri = $url;
          $uri = $url->uri if UNIVERSAL::isa($url, 'HTTP::Request');
          print STDERR "Processing ($s:$target_mode) $uri\n";
        }

        # We're a bit more persistent with quotes. It is more suspicious
        # if we get no quote rows, but it is nevertheless possible.
        my $trys = $target_mode eq 'quote' ? $self->{attempts} : 1;
        my $initial_trys = $trys;
        my($data, $rows) = ('', []);
        do {
          print STDERR "$s Trying ($target_mode) again due to no rows...\n"
            if $self->{verbose} && $trys != $initial_trys;
          if (!($data = $self->{url_cache}{$url})) {
            $data = $self->fetch($url);
            if (my $pre_parser = $self->pre_parser) {
              $data = $pre_parser->(
                $data,
                target_mode => $target_mode,
                parse_mode  => $parse_mode,
              );
            }
          }
          # make sure our url_maker hasn't sent us into a twister
          if ($data && $data eq $last_data) {
            print STDERR "Redundant data fetch, assuming end of URLs.\n"
              if $self->{verbose};
            last URL;
          }
          else {
            $last_data = defined $data ? $data : '';
          }
          $rows = $self->rows($self->parser->($data));
          last URL if $so_far_so_good && !@$rows;
          --$trys;
        } while !@$rows && $trys && $self->{_lwp_success};
        $so_far_so_good = 1;

        if ($target_mode ne 'quote' || $target_mode ne 'intraday') {
          # We are not very stubborn about dividends and splits right
          # now. This is because we cannot prove a successful negative
          # (i.e., say there were no dividends or splits over the time
          # period...or perhaps there were, but it is a defunct
          # symbol...whatever...quotes should always be present unless
          # they are defunct, which is dealt with later.
          if (!$self->{_lwp_success} || !$data) {
            ++$empty_fetch{$s};
            @$rows = ();
          }
          elsif ($self->{_lwp_success} && !@$rows) {
            ++$empty_fetch{$s};
          }
        }

        # Raw cache
        $self->{url_cache}{$url} = $data;
  
        # Extraction filters. This is an opportunity to extract rows
        # that are not what we are looking for, but contain valuable
        # information nevertheless. An example of this would be the
        # split and dividend rows you see in Yahoo HTML quote output. An
        # extraction filter method should expect an array ref as an
        # argument, representing a single row, and should return another
        # array ref with extracted output. If there is a return value,
        # then this row will be filtered from the primary output.
        my(%extractions, $ecount, $rc);
        $rc = @$rows;
        if (%extractors) {
          my(@filtered, $row);
          while ($row = pop(@$rows)) {
            my $erow;
            foreach my $mode (sort keys %extractors) {
              $extractions{$mode} ||= [];
              my $em = $extractors{$mode};
              if ($erow = $em->($row)) {
                print STDERR "$s extract ($mode) got $s, ",
                   join(', ', @$erow), "\n" if $self->{verbose};
                push(@{$extractions{$mode}}, [@$erow]);
                ++$ecount;
                last;
              }
            }
            push(@filtered, $row) unless $erow;
          }
          if ($self->{verbose} && $ecount) {
            print STDERR "$s Trimmed to ",$rc - $ecount,
               " rows after $ecount extractions.\n";
          }
          $rows = \@filtered;
        }

        if ($extractions{$target_mode}) {
          $rows = [@{$extractions{$target_mode}}];
          print STDERR "Coopted to ", scalar @$rows,
            " rows after $target_mode extraction redundancy.\n"
            if $self->{verbose};
        }

        if (@$rows) {
          # Normalization steps

          if ($target_mode eq 'split') {
            if (@{$rows->[0]} == 2) {
              foreach (@$rows) {
                if ($_->[-1] =~ /(split\s+)?(\d+)\D+(\d+)/is) {
                  splice(@$_, -1, 1, $2, $3);
                }
              }
            }
          }

          # Saving the rounding operations until after the adjust
          # routine is deliberate since we don't want to be auto-
          # adjusting pre-rounded numbers.
          $self->number_normalize_rows($rows);
  
          # Do the same for the extraction rows, plus store the
          # extracted rows
          foreach my $mode (keys %extractions) {
            # _store_results splices each row...don't do it twice
            next if $mode eq $target_mode;
            $self->target_mode($mode);
            $self->number_normalize_rows($extractions{$mode});
            $self->_target_source($mode, $s, ref $self);
            $self->_store_results($mode, $s, $dcol, $extractions{$mode});
          }
          # restore original target mode
          $self->target_mode($target_mode);
  
          if ($target_mode eq 'quote' || $target_mode eq 'intraday') {
            my $count = @$rows;
            @$rows = grep($self->is_quote_row($_) &&
                          $self->row_not_seen($s, $_), @$rows);
            if ($self->{verbose}) {
              if ($count == @$rows) {
                print STDERR "$s Retained $count rows\n";
              }
              else {
                print STDERR "$s Retained $count raw rows, trimmed to ",
                  scalar @$rows, " rows due to noise\n";
              }
            }
  
          }
          if ($target_mode eq 'quote') {
            # zcount is an attempt to capture null values; if there are
            # too many we assume there is something wrong with the
            # remote data
            my $close_col = $self->label_column('close');
            my($zcount, $hcount) = (0,0);
            foreach (@$rows) {
              foreach (@$_) {
                # Sometimes N/A appears
                s%^\s*N/A\s*$%%;
              }
              my $q = $_->[$close_col];
              if (defined $q && $q =~ /\d+/) { ++$hcount }
              else                            { ++$zcount }
            }
            my $pct = $hcount ? 100 * $zcount / ($zcount + $hcount) : 100;
            if (!$trys || $pct >= $self->{zthresh}) {
              ++$empty_fetch{$s} unless $saw_good_rows{$s};
            }
            else {
              # For defunct symbols, we could conceivably get quotes
              # over a date range that contains blocks of time where the
              # ticker was actively traded, as well as blocks of time
              # where the ticker doesn't exist. If we got good data over
              # some of the blocks, then we take note of it so we don't
              # toss the whole set of queries for this symbol.
              ++$saw_good_rows{$s};
            }
            $self->precision_normalize_rows($rows)
              if @$rows && $self->{quote_precision};
          }

          last URL if !$ecount && !@$rows;
          $self->_store_results($target_mode, $s, $dcol, $rows) if @$rows;
          $self->_target_source($target_mode, $s, ref $self);
        }
      }
    }

    $self->_store_empty_fetches([keys %empty_fetch]);
  
    # Check for bad fetches. If we failed on some symbols, punt them to
    # our champion class.
    if (%empty_fetch) {
      my @bad_symbols = $self->empty_fetches;
      my @champion_classes = $self->lineup;
      while (@champion_classes && @bad_symbols) {
        print STDERR "Bad fetch for ", join(',', @bad_symbols), "\n"
          if $self->{verbose} && $target_worthy;
        my $champion =
          $self->_summon_champion(shift @champion_classes, @bad_symbols);
        next unless $champion &&
                    $champion->target_worthy(target_mode => $target_mode);
        print STDERR ref $champion, ", my hero!\n" if $self->{verbose};
        # Hail Mary
        $champion->getter(target_mode => $target_mode)->();
        # Our champion was the source for these symbols (including
        # extracted info).
        foreach my $mode ($champion->result_modes) {
          foreach my $symbol ($champion->result_symbols($mode)) {
            $self->_target_source($mode, $symbol, ref $champion);
            $self->_copy_results($mode, $symbol,
                                 $champion->results($mode, $symbol));
          }
        }
        @bad_symbols = $champion->empty_fetches;
      }
      if (@bad_symbols && !$self->{quiet}) {
        print STDERR "WARNING: Could not fetch $target_mode for some symbols (",join(', ', @bad_symbols), "). Abandoning request for these symbols.";
        if ($target_mode ne 'quote') {
          print STDERR " Don't worry, though, we were looking for ${target_mode}s. These are less likely to exist compared to quotes.";
        }
        if ($self->{_lwp_status}) {
          print STDERR "\n\nLast status: $self->{_lwp_status}\n";
        }
        print STDERR "\n";
      }
    }
  
    $self->target_mode($original_target_mode);
    $self->parse_mode($original_parse_mode);

    @rows = $self->result_rows($target_mode);
    if ($self->{verbose}) {
      print STDERR "Class ", ref $self, " returning ", scalar @rows,
         " composite rows.\n";
    }

    # Return the loot.
    wantarray ? @rows : \@rows;
  };
}

sub _store_results {
  my($self, $mode, $symbol, $dcol, $rows) = @_;
  foreach my $row (@$rows) {
    my $date = splice(@$row, $dcol, 1);
    $self->{results}{$mode}{$symbol}{$date} = $row;
  }
}

sub _copy_results {
  my($self, $mode, $symbol, $results) = @_;
  foreach my $date (sort keys %$results) {
    $self->{results}{$mode}{$symbol}{$date} = [@{$results->{$date}}];
  }
}

sub result_rows {
  my($self, $target_mode, @symbols) = @_;
  $target_mode ||= $self->target_mode;
  @symbols = $self->result_symbols($target_mode) unless @symbols;
  my @rows;
  foreach my $symbol (@symbols) {
    my $results = $self->results($target_mode, $symbol);
    foreach my $date (sort keys %$results) {
      push(@rows, [$symbol, $date, @{$results->{$date}}]);
    }
  }
  sort { $a->[1] cmp $b->[1] } @rows;
}

sub _store_empty_fetches {
  my $self = shift;
  my $ref = shift || [];
  @$ref = sort @$ref;
  $self->{empty_fetches} = $ref;
}

sub empty_fetches {
  my $self = shift;
  return () unless $self->{empty_fetches};
  @{$self->{empty_fetches}} 
}

sub extractors { () }

sub rows {
  my($self, $rows) = @_;
  return wantarray ? () : [] unless $rows;
  my $rc = @$rows;
  print STDERR "Got $rc raw rows\n" if $self->{verbose};

  # Load user filter if present
  my $row_filter = $self->row_filter;

  # Prep the rows
  foreach my $row (@$rows) {
    $row_filter->($row) if $row_filter;
    foreach (@$row) {
      # Zap leading and trailing white space
      next unless defined;
      s/^\s+//; s/\s+$//;
    }
  }
  # Pass only rows with a valid date that is in range (and store the
  # processed value while we are at it)
  my $target_mode = $self->target_mode;
  my @date_rows;
  my $dcol = $self->label_column('date');
  my $tcol = $self->label_column('time') if $target_mode eq 'intraday';
  my $r;
  while($r = pop @$rows) {
    my $date = $r->[$dcol];
    if ($target_mode eq 'intraday') {
      my $time = splice(@$r, $tcol, 1);
      $date = join('', $date, $time);
    }
    $date = $self->date_normalize($date);
    unless ($date) {
      print STDERR "Reject row (no date): '$r->[$dcol]'\n" if $self->{verbose};
      next;
    }
    next unless $self->date_in_range($date);
    $r->[$dcol] = $date;
    push(@date_rows, $r);
  }

  print STDERR "Trimmed to ", scalar @date_rows, " applicable date rows\n"
    if $self->{verbose} && @date_rows != $rc;

  return wantarray ? @date_rows : \@date_rows;
}

### Adjustment triggers and manipulation

sub adjuster {
  # In order to be an adjuster, it must first be enabled. In addition,
  # there has to be a column specified as the adjusted value. This is
  # not as generic as I would like it, but so far it's just for
  # Yahoo...it should work for any site with "adj" in the column
  # label...this column should be the adjusted closing value.
  my $self = shift;
  return 0 if !$self->{adjusted};
  foreach ($self->labels) {
    return 1 if /adj/i;
  }
  0;
}

sub adjusted { shift->{adjusted} ? 1 : 0 }

### Bulk manipulation filters

sub date_normalize_rows {
  # Place dates into a consistent format, courtesy of Date::Manip
  my($self, $rows, $dcol) = @_;
  $dcol = $self->label_column('date') unless defined $dcol;
  foreach my $row (@$rows) {
    $row->[$dcol] = $self->date_normalize($row->[$dcol]);
  }
  $rows;
}

sub date_normalize {
  my($self, $date) = @_;
  return unless $date;
  my $normal_date;
  if ($self->granularity =~ /^m/ && $date =~ m{^\s*(\D+)[-/]+(\d{2,})\s*$}) {
    my($m, $y) = ($1, $2);
    $y += 1900 if length $y == 2;
    $normal_date = ParseDate($m =~ /^\d+$/ ? "$y/$m/01" : "$m 01 $y");
  }
  else {
    $normal_date = ParseDate($date);
  }
  $normal_date or return undef;
  return $normal_date if $self->target_mode eq 'intraday';
  join('/', $self->ymd($normal_date));
}

sub snap_start_date {
  my($self, $date) = @_;
  my $g = $self->granularity;
  if ($g =~ /^(m|w)/i) {
    if ($1 eq 'm') {
      my($dom) = UnixDate($date, '%d') - 1;
      $date = DateCalc($date, "- $dom days") if $dom;
    }
    else {
      my $dow = Date_DayOfWeek(UnixDate($date, '%m', '%d', '%Y')) - 1;
      $date = DateCalc($date, "- $dow days") if $dow;
    }
  }
  $date;
}

sub snap_end_date {
  my($self, $date) = @_;
  my $g = $self->granularity;
  if ($g =~ /^(m|w)/i) {
    if ($1 eq 'm') {
      my($m, $y) = UnixDate($date, '%m', '%Y');
      my $last = Date_DaysInMonth($m, $y);
      $date = ParseDateString("$y$m$last");
    }
    else {
      my $dow = Date_DayOfWeek(UnixDate($date, '%m', '%d', '%Y')) - 1;
      $date = DateCalc($date, "+ " . (6 - $dow) . ' days')
        unless $dow == 6;
    }
  }
  $date;
}

sub number_normalize_rows {
  # Strip non-numeric noise from numeric fields
  my($self, $rows, $dcol) = @_;
  $dcol = $self->label_column('date') unless defined $dcol;
  # filtered rows might not have same columns
  my @cols = grep($_ != $dcol, 0 .. $#{$rows->[0]});
  foreach my $row (@$rows) {
    s/[^\d\.]//go foreach @{$row}[@cols];
  }
  $rows;
}

sub precision_normalize_rows {
  # Round off numeric fields, if requested (%.4f by default). Volume
  # is the exception -- we just round that into an integer. This
  # should probably only be called for 'quote' targets because it
  # knows details about where the numbers of interest reside.
  my($self, $rows) = @_;
  my $target_mode = $self->target_mode;
  croak "precision_normalize invoked in '$target_mode' mode rather than 'quote'  or 'intraday' mode.\n"
    unless $target_mode eq 'quote' || $target_mode eq 'intraday';
  my @columns;
  if ($target_mode ne 'intraday') {
    @columns = $self->label_column(qw(open high low close));
    push(@columns, $self->label_column('adj')) if $self->adjuster;
  }
  else {
    @columns = $self->label_column(qw(high low close));
  }
  my $vol_col = $self->label_column($Default_Vol_Pat);
  foreach my $row (@$rows) {
    $row->[$_] = sprintf("%.$self->{quote_precision}f", $row->[$_])
      foreach @columns;
    $row->[$vol_col] = int $row->[$vol_col];
  }
  $rows;
}

### Single row filters

sub is_quote_row {
  my($self, $row, $dcol) = @_;
  ref $row or croak "Row ref required\n";
  # Skip date in first field
  $dcol = $self->label_column('date') unless defined $dcol;
  foreach (0 .. $#$row) {
    next if $_ == $dcol;
    next if $row->[$_] =~ /^\s*$/;
    if ($row->[$_] !~ /^\s*\$*[\d\.,]+\s*$/) {
      return 0;
    }
  }
  1;
}

sub row_not_seen {
  my($self, $symbol, $row, $dcol) = @_;
  ref $row or croak "Row ref required\n";
  $symbol or croak "ticker symbol required\n";
  my $mode = $self->target_mode;
  my $res = $self->{results}{$mode} or return 1;
  my $mres = $res->{$symbol} or return 1;
  $dcol = $self->label_column('date') unless defined $dcol;
  $mres->{$row->[$dcol]} or return 1;
  return 0;
}

sub date_in_range {
  my $self = shift;
  my $date = shift;
  $date = $self->date_standardize($date) or return undef;
  return 0 if $self->{start_date} && $date lt $self->{start_date};
  return 0 if $self->{end_date}   && $date gt $self->{end_date};
  1;
}

### Label and label mapping/extraction management

sub default_target_mode { $Default_Target_Mode }
sub default_parse_mode  { $Default_Parse_Mode  }
sub default_granularity { $Default_Granularity }

sub set_label_pattern {
  my $self = shift;
  my %parms = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;
  my $label = $parms{label};
  croak "Column label required\n" unless $label;
  my $l2p = $self->{_label_pat}{$target_mode}{$parse_mode} ||= {};
  my $p2l = $self->{_pat_label}{$target_mode}{$parse_mode} ||= {};
  my $pattern = $parms{pattern};
  if ($pattern) {
    $l2p->{$label} = $pattern;
    delete $self->{label_map};
    delete $self->{pattern_map};
  }
  my $pat = $l2p->{$label} ||= ($label =~ $Default_Vol_Pat ?
                                  qr/\s*$label/i : qr/^\s*$label/i);
  $p2l->{$pat} ||= $label;
  $pat;
}

sub label_pattern {
  my $self = shift;
  my $target_mode = $self->target_mode;
  my $parse_mode  = $self->parse_mode;
  my $label = shift;
  croak "column label required\n" unless $label;
  my $l2p = $self->{_label_pat}{$target_mode}{$parse_mode} ||= {};
  my $pat = $l2p->{$label} || $self->set_label_pattern(label => $label);
  $pat;
}

sub label_column {
  my $self = shift;
  my @cols;
  if (!$self->{label_map}) {
    delete $self->{pattern_map};
    my @labels = $self->labels;
    foreach my $i (0 .. $#labels) {
      $self->{label_map}{$labels[$i]} = $i;
    }
  }
  foreach (@_) {
    croak "Unknown label '$_'\n" unless exists $self->{label_map}{$_};
    push(@cols, $self->{label_map}{$_});
  }
  unless (wantarray) {
    croak "multiple columns in scalar context\n" if @cols > 1;
    return $cols[0];
  }
  @cols;
}

sub pattern_column {
  my $self = shift;
  if (!$self->{pattern_map}) {
    my @patterns = $self->patterns;
    foreach my $i (0 .. $#patterns) {
      $self->{pattern_map}{$patterns[$i]} = $i;
    }
  }
  return unless @_;
  my $pattern = shift;
  croak "Unknown pattern '$pattern'\n" unless $self->{_pat_map}{$pattern};
  $self->{pattern_map{$pattern}};
}

sub pattern_map {
  my $self = shift;
  $self->pattern_column unless $self->{pattern_map};
  $self->{pattern_map};
}

sub label_map {
  my $self = shift;
  $self->label_column unless $self->{label_map};
  $self->{label_map};
}

sub pattern_label {
  my $self = shift;
  my %parms = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;
  my $pat = $parms{pattern} or croak "pattern required for label lookup\n";
  my $p2l = $self->{_pat_label}{$target_mode}{$parse_mode} ||= {};
  my $label = $p2l->{$pat};
  unless (defined $label) {
    delete $parms{pattern};
    $self->set_label_pattern(%parms, label => $_) foreach $self->labels;
  }
  $label;
}

sub patterns {
  my $self = shift;
  my %parms = @_;
  $parms{target_mode} ||= $self->target_mode;
  $parms{parse_mode}  ||= $self->parse_mode;
  map($self->label_pattern($_), $self->labels(%parms));
}

sub columns {
  my $self = shift;
  my %parms = @_;
  $parms{target_mode} ||= $self->target_mode;
  $parms{parse_mode}  ||= $self->parse_mode;
  $self->label_column($self->labels(%parms));
}

sub default_labels {
  my $self = shift;
  my %parms = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $tm = $Default_Labels{$target_mode};
  unless ($tm) {
    $tm = $Default_Labels{$self->default_target_mode};
  }
  my $parse_mode = $parms{parse_mode} || $self->parse_mode;
  my $labels = $tm->{$parse_mode};
  unless ($labels) {
    $labels = $tm->{$self->default_parse_mode};
  }
  @$labels;
}

sub labels {
  my $self  = shift;
  my %parms = @_;
  my $target_mode = $parms{target_mode} || $self->target_mode;
  my $parse_mode  = $parms{parse_mode}  || $self->parse_mode;
  my $tm = $self->{_labels}{$target_mode};
  if ($parms{labels} || ! $tm->{$parse_mode}) {
    delete $self->{label_map};
    delete $self->{pattern_map};
  }
  $tm->{$parse_mode} = $parms{labels} if $parms{labels};
  my $labels = $tm->{$parse_mode} ||= [$self->default_labels(
                                         target_mode => $target_mode,
                                         parse_mode  => $parse_mode)];
  @$labels;
}

sub parse_mode {
  my $self = shift;
  if (@_) {
    $self->{parse_mode} = shift;
  }
  $self->{parse_mode} || $self->default_parse_mode;
}

sub target_mode {
  my $self = shift;
  if (@_) {
    $self->{target_mode} = shift;
  }
  $self->{target_mode} || $self->default_target_mode;
}

sub granularity {
  my $self = shift;
  if (@_) {
    $self->{granularity} = shift;
  }
  $self->{granularity} || $self->default_granularity;
}

sub lineup {
  my $self = shift;
  $self->{lineup} = \@_ if @_;
  return unless $self->{lineup};
  @{$self->{lineup}};
}

### Parser methods

sub pre_parser {
  my($self, %parms) = @_;
  my $parse_mode = $parms{parse_mode} || $self->parse_mode;
  my $method = "${parse_mode}_pre_parser";
  return unless $self->can($method);
  $self->$method(%parms, parse_mode => $parse_mode);
}

sub parser {
  my($self, %parms) = @_;
  my $parse_mode = $parms{parse_mode} || $self->parse_mode;
  my $make_parser = "${parse_mode}_parser";
  $self->$make_parser(%parms, parse_mode => $parse_mode);
}

sub html_parser {
  # HTML::TableExtract supports automatic column reordering.
  my $self = shift;
  my $class = HTML_CLASS;
  my @labels = $self->labels(@_);
  my @patterns = $self->patterns(@_);
  my(%pat_map, %label_map);
  $pat_map{$patterns[$_]} = $_ foreach 0 .. $#patterns;
  $label_map{$labels[$_]} = $_ foreach 0 .. $#labels;
  $self->pattern_map(\%pat_map);
  $self->label_map(\%label_map);
  sub {
    my $data = shift;
    my $html_string;
    if (ref $data) {
      local($/);
      $html_string = <$data>;
    }
    else {
      $html_string = $data;
    }
    my %te_parms = (
      headers => \@patterns,
      automap => 1,
    );
    $te_parms{debug} = $self->{debug} if $self->{debug} > 2;
    my $te = $class->new(%te_parms) or croak "Problem creating $class\n";
    $te->parse($html_string);
    $te->eof;
    my $ts = $te->first_table_found;
    [ $ts ? $ts->rows() : ()];
  }
}

sub csv_parser {
  # Text::CSV_XS doesn't column slice or re-order, so we do.
  my $self = shift;
  my @patterns = $self->patterns(@_);
  sub {
    my $data = shift;
    return [] unless defined $data;
    my @csv_lines = ref $data ? <$data> : split("\n", $data);
    # BOM squad (byte order mark, as csv from google tends to be)
    if ($csv_lines[0] =~ s/^\xEF\xBB\xBF//) {
      for my $i (0 .. $#csv_lines) {
        utf8::decode($csv_lines[$i]);
      }
    }
    # might be unix, windows, or mac style newlines
    s/\s+$// foreach @csv_lines;
    return [] if !@csv_lines || $csv_lines[0] =~ /(no data)|error/i;
    # attempt to get rid of comments at front of csv data
    while (@csv_lines) {
      last if $csv_lines[0] =~ /date/i || $csv_lines[0] =~ /\d+$/;
      print STDERR "CSV reject line: $csv_lines[0]\n" if $self->{verbose};
      shift @csv_lines;
    }
    my $first_line = $csv_lines[0];
    my $sep_char = $first_line =~ /date\s*(\S)/i ? $1 : ',';
    my $cp = $CSV_Class->new({sep_char => $sep_char, binary => 1})
      or croak "Problem creating $CSV_Class\n";
    my @pat_slice;
    if ($first_line =~ /date/i) {
      # derive column detection and ordering
      $cp->parse($first_line) or croak ("Problem parsing (" .
        $cp->error_input . ") : " . $cp->error_diag . "\n");
      my @headers = $cp->fields;
      my @pats = @patterns;
      my @labels = map($self->pattern_label(pattern => $_), @patterns);
      my(%pat_map, %label_map);
      HEADER: for my $i (0 .. $#headers) {
        last unless @pats;
        my $header = $headers[$i];
        for my $pi (0 .. $#pats) {
          my $pat = $pats[$pi];
          if ($header =~ /$pat/) {
            my $label = $labels[$pi];
            splice(@pats,   $pi, 1);
            splice(@labels, $pi, 1);
            $pat_map{$pat} = $i;
            $label_map{$label} = $i;
            next HEADER;
          }
        }
      }
      shift @csv_lines;
      @pat_slice = map($pat_map{$_}, @patterns);
    }
    else {
      # no header row, trust natural order and presence
      @pat_slice = 0 .. $#patterns;
    }
    my @rows;
    foreach my $line (@csv_lines) {
      $cp->parse($line) or next;
      my @fields = $cp->fields;
      push(@rows, [@fields[@pat_slice]]);
    }
    \@rows;
  };
}

### Accessors, generators

sub start_date {
  my $self = shift;
  if (@_) {
    my $start_date = shift;
    my $clear = @_ ? shift : 1;
    $self->clear_cache if $clear;
    $self->{start_date} = defined $start_date ?
      $self->date_standardize($start_date) : undef;
  }
  $self->{start_date};
}

sub end_date {
  my $self = shift;
  if (@_) {
    my $end_date = shift;
    my $clear = @_ ? shift : 1;
    $self->clear_cache if $clear;
    $self->{end_date} = defined $end_date ?
      $self->date_standardize($end_date) : undef;
  }
  $self->{end_date};
}

sub date_standardize {
  my($self, @dates) = @_;
  return unless @dates;
  foreach (@dates) {
    $_ = ParseDate($_) or Carp::confess "Could not parse date '$_'\n";
    s/\d\d:.*//;
  }
  @dates > 1 ? @dates : ($dates[0]);
}

sub mydates {
  my $self = shift;
  $self->dates($self->{start_date}, $self->{end_date});
}

sub dates {
  my($self, $sdate, $edate) = @_;
  $sdate && $edate or croak "Start date and end date strings required\n";
  my($sd, $ed) = sort($self->date_standardize($sdate, $edate));
  my @dates;
  push(@dates, $sd) if Date_IsWorkDay($sd);
  my $cd = $self->date_standardize(Date_NextWorkDay($sd, 1));
  while ($cd <= $ed) {
    push(@dates, $cd);
    $cd = $self->date_standardize(Date_NextWorkDay($cd));
  }
  @dates;
}

sub symbols {
  my($self, @symbols) = @_;
  if (@symbols) {
    my %seen;
    grep(++$seen{$_}, grep(uc $_, @symbols));
    $self->{symbols} = [sort keys %seen];
    $self->clear_cache;
  }
  @{$self->{symbols}};
}

sub successors {
  my $self = shift;
  @{$self->{successors}};
}

sub clear_cache {
  my $self = shift;
  delete $self->{url_cache};
  delete $self->{results};
  1;
}

sub result_modes {
  my $self = shift;
  return () unless $self->{results};
  sort keys %{$self->{results}};
}

sub result_symbols {
  my($self, $target_mode) = @_;
  $target_mode ||= $self->target_mode;
  return () unless $self->{sources}{$target_mode};
  sort keys %{$self->{results}{$target_mode}};
}

sub results {
  my($self, $target_mode, $symbol) = @_;
  $self->{results}{$target_mode}{$symbol};
}

sub quote_source    { shift->source(shift, 'quote')    }
sub dividend_source { shift->source(shift, 'dividend') }
sub split_source    { shift->source(shift, 'split')    }
sub intraday_source { shift->source(shift, 'intraday') }

sub row_filter { shift->{row_filter} }

sub source {
  my($self, $symbol, $target_mode) = @_;
  croak "Ticker symbol required\n" unless $symbol;
  $target_mode ||= $self->target_mode;
  $self->{sources}{$target_mode}{$symbol} || '';
}

sub _target_source {
  my($self, $target_mode, $symbol, $source) = @_;
  croak "Target mode required\n"   unless $target_mode;
  croak "Ticker symbol required\n" unless $symbol;
  $symbol = uc $symbol;
  if ($source) {
    $self->{sources}{$target_mode}{$symbol} = $source;
  }
  $self->{sources}{$target_mode}{$symbol};
}

###

sub _summon_champion {
  # Instantiate the next class in line if this class failed in
  # fetching any quotes. Make sure and pass along the remaining
  # champions to the new champion.
  my($self, $champion_class, @bad_symbols) = @_;
  return undef unless ref $self->{lineup} && @{$self->{lineup}};
  print STDERR "Loading $champion_class\n" if $self->{verbose};
  eval "require $champion_class;";
  die $@ if $@;
  my $champion = $champion_class->new
    (
     symbols    => [@bad_symbols],
     start_date => $self->{start_date},
     end_date   => $self->{end_date},
     adjusted   => $self->{adjusted},
     verbose    => $self->{verbose},
     lineup     => [],
    );
  $champion;
}

### Toolbox

sub save_query    { shift->_save_restore_query(1) }
sub restore_query { shift->_save_restore_query(0) }
sub _save_restore_query {
  my($self, $save) = @_;
  $save = 1 unless defined $save;
  foreach (qw(parse_mode target_mode start_date end_date granularity quiet)) {
    my $qstr = "_query_$_";
    if ($save) {
      $self->{$qstr} = $self->{$_};
    }
    else {
      $self->{$_} = $self->{$qstr} if exists $self->{$qstr};
    }
  }
  $self;
}

sub ymd {
  my $self = shift;
  my @res = $_[0] =~ /^\s*(\d{4})(\d{2})(\d{2})/o;
  shift =~ /^\s*(\d{4})(\d{2})(\d{2})/o;
}

sub date_iterator {
  my $self = shift;
  my %parms = @_;
  my $start_date = $parms{start_date};
  my $end_date   = $parms{end_date} || 'today';
  my $increment  = $parms{increment};
  my $units      = $parms{units} || 'days';
  $increment && $increment > 0 or croak "Increment > 0 required\n";
  $start_date = ParseDate($start_date) if $start_date;
  $end_date   = ParseDate($end_date)   if $end_date;
  if ($start_date && $start_date gt $end_date) {
    ($start_date, $end_date) = ($end_date, $start_date);
  }
  my($low_date, $high_date);
  $high_date = $end_date;
  sub {
    return () unless $end_date;
    $low_date = DateCalc($high_date, "- $increment $units");
    if ($start_date && $low_date lt $start_date) {
      $low_date = $start_date;
      undef $start_date;
      undef $end_date;
      return () if $low_date eq $high_date;
    }
    my @date_pair = ($low_date, $high_date);
    $high_date = $low_date;
    @date_pair;
  }
}

1;

__END__

=head1 NAME

Finance::QuoteHist::Generic - Base class for retrieving historical stock quotes.

=head1 SYNOPSIS

  package Finance::QuoteHist::MyFavoriteSite;
  use strict;
  use vars qw(@ISA);
  use Finance::QuoteHist::Generic;
  @ISA = qw(Finance::QuoteHist::Generic);

  sub url_maker {
    # This method returns a code reference for a routine that, upon
    # repeated invocation, will provide however many URLs are necessary
    # to fully obtain the historical data for a given target mode and
    # parsing mode.
  }

=head1 DESCRIPTION

This is the base class for retrieving historical stock quotes. It is
built around LWP::UserAgent. Page results are currently parsed as either
CSV or HTML tables.

In order to actually retrieve historical stock quotes, this class should
be subclassed and tailored to a particular web site. In particular, the
C<url_maker()> factory method should be overridden, which provides a
code reference to a routine that provides however many URLs are
necessary to retrieve the data over a list of symbols within the given
date range, for a particular target (quotes, dividends, splits).
Different sites have different formats and different limitations on how
many quotes are returned for each query. See Finance::QuoteHist::Yahoo
for an example of how to do this.

For more complicated sites, such as Yahoo, overriding additional methods
might be necessary for dealing with things such as splits and dividends.

=head1 METHODS

=over

=item new()

Returns a new Finance::QuoteHist::Generic object.  Valid attributes
are:

=over

=item start_date

=item end_date

Specify the date range from which you would like historical quotes.
These dates get parsed by the C<ParseDate()> method in Date::Manip, so
see L<Date::Manip(3)> for more information on valid date strings. They
are quite flexible, and include such strings as '1 year ago'. Date
boundaries can also be dynamically set with methods of the same
name. The absence of a start date means go to the beginning of the
history. The absence of an end date means go up to the most recent
historical date. The absence of both means grab everything.

=item symbols

Indicates which ticker symbols to include in the search for historical
quotes. Passed either as a string (for single ticker) or an array ref
for multiple tickers.

=item granularity

Returns rows at 'daily', 'weekly', or 'monthly' levels of granularity.
Defaults to 'daily'.

=item attempts

Sets how persistently the module tries to retrieve the quotes. There are
two places this will manifest. First, if there are what appear to be
network errors, this many network connections are attempted for that
URL. Secondly, for quotes only, if pages were successfully retrieved,
but they contained no quotes, this number of attempts are made to
retrieve a document with data. Sometimes sites will report a temporary
internal error via HTML, and if it is truly transitory this will usually
get around it. The default is 3.

=item lineup

Passed as an array reference (or scalar for single class), this list
indicates which Finance::QuoteHist::Generic sub classes should be
invoked in the event this class fails in its attempt to retrieve
historical quotes. In the event of failure, the first class in this list
is invoked with the same parameters as the original class, and the
remaining classes are passed as the lineup to the new class. This sets
up a daisy chain of redundancy in the event a particular site is hosed.
See L<Finance::QuoteHist(3)> to see an example of how this is done in a
top level invocation of these modules. This list is empty by default.

=item quote_precision

Sets the number of decimal places to which quote values are rounded.
This might be of particular significance if there is auto-adjustment
taking place (which is only under particular circumstances
currently...see L<Finance::QuoteHist::Yahoo>). Setting this to 0 will
disable the rounding behavior, returning the quote values as they
appear on the sites (assuming no auto-adjustment has taken place). The
default is 4.

=item row_filter

When provided a subroutine reference, the routine is invoked with an
array reference for each raw row retrieved from the quote source. This
allows user-defined filtering or formatting for the items of each
row. This routine is invoked before any built-in routines are called
on the row. The array must be modified directly rather than returned
as a value. Use sparingly since the built-in filtering and
normalizing routines do expect each row to more or less look like
historical stock data. Rearranging the order of the columns in each row
is contraindicated.

=item env_proxy

When set, instructs the underlying LWP::UserAgent to load proxy
configuration information from environment variables. See the C<ua()>
method and L<LWP::UserAgent> for more information.

=item auto_proxy

Same as env_proxy, but tests first to see if $ENV{http_proxy} is
present.

=item verbose

When set, many status messages are printed to STDERR indicating
progression through URLs and lineup invocations.

=item quiet

When set, certain failure messages are suppressed from appearing on
STDERR. These messages would normally appear regardless the setting of
the C<verbose> flag.

=back

=back

The following methods are the primary user interface methods; methods
of interest to developers wishing to make their own site-specific
instance of this module will find information on overriding methods
further below.

=over

=item quotes()

Retrieves historical quotes for all provided symbols over the specified
date range. Depending on context, returns either a list of rows or an
array reference to the same list of rows.

=item dividends()

=item splits()

If available, retrieves dividend or split information for all provided
symbols over the specified date range. If there are no site-specific
subclassed modules in the B<lineup> capable of getting dividends or
splits, the user will be notified on STDERR unless the B<quiet> flag was
requested during object creation.

=item start_date(date_string)

=item end_date(date_string)

Set the date boundaries of all queries. The B<date_string> is
interpreted by the Date::Manip module. The absence of a start date means
retrieve back to the beginning of that ticker's history. The absence of
an end date means retrieve up to the latest date in the history.

=item clear_cache()

When results are gathered for a particular date range, whether they be
via direct query or incidental extraction, they are cached. This cache
is cleared by invoking this method directly, by resetting the boundary
dates of the query, or by changing the C<adjusted()> setting.

=item quote_source(ticker_symbol)

=item dividend_source(ticker_symbol)

=item split_source(ticker_symbol)

After query, these methods can be used to find out which particular
subclass in the B<lineup> fulfilled the corresponding request for a
particular ticker symbol.

=back

The following methods are the primary methods of interest for developers
wishing to make a site-specific subclass. The url_maker() factory is
typically all that is necessary.

=over

=item url_maker()

Returns a subroutine reference that serves as an iterrator for producing
URLs based on target and parse mode. Repeated calls to this routine
produce subsequent URLs in the sequence.

=item extractors()

For a particular target mode and parse mode, returns a hash containing
code references to extraction routines for the remaining targets. For
example, for target 'quote' in parse mode 'html' there might be
extractor routines for both 'dividend' and 'split'.

=item ua()

Accessor method for the LWP::UserAgent object used to process
HTTP::Request for individual URLs. This can be handy for such things as
configuring proxy access for the underlying user agent. Example:

 # Manual configuration
 $qh1->ua->proxy(['http'], 'http://proxy.sn.no:8001/');

 # Load from environment variables
 $qh2->ua->env_proxy();

See L<LWP::UserAgent> for more information on the capabilities
of that module.

=back

The following are potentially useful for calling within methods
overridden above:

=over

=item parse_mode($parse_mode)

Set the current parsing mode. Currently parsers are available for html
and csv.

=item target_mode($target_mode)

Return the current target mode.

=item dates($start_date, $end_date)

Returns a list of business days between and including the provided
boundary dates. If no arguments are provided, B<start_date> and
B<end_date> default to the currently specified date range.

=item labels(%parms)

Used to override the default labels for a given target mode and parse
mode. Takes the following named parameters:

=over

=item target_mode

Can currently be 'quote', 'dividend', or 'split'. Default is 'quote'.

=item parse mode

Can currently be 'csv' or 'html'. The default is typically 'csv' but
might vary depending on the quote source.

=item labels

The following are the default labels. Text entries convert to case-
insensitive regular expressions):

  target_mode
  -------------------------------------------------------
  quote    => ['date','open','high','low','close',qr(vol|shares)i]
  dividend => ['date','div']
  split    => ['date','post','pre']

=back

=back

=head1 DISCLAIMER

The data returned from these modules is in no way guaranteed, nor are
the developers responsible in any way for how this data (or lack
thereof) is used. The interface is based on URLs and page layouts that
might change at any time. Even though these modules are designed to be
adaptive under these circumstances, they will at some point probably be
unable to retrieve data unless fixed or provided with new parameters.
Furthermore, the data from these web sites is usually not even
guaranteed by the web sites themselves, and oftentimes is acquired
elsewhere. See the documentation for each site-specific module for more
information regarding the disclaimer for that site.

Above all, play nice.

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2000-2017 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Finance::QuoteHist(3), HTML::TableExtract(3), Date::Manip(3),
perlmodlib(1), perl(1).

=cut
