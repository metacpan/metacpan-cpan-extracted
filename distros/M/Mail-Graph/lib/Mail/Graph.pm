
package Mail::Graph;

# Read mail mbox files (compressed or uncompressed), and generate a
# statistic from it
# (c) by Tels 2002. See http://bloodgate.com/spams/ for an example.

use strict;
use GD::Graph::lines;
use GD::Graph::bars;
use GD::Graph::colour;
use GD::Graph::Data;
use GD::Graph::Error;
use Date::Calc 
  qw/Delta_Days Date_to_Days Today_and_Now Today check_date
     Delta_YMDHMS Add_Delta_Days
    /;
use Math::BigFloat lib => 'GMP';
use File::Spec;
use Compress::Zlib;		# for gzip file support
use Time::HiRes;

use vars qw/$VERSION/;

$VERSION = '0.14';

BEGIN
  {
  $| = 1;	# buffer off
  }

my ($month_table,$dow_table);

sub new
  {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->_init(@_);
  }

sub _init
  {
  my $self = shift;
  my $options = $_[0];

  $options = { @_ } unless ref $options eq 'HASH';

  $self->{_options} = $options;
  my $def = {
    input => 'archives',
    output => 'spams',
    items => 'spams',
    index => 'index/',
    height => 200,
    template => 'index.tpl',
    no_title => 0,
    filter_domains => [ ],
    filter_target => [ ],
    average => 7,
    average_daily => 14,
    graph_ext => 'png',
    first_date => undef,
    last_date => undef,
    valid_forwarders => undef,
    generate => {
      month => 1,
      yearly => 1,
      day => 1,
      daily => 1,
      dow => 1,
      monthly => 1,
      hour => 1,
      toplevel => 1,
      rule => 1,
      target => 1,
      domain => 1,
      last_x_days => 30,
      score_histogram => 5,
      score_daily => 60,
      score_scatter => 6,		# limit is 6
      },
    };
  
  foreach my $k (keys %$def)
    {
    $options->{$k} = $def->{$k} unless exists $options->{$k};
    }
  # accept only valid options
  foreach my $k (keys %$options)
    {
    die ("Unknown option '$k'") if !exists $def->{$k};
    }

  # try to create the output directory
  mkdir $options->{output} unless -d $options->{output};
  
  $options->{input} .= '/'
    if -d $options->{input} && $options->{input} !~ /\/$/;
  $self->{error} = undef;
  $self->{error} = "input '$options->{input}' is neither directory nor file"
   if ((! -d $options->{input}) && (!-f $options->{input}));
  $self->{error} = "output '$options->{output}' is not a directory"
   if (! -d $options->{output});
  return $self;
  }

sub error
  { 
  my $self = shift;
  return $self->{error};
  }

sub _process_mail
  {
  # takes one mail text and processes it
  # It will take it apart and store it in an index cache, which can be written
  # out to an index file, which later can be reread
  my ($self,$mail) = @_;

  my $cur = {
    target => 'unknown',
    domain => 'unknown',
    size => $mail->{size},
    };

  # split "From blah@bar.baz Datestring"
  if (!defined $mail->{header}->[0])
    {
    $cur->{invalid} = 'no_mail_header';
    return $cur;
    }
  # skip replies of the mailer-daemon to non-existant addresses
  if ($mail->{header}->[0] =~ /MAILER-DAEMON/i)
    {
    $cur->{invalid} = 'from_mailer_daemon';
    return $cur;
    }

  my ($a,$b,$c,$d);

  if ($mail->{header}->[0] =~  
  /^From [<]?(.+?\@)([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})[>]? (.*)/)
    {
    $cur->{from} = $1.$2;
    $cur->{toplevel} = 'undef';
    $cur->{date} = $3;
    }
  else
    {
    $mail->{header}->[0] =~ /^From [<]?(.+?\@)([a-zA-Z0-9\-\.]+?)(\.[a-zA-Z]{2,4})[>]? (.*)/;
    $a = $1 || 'undef';
    $b = $2 || 'undef';
    $c = $3 || 'undef';
    $d = $4 || 'undef';
    $cur->{from} = $a.$b.$c;
    $cur->{date} = $d;
    $cur->{toplevel} = lc($c);
    }
  if (!defined $cur->{date})
    {
    $cur->{invalid} = 'invalid_date';
    return $cur;
    }

  ($cur->{day},$cur->{month},$cur->{year},
    $cur->{dow},$cur->{hour},$cur->{minute},$cur->{second},$cur->{offset})
   = $self->_parse_date($cur->{date});

  if ((!defined $cur->{month}) || ($cur->{month} == 0))
    {
    $cur->{invalid} = 'invalid_month';
    return $cur;
    }
  if (! check_date($cur->{year},$cur->{month},$cur->{day}))
    {
    $cur->{invalid} = 'invalid_date_check';
    return $cur;
    }
 
  # Mktime() doesn't like these (they are probably forged, anyway) 
  if ($cur->{year} < 1970 || $cur->{year} > 2038)
    {
    $cur->{invalid} = 'before_1970_or_after_2038';
    return $cur;
    }
  
  # extract the filter rule that matched and also the SpamAssassin score
  my $filter_rule = $self->{_options}->{filter_rule} || 'X-Spamblock:';
  foreach my $line (@{$mail->{header}})
    {
    chomp($line);
    if ($line =~ /^$filter_rule/i)
      { 
      my $rule = lc($line); $rule =~ s/^[A-Za-z0-9:\s-]+//;
      $rule =~ s/^(kill|bounce), //;
      $rule =~ s/^, caught by //;
      $rule =~ s/^by //;
      $rule =~ s/^rule //;
      $rule =~ s/^, //;
      push @{$cur->{rule}}, $rule if $rule !~ /^\s*$/; 
      }
    else
      {
      next if $line !~ /^X-Spam-Status:/i;
      $line =~ /, hits=([0-9.]+)/;
      $cur->{score} = $1 || 0;
      }
    }
  
  ($cur->{target}, $cur->{domain}) =
    $self->_extract_target($mail->{header});

  $cur;
  }
      
sub _clear_index
  {
  my $self = shift;

  $self->{_index} = [];
  }

sub _index_mail
  {
  my ($self,$cur) = @_;

  push @{$self->{_index}}, $cur;
  }

sub _write_index
  {
  # write the index file for archive $file
  my ($self,$file,$stats) = @_;

  my $invalid = 0;
  # gather count of skipped mails
  foreach my $mail (@{$self->{_index}})
    {
    $invalid ++ if exists $mail->{invalid};
    }

  # get the filename alone, without directory et all
  my ($volume,$directories,$filename) = File::Spec->splitpath( $file );
  my $index_file = 
   File::Spec->catfile($self->{_options}->{index},$filename.'.idx.gz');
  
  unlink $index_file;			# delete old version

  my $gz = gzopen($index_file, "wb")
   or die "Cannot open $index_file: $gzerrno\n" ;

  $gz->gzwrite(
    "# Mail::Graph mail index file\n"
   ."# Automatically created on "
   . scalar localtime() . " by Mail::Graph v$VERSION\n"
   . "# To force re-indexing of $filename, delete this file.\n"
   . "items_skipped=$invalid\n"
   . "size_compressed=$stats->{stats}->{current_size_compressed}\n\n" );
 
  my $doc = ""; 
  foreach my $mail (@{$self->{_index}})
    {
    # don't include invalid mail
    next if exists $mail->{invalid};
    my $m = "";
    foreach my $key (qw/
       target size rule from score/)
      {
      if (ref($mail->{$key}) eq 'ARRAY')
        {
        foreach (@{$mail->{$key}})
	  {
          $m .= "$key=$_\n" if ($_||'') ne '';
          }
        }        
      else
        {
        # $mail->{$key} = '' unless defined $mail->{$key};
        $m .= "$key=$mail->{$key}\n" if ($mail->{$key} || '') ne '';
        }
      }
    if (($mail->{invalid} || 0) == 0)
      {
      eval {
      $m .= "date=" . Date::Calc::Mktime( 
	  $mail->{year},
	  $mail->{month},
	  $mail->{day},
	  $mail->{hour},
	  $mail->{minute},
	  $mail->{second}) . "\n";
        };
      }
#    else
#      {
#	print join(' ', $mail->{year}, 
#	$mail->{month},
#	$mail->{day},
#	$mail->{hour},
#	$mail->{minute},
#	$mail->{second}) . "\n";
#      require Data::Dumper; print Data::Dumper::Dumper($mail),"\n";
#      }
    if ($@ ne '')
      {
      require Data::Dumper; print Data::Dumper::Dumper($mail),"\n";
      die ($@);
      }
    $doc .= "$m\n";
    if (length($doc) > 8192)
      {
      $gz->gzwrite ( $doc ); $doc = "";
      }
    }
  $gz->gzwrite ( $doc ) if $doc ne '';
  $gz->gzclose();
  $self;
  }

sub _read_index
  {
  # read index file $index (or for archive $file) and return list of indexed
  # mails; also reads global counts and applies (adds) them to $stats
  my ($self,$file,$stats) = @_;

  $file .= '.idx' if $file !~ /\.idx(\.gz)?$/;

  my $index_file = 
   File::Spec->catfile($self->{_options}->{index},$file);
  
  $index_file .= '.gz' if -f "$index_file.gz";	# prefer compressed version

  # might be a bit slow to read in everything at once, but better than reading
  # the entire mail archive at once
  my $index = $self->_read_file($file);
  
  my @lines = @{ _split ($index); };
  
  if ($lines[0] !~ /^# Mail::Graph mail index file/)
    {
    warn ("$index_file doesn't look like a mail index, skipping");
    return ();
    }

  # read the "header" lines, e.g. the lines with global parameters
  my $line_nr = 0;
  foreach my $line (@lines)
    {
    $line_nr++;
    chomp($line);
    next if $line =~ /^#/;	# skip comments
    last if $line =~ /^\s*$/;	# end at first empty line
    if ($line !~ /^([A-Za-z0-9_-]+)=([0-9]+)\s*/)
      {
      warn ("malformed header line in index $index_file at line $line_nr");
      return ();
      }
    my $name = $1;
    my $value = $2;
    $stats->{stats}->{$name} += $value;
    }
 
  splice @lines, 0, $line_nr;		# remove first N lines

  my $cur = {}; 
  foreach my $line (@lines)
    {
    $line_nr++;
    chomp($line);
    next if $line =~ /^#/;	# skip comments
    if ($line =~ /^\s*$/)	# next mail at empty line
      {
      # disassemble the date field into the parts again
      ($cur->{year},$cur->{month},$cur->{day},
       $cur->{hour},$cur->{minute},$cur->{second},
       $cur->{doy},$cur->{dow},$cur->{dst}) =
	 Date::Calc::Localtime($cur->{date});
      # extract the target domain from the target field
      $cur->{domain} = $cur->{target};
      $cur->{domain} =~ /\@((.+?)\.(.+))$/; $cur->{domain} = $1 || 'unknown';
      # get the toplevel from target
      $cur->{toplevel} = $cur->{target};
      $cur->{toplevel} =~ /(\.[^.]+)$/; 
      $cur->{toplevel} = $1 || 'unknown';

      # remember this mail and move to the next one
      push @{$self->{_index}}, $cur;
      $cur = {};
      next;
      }
    if ($line !~ /^([A-Za-z0-9_-]+)=(.*)\s*/)
      {
      warn ("malformed line in index $index_file at line $line_nr");
      warn ("line '$line'");
      return ();
      }
    my $name = $1; my $value = $2 || '';
    if ($name eq 'rule')
      {
      # create array, but don't push empty values
      $cur->{rule} = [] unless exists $cur->{rule};
      push @{$cur->{rule}}, $value if $value ne '';
      }
    else
      {
      $cur->{$1} = $2 || '';
      }
    }
 
  return $self;
  }

sub _merge_mail
  {
  # take on mail in HASH format (read from index or processed from mail text)
  # and merge it in into $stats. $first is an optional first date, anything
  # earlier is discarded as invalid.
  my ($self,$cur,$stats,$now,$first) = @_;  

  $cur->{invalid} = $cur->{invalid} || '';
  
  if ($cur->{invalid} ne '')
    {
    $stats->{reasons}->{$cur->{invalid}}++;
    $stats->{stats}->{items_skipped}++; return;
    }

  # shortcut
  my ($year,$month,$day) = ($cur->{year}, $cur->{month}, $cur->{day});
  my ($hour,$minute,$second) = ($cur->{hour}, $cur->{minute}, $cur->{second});
  my ($dow) = $cur->{dow};

  if (!defined $year || !defined $month || !defined $day)
    {
    # huh?
    $stats->{reasons}->{invalid_date}++;
    $stats->{stats}->{items_skipped}++;
    return;
    }

  # mail is earlier than first_date?
  if (defined $first)
    {
    my $delta =
     Delta_Days($first->[0],$first->[1],$first->[2],$year,$month,$day);
    if ($delta < 0)
      {
      # too early
      $stats->{reasons}->{too_early}++;
      $stats->{stats}->{items_skipped}++;
      return;
      }
    }

  # mail is newer than last_date (or today)?
  my $delta = Delta_Days($year,$month,$day,$now->[0],$now->[1],$now->[2]);
  if ($delta < 0)
    {
    # mail newer
    $stats->{stats}->{items_skipped}++;
    $stats->{reasons}->{too_new}++;
    return;
    }

  $stats->{stats}->{items_processed}++;

  $stats->{target}->{$cur->{target}}++;
  $stats->{domain}->{$cur->{domain}}++;
      
  # XXX TODO include check for valid target domain

  my ($D_y,$D_m,$D_d, $Dh,$Dm,$Ds) =
   Delta_YMDHMS($year,$month,$day,$hour,$minute,$second, @$now);

  $stats->{stats}->{last_24_hours}++
    if ($D_y == 0 && $D_m == 0 && $D_d == 0 && $Dh < 24);
  $stats->{stats}->{last_7_days}++ if $delta <= 7;
  $stats->{stats}->{last_30_days}++ if $delta <= 30;
      
  $stats->{month}->{$year}->[$month-1]++;
  $stats->{hour}->{$year}->[$hour]++ if $hour >= 0 && $hour <= 23;
  $stats->{dow}->{$year}->[$dow-1]++;
  $stats->{day}->{$year}->[$day-1]++;
  $stats->{yearly}->{$year}++;
  $stats->{monthly}->{"$month/$year"}++;
  $stats->{daily}->{"$day/$month/$year"}++;
  my $l = $self->{_options}->{generate}->{last_x_days} || 0;
  if ($l > 0 && $delta <= $l && $delta > 0)
    {
    $stats->{last_x_days}->{"$day/$month/$year"}++;
    }
   
  foreach my $rule (@{$cur->{rule}})
    { 
    $stats->{rule}->{$rule}++;
    }
 
  # SpamAssassing or other score 
  $cur->{score} = 0 if !defined $cur->{score};
  # for scatter diagram (score_daily is just a limited scatter diagram)
  $stats->{score_daily}->{"$day/$month/$year"}->{$cur->{score}}++;
  # for histogram
  my $s = $self->{_options}->{generate}->{score_histogram};
  if ($s > 0)
    {
    $cur->{score} = $cur->{score} || 0; 
    $cur->{score} = 10000 if $cur->{score} > 10000;	# hard limit
    if ($cur->{score} > 0)				# uh?
      {
      my $s = int($cur->{score} / int($s)) * int($s);	# normalize to steps
      $stats->{score_histogram}->{$s} ++;
      $stats->{stats}->{max_score} = $s if $s > $stats->{stats}->{max_score};
      }
    }
    
  $stats->{stats}->{size_uncompressed} += $cur->{size};
 
  $stats->{toplevel}->{$cur->{toplevel}}++;
  }

sub generate
  {
  my $self = shift;

  return $self if defined $self->{error};

  # for stats:
  my $stats = {  
    reasons => {} , 				# reasons for invalid skips
    start_time => Time::HiRes::time() };
  foreach my $k (
   qw/toplevel date month dow day yearly monthly daily rule target domain
      hour score_histogram score_daily score_scatter/)
    {
    $stats->{$k} = {};
    }
  foreach my $k (qw/
    items_proccessed items_skipped last_30_days last_7_days last_24_hours
    size_compressed size_uncompressed max_score
    /)
    {
    $stats->{stats}->{$k} = 0;
    }
  my @files = $self->_gather_files($stats);
  my $id = 0; my @mails;

  my $first;
  my $now = [ Today_and_Now() ]; 	# [year,month,day,...]
  if (defined $self->{_options}->{last_date})
    {
    ($now->[0],$now->[1],$now->[2]) = split '-',$self->{_options}->{last_date};
    }
  print "Last valid date is $now->[0]",'-',$now->[1],'-',$now->[2],"\n";
  if (defined $self->{_options}->{first_date})
    {
    $first = [ split ('-',$self->{_options}->{first_date}) ];
    print "First date is $first->[0]",'-',$first->[1],'-',$first->[2],"\n";
    }

  foreach my $file (sort @files)
    {
    print "At file $file\n";

    # if index file exists, use it. Otherwise process archive and create index
    # at the same time
    $self->_clear_index();				# empty internal index
    if ($file =~ /\.(idx|idx\.gz)$/)
      {
      $self->_read_index($file,$stats);
      foreach my $cur (@{$self->{_index}})
        {
        $self->_merge_mail($cur,$stats,$now,$first); 	# merge into $stats
        }
      }
    else
      {
      # gather and merge mails into the current stats
      $self->_gather_mails($file,\$id,$stats,$now,$first);
      $self->_write_index($file,$stats);	# write index for that archive
      }
    }
  $self->_clear_index();			# empty to save mem

  my $what = $self->{_options}->{items};
  my $h = $self->{_options}->{height};

  # adjust the width of the toplevel stat, so that it doesn't look to broad
  my $w = (scalar keys %{$stats->{toplevel}}) * 30; $w = 1020 if $w > 1020;
  $self->_graph ($stats,'toplevel', $w, $h, {
    title => "$what/top-level domain",
    x_label => 'top-level domain',
    bar_spacing     => 3,
    show_values		=> 1,
    values_vertical	=> 1,
    },
    undef,0,$now,
    );

  $self->_graph ($stats,'month', 400, $h, {
    title => "$what/month",
    x_label => 'month',
    x_labels_vertical => 0,
    bar_spacing     => 6,
    cumulate => 1, 
    },
    \&_num_to_month,
    0,$now,
    );

  $self->_graph ($stats,'hour', 800, $h, {
    title => "$what/hour",
    x_label => 'hour',
    x_labels_vertical => 0,
    bar_spacing     => 6,
    cumulate => 1, 
    },
    undef,0,$now,
    );

  $self->_graph ($stats,'dow', 300, $h, {
    title => "$what/day",
    x_label => 'day of the week',
    x_labels_vertical => 0,
    bar_spacing     => 6,
    cumulate => 1, 
    },
    \&_num_to_dow,
    0,$now,
    );

  $self->_graph ($stats,'day', 800, $h, {
    title => "$what/day",
    x_label => 'day of the month',
    x_labels_vertical => 0,
    bar_spacing     => 4,
    cumulate => 1, 
    },
    undef,0,$now,
    );

  # adjust the width of the yearly stat, so that it doesn't look to broad
  $w = (scalar keys %{$stats->{yearly}}) * 50; $w = 600 if $w > 600;
  $self->_graph ($stats,'yearly', $w, $h, {
    title => "$what/year",
    x_label		=> 'year',
    x_labels_vertical	=> 0,
    bar_spacing		=> 8,
    show_values		=> 1,
    },
    undef,
    2,				# do linear plus last 60 days prediction
    $now,
    );

  # adjust the width of the monthly stat, so that it doesn't look to broad
  $w = (scalar keys %{$stats->{monthly}}) * 30;  
  $w = 800 if $w > 800;
  $w = 160 if $w < 160;	# min width due to long "prediction for this month" txt
  $self->_graph ($stats,'monthly', $w, $h, {
    title => "$what/month",
    x_label => 'month',
    x_labels_vertical => 1,
    bar_spacing     => 2,
    },
    \&_year_month_to_num,
    1,							# do prediction
    $now,
    );
  
  # adjust the width of the rule stat, so that it doesn't look to broad
  $w = (scalar keys %{$stats->{rule}}) * 30; $w = 800 if $w > 800;
  # go trough the rule data and create a percentage
  $self->_add_percentage($stats,'rule');
  # need more height for long rule names
  $self->_graph ($stats,'rule', $w, $h + 200, {
    title => "$what/rule",
    x_label => 'rule',
    x_labels_vertical => 1,
    bar_spacing     => 2,
    show_values		=> 1,
    values_vertical	=> 1,
    },
    undef,
    undef,0,$now,
    );
  
  # adjust the width of the target stat, so that it doesn't look to broad
  $w = (scalar keys %{$stats->{target}}) * 30; $w = 800 if $w > 800;
  $self->_add_percentage($stats,'target');
  # need more height for long target names
  $self->_graph ($stats, 'target', $w, $h + 320, {
    title => "$what/address",
    x_label => 'target address',
    x_labels_vertical => 1,
    bar_spacing     => 2,
    show_values		=> 1,
    values_vertical	=> 1,
    },
    undef,0,$now,
    );
  
  # adjust the width of the domain stat, so that it doesn't look to broad
  $w = (scalar keys %{$stats->{domain}}) * 50; $w = 800 if $w > 800;
  $self->_add_percentage($stats,'domain');
  # need more height for long domain names
  $self->_graph ($stats, 'domain', $w, $h + 120, {
    title => "$what/domain",
    x_label => 'target domain',
    x_labels_vertical => 1,
    bar_spacing     => 4,
    show_values		=> 1,
    values_vertical	=> 1,
    long_ticks	=> 0,
    },
    undef,0,$now,
    );
  
  my $l = $self->{_options}->{generate}->{last_x_days} || 0;
  if ($l > 0)
    {
    $stats->{last_x_days} = $self->_average($stats->{last_x_days});
    # adjust the width of the stat, so that it doesn't look to broad
    $w = $l * 50; $w = 800 if $w > 800;
    $self->_graph ($stats, ['last_x_days','daily'], $w, $h, {
      title => "$what/day",
      x_label => 'day',
      x_labels_vertical => 1,
      bar_spacing     => 4,
      long_ticks	=> 0,
      type	=> 'lines',
     },
     \&_year_month_day_to_num,
     0,$now,
      );
    }
 
  # calculate how many entries we must skip to have a sensible amount of them
  my $skip = scalar keys %{$stats->{daily}};
  $skip = int($skip / 82); $skip = 1 if $skip < 1;
  $stats->{daily} = $self->_average($stats->{daily},
    $self->{_options}->{average_daily});

  $self->_graph ($stats,'daily', 900, $h + 50, {
    title => "$what/day",
    x_label => 'date',
    x_labels_vertical => 1,
    x_label_skip => $skip,
    type	=> 'lines',
    },
    \&_year_month_day_to_num,
     0,$now,
    );
  
  $l = $self->{_options}->{generate}->{score_histogram} || 0;
  if ($l > 0)
    {
    $w = ($stats->{stats}->{max_score} || 0) * 50;
    if ($w > 0)
      {
      $w = 800 if $w > 800;
      # for each undefined between first defined and last, set to 0
      for (my $i = 0; $i < $stats->{stats}->{max_score}; $i += $l)
        {
        $stats->{score_histogram}->{$i} ||= 0;
        }
      }
    }

  $self->_graph ($stats,'score_histogram', $w, $h + 50, {
    title => "SpamAssassin score histogram",
    x_label => 'score',
    x_labels_vertical => 0,
    y_label	=> $self->{_options}->{items},
    bar_spacing		=> 2,
    },
    undef, 0,$now,
    );
  
  
  # calculate how many entries we must skip to have a sensible amount of them
  $skip = scalar keys %{$stats->{score_daily}};
  $skip = int($skip / 82); $skip = 1 if $skip < 1;
  $stats->{score_daily} = $self->_average($stats->{score_daily},
    $self->{_options}->{average_score_daily});

  $self->_graph ($stats,'score_daily', 900, $h + 50, {
    title => "SpamAssassin score",
    x_label => 'date',
    x_labels_vertical => 1,
    x_label_skip => $skip,
    type	=> 'points',
    },
    \&_year_month_day_to_num,
    );

  $l = $self->{_options}->{generate}->{score_daily} || 0;
  if ($l > 0)
    {
    $stats->{score_daily} = $self->_average($stats->{score_daily});
    # adjust the width of the stat, so that it doesn't look to broad
    $w = $l * 50; $w = 800 if $w > 800;
    $self->_graph ($stats, ['last_x_days','daily'], $w, $h, {
      title => "$what/day",
      x_label => 'day',
      x_labels_vertical => 1,
      bar_spacing     => 4,
      long_ticks	=> 0,
      type	=> 'lines',
     },
     \&_year_month_day_to_num,
     undef,0,$now,
      );
    }

  require Data::Dumper; print Data::Dumper::Dumper($stats->{reasons});

  # calculate how many entries we must skip to have a sensible amount of them

  $self->_fill_template($stats);
  }

###############################################################################
# private methods
  
sub _add_percentage
  {
  # given the single numbers for a certain statistics, chnages the values
  # from "xyz" to "xyz (u%)"
  my ($self,$stats,$what) = @_;

  my $sum = 0;
  my $s = $stats->{$what};
  # sum them all up
  foreach my $k (keys %$s)
    {
    $sum += $s->{$k};
    }
  # calculate the percantage value
  $sum = Math::BigInt->new($sum);
  foreach my $k (keys %$s)
    {
    # 12 / 100 => 0.12 * 100 => 12%
    # round to 1 digit after dot
    my $p = 
      Math::BigFloat->new($s->{$k} * 100)->bdiv($sum,undef,-1); 
    $p->precision(undef);			# no pading with 0's
    $s->{$k} = "$s->{$k}, $p%" if $p > 0;	# don't add "(0%)"
    }
  $self;
  }

sub _average
  {
  my ($self,$stats,$average) = @_;
  # calculate a rolling average over the last x day
  my $avrg = {};

  my $back = $average || $self->{_options}->{average} || 7;
  foreach my $thisday (keys %$stats)
    {
    my $sum = $stats->{$thisday};
    my ($day,$month,$year) = split /\//,$thisday;
    my ($d,$m,$y);
    for (my $i = 1; $i < $back; $i++)
      {
      ($y,$m,$d) = Add_Delta_Days($year,$month,$day,-$i);
      my $this = "$d/$m/$y";
      $sum += $stats->{$this}||0;		# non-existant => 0
      }
    $avrg->{$thisday} = [ $stats->{$thisday}, int($sum / $back) ];
    }
  return $avrg;
  }

sub _fill_template
  {
  my ($self,$stats) = @_;
  
  # read in
  my $file = $self->{_options}->{template};
  my $tpl = '';
  open FILE, "$file" or die ("Cannot read $file: $!");
  while (<FILE>) { $tpl .= $_; }
  close FILE;

  # replace placeholders
  $tpl =~ s/##generated##/scalar localtime();/eg;
  $tpl =~ s/##version##/$VERSION/g;
  $tpl =~ s/##items##/lc($self->{_options}->{items})/eg;
  $tpl =~ s/##Items##/ucfirst($self->{_options}->{items})/eg;
  $tpl =~ s/##ITEMS##/uc($self->{_options}->{items})/eg;
  my $time = sprintf("%0.2f",Time::HiRes::time() - $stats->{start_time});
  $tpl =~ s/##took##/$time/g;
  
  foreach my $t (qw/
     items_processed items_skipped last_7_days last_30_days last_24_hours
    /)
    {
    print "at $t\n";
    $tpl =~ s/##$t##/$stats->{stats}->{$t}/g;
    }
  foreach (qw/
     size_compressed size_uncompressed
    /)
    {
    # in MByte
    $stats->{stats}->{$_} = 
    int(($stats->{stats}->{$_} * 10) / (1024*1024)) / 10;
    $tpl =~ s/##$_##/$stats->{stats}->{$_}/g;
    }

  # write out
  $file =~ s/\.tpl/.html/;
  $file = File::Spec->catfile($self->{_options}->{output},$file);
  open FILE, ">$file" or die ("Cannot write $file: $!");
  print FILE $tpl;
  close FILE;
  return $self;
  }

BEGIN
  {
  $month_table = { jan => 1, feb => 2, mar => 3, apr => 4, may => 5, jun => 6,
	      jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12 };
  $dow_table = { mon => 1, tue => 2, wed => 3, thu => 4, fri => 5,
                 sat => 6, sun => 7, };
  }

sub _month_to_num
  {
  my $m = lc(shift || 0);
  return $month_table->{$m} || 0;
  }

sub _year_month_to_num
  {
  my $m = shift;

  my ($month,$year) = split /\//,$m;
  $year * 12+$month;
  }

sub _year_month_day_to_num
  {
  my $m = shift;

  my ($day,$month,$year) = split /\//,$m;
  return Date_to_Days($year,$month,$day);
  }

sub _dow_to_num
  {
  my $d = lc(shift);
  return $dow_table->{$d} || 0;
  }

sub _num_to_dow
  {
  my $d = shift;
  foreach my $k (keys %$dow_table)
    {
    return $k if $dow_table->{$k} eq $d;
    }
  return 'unknown dow $d';
  }

sub _num_to_month
  {
  my $d = shift;
  foreach my $k (keys %$month_table)
    {
    return $k if $month_table->{$k} eq $d;
    }
  return 'unknown month $d';
  }

sub _parse_date
  {
  my ($self,$date) = @_;

  return (0,0,0,0,0,0,0,0) if !defined $date;

  my ($day,$month,$year,$dow,$hour,$minute,$seconds,$offset);
  if ($date =~ /,/)
    {
    # Sun, 19 Jul 1998 23:49:16 +0200
    # Sun, 19 Jul 03 23:49:16 +0200
    $date =~ /([A-Za-z]+),\s+(\d+)\s([A-Za-z]+)\s(\d+)\s(\d+):(\d+):(\d+)\s(.*)/;
    $day = int($2 || 0);
    $month = _month_to_num($3);
    $year = int($4 || 0);
    $dow = _dow_to_num($1 || 0);
    $hour = $5 || 0;
    $minute = $6 || 0;
    $seconds = $7 || 0;
    $offset = $8 || 0;
    }
  elsif ($date =~ /([A-Za-z]+)\s([A-Za-z]+)\s+(\d+)\s(\d+):(\d+):(\d+)\s(\d+)/)
    {
    # Tue Oct 27 18:38:52 1998
    $date =~ /([A-Za-z]+)\s([A-Za-z]+)\s+(\d+)\s(\d+):(\d+):(\d+)\s(\d+)/;
    $day = int($3 || 0);
    $month = _month_to_num($2);
    $year = int($7 || 0);
    $dow = _dow_to_num($1 || 0);
    $hour = $4 || 0; $minute = $5 || 0; $seconds = $6 || 0; $offset = 0;
    my $dow2 = Date::Calc::Day_of_Week($year,$month,$day);
    # wrong Day Of Week? Shouldn't happen unless date is forged
    return (0,0,0,0,0,0,0,0)
      if ($dow2 ne $dow);
    }
  elsif ($date =~ /(\d{2})\s([A-Za-z]+)\s(\d+)\s(\d+):(\d+):(\d+)\s([-+]?\d+)/)
    {
    # 18 Oct 2003 23:45:29 -0000
    $day = int($1 || 0);
    $month = _month_to_num($2 || 0);
    $year = int($3 || 0);
    $hour = $4 || 0; $minute = $5 || 0; $seconds = $6 || 0; $offset = $7 || 0;
    $dow = Date::Calc::Day_of_Week($year,$month,$day);
    }
  else
    {
    $month = 0;
    $day = 0;
    $year = 0;
    $dow = 0;
    $hour = 0;
    $seconds = 0;
    $minute = 0;
    $offset = 0;
    }
  $year += 1900 if $year < 100 && $year >= 70;
  $year += 2000 if $year < 70 && $year > 0;
  return ($day,$month,$year,$dow,$hour,$minute,$seconds,$offset);
  }

sub _graph
  {
  my ($self,$stats,$stat,$w,$h,$options,$map,$predict,$now) = @_;

  $predict = $predict || 0;
  my $label = $stat; 
  if (ref($stat) eq 'ARRAY')
    {
    $label = $stat->[1];
    $stat = $stat->[0];
    }
  return if ($self->{_options}->{generate}->{$stat}||0) == 0;	# skip this

  print "Making graph $stat...\n";
  my $max = 0;
  $map = sub { $_[0]; } if !defined $map;

  # sort the data so that it can be processed by GD::Graph
  my @legend = (); my @data;
  my $k = []; my $v = [];
  if (defined $options->{cumulate})
    {
    my $make_k = 0;				# only once
    foreach my $key (sort keys %{$stats->{$stat}})
      {
      #print "at key $key\n";
      push @legend, $key;
      $v = []; my $i = 1;
      foreach my $kkey (@{$stats->{$stat}->{$key}})
        {
        $kkey = 0 if !defined $kkey;
        push @$k, &$map($i) if $make_k == 0; $i++;
        push @$v, $kkey;
        }
      $make_k = 1;
      push @data, $v;
      }
    }
  elsif ($options->{type}||'' eq 'lines')
    {
    my $av = 'average'; $av .= '_daily' if $stat eq 'daily';
    push @legend, $label,  
     "average over last ".$self->{_options}->{$av}." days";

    foreach my $key (sort { 
      my $aa = &$map($a); my $bb = &$map($b);
      if (($aa =~ /^[0-9\.]+$/) && ($bb =~ /^[0-9\.]+$/))
        {
        return $aa <=> $bb;
        }
      $aa cmp $bb;
      }  keys %{$stats->{$stat}})
      {
      push @$k, $key;
      my $i = 0;
      foreach my $j (@{$stats->{$stat}->{$key}})
        {
        push @{$v->[$i]}, $j; $i++;
        }
      }
    foreach my $j (@$v)
      {
      push @data, $j;
      }
    }
  else
    {
    foreach my $key (sort { 
      my $aa = &$map($a); my $bb = &$map($b);
      if (($aa =~ /^[0-9\.]+$/) && ($bb =~ /^[0-9\.]+$/))
        {
        return $aa <=> $bb;
        }
      $aa cmp $bb;
      }  keys %{$stats->{$stat}})
      {
      push @$k,$key;
      push @$v, $stats->{$stat}->{$key};
      }
    push @data, $v;
    }
  # end sort data
  
  if ($predict)
    {
    my $t = 1;		# month
    $t = 0 if $stat eq 'yearly';
    unshift @data, $self->_prediction($stats, $t, scalar @{$data[0]}, $now);
    $t = $stat; $t =~ s/ly//;
    # legend only if we did prediction
    if ($predict != 1)
      {
      # based on last 60 days
      $predict = 1;				# 2 colors
      # if under 80 days in the current year, don't make this (to have a
      # difference between the two)
      if (Delta_Days($now->[0],1,1, $now->[0], $now->[1], $now->[2]) > 80)
        {
        unshift @data, $self->_prediction($stats, 2, scalar @{$data[0]}, $now);
        push @legend, "based on last 60 days" if defined $data[0]->[-1];
        $predict = 2;				# 3 colors
        }
      push @legend, "linear prediction" if defined $data[0]->[-1];
      }
    else
      {
      push @legend, "prediction for this $t" if defined $data[0]->[-1];
      }
    $options->{overwrite} = 1;
    }
  # calculate maximum value
  my @sum;
  if (defined $options->{cumulate})
    {
    foreach my $r ( @data )
      {
      my $i = 0; my $j;
      foreach my $h ( @$r )
        {
        $j = $h || 0; $j =~ s/,.*//;			# "12, 12%" => 12
        $sum[$i++] += $j || 0;
        }
      }
    }
  else
    {
    foreach my $r ( @data )
      {
      my $i = 0; my $j;
      foreach my $h ( @$r )
        {
        $j = $h || 0; $j =~ s/,.*//;			# "12, 12%" => 12
        $sum[$i] = $j if ($j || 0) >= ($sum[$i] || 0); $i++;
        }
      }
    }
  foreach my $r ( @sum )
    {
    $max = $r if $r > $max;
    }
 
  my $data = GD::Graph::Data->new([$k, @data]) or die GD::Graph::Data->error;

  # This is hackery, replace it with something more clean
  my $grow = 1.05;
  $grow = 1.15 if defined $options->{show_values};
  $grow = 1.25 if defined $options->{values_vertical};
  $grow = 1.15 if defined $options->{values_vertical} &&
   $options->{x_label} eq 'target address';
  $grow = 1.6 if $stat =~ /^(rule)$/;		# percentages
  $grow = 1.4 if $stat =~ /^(domain|target)$/;	# percentages
  if (int($max * $grow) == $max)	# increase by at least 1
    {
    $max++;
    }
  else
    {
    $max = int($max*$grow);	# + x percent
    }
  my $defaults = {
    x_label	=> $self->{_options}->{items},
    y_label	=> 'count',
    title	=> $self->{_options}->{items} . '/day',
    y_max_value	=> $max,
    y_tick_number	=> 8,
    bar_spacing		=> 4,
    y_number_format	=> '%i',
    x_labels_vertical	=> 1,
    transparent		=> 1,
#    gridclr		=> 'lgray',	# to be compatible w/ old GD::Graph
    y_long_ticks  	=> 2,	
    values_space	=> 6,
   };
  my @opt = ();
  foreach my $k (keys %$options, keys %$defaults)
    {
    next if $k eq 'title' && $self->{_options}->{no_title} != 0;
    next if $k eq 'type';
    $options->{$k} = $defaults->{$k} if !defined $options->{$k};
    push @opt, $k, $options->{$k};
    }
 
  #############################################################################
  # retry to make a graph until it fits

  $w = 120 if $w < 120;		# minimum width
  my $redo = 0;
  while ($redo == 0)
    {
    my $my_graph;
    if (($options->{type} || '') eq 'lines')
      {
      $my_graph = GD::Graph::lines->new( $w, $h );
      $my_graph->set( dclrs => [ '#9090e0','#ff6040' ] );
      }
    else
      {
      $my_graph = GD::Graph::bars->new( $w, $h );
      if ($predict == 2)
        {
        $my_graph->set( dclrs => [ '#f8e8e8', '#e0c8c8', '#ff2060' ] ); 
        }
      elsif ($predict)
        {
        $my_graph->set( dclrs => [ '#e0d0d0', '#ff2060' ] ); 
        }
      else
        {
        $my_graph->set( dclrs =>
          [ '#ff2060','#60ff80','#6080ff','#ffff00','#f060f0', 
 	    '#209020','#d0d0f0','#f0a060','#ffd0d0','#b0ffb0' ] );
        }
      }
    $my_graph->set_legend(@legend) if @legend != 0;
  
    $my_graph->set( @opt ) or warn $my_graph->error();

    print " Making $w x $h\n";
    $my_graph->clear_errors();
    $my_graph->plot($data);
    $redo = 1;
    if (($my_graph->error()||'') =~ /Horizontal size too small/)
      {
      $w += 32; $redo = 0;
      }
    if (($my_graph->error()||'') =~ /Vertical size too small/)
      {
      $h += 64; $redo = 0;
      }
    if (!$my_graph->error())
      {
      $self->_save_chart($my_graph, 
	File::Spec->catfile($self->{_options}->{output},$stat));
      print "Saved\n";
      last;
      }
    elsif ($redo != 0)
      {
      print $my_graph->error(),"\n";
      }
    }
  return $self;
  }

sub _prediction
  {
  # from item count per day calculate an average for the given timeframe,
  # then interpolate how many items will occur this month/year
  my ($self, $stats, $m, $needed_samples, $now ) = @_;

  my $max = undef;
  my ($month,$year) = ($now->[1],$now->[0]);
  my $day = 1; my $days;
  if ($m == 1)
    {
    # good enough?
    $days = 28 if $month == 2;
    $days = 30 if $month != 2;
    $days = 31 if $now->[2] == 31;
    }
  elsif ($m == 2)
    {
    # prediction for year based on last 60 days
    ($year,$month,$day) = @$now;
    ($year,$month,$day) = Add_Delta_Days($year,$month,$day, -60);
    $days = 365;	# good enough?
    }
  else
    {
    $month = 1;
    $days = 365;	# good enough?
    }
  my $delta = Delta_Days($year,$month,$day, $now->[0], $now->[1], $now->[2]);
  # sum up all items for each day since start of timeframe
  my $sum = 0;
  for (my $i = 0; $i < $delta; $i++)
    {
    $sum += $stats->{daily}->{"$day/$month/$year"} || 0;
    ($year,$month,$day) = Add_Delta_Days($year,$month,$day, 1);
    }
  if ($delta != 0)
    {
    $max = int($days * $sum / $delta);
    }
  my @samples;
  for (my $i = 1; $i < $needed_samples; $i++)
    {
    push @samples, undef;
    }
  push @samples, $max;
  \@samples;
  }

sub _extract_target
  {
  my ($self,$header) = @_;

  my ($target,$domain) = '';

  # ignore target in "From target@target-host.com datestring" and
  # try to extract target from defined valid forwardes, since X-Envelope-To
  # will probably point to the forwarded address endpoint
 
  foreach my $line (@$header)
    {
    foreach my $for (@{$self->{_options}->{valid_forwarders}})
      {
      if (($line =~ /^Received:/) &&
          ($line =~ /by [^\s]*?$for.*? for <([^>]+)>/))
        {
        $target = $1 || 'unknown'; last;
        }
      }
    last if $target ne '';
    }
  $target ||= 'unknown';

  if ($target eq 'unknown')
    {
    # try to extract the target address from X-Envelope-To;
    foreach my $line (@$header)
      {
      if ($line =~ /^X-Envelope-To:/i)
        {
        $target = $line; $target =~ s/^[A-Za-z-]+: //; last;
        }
      }
    }

  # no X-Envelope-To:, no valid forwarder? So try "From "
  if ($target eq 'unknown')
    {
    my $line = $header->[0] || '';
    $line =~ /^From ([^\s]+)/;
    $target = $1 || 'unknown';
    }

  # if still not defined, try 'received for' in Received: header lines
  if ($target eq 'unknown')
    {
    foreach my $line (@$header)
      {
      if (($line =~ /^Received:/) &&
          ($line =~ /received for <([^>]+)>:/))
        {
        $target = $1 || 'unknown'; last;
        }
      }
    }

  $target = lc($target);		# normalize
  $target =~ s/^\".+?\"\s+//;		# throw away comment/name
  $target =~ s/[<>]//g; 
  $target = substr($target,0,64) if length($target) > 64;

  foreach my $dom (@{$self->{_options}->{filter_domains}})
    {
    $target = 'unknown' if $target =~ /\@.*$dom/i;
    }
  foreach my $dom (@{$self->{_options}->{filter_target}})
    {
    $target = 'unknown' if $target =~ /$dom/i;
    }

  $domain = $target; $domain =~ /\@(.+)$/; $domain = $1 || 'unknown';

  $target = 'unknown' if $target eq '';
  $domain = 'unknown' if $target eq 'unknown';

  ($target,$domain);
  }

sub _gather_files
  {
  my ($self,$stats) = @_;

  my $dir = $self->{_options}->{input};
  # if input is a single file, use only this (does not look for an index yet)
  if (-f $dir)
    {
    $stats->{stats}->{size_compressed} += -s $dir;
    return ($dir);
    }

  ############################################################################  
  # open the input/archive directory
  
  opendir my $DIR, $dir or die "Cannot open dir $dir: $!";
  my @files = readdir $DIR;
  closedir $DIR;

  ############################################################################  
  # open the index directory
  my $index_dir = $self->{_options}->{index};
  opendir $DIR, $index_dir or die "Cannot open dir $index_dir: $!";
  my @index = readdir $DIR;
  closedir $DIR;

  # for each archive file, see if we have an index file. If yes, use that
  # instead and also prefer gzipped (.idx.gz) index files over the normal 
  # ones (.idx)

  my @ret = ();
  foreach my $file (@files)
    {
    next if $file =~ /^\.\.?\z/;		# skip '..', '.' etc
    print "Evaluating file '$file' ... ";
    my $archive = File::Spec->catfile ($dir,$file);
    my $index = File::Spec->catfile ($index_dir,$file.'idx');
    my $index_gz = File::Spec->catfile ($index_dir,$file.'.idx.gz');

    # compressed size is stored in index file
    if (-f $index_gz)
      {
      print "found gzipped index.\n";
      push @ret, $index_gz;
      }
    elsif (-f $index)
      {
      print "found index.\n";
      push @ret, $index;
      }
    elsif (-f $archive)
      {
      print "found no index at all, will re-index.\n";
      push @ret, $archive;
      $stats->{stats}->{size_compressed} += -s $archive;
      $stats->{stats}->{current_size_compressed} = -s $archive;
      }
    # everything else (directories etc) is ignored
    }
   
  # also, for all (gzipped) index files without an archive file, add these
  # too, so that you can safey remove the archives
  foreach my $file (@index)
    {
    my $index = File::Spec->catfile ($index_dir,$file);
  
    my $archive = File::Spec->catfile ($dir,$file);
    $archive =~ s/\.idx.gz$//;
    $archive =~ s/\.idx$//;

    if ((-f $index) && (!-f $archive))
      {
      print "Will also use index '$index' w/o archive.\n";
      push @ret, $index;
      }
    }

  return @ret;
  }

sub _open_file
  {
  my ($file) = @_;

  # try as .gz file first
  my $FILE;
  if ($file =~ /\.(gz|zip|gzip)$/)
    {
    $FILE = gzopen($file, "r") or die "Cannot open $file: $gzerrno\n";
    }
  else
    {
    open ($FILE, $file) or die "Cannot open $file: $!\n";
    }
  $FILE;
  }

sub _read_line
  {
  my ($file) = @_;

  if (ref($file) eq 'GLOB')
    {
    return <$file>;
    }
  my $line;
  $file->gzreadline($line);
  return if $gzerrno != 0;
  $line;
  }

sub _close_file
  {
  my ($file) = shift;

  if (ref($file) ne 'GLOB')
    {
    die "Error reading from $file: ", $file->gzerror(),"\n"
     if $file->gzerror != Z_STREAM_END;
    $file->gzclose();
    }
  else
    {
    close $file;
    }
  }
 
sub _read_file
  {
  # read file (but prefer the gzipped version) in one go and return a ref to
  # the contents

  my ($self,$file) = @_;
  
  # that is a bit inefficient, sucking in anything at a time...
  my $doc;
  if ($file =~ /\.gz$/)
    {
    return $self->_read_compressed_file($file);
    }

  open FILE, "$file" or die ("Cannot read $file: $!");
  while (<FILE>)
    {
    $doc .= $_;
    }
  close FILE;
  \$doc;
  }

sub _read_compressed_file
  {
  my ($self,$file) = @_;

  my $gz = gzopen($file, "rb") or die "Cannot open $file: $gzerrno\n";

  my ($line, $doc);
  while ($gz->gzreadline($line) > 0)
    {
    $doc .= $line;
    }
  die "Error reading from $file: $gzerrno\n" if $gzerrno != Z_STREAM_END;
  $gz->gzclose();
  \$doc;
  }
 
sub _split
  {
  my $doc = shift;

  my $l = [ split(/\n/, $$doc) ];
  $l; 
  }

sub _gather_mails
  {
  my ($self,$file,$id,$stats,$now,$first) = @_;

  my $FILE = _open_file($file);

  my $header = 0; 		# in header or body?
  my @header_lines = ();	# current header
 
  my $cur_size = 0;
  my $line;
  my $lines = 0;
  # endless loop  until done
  while ( 3 < 5 )
    {
    if (ref($FILE) eq 'GLOB')
      {
      $line = <$FILE>;
      }
    else
      {
      $FILE->gzreadline($line);
      $line = undef if $gzerrno == Z_STREAM_END;
      if ($FILE->gzerror())
	{
        $line = undef;
        print "Compress:Zip error: ", $FILE->gzerror(), "\n"
          if $FILE->gzerror() != Z_STREAM_END;
        }
      }
    last if !defined $line;
    $lines++;

    $cur_size += length($line);

    if ($line =~ /^From .*\d+/)
      {
      $header = 1;
      if (@header_lines > 0)
        {
	# had a mail before with header?
        my $cur = $self->_process_mail( 
	  { header => [ @header_lines ],
	   size => $cur_size,
           id => $$id,
	  }, $now); 
        $self->_index_mail($cur);
        $self->_merge_mail($cur,$stats,$now,$first);    # merge into $stats
        $$id ++;
        @header_lines = ();
        $cur_size = 0;
        }
      }
    $header = 0 if $header == 1 && $line =~ /^\n$/;	# now in body?
    push @header_lines, $line if $header == 1;
    }
  # process last mail
  if (@header_lines > 0)
    {
    # was a valid mail? so get it's size (because we throw away the body)
    my $cur = $self->_process_mail( 
      { header => [ @header_lines ],
      size => $cur_size,
      id => $$id,
       }, $now); 
    $self->_index_mail($cur);
    $self->_merge_mail($cur,$stats,$now,$first);    # merge into $stats
    }
  $$id ++;
  _close_file($FILE);
  return;
  }

sub _save_chart
  {
  my $self = shift;
  my $chart = shift or die "Need a chart!";
  my $name = shift or die "Need a name!";
  local(*OUT);

  my $ext = $self->{_options}->{graph_ext} || $chart->export_format();

  open(OUT, ">$name.$ext") or
   die "Cannot open $name.$ext for write: $!";
  binmode OUT;
  print OUT $chart->gd->$ext();
  close OUT;
  }

1;

__END__

###############################################################################
###############################################################################
=pod

=head1 NAME

Mail::Graph - draw graphical stats for mails/spams

=head1 SYNOPSIS

	use Mail::Graph;

	$graph = Mail::Graph->new( items => 'spam', 
	  output => 'spams/',
	  input => '~/Mail/spam/',
          );
        $graph->generate();

=head1 DESCRIPTION

This module parses mailbox files in either compressed or uncompressed form
and then generates pretty statistics and graphs about them. Although at first
developed to do spam statistics, it works just fine for normal mail.

=head2 File Format

The module reads in files in mbox format. These can be compressed by gzip,
or just plain text. Since the module read in any files that are in one
directory, it can also handle mail-dir style folders, e.g. a directory where
each mail resides in an extra file.

The file format is quite simple and looks like this:

	From sample_foo@example.com  Tue Oct 27 18:38:52 1998
	Received: from barfel by foo.example.com (8.9.1/8.6.12) 
	From: forged_bar@example.com
	X-Envelope-To: <sample_foo@example.com>
	Date: Tue, 27 Oct 1998 09:52:14 +0100 (CET)
	Message-Id: <199810270852.12345567@example.com>
	To: <none@example.com>
	Subject: Sorry...
	X-Loop-Detect: 1
	X-Spamblock: caught by rule dummy@

	This is a sample spam

Basically, an email header plus email body, separated by the C<From> lines.

The following fields are examined to determine:

	X-Envelope-To		the target address/domain
	From address@domain	the sender
	From date		the receiving date

=head1 METHODS

=head2 new()

Create a new Mail::Graph object.

The following options exist:

	input		Path to a directory containing (gzipped) mbox files
			Alternatively, name of an (gzipped) mbox file
	index		Directory where to write (and read) the index files
	output		Directory where to write the output stats
	items		Try 'spams' or 'mails' (can be any string)
	generate	hash with names of stats to generate (1=on, 0=off):
			 month		 per each month of the year
			 day		 per each day of the month
			 hour		 per each hour of the day
			 dow		 per each day of the week
			 yearly		 per year
			 daily		 per each day (with average)
			 monthly	 per each month
			 toplevel	 per top_level domain
			 rule		 per filter rule that matched
			 target		 per target address
			 domain	         per target domain
			 last_x_days     items for each of the last x days
				         set it to the number of days you want
			 score_histogram show histogram of SpamAssassin scores
					 set it to the step-width (like 5)
			 score_daily     SA score for each of the last x days
				         set it to the number of days you want
			 score_scatter   SA scatter score diagram, set it to
					 the limit of the score (a line will be
					 draw there)
	average		set to 0 to disable, otherwise it gives the number
			of days/weeks/month to average over
	average_daily	if not set, uses average, 0 to disable
			number of days to average over in the daily graph
	height		base height of the generated images
	template	name of the template file (ending in .tpl) that is
			used to generate the html output, e.g. 'index.tpl'
	no_title	set to 1 to disable graph titles, default 0
	filter_domains	array ref with list of domains to show as "unknown"
	filter_target	array ref with list of targets (regualr expressions)
	graph_ext	extension of the generated graphs, default 'png'
	last_date	in yyyy-mm-dd format: specify the last used date, any
			mail newer than that will be skipped. Defaults to today
	first_date	in yyyy-mm-dd format: specify the first used date, any
			mail older than that will be skipped. Defaults to undef
			meaning any old mail will be considered.

=head2 generate()

Generate the stats, fill in the template and write it out. Takes no options.

=head2 error()

Return an error message or undef for no error.

=head1 BUGS

There are a couple of known bugs, some of the are unfinished features or
problem of GD::Graph:

=over 2

=item Divide by Zero

This is a bug in some versions of GD::Graph, when generating a graph with only
one bar it will crash with this error. If you encounter this, please bug the
author of GD::Graph and send me a copy.

=item Argument "4, 0.7%" isn't numeric

You might get a lot of warnings like

	Argument "4, 0.7%" isn't numeric in numeric lt (<) at 
	/usr/lib/perl5/site_perl/5.8.2/GD/Graph/Data.pm line 231.

This is a problem with GD::Graph: Mail::Graph wants to use labels like 
C<4, 0.7%> but GD::Graphs uses the same string for the label and the value
of the point/bar. And thus Perl warns. This needs a small patch to GD::Graph
that strips anything non-numeric out of the label before using it in numeric
context. Please bug the author of GD::Graph and send me a copy.

=item gzipped archives are not included in the stats

Some of the gzipped archives seem to trigger some bug in Compress::Zlib,
at least til version v1.32. For instance, on my system on of the sample
archives in C</sample/archives/> is not read properly by Compress::Zlib. I
already have notified the author of Compress::Zlib.

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

(c) Copyright by Tels http://bloodgate.com/ 2002.

=cut

