package Geo::TCX::Interactive;
use strict;
use warnings;

our $VERSION = '1.05';
our @ISA=qw(Geo::TCX);

=encoding utf-8

=head1 NAME

Geo::TCX::Interactive - Sub-class of Geo::TCX to be used interactively in the debugger

=head1 SYNOPSIS

  perl -d -MGeo::TCX::Interactive -e '$o= Geo::TCX::Interactive->new("~/Data/Src/Garmin/History"); 1'

or
  perl -d -MGeo::TCX::Interactive -e 0
  $o = Geo::TCX::Interactive->new('~/Data/Src/Garmin/History', work_dir => '~/Data/Garmin/');

or in a script as

  use Geo::TCX::Interactive;
  use Geo::Gpx;
  $o= Geo::TCX::Interactive->new( $sr_dir, recent => $recent, work_dir => $wk_dir );

=head1 DESCRIPTION

A sub-class of L<Geo::TCX>, this module provides methods to manage TCX files interactively in the debugger, e.g. with prompts to select which recent file to edit, modify, and save.

C<Geo::TCX::Interactive> also enables the interactive management and editing of waypoints using L<Geo::Gpx>, that is, by loading/saving *.gpx files, retrieving waypoints from devices, and comparing these points with L<Geo::TCX> Activity and Course files.

There are no return values for a few methods that prompt the user for a response before performing certain actions. This may change in the future if sensible return values can be identified. All values actually returned are documented below.

=cut

use Geo::TCX;
use File::Basename;
use File::Temp qw/ tempfile /;
use IPC::System::Simple qw(system);
use Carp qw(confess croak cluck);
use Cwd;

=head2 Constructor Methods

=over 4

=item new( $foldername, key/values )

Expects a folder as main argument instead of a file name. The user is then prompted to select a file from a list of the most recent ones modified in that folder before returning an instance of the class. Many convenience methods can then be used interactively, particularly if used in the perl debugger.

I<key/values> (all are optional)

Z<>    C<< recent     => # >>      : specifies how many recent files to display, the default being 25.
Z<>    C<< work_dir   => $folder >>: specifies where to save any working files, such as with the save_laps() method.

=back

=cut

sub new {
    my ($proto, $dir) = (shift, shift);
    if ($dir) {
        $dir =~ s/~/$ENV{'HOME'}/ if $dir =~ /^~/;
        $dir =~ s,/*$,/,
    }
    croak 'first argument must be a folder' unless $dir and -d $dir;
    my %opts = @_;
    my $recent_n = $opts{recent} || 25;
    my $class = ref($proto) || $proto;

    my $fname;
    $fname = _select_file_from_dir( $dir, '.tcx', $recent_n );
    my $o = $class->SUPER::new( $fname, work_dir => $opts{work_dir} );
    return $o
}

=head2 Object Methods

=cut

=over 4

=item prompt_and_set_wd( $folder )

Prompts for a choice between existing folders in the current working directory and calls C<set_wd> to set it as the working directory. Returns the path to that working directory.

=back

=cut

sub prompt_and_set_wd {
    my $o = shift;
    croak 'set_wd() expects no arguments' if @_;
    my $wd = $o->set_wd;
    my ($i, @folders) = (0);
    opendir my($dirhandle), $wd;
    for( readdir $dirhandle ) {
        if (-d $wd . "$_" ) {
            next if (m/^[.]/);
            print "(" . ++$i . ") " . $_ . "\n";
            push @folders, $_
       }
    }
    croak "There are no folders to choose from in the current working directory" unless( @folders );
    print "please select which folder to use (#): ";
    my $folder = <STDIN>;
    $folder = $folders[$folder-1];
    return $o->set_wd( $wd . $folder )
}

=over 4

=item save_laps( %options )

is identical to C<< save_laps() >> in L<Geo::TCX> but will prompt the user to confirm the intention to save the laps before continuing. It expects the same I<%options> and returns the same value, except that it returns false if the user does not answer yes at the prompt.

=back

=cut

sub save_laps {
    my $o = shift;
    print "Do you want to save the laps as individual files: ";
    my $answer = _prompt_yes_no();
    if ($answer =~ m/^y|ye|yes$/i) {
        my $ret_val = $o->SUPER::save_laps(@_);
        return $ret_val
    }
    return 0
}

=over 4

=item gpx_load( $file )

Loads a Gpx file into the TCX object. If a directory is specified instead of a file, prompts for a choice among the gpx files found in that directory.

Return a reference to the C<Geo::Gpx> object loaded.

=back

=cut

sub gpx_load {
    my ($o, $file_or_dir) = (shift, shift);
    $file_or_dir =~ s/~/$ENV{'HOME'}/ if $file_or_dir =~ /^~/;
    my $fname;
    if (-d $file_or_dir ) {
        my $dir = $file_or_dir;
        $dir =~ s,/*$,/,;
        $fname = _select_file_from_dir( $dir, '.gpx' )
    } elsif (-f $file_or_dir ) {
        $fname = $file_or_dir;
        my ($name,$path,$ext) = fileparse($fname,'\..*');
        croak 'Gpx file must have a *.gpx extension' unless $ext eq '.gpx'
    } else { croak 'first argument must be a filename or directory' };
    return $o->{gpx} = Geo::Gpx->new( input => $fname );
}

=over 4

=item way_add_endpoints( tolerance_meters => # )

Compare the end points of each lap with all waypoints read in the L<Geo::Gpx> instance (by C<< gpx_load() >> and, if the distance is less than C<tolerance_meters>, prompts whether the waypoint should be added to it.

In the affirmative, prompts what name and description should be given to the new waypoint. Set C<tolerance_meters> to 0 to compare all start/end points of laps with waypoints, or to another desired value.

The default C<tolerance_meters> is 10. Returns true.

=back

=cut

sub way_add_endpoints {
    my ($o, %opts) = @_;
    $opts{tolerance_meters} = 10 unless defined $opts{tolerance_meters};  # could be zero
    my $gpx = $o->gpx;

    for my $i (1 .. $o->laps) {
        my $pass = 0;
        while ($pass++ < 2 ) {
            my ($order, $index);
            $order = ($pass == 1) ? 'first' : 'last';
            $index = ($pass == 1) ? 1 : -1;
            my $end_pt = $o->lap($i)->trackpoint( $index );
            my $has_latitude = $end_pt->LatitudeDegrees;


            my ($closest_wpt, $distance);
            ($closest_wpt, $distance) = $gpx->waypoint_closest_to( $end_pt ) if $has_latitude;
            if ($distance > $opts{tolerance_meters} ) {
                print "\n$order point of lap $i is ", sprintf('%.1f', $distance), " meters from Waypoint \'";
                print $closest_wpt->name, "\'\n   --> do you want to add that point ? ";

                print "$order point of lap $i info:\n";
                $end_pt->summ;
                print $end_pt->LatitudeDegrees . "  " . $end_pt->LongitudeDegrees;
                print "\n\n";

                print $closest_wpt->name, " info:\n";
                $closest_wpt->summ;
                print $closest_wpt->lat . "  " . $closest_wpt->lon;
                print "\n\n";

                my $answer = _prompt_yes_no();
                if ( $answer eq 'y' ) {
                    my $gpx_pt = $end_pt->to_gpx();
                    my ($name, $desc, $cmt) = _prompt_for_waypoint_fields(qw/ name desc cmt /);
                    $gpx_pt->desc( $desc ) if $desc;
                    $gpx_pt->cmt( $cmt ) if $cmt;
                    while ( ! $name ) {
                        print "Waypoint name is required\n";
                        $name = _prompt_for_waypoint_fields('name');
                    }
                    $gpx_pt->name( $name );

                    $gpx->waypoints_add($gpx_pt)
                } else { next }
            }
        }
    }
    return 1
}

=over 4

=item way_add_device( $directory_on_device )

Prompts the user whether they wish to look for waypoints saved on a GPS device and compare them to the waypoints read in the C<Geo::TCX> instance by C<< gpx_load() >>. The device must be currently plugged in with a USB cable.

In the affirmative, compares each waypoint from the device to those in the instance and, if the distance is greater than 1 meter, prompts whether the waypoint should be added to the waypoints in the object.

If no directory is provided, tries to guess where that directory might be (provided the device is plugged in). Returns false if the directory or waypoints file cannot be found (does not die) or if the user responds no at the initial prompt. Otherwise returns true.

=back

=cut

sub way_add_device {
    my ($o, $loc_dir) = (shift, shift);
    print "Do you want to search for waypoints saved on your device and add any new ones to the gpx file?\n";
    print "  - first ensure the device is plugged in with a USB cable\n";
    print "  - note that you will be prompted before adding any new waypoints\n  - ";
    my $answer = _prompt_yes_no();
    return 0 unless $answer =~ m/^y|ye|yes$/i;

    if ($loc_dir) {
        croak "$loc_dir cannot be found" unless -d $loc_dir
    } else {
        my @try_these = (
            "/media/$ENV{USER}/GARMIN/Garmin/Locations/",
            "/media/$ENV{USER}/GARMIN/Garmin/GPX/current/"
        );
        for (@try_these) {
            $loc_dir = $_ if -d $_;
            last if $loc_dir
        }
    }
    unless (defined $loc_dir) {
        print "No Locations/Waypoints folder found on the device\n";
        print "  - is the device plugged in?\n";
        print "  - skipping adding waypoints from the device for now\n";
        print "  - the location of the directory on the device can also be specified with --loc_dir=<path>\n";
        return 0
    }

    my $fname;
    $fname = ($loc_dir =~ /Locations/) ? $loc_dir . '/Locations.fit' : $loc_dir . '/current.gpx';
    unless (-f $fname) {
        print "No Locations/Waypoints file found on the device\n";
        print "  - is the device plugged in?\n";
        print "  - skipping adding waypoints from the device for now\n";
        return 0
    }
    if ($loc_dir =~ /Locations/) {
        my ($fh, $tmp_fname) = tempfile();
        _convert_locations_to_gpx( $fname, $tmp_fname );
        $fname = $tmp_fname
    }

    my $gpx = $o->gpx;

    my $device = Geo::Gpx->new( input => $fname );

    my $iter = $device->iterate_waypoints();
    while ( my $pt = $iter->() ) {
        my ($closest_wpt, $distance) = $gpx->waypoint_closest_to( $pt );
        if ($distance > 1 ) {
            print "Point '", $pt->name, "' from the device is ";
            print sprintf('%.1f', $distance), " meters from Waypoint \'", $closest_wpt->name;
            print "\'\n   --> do you want to add that point? ";
            print "If so please type 'Y' (or type a new name to rename it), ";
            print "otherwise just press 'N' or return:\n";
            my $answer = <STDIN>;
            chomp $answer;
            $answer =~ s,^ *,,;
            $answer =~ s, *$,,;
            if ($answer =~ m/^y|ye|yes$/i) {
                $gpx->waypoints_add( $pt )
            } elsif ($answer =~ m/^n|no*$/i) {
                next
            } else {
                $pt->name( $answer );
                $gpx->waypoints_add( $pt )
            }
        }
    }
    return 1
}

=over 4

=item gpx_save( )

Save the gpx file. The same options as C<Geo::Gpx->save()> are expected but will prompt the user whether to overwrite an existing file if C<$force> is false.

Returns true if the file was saved, false otherwise.

=back

=cut

sub gpx_save {
    my ($o, %opts) = @_;
    if (-f $o->gpx->set_filename and ! $opts{force} ) {
        print "Overwrite " . $o->gpx->set_filename . ": ";
        my $answer = _prompt_yes_no();
        if ($answer =~ m/^y|ye|yes$/i) {
            $opts{force} = 1
        } else { return 0 }
    }
    $o->gpx->save( %opts );
    return 1
}

=over 4

=item gpx( )

Returns the L<Geo::Gpx> instance currently referenced in the object. Croaks if none is found.

=back

=cut

sub gpx {
    my $o = shift;
    my $class = ref $o;
    croak "no waypoint file loaded in $class object" unless defined $o->{gpx};
    return $o->{gpx}
}

=over 4

=item way_clip( $name | $regex | LIST )

Sends the coordinates of waypoints whose name is either C<$name> or matches C<$regex> to the clipboard (all points found are sent to the clipboard). Returns an array of points found.

By default, the regex is case-sensitive; specify C<qr/(?i:...)/> to ignore case.

Alternatively, an array of C<Geo::GXP::Points> can be supplied such that we can call C<< $o->way_clip( $o->gpx->search_desc( qr/(?i:Sunset)/ ) >>.

This method is only supported on unix-based systems that have the C<xclip> utility installed (see BUGS AND LIMITATIONS).

=back

=cut

sub way_clip {
    my $gpx = shift->gpx;

    my @points;
    if ( ref $_[0] and $_[0]->isa('Geo::Gpx::Point' )) {
        @points = @_
    } else {
        my $first_arg = shift;
        if ( ref( $first_arg ) eq 'Regexp' )  {
            @points = $gpx->waypoints_search( name => $first_arg )
        } else {
            my $match = $gpx->waypoints( name => $first_arg );
            push @points, $match if $match
        }
        croak 'no point matches the supplied regex' unless @points
    }
    my @points_reversed = reverse @points;

    for my $pt (@points_reversed) {
        croak 'way_clip() expects list of Geo::Gpx::Point objects' unless $pt->isa('Geo::Gpx::Point');
        my $coords = $pt->lat . ', ';
        $coords   .= $pt->lon;
        system("echo $coords | xclip -selection clipboard")
    }
    return @points
}

=over 4

=item way_device_send()

Send the waypoints to a GPS device, overwriting any existing file. The device must be plugged in.

Some devices have a limit of a 100 waypoints, it will keep the first 100 in the order that they appear in the file. Returns true.

=back

=cut

sub way_device_send {
    my $clone = shift->gpx->clone;
    croak "device_dir not defined" unless $clone->{device_dir};
    # TODO: use proper method once they have been created
    $clone->{tracks} = [];
    $clone->{routes} = [];
    $clone->set_wd( $clone->{device_dir} );
    $clone->save( filename => 'Temp.GPX', force => 1 );
    return 1
}

=over 4

=item lap_summary( # )

prints summary data for a given lap number. Returns true.

=back

=cut

sub lap_summary {
    my ($o, $lap_i) = @_;
    my $lap = $o->{Laps}[$lap_i-1];
    print "---->   Lap ",  $lap_i, "   <----:\n\n";
    for my $key (sort keys %$lap) {
       next if $key eq 'Track';
       next if $key eq 'Temp';          # delete this one too
       print $key, ":", $lap->{$key}, "\n"
    }
    print "\n";
    return 1
}

our $FitConvertPl;
sub _convert_locations_to_gpx {
    require Geo::FIT;
    my ( $fname, $tmp_fname ) = @_;
    if (!defined $FitConvertPl) {
        for (split /:/, $ENV{PATH} ) {
            $FitConvertPl  = $_ . '/locations2gpx.pl';
            last if -f $FitConvertPl
        }
    }
    my @args = ('--outfile=' . $tmp_fname, '--force', $fname);
    system($^X, $FitConvertPl, @args);
    return 1
}

sub _select_file_from_dir {
    my ($dir, $ext, $recent) = @_;

    my $dh;
    # prompt user to select a file from recent *.tcx files showed
    opendir($dh, $dir || die "can't opendir $dir $!");
    my @files = grep { /.*$ext$/i } readdir $dh;
    closedir $dh;
    my @sorted_files = sort { -M ($dir . $a) <=> -M ($dir . $b) } @files;

    my $i = 0;
    $recent ||= @sorted_files;  # kludge as I now (v 1.5) made $recent non-mandatory
    print $sorted_files[$i++], "\t ($i)\n" while ( $i < $recent );
    print "please select which file to use (#): ";
    my $fileno = <STDIN>;
    return $dir . $sorted_files[$fileno-1]
}

sub _prompt_for_waypoint_fields {
    my @values;
    print "Please specify waypoint fields...\n";
    for (@_) {
        print $_ . ": ";
        my $input = <STDIN>;
        chomp $input;
        push @values,  $input
    }
    return @values if wantarray;
    return $values[0]
}

# internal function, so no integrity check
sub _prompt_yes_no {
    my %opts = @_;
    my $default = $opts{default};
    my $prompt_str = ($default) ? "Y/N [". $default . "]?" : "Y/N? ";
    my $answer;
    while( 1 ) {
        print $prompt_str;
        my $answer = <STDIN>;
        return 'y' if ($answer =~ m/^ *(y|ye|yes) *$/i);
        return 'n' if ($answer =~ m/^ *(n|no) *$/i);
        return $default if ($answer eq '');
        print "\n"
    }
}

=head1 EXAMPLES

Coming soon.

=head1 DEPENDENCIES

L<Geo::FIT> is also required to parse FIT files and to add waypoints from a GPS device (except for some older models).

The C<< way_clip() >> method is only supported on unix-based systems that have the C<xclip> utility installed. On Debian based system, you may install it as

  aptitude show xlip
  sudo apt install xclip

See your package manager's instructions for information on how to install it on other systems.

=head1 SEE ALSO

L<Geo::TCX>, L<Geo::Gpx>, L<Geo::FIT>, xclip(1).

=head1 BUGS

No bugs have been reported yet.

=head1 AUTHOR

Patrick Joly

=head1 VERSION

1.05

=cut

1;
