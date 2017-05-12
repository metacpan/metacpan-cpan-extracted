#-----------------------------------------------------------------
# GPS::Tracer
# Authors: Martin Senger <martin.senger@gmail.com>
#          Kim Senger <senger.kim@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Tracer.pm,v 1.2 2007/04/30 21:52:10 senger Exp $
#-----------------------------------------------------------------

package GPS::Tracer;

use strict;
use warnings;
use vars qw( $VERSION $Revision $AUTOLOAD );

use constant PI => 3.14159;
use constant R  => 6378700;

use Text::CSV::Simple;
use XML::Simple;
use LWP::UserAgent;
use File::Temp qw/ :POSIX /;
use File::Spec;
use Date::Calc qw( Add_Delta_Days );
use GD::Graph::hbars;

$VERSION = '1.2';
$Revision  = '$Id: Tracer.pm,v 1.2 2007/04/30 21:52:10 senger Exp $';

#-----------------------------------------------------------------
# A list of allowed attribute names.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 user             => 1,
         passwd           => 1,
	 from_date        => 1,
	 to_date          => 1,
	 login_url        => 1,
	 data_url         => 1,
	 default_id       => 1,
	 min_distance     => 1,
	 result_dir       => 1,
	 result_basename  => 1,
	 input_data       => 1,
	 input_format     => 1,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr};
    }
}

#-----------------------------------------------------------------
# Deal with 'set' and 'get' methods.
#-----------------------------------------------------------------
sub AUTOLOAD {
    my ($self, $value) = @_;
    my $ref_sub;
    if ($AUTOLOAD =~ /.*::(\w+)/ && $self->_accessible ("$1")) {

	# get/set method
	my $attr_name = "$1";
	$ref_sub =
	    sub {
		# get method
		local *__ANON__ = "__ANON__$attr_name" . "_" . ref ($self);
		my ($this, $value) = @_;
		return $this->{$attr_name} unless defined $value;

		# set method
		$this->{$attr_name} = $value;
		return $this->{$attr_name};
	    };

    } else {
	die ("No such method: $AUTOLOAD");
    }

    no strict 'refs'; 
    *{$AUTOLOAD} = $ref_sub;
    use strict 'refs'; 
    return $ref_sub->($self, $value);
}

#-----------------------------------------------------------------
# Keep it here! The reason is the existence of AUTOLOAD...
#-----------------------------------------------------------------
sub DESTROY {
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
    my ($class, @args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # initialize the object
    $self->init();

    # set all @args into this object with 'set' values
    my (%args) = (@args == 1 ? (value => $args[0]) : @args);
    foreach my $key (keys %args) {
        no strict 'refs';
        $self->$key ($args {$key});
    }

    # done
    return $self;
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;

    # some default values
    $self->from_date ('0000-00-00 00:00:00');  # format: 2006-10-28 18:02:20
    $self->to_date ('9999-99-99 23:59:59');    # format: 2006-10-28 18:02:20
    $self->result_basename ('trout');          # as TRacer OUTput
    $self->min_distance (500);                 # in metres
    $self->input_format ('6,7,8,9');           # column indeces for time, lat, lng, alt

}

#-----------------------------------------------------------------
# toString
#-----------------------------------------------------------------
sub toString {
    my $self = shift;
    require Data::Dumper;
    return Data::Dumper->Dump ( [$self], ['Tracer']);
}


# ----------------------------------------
# Subroutines
# ----------------------------------------

my @MONTHS = qw(dummy Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub create_all {
    my ($self) = @_;
    my @files = ();

    my $ra_data = $self->get_data;
    push (@files, $self->convert2xml ($ra_data));
    push (@files, $self->oneperday2xml ($ra_data));

    my $ra_sum = $self->get_summary ($ra_data);
    push (@files, $self->_summary2csv ($ra_sum));
    push (@files, $self->_summary2xml ($ra_sum));
    push (@files, $self->_summary2graph ($ra_sum));

    my $ra_mindist = $self->_min_distance ($ra_data);
    push (@files, $self->_min_distance2xml ($ra_mindist));
    push (@files, $self->_convert2oziwpt ($ra_mindist));

    return @files;

}

#
# save daily distances to a CSV file
#
sub summary2csv {
    my ($self, $ra_data) = @_;
    return $self->_summary2csv ($self->get_summary ($ra_data));
}

sub _summary2csv {
    my ($self, $ra_sum) = @_;

    my @day_names = @{ $$ra_sum{day_names} };
    my @day_dists = @{ $$ra_sum{day_dists} };

    my $filename = $self->_get_filename ('.csv');
    if (open (CSV, ">$filename")) {
	print CSV "Date,Metres\n";
	foreach my $day (0..$#day_names) {
	    print CSV $day_names[$day], ',', $day_dists[$day], "\n";
	}
	close CSV;
    } else {
	warn "Cannot open file '$filename' for writing: $!\n";
    }
    return $filename;
}

#
# save summaries to a short XML file:
#   <summary>
#      <total days="6" kms="42.1626162462093" />
#   </summary>
#
sub summary2xml {
    my ($self, $ra_data) = @_;
    return $self->_summary2xml ($self->get_summary ($ra_data));
}

sub _summary2xml {
    my ($self, $ra_sum) = @_;

    my @day_names = @{ $$ra_sum{day_names} };
    my $total_distance = $$ra_sum{total_dist};

    my $filename = $self->_get_filename ('-summary.xml');
    my $xs = XML::Simple->new();
    $xs->XMLout ({ 'total' => { days => (@day_names+0), kms => $total_distance / 1000 } },
		 RootName => 'summary',
		 OutputFile => $filename);
    return $filename;
}

#
# let's make a chart
#
sub summary2graph {
    my ($self, $ra_data) = @_;
    return $self->_summary2graph ($self->get_summary ($ra_data));
}

sub _summary2graph {
    my ($self, $ra_sum) = @_;

    my @day_names = @{ $$ra_sum{day_names} };
    my @day_dists = @{ $$ra_sum{day_dists} };

    # change metres to kilometres (rounded to 100 metres)
    map { $_ = int (($_ / 1000 + .05) * 10) / 10  } @day_dists;

    # make sure that missing dates are also listed (with 0 value)
    if (@day_names > 0) {
	my $expected_date = $day_names[0];
	my $i = 0;
	while ($i < @day_names) {
	    my $current_date = $day_names[$i];
	    while ($current_date gt $expected_date) {
		$expected_date = $self->increase_date ($expected_date);
		splice (@day_names, $i, 0, 'no data');
		splice (@day_dists, $i, 0, 0);
		$i++;
	    }
	    $i++;
	    $expected_date = $self->increase_date ($expected_date);
	}
    }		

    # make dates more human-readable
    map {
	if ($_ ne 'no data') {
	    $_ = $MONTHS [substr ($_, 5, 2)] . ' ' . substr ($_, 8, 2);
	} } @day_names;

    # if there are no data yet
    if (@day_dists == 0) {
	push (@day_dists, 0.001);
	push (@day_names, 'not yet started');
    } 

    # create statistical (charts) files
    my $filename = $self->_get_filename ('-chart.png');
	
    my $width = 400;
    my $height= 100 + 15 * @day_names;
    my $my_graph = GD::Graph::hbars->new ($width, $height);

    my (@g_args) = ();   # for collecting the graph properties
    push (@g_args, y_label => "Travelled km");
    push (@g_args, y_number_format => "%.1f");
    push (@g_args,
	  title           => ' ',
	  x_label         => '',
	  bar_spacing     => 1,
	  shadow_depth    => 0,
	  transparent     => 0,
	  show_values     => 1,
	  box_axis        => 0,
	  r_margin        => 5,
	  l_margin        => 5,
	  fgclr           => 'black',
	  labelclr        => 'black',
	  axislabelclr    => 'black',
	  dclrs           => [ map 'lblue', (0..$#day_names) ],
	  );

    eval {
	# plot the chart...
	$my_graph->set (@g_args);
	my $my_plot = $my_graph->plot ([ \@day_names, \@day_dists ]);

	# ...and save it to a file
	open (IMG, ">$filename")
	    or die "Cannot create file '$filename': $!\n";
	binmode IMG;
	print IMG $my_plot->png;
	close IMG;

    };
    warn "Creating a chart failed: " . ($my_graph->error or $@) . "\n" if $@;
    return $filename;
}

#
sub increase_date {
    my ($self, $date) = @_;
    my ($y, $m, $d) = Add_Delta_Days (substr ($date, 0, 4),
				      substr ($date, 5, 2),
				      substr ($date, 8, 2),
				      1);
    return sprintf "%04u-%02u-%02u", $y, $m, $d;
}

#
# convert degress to radians
#
sub deg2rad {
    my ($deg) = @_;
    return $deg / (180 / PI);
}

sub acos { atan2 ( sqrt (1 - $_[0] * $_[0]), $_[0]) }

#
# calculate distance between two points in meters
#
sub distance {
    my ($prev_lat, $prev_lng, $curr_lat, $curr_lng) = @_;
    my $prev_lat_rad = deg2rad ($prev_lat);
    my $curr_lat_rad = deg2rad ($curr_lat);

    return R * acos (sin ($prev_lat_rad) * sin ($curr_lat_rad) +
		     cos ($prev_lat_rad) * cos ($curr_lat_rad) *
		     cos (deg2rad ($prev_lng - $curr_lng)));
}

#
# return a hashref with two keys ('day_names' and 'day_dists') where
# in both cases the values are arrayrefs of the same size, one with
# dates (YYYY-MM-DD), one with day distances (in metres)
#
sub get_summary {
    my ($self, $ra_data) = @_;

    # here we collect returned values
    my @day_names = ();
    my @day_dists = ();
    my $total_distance = 0;

    my $prev_rec;
    foreach (@$ra_data) {
	$day_dists[$#day_dists] += distance ($$prev_rec{'lat'}, $$prev_rec{'lng'},
					     $$_{'lat'}, $$_{'lng'})
	    if defined $prev_rec;
	$prev_rec = $_;
	if ($$_{'type'} == 1) {
	    push (@day_names, substr ($$_{'time'}, 0, 10));
	    push (@day_dists, 0);
	}
    }

    map { $total_distance += $_ } @day_dists;

    return { day_names  => \@day_names,
	     day_dists  => \@day_dists,
	     total_dist => $total_distance,
	 };
}

#
# convert $ra_data to XML and save the result into
# file $filename - using some precaution
#
sub save2xml {
    my ($self, $ra_data, $filename) = @_;

    # backup the old XML file
    my $backup_file = "$filename.$$";
    -e $filename and rename $filename, $backup_file;

    # convert to XML
    my $xs = XML::Simple->new();
    $xs->XMLout ({ 'marker' => $ra_data },
		 RootName => 'markers',
		 OutputFile => $filename);

    # back to the backup file on failure
    -e $filename or rename $backup_file, $filename;
    unlink $backup_file;
}

#
# take only the first record of each day
#
sub oneperday2xml {
    my ($self, $ra_data) = @_;
    my @unique = grep { $$_{'type'} == 1 } @{$ra_data};

    # ...and the quite last record (if not already taken)
    $self->maybe_add_last_record ($ra_data, \@unique);

    my $outfile = $self->_get_filename ('-oneperday.xml');
    $self->save2xml (\@unique, $outfile);
    return $outfile;
}

#
# return only records with points not too close together
# (but kept there the one-per-day points);
#
sub _min_distance {
    my ($self, $ra_data) = @_;

    my $prev_lat = 1000;
    my $prev_lng = 1000;
    my @unique =
	grep { my $curr_lat = $$_{'lat'};
	       my $curr_lng = $$_{'lng'};
	       if ($prev_lat == 1000 or $$_{'type'} == 1) {
		   $prev_lat = $curr_lat; $prev_lng = $curr_lng;
		   1;
	       } else {
		   my $dist = distance ($prev_lat, $prev_lng, $curr_lat, $curr_lng);
		   $prev_lat = $curr_lat; $prev_lng = $curr_lng;
		   $dist > $self->min_distance;
	       }
	   } @{$ra_data};

    # ...and the quite last record (if not already taken)
    $self->maybe_add_last_record ($ra_data, \@unique);

    return \@unique;
}

#
# convert $ra_data to OziExplorer's waypoints and save the result into
# file $filename - using some precaution
#
sub save2oziwpt {
    my ($self, $ra_data, $filename) = @_;

    # backup the old WPT file
    my $backup_file = "$filename.$$";
    -e $filename and rename $filename, $backup_file;

    # convert to WPT
    if (open (WPT, ">$filename")) {
	local ($\) = "\r\n";   # make newlines as in Windows
	print WPT 'OziExplorer Waypoint File Version 1.1';
	print WPT 'WGS 84';
	print WPT 'Reserved 2';
	print WPT 'magellan';
        foreach (@$ra_data) {
	    my @record = ();
	    push (@record, -1);                                     # 1: wpt number
	    push (@record, $self->wpt_name ($$_{'type'}, $$_{'time'}));    # 2: wpt name
	    push (@record, $$_{'lat'});                             # 3: latitude
	    push (@record, $$_{'lng'});                             # 4: longitude
	    push (@record, '');                                     # 5: date
	    push (@record, $$_{'type'} == 1 ? 10 : 2);              # 6: symbol in GPS
	    push (@record, 1);                                      # 7: status
	    push (@record, 4);                                      # 8: map display format
	    push (@record, 0);                                      # 9: foreground color
	    push (@record, $$_{'type'} == 1 ? 4227327 : 5450740);   # 10: background color
	    push (@record, $$_{'time'});                            # 11: description
	    push (@record, 0);                                      # 12: pointer direction
	    push (@record, 0);                                      # 13: garmin display format
	    push (@record, 0);                                      # 14: proximity distance
	    push (@record, ($$_{'elevation'} or -777));             # 15: altitude
	    push (@record, $$_{'type'} == 1 ? 8 : 6);               # 16: font size
	    push (@record, 0);                                      # 17: font style
	    push (@record, 17);                                     # 18: symbol size
	    print WPT join (', ', @record);
	}
	close WPT;
    }

    # back to the backup file on failure
    -e $filename or rename $backup_file, $filename;
    unlink $backup_file;
}

#
# format waypoint name from the given timestamp $date_time
# 'wpt_type' is 1 for the first waypoint of the day
#
sub wpt_name {
    my ($self, $wpt_type, $date_time) = @_;
    if ($wpt_type == 1) {
	return
	    $MONTHS [substr ($date_time, 5, 2)] . '-' . substr ($date_time, 8, 2)
	    . '/'
	    . substr ($date_time, 11, 5);
    } else {
	# return unchanged
	return substr ($date_time, 11, 5);
    }
}

#
# create a file with OziExplorer waypoints
#
sub convert2oziwpt {
    my ($self, $ra_data) = @_;
    my $ra_mindist = $self->_min_distance ($ra_data);
    return $self->_convert2oziwpt ($ra_mindist);
}
sub _convert2oziwpt {
    my ($self, $ra_data) = @_;
    my $outfile = $self->_get_filename ('-ozi.wpt');
    $self->save2oziwpt ($ra_data, $outfile);
    return $outfile;
}

#
# create a file with more DISTANT points
#
sub min_distance2xml {
    my ($self, $ra_data) = @_;
    my $ra_mindist = $self->_min_distance ($ra_data);
    return $self->_min_distance2xml ($ra_mindist);
}
sub _min_distance2xml {
    my ($self, $ra_data) = @_;
    my $outfile = $self->_get_filename ('-distance.xml');
    $self->save2xml ($ra_data, $outfile);
    return $outfile;
}

#
# add the last record from $ra_from_data to $ra_to_data only if:
#   - there is any record in $ra_from_data, and
#   - the same record is not already in $ra_to_data, and
#   - the new record is "far enough" from the last one in $ra_to_data
#
sub maybe_add_last_record {
    my ($self, $ra_from_data, $ra_to_data) = @_;
    # 'from' array must be non-empty, otherwise there is nothing to copy from
    if (@$ra_from_data > 0) {
	my $last_rec = $$ra_from_data[$#$ra_from_data];
	# if 'to' array is still empty, there is nothing to test
	if (@$ra_to_data == 0) {
	    push (@$ra_to_data, $last_rec);
	    return;
	}
	my $prev_rec = $$ra_to_data[$#$ra_to_data];
	# the last record is already there, nothing to do
	return if $last_rec eq $prev_rec;

	# finally: is the last record far enough from the previous one?
	if (distance ($$prev_rec{'lat'}, $$prev_rec{'lng'},
		      $$last_rec{'lat'}, $$last_rec{'lng'}) > $self->min_distance) {
	    push (@$ra_to_data, $last_rec);
	}
    }
}

#
# convert given $ra_data into XML and save it in a file;
# return the filename;
# do not change existing files if data are empty
#
sub convert2xml {
    my ($self, $ra_data) = @_;
    my $outfile = $self->_get_filename ('-all.xml');
    $self->save2xml ($ra_data, $outfile);
    return $outfile;
}

#
# clean given data $ra_data: remove CSV header, remove records without
# any position, sort by time, remove records that are not in the
# wnated time range, add  key 'type' to each record; return cleaned data
#
# $ra_data is a reference to an array of hashes with the following keys
# (the values are just examples):
#   {
#     'elevation' => '',
#     'lat'       => '78.22259',
#     'time'      => '2006-10-29 16:02:01',
#     'lng'       => '15.65249'
#   },
#
# (the first element in $ra_data contains only headers)
#
sub clean_data {
    my ($self, $ra_data) = @_;

    return unless $ra_data;
    return $ra_data unless (@$ra_data > 1);
    shift @$ra_data;   # skip CSV headers

    # ignore records that do not have position
    # (i.e. where lat="-90.00000" lng="-180.00000")
    my @records =
	grep { $$_{'lat'} !~ /^-90\./ and $$_{'lng'} !~ /^-180\./ }
            @$ra_data;

    # sort by time
    my @sorted =
	grep { $$_{'time'} ge $self->from_date and $$_{'time'} le $self->to_date }
            sort { $$a{'time'} cmp $$b{'time'} } @records;

    # label type of the marker...
    #    type 1 ... the first-in-a-day-points
    #    type 0 ... others
    my $last_time = '0000-00-00';
    foreach (@sorted) {
	my $curr_time = substr ($$_{'time'}, 0, 10);
	if ($curr_time ne $last_time) {
	    $last_time = $curr_time;
	    $$_{'type'} = 1;
	} else {
	    $$_{'type'} = 0;
	}
    }
    return \@sorted;
}

#
# parse data from $filename and extract only wanted fields (columns)
#
sub parse_data {
    my ($self, $filename) = @_;

    my @indeces = split (/\s*,\s*/, $self->input_format);
    my $parser = Text::CSV::Simple->new;

    # field #:    5              6             7         8        9
    # CSV header: Satellite_time Guardian_time Longitude Latitude Altitude
    # XML attr:                  time          lng       lat      elevation
    $parser->want_fields (@indeces);
    $parser->field_map (qw/time lng lat elevation/);
    my @data = $parser->read_file ($filename);
    return \@data;
}

#
# create a file name from existing parameters and from the given
# $suffix; if there is a parameter indicateing result directory but
# this directory does not exist it is created (no error messages if it
# fails, however)
#
sub _get_filename {
    my ($self, $suffix) = @_;

    # make the result directory unless it exists already
    if ($self->result_dir) {
	mkdir $self->result_dir
	    unless -d $self->result_dir;
	return File::Spec->catfile ($self->result_dir,
				    $self->result_basename . $suffix);
    }
    return File::Spec->catfile ($self->result_basename . $suffix);
}

#
# if the input file is defined and it exists, do nothing, just return
# its full name; otherwise use other fields to get data from Guardian,
# put them into a local file and return its full name
#
# die if an error occurs
#
sub fetch_data {
    my $self = shift;

    # input file may be defined
    if ($self->input_data) {
	die "File with input data " . $self->input_data . " does not seem to exists.\n"
	    unless -e $self->input_data;
	return $self->input_data;
    }

    # no input give, let's go to Guardian

    my $ua = LWP::UserAgent->new (agent => 'Mozilla/5.0');

    # --- get login ID (from a user name and password)
    my $response = $ua->post ($self->login_url,
			      { name => $self->user,
				pw   => $self->passwd,
			    });
    $response->is_success or
	die "$self->login_url: ", $response->status_line;
    my $content = $response->content;

    my ($id) = $content =~ /name="id"\s+value="([^"]+)"/; #"
    $id = $self->default_id unless $id;

    # --- get data (using the just received ID)
    my $outfile = $self->_get_filename ('-guardian-raw.csv');
    $response = $ua->post ($self->data_url, {
	id           => $id,
	period       => 'year',
    }, ':content_file' => $outfile);
    $response->is_success or
        die "$self->data_url: ", $response->status_line;

    return $outfile;
}

#
# a convenient method combining fetch_data(), parse_data() and
# clean_data()
#
sub get_data {
    my $self = shift;
    my $datafile = $self->fetch_data;
    return $self->clean_data ($self->parse_data ($datafile));
}

1;
__END__


=head1 NAME

GPS::Tracer - A processor of geographical route information

=head1 SYNOPSIS

    # with having an account with Guardian Mobility
    my $tracer = new GPS::Tracer (user => 'my.name', passwd => 'my.password');
    my @files = $tracer->create_all;
    map { print "Created file: ", $_, "\n" } @files;

    # with your own input file
    my $tracer = new GPS::Tracer (input_data => 'my-data.csv');
    my @files = $tracer->create_all;
    map { print "Created file: ", $_, "\n" } @files;

    # create only OziExplorer waypoint file
    my $tracer = new GPS::Tracer (input_data => 'my-data.csv');
    my $data = $tracer->get_data;
    print "Created file: ", $tracer->convert2oziwpt ($data), "\n";

=head1 DESCRIPTION

This module reads geographical location data (longitude, latitude and
time) and converts them into various other formats and pre-processed
files that can be used to display route information, for example using
Google Maps.

The module was developed primarily to read data from the secure web
site provided by Guardian Mobility
(L<http://www.guardianmobility.com>) for their product "Tracer" (data
are published there after they are collected from the Globastar
satellites). However, it was made flexible enough that it can also
read data from a simple CSV format instead from their web site.

Some of the files created by this module were designed to be read by
JavaScript in order to create/update web pages. Example of such usage
is on the pages of the Arctic student expedition FrozenFive
(L<http://frozenfive.org>) - for whom the module was actually created
in the first place, and also in the C<examples> folder of this module
distribution.

One scenario is to use this module in a periodically and automatically
repeated script (on UNIX machine called a 'cronjob') and let the web
pages read data from output files anytime they are accessed. This is
the way how it was used for the FrozenFive expedition.

=head1 Input format

The input data are comma-separated values (CSV) (the first line being
a header line). The only extracted values are those representing
longitude, latitude, elevation and time. They are expected to be in
the following format:

  latitude  = 78.21582
  longitude = 15.73496
  time      = 2007-03-29 11:32:32
  elevation = 532

If no format of the input data is specified, only the following field
indexes are used (indexes starts from 0):

  index    field contents
  -----------------------
    6      time
    7      longitude
    8      latitude
    9      elevation

At the moment, Guardian Mobility data do not record any elevation -
therefore the ninth field is extracted but not used (an therefore also
not much tested).

Example of the Guarding Mobility raw input file is in 'examples' (file
C<trout-guardian.csv>).

If you use your own input data, you specify your input data file by
using parameter C<input_data>, and you can specify your own indexes
for the mentioned fields, as a comma-separated list of four numbers,
by using parameter C<input_format>. For example, if your data are in
file C<my-input.csv> with this contents:

    Time,Longitude,Latitude,Altitude
    2007-04-21 12:48:27,16.78029,76.66666,
    2007-04-21 12:36:05,16.78040,76.66668,
    2007-04-21 12:06:11,16.78067,76.66664,

then you create a Tracer object by:

    my $tracer = new GPS::Tracer (input_data   => 'my-input.csv',
                                  input_format => '0,1,2,3');


=head1 Outputs

All outputs are created, under various file names, in the current
directory, or in the directory given by the parameter
C<result_dir>. Part of the file names is hard-coded, but you can
specify how all the file names will start by using parameter
C<result_basename> (default value is simply C<output>).

The method I<create_all> creates all of them - but you can also use
other methods (see below) for selecting only some outputs. All created
files (showing them with the default prefix C<output>) are:

=head3 output-guardian-raw.csv

This is the copy of the data fetched from the Guardian web site. Such
file is not created when you use your own inputs.

=head3 output-all.xml

An XML file containing I<all> geographical points from the input. The
format is easy-to-process by AJAX-based JavaScript page (see
C<examples> sub-directory):

   <markers>
     <marker elevation="" lat="78.21582" lng="15.73496" time="2007-03-29 11:32:32" type="1" />
     <marker elevation="" lat="78.21057" lng="15.76251" time="2007-03-29 11:47:32" type="0" />
     <marker elevation="" lat="78.20559" lng="15.80085" time="2007-03-29 12:22:58" type="0" />
     ...
   </markers>

The attribute C<type> has value 1 for the first point in a day,
otherwise value 0.

=head3 output-oneperday.xml

An XML file - using the same format as C<output-all.xml> described
above - containing only one point per day (the first one recorder each
day). Plus the last point (if it is far enough from the first point of
the last day - see below about what "far enough" means).

=head3 output-distance.xml

Another XML file - again using the same format as C<output-all.xml>
described above - containing points that are "far enough" from each
other, but always also the first point for every day. The "far enough"
is defined in metres by parameter C<min_distance> (default value is
500).

=head3 output-summary.xml

A very simple XML file containing just a number of days and the total
distance (in kilometres) of the whole recorded route. For example:

   <summary>
     <total days="23" kms="302.676710159346" />
   </summary>

=head3 output.csv

It contains daily total distances in a comma-separated value
format. The headers are C<Date> and C<Metres>. For example:

   Date,Metres
   2007-03-29,8189.15115656143
   2007-03-30,16177.7833535657
   2007-03-31,15906.9657189604
   2007-04-01,16826.279102736
   2007-04-02,1032.79778451296

=head3 output-ozi.wpt

It contains points that are "far enough" (see above) in the format of
OziExplorer (L<http://www.oziexplorer.com/>) waypoints. For example:

   OziExplorer Waypoint File Version 1.1
   WGS 84
   Reserved 2
   magellan
   -1, Mar-29/11:32, 78.21582, 15.73496, , 10, 1, 4, 0, 4227327, 2007-03-29 11:32:32, 0, 0, 0, -777, 8, 0, 17
   -1, 11:47, 78.21057, 15.76251, , 2, 1, 4, 0, 5450740, 2007-03-29 11:47:32, 0, 0, 0, -777, 6, 0, 17
   -1, 12:22, 78.20559, 15.80085, , 2, 1, 4, 0, 5450740, 2007-03-29 12:22:58, 0, 0, 0, -777, 6, 0, 17
   -1, Mar-30/09:26, 78.15688, 15.82510, , 10, 1, 4, 0, 4227327, 2007-03-30 09:26:08, 0, 0, 0, -777, 8, 0, 17
   -1, 13:47, 78.09275, 15.78624, , 2, 1, 4, 0, 5450740, 2007-03-30 13:47:26, 0, 0, 0, -777, 6, 0, 17
   -1, Mar-31/08:53, 78.01713, 15.83664, , 10, 1, 4, 0, 4227327, 2007-03-31 08:53:31, 0, 0, 0, -777, 8, 0, 17
   -1, 09:24, 78.00934, 15.84894, , 2, 1, 4, 0, 5450740, 2007-03-31 09:24:43, 0, 0, 0, -777, 6, 0, 17

=head3 output-chart.png

This is a graph showing daily distances. See an example in C<examples>.

=head1 METHODS

=head3 new

   use GPS::Tracer;
   my $tracer = new GPS::Tracer (@parameters);

The recognized parameters are name-value pairs. The names are:

=head4 C<user>, C<passwd>, C<login_url>, C<data_url>

These are used to access Guardian web site. C<login_url> is a URL of
the main page where C<user> and C<passwd> are used to authenticate to
get data from the C<data_url>. Look into the source code how these
parameters are used.

=head4 C<from_date>, C<to_date>

These parameters specify the time range of the data they will go to
the outputs. Their format is C<YYYY-MM-DD hh:mm:ss> and default values
allow all data to be processed:

  from_date: '0000-00-00 00:00:00'
  to_date:   '9999-99-99 23:59:59'

=head4 C<result_dir>, C<result_basename>

The C<result_dir> defines a directory name where all output files will
be created (default is an empty value which indicates the current
directory). All files are created with the names starting by
C<result_basename>.

=head4 C<min_distance>

Its value (in metres) defines the minimal distance between points in
some outputs (other outputs ignore this parameter and process all
points). Default is 500.

=head4 C<input_data>

It is a name of the input file. If it is not given, the program will
try to fetch data from the Guardian web site (which will fail if other
parameters (C<user>, C<passwd>, C<login_url>, and C<data_url>) are not
given.

=head4 C<input_format>

A string with four digits, separated by commas, each of them
indicating an index (column) in the input CSV file. The four indexes
should indicate columns with time, longitude, latitude, and
elevation. The first column in the file has index 0. Default value is
'6,7,8,9'.

All described parameters can be also set by the "set" methods and read
by the "get" methods. The method names are the same as the parameter
names. If it has a parameter, it is a "set" method, otherwise it is a
"get" method:

=head3 user

   my $tracer = new GPS::Tracer;
   $tracer->user ('my.username');
   print "My user name is: ", $tracer->user, "\n"

=head3 passwd

=head3 from_date

=head3 to_date

=head3 login_url

=head3 data_url

=head3 min_distance

=head3 result_dir

=head3 result_basename

=head3 input_data

=head3 input_format

=head3 create_all

It creates all outputs from the given data. This is the most common
way to use the GPS::Tracer:

    my $tracer = new GPS::Tracer (input_data => 'my-data.csv');
    my @files = $tracer->create_all;
    map { print "Created file: ", $_, "\n" } @files;

The method returns a list of created file names.

=head3 get_data

This method returns a reference to an array with elements being
references to hashes, each such hash containing one route point. Key
names are C<elevation>, C<lat>, C<lng>, C<type> and C<time>. For
example, this code:

    my $tracer = new GPS::Tracer (input_data => 'testing-data/small.csv');
    my @files = $tracer->get_data;
    require Data::Dumper;
    print Data::Dumper->Dump ( [$data], ['DATA']);

prints this:

  $DATA = [
            {
              'elevation' => '',
              'lat' => '76.66664',
              'time' => '2007-04-21 12:06:11',
              'type' => 1,
              'lng' => '16.78067'
            },
            {
              'elevation' => '',
              'lat' => '76.66668',
              'time' => '2007-04-21 12:36:05',
              'type' => 0,
              'lng' => '16.78040'
            },
            {
              'elevation' => '',
              'lat' => '76.66666',
              'time' => '2007-04-21 12:48:27',
              'type' => 0,
              'lng' => '16.78029'
            }
          ];

This method is the first step if you wish to create only some
outputs. Each output has its own method whose single parameters is the
structure produced by I<get_data> method. All of these methods returns
a created file name:

=head3 convert2xml

Creates output C<output-all.xml>.

=head3 summary2csv

Creates output C<output.csv>.

=head3 summary2xml

Creates output C<output-summary.xml>.

=head3 summary2graph

Creates output C<output-chart.png>.

=head3 oneperday2xml

Creates output C<output-oneperday.xml>.

=head3 min_distance2xml

Creates output C<output-distance.xml>.

=head3 convert2oziwpt

Creates output C<output-ozi.wpt>.

=head1 SUPPORTING FILES

The distribution of the GPS::Tracer has a script
C<fetch_and_create.pl> that can be used to produce just described
outputs from the command-line parameters:

  ./fetch_and_create.pl -h

will produce a short help. Assuming that you are fetching data from
Guardian, you can use:

  ./fetch_and_create -u your.user.name -p your.password

which will create all output files in the C<data>
sub-directory. However, more often you would need to define a range of
data for which you are creating "route" files:

  ./fetch_and_create -u your.user.name -p your.password \
                     -b '2007-29-03 00:00:00'           \
                     -e '2007-15-06 23:59:59'

Or, you can pass your own input file, and its CSV format (column
indexes):

  ./fetch_and_create -i data/otherfields.csv \
                     -f '0,1,2,3'
                     

Other supporting files and HTML documenttaion are in the C<docs>
directory. They show how to use output files together with JavaScript
to create and enhance web pages.

=head1 MISSING FEATURES

=over

=item *

There could/should be an easier way how to read input data in more
formats. At the moment, you need to overwrite the full I<get_data> or
even I<fetch_data> method.

=item *

Sometimes, it would be beneficial to have more filtering options then
just C<from_date> and C<to_date>. For example, for the FrozenFive
expedition we had to ignore days when they made trips on snow
mobiles, not on skis.

=item *

There should be a way how to pass user-defined properties for the
created graph.

=item *

Similarly, there should be a way how to pass user-defined properties
for the created OziExplorer waypoints (such as what symbols to
use). As it is already now for the waypoint name (method I<wpt_name>).

=back

=head1 DEPENDENCIES

The GPS::Tracer module uses the following modules:

   Text::CSV::Simple
   XML::Simple
   LWP::UserAgent
   File::Temp
   File::Spec
   Date::Calc
   GD::Graph

=head1 AUTHORS

Martin Senger E<lt>martin.senger@gmail.comE<gt>,
Kim Senger E<lt>senger.kim@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007, Martin Senger, Kim Senger.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.


=cut
