#!/usr/bin/perl
# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.

use Ham::Callsign::DB;
use Ham::Callsign::Display::Format;
use Data::Dumper;
use strict;

my %opts;

LocalGetOptions(\%opts,
	   ["GUI:screen","Database Options:"],
	   ["dbtype=s",
	    "DBI database initialization string (EG: SQLite:/path)"],
	   ["sets=s",
	    "Comma separated list of databases sets to use.  Default: US"],

	   ["GUI:screen","Commands:"],
	   ["c|create","Create database files"],
	   ["i|import=s","Import database files"],
	   ["s|search=s","Search for details on a callsign"],
	   ["F|format-type=s", "Format type (format or dump)"],
	   ["f|format-string=s","Format string (for type = 'format' only)"],
	  ) || exit;

my $dbs;
$dbs = [split(/,\s*/,$opts{'sets'})] if ($opts{'sets'});

my $db = new Ham::Callsign::DB(%opts);
$dbs = [split(/,\s*/,$db->{'sets'})] if (!$dbs && $db->{'sets'});
$dbs = ["US", "DX"] if (!$dbs);

$db->initialize_dbs($dbs);

my $donesomething;

if ($opts{'c'}) {
    $db->create_tables();
    $donesomething = 1;
}

if ($opts{'i'}) {
    $db->load_data($opts{'i'});
    $donesomething = 1;
}

if (!$opts{'s'} && !$donesomething) {
    # assume they just want to search based on an argument if they
    # didn't ask to do anything else.
    $opts{'s'} = $ARGV[0];
}

if ($opts{'s'}) {
    my $results = $db->lookup(uc($opts{'s'}));

    $opts{'F'} = 'format' if (!$opts{'F'});
    $opts{'F'} =~ s/^(.)(.*)/uc($1) . lc($2)/e;
    if (!eval "require Ham::Callsign::Display::$opts{'F'};") {
	die "Failed to load formatting type $opts{F}\n";
    }
    my $formatter = eval "new Ham::Callsign::Display::$opts{F}";
    if (!$results) {
	print "No such callsign found: '$opts{'s'}'\n";
    } else {
	$formatter->display($results, $opts{f});
    }
}

#######################################################################
# Getopt::GUI::Long portability wrapper
#
sub LocalGetOptions {
    if (eval {require Getopt::GUI::Long;}) {
	import Getopt::GUI::Long;
	# optional configure call
	Getopt::GUI::Long::Configure(qw(display_help no_ignore_case
					capture_output));
	return GetOptions(@_);
    }
    require Getopt::Long;
    import Getopt::Long;
    # optional configure call
    Getopt::Long::Configure(qw(auto_help no_ignore_case));
    my $ret = GetOptions(LocalOptionsMap(@_));
    if ($opts{'h'}) {
	die("You need to install the perl Getopt::GUI::Long perl module to get help;\n\n  Even better: if you want a Graphical User Interface, install the QWizard\n  perl module and either the Gtk2 or Tk perl modules.\n\n");
    }
    return $ret;
}

sub LocalOptionsMap {
    my ($st, $cb, @opts) = ((ref($_[0]) eq 'HASH')
			    ? (1, 1, $_[0]) : (0, 2));
    for (my $i = $st; $i <= $#_; $i += $cb) {
	if ($_[$i]) {
	    next if (ref($_[$i]) eq 'ARRAY' && $_[$i][0] =~ /^GUI:/);
	    push @opts, ((ref($_[$i]) eq 'ARRAY') ? $_[$i][0] : $_[$i]);
	    push @opts, $_[$i+1] if ($cb == 2);
	}
    }
    push @opts,"h|help";
    return @opts;
}

=pod

=head1 NAME

cs - command line callsign searching program

=head1 SYNOPSIS

  Usage: cs [OPTIONS]

  OPTIONS:

  Database Options:
    --dbtype=STRING        DBI database initialization string (EG: SQLite:/path)
    --sets=STRING          Comma separated list of databases sets to use.  Default: US

  Commands:
     -c                    Create database files
     -i STRING             Import database files
     -s STRING             Search for details on a callsign
     -F STRING             Format type (format or dump)
     -f STRING             Format string (for type = 'format' only)

=head1 EXAMPLE

  # create (or recreate) the storage database (defaults to ~/.callsigns.sqlite)
  % cs -c

  # get a copy of the fcc zip file and unzip it...
  # then run (this will take a while and the resulting file will be >600Mb!):
  # Get the zip file from http://wireless.fcc.gov/uls/data/complete/a_amat.zip
  % cs -i /path/to/dir/containing/dotdat/files

  # search for the WS6Z details:
  % cs -s WS6Z
  US: E WS6Z      Wesley Hardaker => Davis, CA
  DX:   WS6Z        W = United States

  # if all you're doing is searching, you can drop the -s flag too:
  % cs WS6Z
  US: E WS6Z      Wesley Hardaker => Davis, CA
  DX:   WS6Z        W = United States

=head1 Command Line Options

=over

=item --sets SETNAMES

There are actually multiple databases that can be searched.  By
default, the US and DX sets are searched.  Here are current possibilities:

=over

=item US

Searches a loaded U.S. FCC callsign database (must be loaded using the
-c and -i switches first).

=item DX

An internal database consisting country callsign prefix listings.

=item QRZ

Does an online lookup using the Ham::Scraper class (which must be
loaded first).  The current Ham::Scraper class in CPAN is broken, so
this isn't on by default.  WS6Z has a patched copy that he's trying to
feed back to the author.

=item YFK

If you're using the yfk program from the yfklog package for doing QSO
logging, this module will look up previous contact information with
that person.  You need to specify your callsign in the ~/.callsignrc
file with a line like "callsign WS6Z" for example so it finds the
right database lookup table to use.

=back

=item -f I<FORMATTING STRING>

Is a printf-like string containing %{NUMBERS:VARIABLE} which will
control the output.  EGs:

  # normal output
  % cs WS6Z
  US: E WS6Z      Wesley Hardaker => Davis, CA
  DX:   WS6Z         W = United States

  # just a listing of the state
  % cs -f '%{-8.8:thecallsign} %{state}' WS6Z
  WS6Z     CA
  WS6Z

See the -F flag below for dumping all available data to see what can be used.

=item -F I<FORMAT TYPE>

The -F flag will try to load a generic
Ham::Callsign::Display::I<FORMAT> module to display the results, where
I<FORMAT> is the option to the -F flag.  By default this is the
"Format" module (which gets translated to
Ham::Callsign::Display::Format).  You can also write your own module
or use the other "Dump" module:

  # dump all the possible data from a callsign resource
  cs -F  WS6Z
  Data for WS6Z in US:
    certifier_last_name:           Hardaker
    region_code:                   6
    group_code:                    A
    request_sequence:              1
  ...

=back

=head1 Configuration

By default the I<$HOME/.callsignrc> file will be read which can
contain various types of configuration settings:

=over

=item format: I<FORMAT>

Formatting string similar to -f

=item DBformat: I<FORMAT>

Formatting for a particular DB type.  EG, the following will be the
formatting used for the US database but all others (eg, QRZ and DX)
will continue to use the default formatting:

  USformat: %{3.3:FromDB}:   %{-8.8:thecallsign} %{first_name} %{last_name} %{street_address} %{qth}

=item sets: I<SETS>

Sets setting, similar to --sets

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Ham::Callsign::DB(3)

=cut

