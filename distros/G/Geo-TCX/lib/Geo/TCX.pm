package Geo::TCX;
use strict;
use warnings;

our $VERSION = '1.01';

=encoding utf-8

=head1 NAME

Geo::TCX - Parse and edit and TCX activity and course files from GPS training devices

=head1 SYNOPSIS

  use Geo::TCX;

=head1 DESCRIPTION

C<Geo::TCX> enables the parsing and editing of TCX activity and course files. TCX files follow an XML schema developed by Garmin and common to its GPS sports devices. Among other methods, the module enables laps from an activity to be saved as individual *.tcx files, split into separate laps based on a given point, merged, or converted to courses to plan a future activity.

The module supports files containing a single Activity or Course. Database files consisting of multiple activities or courses are not supported.

The documentation regarding TCX files in general uses the terms history and activity quite interchangeably, including in the user guides such as the one for the Garmin Edge device the author of this module is using. In C<Geo::TCX>, the terms Activity/Activities are used to refer to tracks recorded by a device (consistently with the XML mark-up) and Course/Courses refer to planned tracks meant to be followed during an activity (i.e. the term history is seldomly used).

=cut

use Geo::TCX::Lap;
use File::Basename;
use Cwd qw(cwd abs_path);
use Carp qw(confess croak cluck);

=head2 Constructor Methods (class)

=over 4

=item new( $filename or $str_ref, work_dir => $working_directory )

loads and returns a new Geo::TCX instance using the I<$filename> supplied as first argument or a string reference equivalent to the xml tags of a *.tcx file.

  $o = Geo::TCX->new('2022-08-11-10-27-15.tcx');
or
  $o = Geo::TCX->new( \'...');

C<work_dir> or C<wd> for short can be set to specify where to save any working files (such as with the save_laps() method). The module never actually L<chdir>'s, it just keeps track of where the user wants to save files (and not have to type filenames with path each time), hence it is always defined.

The working directory can be supplied as a relative (to L<Cwd::cwd>) or absolute path but is internally stored by C<set_wd()> as a full path. If C<work_dir> is ommitted, it is set based on the path of the I<$filename> supplied or the current working directory if the constructor is called with a string reference.

=back

=cut

sub new {
    my ($proto, $first_arg) = (shift, shift);
    my %opts = @_;
    my $o  = {};
    my $class = ref($proto) || $proto;
    bless($o, $class);

    my $txt;
    if (ref( $first_arg ) eq 'SCALAR') {
        $txt = $$first_arg
    } else {
        croak 'first argument must be a filename' unless -f $first_arg;
        $txt = do { local(@ARGV, $/) = $first_arg; <> };
        $o->set_filename($first_arg)
    }

    $txt =~ s,\r,,g;                               # if it's a windows file
    $txt =~ s,>\s+<,><,g;
    $o->{tag_creator} = $1 if $txt =~ s/(<Creator.*<\/Creator>)//;

    # Activities/Activity  - are as recorded  by an EDGE 705 device
    # Courses/Course       - are as converted by an EDGE 705 device from an Activity

    $o->{tag_xml_version} = $1             if $txt =~ /(<.xml version[^>]*>)/;
    $o->{tag_trainingcenterdatabase} = $1  if $txt =~ /(<TrainingCenterDatabase.*<\/TrainingCenterDatabase>)/;
    $o->{tag_activities} = $1              if $txt =~ /(<Activities.*<\/Activities>)/;
    $o->{tag_activity} = $1                if $txt =~ /(<Activity.*<\/Activity>)/;
    $o->{tag_courses} = $1                 if $txt =~ /(<Courses.*<\/Courses>)/;
    $o->{tag_course} = $1                  if $txt =~ /(<Course(?!s).*<\/Course>)/;

    # Id seems only for Activities/Activity...
    if ($o->{tag_activity}) {
        $o->{tag_id} = $1            if $o->{tag_activity} =~ /<Activity.*<Id>(.*)<\/Id>/;
        $o->{tag_activity_type} = $1 if $o->{tag_activity} =~ /<Activity Sport="([^"]+)"/;
    }

    # ... and Name only for Courses/Course
    if ($o->{tag_course}) {
        # will pick up device name under Creator if we are not specific about the Course tag
        $o->{tag_name} = $1 if $o->{tag_course} =~ /<Course.*<Name>(.*)<\/Name>/
    }

    $o->{tag_author}  = $1  if $txt =~ /(<Author.*<\/Author>)/;
    $o->_parse_author_tag if $o->{tag_author};

    my @Lap;
    if ( $o->{tag_activity} ) {
        my $i = 0;
        my $lap;
        while ( $o->{tag_activity} =~ /(\<Lap StartTime=.*?\>.*?\<\/Lap\>)/g ) {
            my ($lapstring, $last_point_previous_lap);
            $lapstring = $1;
            $last_point_previous_lap = $lap->trackpoint(-1) if $i > 0;
            $lap = Geo::TCX::Lap->new($lapstring, ++$i, $last_point_previous_lap);
            push @{ $o->{Laps} }, $lap
        }
    }
    if ( $o->{tag_course} ) {
        # in Courses, data is structured as <Lap>...</Lap><Lap>...</Lap><Track>...</Track><Track>...</Track>
        # actually, not sure just seem like it's one long ... track, not multiple ones, which complicates things
        my $xml_str = $o->{tag_course};

        my (@lap_tags, @lap_endpoints, @track_tags);

        if ( $xml_str =~ m,(<Lap>.*</Lap>),s ) {
            my $str = $1;
            @lap_tags = split(/(?s)<\/Lap>\s*<Lap>/, $str );
            if (@lap_tags == 0) { push @lap_tags, $str }
        }

        for my $i (0 .. $#lap_tags) {
            my ($end_pos, $end_pt);
            if ( $lap_tags[$i] =~ m,<EndPosition>(.*)</EndPosition>,s ) {
                $end_pt = Geo::TCX::Trackpoint->new( $1 );
                push @lap_endpoints, $end_pt
            }
            # since split removed tags sometimes at ^ of string for other at $
            # let's remove them all and add back
            $lap_tags[$i] =~ s,</?Lap>,,g;
            $lap_tags[$i] =~ s,^,<Lap>,g;
            $lap_tags[$i] =~ s,$,</Lap>,g
        }
        my $track_str;
        if ( $xml_str =~ m,(<Track>.*</Track>),s ) {
            $track_str = $1;
        }

        my $t = Geo::TCX::Track->new( $track_str );
        if (@lap_tags ==1)  { $track_tags[0] = $track_str }
        else  {
            my ($t1, $t2);
            for my $i (0 .. $#lap_tags ) {
                if ($i < $#lap_tags) {
                    ($t1, $t2) = $t->split_at_point_closest_to( $lap_endpoints[$i] );
                    push @track_tags, $t1->xml_string;
                    $t = $t2
                } else { push @track_tags, $t->xml_string } # ie don't split the last track portion
            }
        }

        my $lap;
        for my  $i (0 .. $#lap_tags) {
            my ($lapstring, $last_point_previous_lap);
            $lapstring = $lap_tags[$i] . $track_tags[$i];
            $last_point_previous_lap = $lap->trackpoint(-1) if $i > 0;
            $lap = Geo::TCX::Lap->new($lapstring, ++$i, $last_point_previous_lap);
            push @{ $o->{Laps} }, $lap
        }
    }

    my $n = $o->laps;
    die "cannot find any laps, must not be a *.tcx file or str" unless $n;
    print "\nFound " . $n, ($n > 1 ? " Laps": " Lap"), "\n\n";
    $o->{_txt} = $txt;                      # only for debugging
    $o->set_wd( $opts{work_dir} || $opts{wd} );
    return $o
}

=head2 Constructor Methods (object)

=over 4

=item activity_to_course( key/values )

returns a new <Geo::TCX> instance as a course, based on the current activity.

All I<key/values> are optional:

Z<>    C<< lap => I<#> >>: converts lap number I<#> to a course, dropping all other laps. All laps are converted if C<lap> is omitted.
Z<>    C<< course_name => I<$string> >>: the name for the course. The name will be the lap's C<StartTime> if a value is not specified.
Z<>    C<< filename => I<$filename> >>: will call C<set_filename()> with this value.
Z<>    C<< work_dir => I<$work_dir> >>: if omitted, it will be set to the same as that of the current object.

=back

=cut

sub activity_to_course {
    my $clone = shift->clone;
    my %opts = @_;
    croak 'this instance is already a course' if $clone->is_course;
    my $wd = $opts{work_dir} || $opts{wd} || $clone->set_wd();

    my (@laps, $course);
    @laps = $opts{lap} ? ($opts{lap}) : (1 .. $clone->laps);

    for my $lap_i (@laps) {
        my $str = $clone->save_laps( [ $lap_i ], nosave => 1, course => 1, course_name => $opts{course_name} );
        my $course_i = Geo::TCX->new( \$str, work_dir => $wd );
        if ( defined $course ) {
            push @{ $course->{Laps} }, $course_i->lap(1)
        } else { $course = $course_i }
    }
    $course->set_filename( $opts{filename} );
    return $course
}

=over 4

=item clone()

Returns a deep copy of a C<Geo::TCX> instance.

  $clone = $o->clone;

=back

=cut

sub clone {
    my $clone;
    eval(Data::Dumper->Dump([ shift ], ['$clone']));
    confess $@ if $@;
    return $clone
}

=head2 Object Methods

=over 4

=item lap( # )

Returns the lap object corresponding to the lap number I<#> specified. I<#> is one-indexed but negative numbers can be used to count from the end, e.g C<-1> to get the last lap.

=back

=cut

sub lap {
    my ($o, $lap_i, %exists) = (shift, shift);
    croak 'requires a single integer as argument' if ! $lap_i or @_;
    $lap_i = $o->_lap_number($lap_i);
    return $o->{Laps}[$lap_i-1]
}

=over 4

=item laps( qw/ # # ... / )

Returns a list of L<Geo::TCX::Lap> objects corresponding to the lap number(s) specified, or all laps if called without arguments. This method is useful as an access for the number of laps (i.e. without arguments in scalar context).

=back

=cut

sub laps {
    my $o = shift;
    return @{$o->{Laps}} unless @_;
    my @numbers = @_;
    my @laps;
    for my $lap_i (@numbers) {
        $lap_i = $o->_lap_number($lap_i);
        push @laps, $o->{Laps}[$lap_i-1]
    }
    return @laps
}

=over 4

=item merge_laps( #1, #2 )

Merges lap I<#1> with lap I<#2> and returns true. Both laps must be consecutive laps and the number of laps in the object decreases by one.

The C<TotalTimeSeconds> and C<DistanceMeters> aggregates of the merged lap are adjusted. For Activity laps, performance metrics are also adjusted. For Course laps, C<EndPosition> is also adjusted. See L<Geo::TCX::Lap>.

=back

=cut

sub merge_laps {
    my ($o, $i1, $i2, %exists) = (shift, shift, shift);
    croak 'merge_laps() requires two integers as argument' if ! $i2 or @_;
    croak 'can only merge consecutive laps' unless ($i2 - $i1)==1;
    my $l1 = $o->lap($i1);
    my $l2 = $o->lap($i2);

    my $lap = $l1->merge($l2, as_is => 1);

    splice @{ $o->{Laps}}, $i1 - 1, 2, $lap;
    return 1
}

=over 4

=item split_lap( #, $trackpoint_no )

Splits lap number I<#> at the specified I<$trackpoint_no> into two laps and returns true. The number of laps in the object increases by one.

=back

=cut

sub split_lap {
    my ($o, $lap_i, $pt_no, %exists) = (shift, shift, shift);
    croak 'split_lap() requires two integers as argument' if ! $pt_no or @_;
    $lap_i = $o->_lap_number($lap_i);
    my ($lap_a, $lap_b) = $o->lap($lap_i)->split($pt_no);
    splice @{ $o->{Laps}}, $lap_i -1, 1, ( $lap_a, $lap_b );
    return 1
}

=over 4

=item split_lap_at_point_closest_to(#, $point or $trackpoint or $coord_str )

Equivalent to C<split_lap()> but splits the specified lap I<#> at the trackpoint that lies closest to a given L<Geo::Gpx::Point>, L<Geo::TCX::Trackpoint>,  or a string that can be interpreted as coordinates by C<< Geo::Gpx::Point->flex_coordinates >>. Returns true.

=back

=cut

sub split_lap_at_point_closest_to {
    my ($o, $lap_i, $to_pt) = (shift, shift, shift);
    croak 'split_lap_at_point_closest_to() expects two arguments' if @_;
    $lap_i = $o->_lap_number($lap_i);
    $to_pt = Geo::Gpx::Point->flex_coordinates( \$to_pt ) unless ref $to_pt;
    my ($closest_pt, $min_dist, $pt_no) = $o->lap($lap_i)->point_closest_to( $to_pt );
    # here we can print some info about the original track and where it will be split
    $o->split_lap( $lap_i, $pt_no );
    return 1
}

=over 4

=item time_add( @duration )

=item time_subtract( @duration )

Perform L<DateTime> math on the timestamps of each trackpoint in the track by adding the specified time as per the syntax of L<DateTime>'s C<add()> and C<subtract()> methods. Returns true.

Perform L<Date::Time> math on the timestamps of each lap's starttime and trackpoint by adding the specified time as per the syntax of L<Date::Time>'s C<add()> method. Returns true.

=back

=cut

sub time_add {
    my $o = shift;
    my @duration = @_;
    my @laps = @{$o->{Laps}};
    for my $l (@laps) {
        $l->time_add( @duration )
    }
    return 1
}

sub time_subtract {
    my $o = shift;
    my @duration = @_;
    my @laps = @{$o->{Laps}};
    for my $l (@laps) {
        $l->time_subtract( @duration )
    }
    return 1
}

=over 4

=item delete_lap( # )

=item keep_lap( # )

delete or keep the specified lap I<#> form the object. Returns the list of laps removed in both cases.

=back

=cut

sub delete_lap {
    my ($o, $lap_i) = (shift, shift);
    croak 'requires a single integer as argument' unless $lap_i;
    $lap_i = $o->_lap_number( $lap_i );
    my @removed = splice @{ $o->{Laps}}, $lap_i - 1, 1;
    return @removed
}

sub keep_lap {
    my ($o, $lap_i) = (shift, shift);
    my @keep = $o->delete_lap($lap_i);
    my @removed = @{ $o->{Laps}};
    @{ $o->{Laps}} = @keep;
    return @removed
}

=over 4

=item save_laps( \@laplist , key/values )

saves each lap as a separate *.tcx file in the working directory as per <set_wd()>. The filenames will consist of the original source file's name, suffixed by the respective lap number.

An array reference can be provided to save only a a subset of lap numbers.

I<key/values> are:

Z<>    C<course>: converts activity lap(s) as course files if true.
Z<>    C<< course_name => $string >>: is only relevant with C<course> and will set the name of the course to I<$string>.
Z<>    C<force>:  overwrites existing files if true, otherwise it won't.
Z<>    C<indent>: adds white space and indents the xml mark-up in the saved file if true.
Z<>    C<nosave>: no files are actually saved if true. Useful if only interested in the xml string of the last lap processed.

C<course_name> will be ignored if there is more than one lap and the lap's C<StartTime> will be used instead. This is to avoid having multiple files with the same name given that devices use this tag when listing available courses. Acttvity files have an C<Id> tag instead of C<Name> and the laps's C<StartTime> is used at all times.  It is easy to edit any of these tags manually in a text editor; just look for the C<< <Name>...</Name> >> tag or C<< <Id>...</Id> >> tags near the top of the files.

Returns a string containing the xml of the last lap processed which can subsequently be passed directly to C<< Geo::TCX->new() >> to construct a new instsance.

=back

=cut

sub save_laps {
    my $o = shift;
    my @laps_to_save;
    if (ref ($_[0]) eq 'ARRAY') {
        my $aref = shift;
        for my $lap_i (@$aref) {
            push @laps_to_save, $o->lap($lap_i)
        }
    } else { @laps_to_save = @{$o->{Laps}} }
    my %opts = @_;

    my ($as_course, $fname);
    $as_course = 1 if $o->is_course or $opts{course};
    $fname = $o->set_filename;
    croak 'no filename found, set_filename(<name>) before saving' unless $fname;

    # as mentioned in the pod, files will be saved in work_dir as they are new files
    # use has expectation that that's where working files go
    my ($name, $path, $ext) = fileparse( $fname, '\..*' );
    my $wd = $o->set_wd();

    my ($tags_before_lap, $tags_after_lap) = $o->_prep_tags( %opts );

    # Id (for Activity) or Name (for Course) tag
    my $tag_id_or_name = '';
    if ($as_course) {
        # a bit tricky to determine Name when saving as course, bear with us here
        if (@laps_to_save == 1 ) {
            my $name;
            if ( defined $opts{course_name} ) { $name = $opts{course_name} }
            else {
                if ($o->is_course) { $name = $o->{tag_name} }
                else { $name = 'StartTimePlaceHolder' }
            }
            $tag_id_or_name  .= '<Name>' . $name . '</Name>'
        } else  {
            $tag_id_or_name  .= '<Name>' . 'StartTimePlaceHolder' . '</Name>';
            # i.e. it's StartTime regardless if more than one lap
        }
    } else { $tag_id_or_name .= '<Id>' .   'StartTimePlaceHolder' . '</Id>' }

    # Now from what is left below, we can create a save() method to save a file with multilaps. Simply move the $tags_before_lap and $tags_after_lap outside of the loop, continue to add to the $str (i.e. it gets appended to at all times) and we put the saving block outside of the loop at the very end.
    # Yah ! And don't distance_net

    my $str;
    for my $i (0 .. $#laps_to_save) {
        my $l = $laps_to_save[$i]->clone;
        $l->distance_net;

        $str  = $tags_before_lap;
        $str .= $tag_id_or_name;
        $str =~ s/StartTimePlaceHolder/$l->StartTime/e;

        my $xml_lap = $l->xml_string( course => $as_course,  indent => $opts{indent} );
        $str .= $xml_lap;
        $str .= $tags_after_lap;

        unless ($opts{nosave}) {
            my $fname_lap = $wd . $name . '-Lap-' . ($i+1) . $ext;
            croak "$fname_lap already exists" if -f $fname_lap and !$opts{force};
            open(my $fh, '>', $fname_lap) or die "can't open $fname_lap $!";
            print $fh $str
        }
    }
    return $str
}

=over 4

=item save( key/values )

saves the current instance.

I<key/values> are:

Z<>    C<filename>: the name of the file to be saved. Has the effect calling C<set_filename()> and changes the name of the file in the current instance (e.g. akin to "save as" in many applications).
Z<>    C<force>:  overwrites existing files if true, otherwise it won't.
Z<>    C<indent>: adds white space and indents the xml mark-up in the saved file if true.

Returns a string containing the xml representation of the file.

=back

=cut

sub save {
    my ($o, %opts) = @_;

    my $fname;
    if ( $opts{filename} ) { $fname = $o->set_filename( $opts{filename} ) }
    else { $fname = $o->set_filename() }
    croak 'no filename found, provide one with set_filename() or use key \'filename\'' unless $fname;
    croak "$fname already exists" if -f $fname and !$opts{force};

    my ($tags_before_lap, $tags_after_lap) = $o->_prep_tags( indent => $opts{indent} );
    my $str = $tags_before_lap;
    if ($o->is_course)   {  $str .= '<Name>' . $o->{tag_name} . '</Name>' }
    else                 {  $str .= '<Id>' .   $o->{tag_id}   . '</Id>'   }

    my ($str_activity_laps, $str_course_laps, $str_course_tracks);
    for my $lap ($o->laps) {
        my $str_lap = $lap->xml_string( indent => $opts{indent} );

        if ($lap->is_course) {
            # for courses, the xml track tags are not nested within the lap
            # tags but follow them instead. Yah, weird. So need to collect
            # the strings seperately then assemble after the loop
            if ( $str_lap =~ s,\s*(<Lap>.*</Lap>)\s*(<Track>.*</Track>)\s*,,s ) {
                $str_course_laps   .= $1;
                $str_course_tracks .= $2
            } else { croak "cannot find lap or track tags in Laps object" }
        } else {
            $str_activity_laps .= $str_lap
        }
    }

    # Flatten the course tracks into a a single track
    $str_course_tracks =~ s,</Track>\s*<Track>,,gs if $str_course_tracks;

    if ($o->is_course) {  $str .= $str_course_laps . $str_course_tracks }
    else {                $str .= $str_activity_laps }

    $str .= $tags_after_lap;

    open(my $fh, '>', $fname) or die "can't open $fname $!";
    print $fh $str;
    return $str
}

sub _prep_tags {
    my ($o, %opts) = @_;

    # identical to save_laps()
    my ($newline, $tab, $as_course);
    $newline = $opts{indent} ? "\n" : '';
    $tab     = $opts{indent} ? '  ' : '';
    $as_course = 1 if $o->is_course or $opts{course};

    #
    # Prepare the mark-up that appears *outside* the laps (therefore will be common to all saved laps)

    # These tag collection blocks could be shortened but it might not become more legible.
    # The many variables help for debugging as the resulting string can be an extremely
    # long flat string

    # we first collect the tags we need, we assemble them later
    # we need these 3 pairs of tags so declare in a block
    my ($tag_open_trainctrdb, $tag_close_trainctrdb);
    my ($tag_open_activity_or_course_plural,   $tag_close_activity_or_course_plural );
    my ($tag_open_activity_or_course_singular, $tag_close_activity_or_course_singular);

    if ($o->{tag_trainingcenterdatabase} =~ /(<TrainingCenterDatabase[^>]*>)/) {
        $tag_open_trainctrdb  = $1;
        $tag_close_trainctrdb = '</TrainingCenterDatabase>'
    } else { croak 'can\'t find the expected <TrainingCenterDatabase ...> tag' }

    # in history files (in mine at least), these tags ever appear only once, nesting all of the data within them
    #   <Activities><Activity Sport="Biking">
    #   <Courses><Course>
    # Activity is nested within Activities and similarly Course is nested within Courses

    if ($o->{tag_activities}) {
        if ( $o->{tag_activities} =~ /(<Activities[^>]*>)/) {
            $tag_open_activity_or_course_plural    = $1
        } else { croak 'can\'t find the expected <Activities> tag' }
        if ( $o->{tag_activity} =~ /(<Activity[^>]*>)/ ) {
            $tag_open_activity_or_course_singular    = $1
        } else { croak 'can\'t find the expected <Activity Sport="..."> tag' }
        ($tag_close_activity_or_course_singular, $tag_close_activity_or_course_plural) = ('</Activity>', '</Activities>')
    }
    if ($o->{tag_courses}) {
        if ( $o->{tag_courses} =~ /(<Courses[^>]*>)/) {
            $tag_open_activity_or_course_plural    = $1
        } else { croak 'can\'t find the expected <Courses> tag' }
        if ( $o->{tag_course} =~ /(<Course(?!s)[^>]*>)/ ) {
            $tag_open_activity_or_course_singular    = $1
        } else { croak 'can\'t find the expected <Course> tag' }
        ($tag_close_activity_or_course_singular, $tag_close_activity_or_course_plural) = ('</Course>', '</Courses>')
    }
    if ($as_course and !$o->{tag_courses}) {   # i.e. when saving an activity as a course
        $tag_open_activity_or_course_plural    = '<Courses>';
        $tag_open_activity_or_course_singular  = '<Course>';
        ($tag_close_activity_or_course_singular, $tag_close_activity_or_course_plural) = ('</Course>', '</Courses>')
    }

    # assembling the tags to get the mark-up that appears *before* the laps
    my $tags_before_lap = '';
    $tags_before_lap  = $o->{tag_xml_version} . "\n";
    $tags_before_lap .= $tag_open_trainctrdb;
    $tags_before_lap .= $newline .  $tab .      $tag_open_activity_or_course_plural;
    $tags_before_lap .= $newline . ($tab x 2) . $tag_open_activity_or_course_singular;
    $tags_before_lap .= $newline . ($tab x 3);

    # assembling the tags to get the mark-up that appears *after* the laps
    my ($tags_after_lap) = '';
    $tags_after_lap  = $newline . ($tab x 3) . $o->{tag_creator} if $o->{tag_creator};
    $tags_after_lap .= $newline . ($tab x 2) . $tag_close_activity_or_course_singular;
    $tags_after_lap .= $newline .  $tab      . $tag_close_activity_or_course_plural;
    $tags_after_lap .= $newline .  $tab      . $o->{tag_author} if $o->{tag_author};
    $tags_after_lap .= $newline .  $tag_close_trainctrdb;

    return $tags_before_lap, $tags_after_lap
}

=over 4

=item set_filename( $filename )

Sets/gets the filename. Returns the name of the file with the complete path.

=back

=cut

sub set_filename {
    my ($o, $fname) = (shift, shift);
    return $o->{_fileABSOLUTENAME} unless $fname;
    croak 'set_filename() takes only a single name as argument' if @_;
    my $wd;
    if ($o->_is_wd_defined) { $wd = $o->set_wd }
    # set_filename gets called before set_wd by new() so can't access work_dir until initialized

    my ($name, $path, $ext);
    ($name, $path, $ext) = fileparse( $fname, '\..*' );
    if ($wd) {
        if ( ! ($fname =~ /^\// ) ) {
            # ie if fname is not an abolsute path, adjust $path to be relative to work_dir
            ($name, $path, $ext) = fileparse( $wd . $fname, '\..*' )
        }
    }
    $o->{_fileABSOLUTEPATH} = abs_path( $path ) . '/';
    $o->{_fileABSOLUTENAME} = $o->{_fileABSOLUTEPATH} . $name . $ext;
    croak 'directory ' . $o->{_fileABSOLUTEPATH} . ' doesn\'t exist' unless -d $o->{_fileABSOLUTEPATH};
    $o->{_fileNAME} = $name;
    $o->{_filePATH} = $path;
    $o->{_fileEXT} = $ext;
    $o->{_filePARSEDNAME} = $fname;
    # _file* keys only for debugging, should not be used anywhere else
    return $o->{_fileABSOLUTENAME}
}

=over 4

=item set_wd( $folder )

Sets/gets the working directory and checks the validity of that path. Relative paths are supported for setting but only full paths are returned or internally stored.

The previous working directory is also stored in memory; can call <set_wd('-')> to switch back and forth between two directories.

Note that it does not call L<chdir>, it simply sets the path for the eventual saving of files.

=back

=cut

sub set_wd {
    my ($o, $dir) = (shift, shift);
    croak 'set_wd() takes only a single folder as argument' if @_;
    my $first_call = ! $o->_is_wd_defined;  # ie if called for 1st time -- at construction by new()

    if (! $dir) {
        return $o->{work_dir} unless $first_call;
        my $fname = $o->set_filename;
        if ($fname) {
            my ($name, $path, $ext) = fileparse( $fname );
            $o->set_wd( $path )
        } else { $o->set_wd( cwd )  }
    } else {
        $dir =~ s/^\s+|\s+$//g;                 # some clean-up
        $dir =~ s/~/$ENV{'HOME'}/ if $dir =~ /^~/;
        $dir = $o->_set_wd_old    if $dir eq '-';

        if ($dir =~ m,^[^/], ) {                # convert rel path to full
            $dir =  $first_call ? cwd . '/' . $dir : $o->{work_dir} . $dir
        }
        $dir =~ s,/*$,/,;                       # some more cleaning
        1 while ( $dir =~ s,/\./,/, );          # support '.'
        1 while ( $dir =~ s,[^/]+/\.\./,, );    # and '..'
        croak "$dir not a valid directory" unless -d $dir;

        if ($first_call) { $o->_set_wd_old( $dir ) }
        else {             $o->_set_wd_old( $o->{work_dir} ) }
        $o->{work_dir} = $dir
    }
    return $o->{work_dir}
}

# if ($o->set_filename) { $o->set_wd() }      # if we have a filename
# else {                  $o->set_wd( cwd ) } # if we don't

sub _set_wd_old {
    my ($o, $dir) = @_;
    $o->{work_dir_old} = $dir if $dir;
    return $o->{work_dir_old}
}

sub _is_wd_defined { return defined shift->{work_dir} }

=over 4

=item is_activity()

=item is_course()

True if the C<Geo::TCX> instance is a of the type indicated by the method, false otherwise.

=back

=cut

sub is_activity { return defined shift->{tag_activity} }
sub is_course {   return defined shift->{tag_course} }

=over 4

=item activity( $string )

Gets/sets the Activity type as detected from C<\<Activity Sport="*"\>>, sets it to I<$string> if provided. Garmin devices (at least the Edge) record activities as being of types 'Running', 'Biking', 'MultiSport', etc.

=back

=cut

sub activity {
    my ($o, $activity) = @_;
    # should I check what activity types are allowed?  Must they be single words?
    if ($activity) {
        $o->{tag_activity} =~ s,(\<Activity Sport=)"[^"]*",$1"$activity",;
        return $o->activity
    }
    $activity = $1 if $o->{tag_activity} =~ /<Activity Sport="([^"]*)"/;
    return $activity
}

=over 4

=item author( key/value )

Gets/sets the fields of the Author tag. Supported keys are C<Name>, C<LangID>, C<PartNumber> and all excpect a string as value.

The C<Build> field can also be accesses but the intent is to set it, the string supplied should be in the form of an xml string in the way this tag appears in a *.tcx file (e.g. Version, VersionMajor, VersionMinor, Type, …). Simply access that key of the returned hash ref to see what is should look like.

Returns a hash reference of key/value pairs.

This method is under development and behaviour could change in the future.

=back

=cut

# the only purpose I have for this at this stage is to set the name mostly, we'll see if I have a need for other, but will take the Build key as is and not set up sub-keys yet.
# I mostly want to use this method so that I can set it if I want for any *.tcx I generate (Courses, save laps), with the version number of my module as well
# the Build entries contain integers but I am not supporting this at this point
#
# <Author xsi:type="Application_t"
# <Name>string</Name>
# <Build containis
#     <Version>
#        VersionMajor
#        VersionMinor
#        BuildMajor
#        BuildMinor
#     </Version>
#     <Type>Release<Type>
# </Build>
# <LangID>EN</LangID>
# <PartNumber>digit and dash string</PartNumber>
# </Author>

my %possible_author_keys;
my @author_keys = qw/ Name Build LangID PartNumber /;
$possible_author_keys{$_} = 1 for @author_keys;

# NB: similar to the _file* keys, the _Author href can not exist at any time
sub _parse_author_tag {
    my $o = shift;
    $o->{_Author} = {};
    my $href = $o->{_Author};
    my $author_xml;
    if ( $o->{tag_author} =~ m,<Author\s+([^=]+="[^"]+")>(.*)<\/Author>, ) {
        $href->{string_inside_author_tag} = $1;
        $author_xml = $2
    }
    for my $key (@author_keys) {
        $href->{$key} = $1 if $author_xml =~ m,<$key>(.+)</$key>,
    }
    return $o->{tag_author}
}

sub _update_author_tag {
    my $o = shift;
    my $href = $o->{_Author};

    my $str = '<Author ' . $href->{string_inside_author_tag} . '>';
    for my $key (@author_keys) {
        $str .= "<$key>" . $href->{$key} . "</$key>" if defined $href->{key}
    }
    $str .= '</Author>';
    $o->{tag_author} = $str;
    return $o->{tag_author}
}

sub author {
    my ($o, %keys_values) = @_;
    my $href = $o->{_Author};
    croak 'no author tag found in object' if (!%keys_values and ! $href);
    if (%keys_values) {
        for my $key (keys %keys_values) {
            croak 'unsupported Author field' unless $possible_author_keys{$key};
            $href->{$key} = $keys_values{$key}
        }
        $o->_update_author_tag
    }
    return $href
}

# returns the actual lap number if a negative index is passed to count from the end
sub _lap_number {
    my ($o, $lap_i, $n, %exists) = (shift, shift);
    $n = $o->laps;
    $lap_i += $n + 1 if $lap_i < 0;
    $exists{$_} = 1 for (1 .. $n);
    croak "Lap $lap_i does not exist" unless $exists{$lap_i};
    return $lap_i
}

=head1 EXAMPLES

Coming soon.

=head1 BUGS

Nothing to report yet.

=head1 AUTHOR

Patrick Joly

=head1 VERSION

1.01

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2022, Patrick Joly C<< <patjol@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Geo::Gpx>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL,
INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR
INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

1;
