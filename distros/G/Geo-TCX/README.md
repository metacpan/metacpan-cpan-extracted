# NAME

Geo::TCX - Parse and edit and TCX activity and course files from GPS training devices

# SYNOPSIS

    use Geo::TCX;

# DESCRIPTION

`Geo::TCX` enables the parsing and editing of TCX activity and course files, including those from FIT files. TCX files follow an XML schema developed by Garmin and common to its GPS sports devices. Among other methods, the module enables laps from an activity to be saved as individual \*.tcx files, split into separate laps based on a given point, merged, or converted to courses to plan a future activity.

FIT activity and course files are supported provided that [Geo::FIT](https://metacpan.org/pod/Geo%3A%3AFIT) is installed and that the `fit2tcx.pl` script it provides appears on the user's path.

The module supports files containing a single Activity or Course. Database files consisting of multiple activities or courses are not supported.

The documentation regarding TCX files in general uses the terms history and activity quite interchangeably, including in the user guides such as the one for the Garmin Edge device the author of this module is using. In `Geo::TCX`, the terms Activity/Activities are used to refer to tracks recorded by a device (consistently with the XML mark-up) and Course/Courses refer to planned tracks meant to be followed during an activity (i.e. the term history is seldomly used).

## Constructor Methods (class)

- new( $filename or $str\_ref, work\_dir => $working\_directory )

    loads and returns a new Geo::TCX instance using the _$filename_ supplied as first argument or a string reference equivalent to the xml tags of a \*.tcx file.

        $o = Geo::TCX->new('2022-08-11-10-27-15.tcx');
      or
        $o = Geo::TCX->new( \'...');

    The optional `work_dir` (or `wd` for short) specifies where to save any working files, such as with the save\_laps() method. It can be supplied as a relative path or as an absolute path. If `work_dir` is omitted, it is set based on the path of the _$filename_ supplied or the current working directory if the constructor is called with an XML string reference (see `set_wd()` for more info).

## Constructor Methods (object)

- activity\_to\_course( key/values )

    returns a new <Geo::TCX> instance as a course, based on the current activity.

    All _key/values_ are optional:

        `lap => _#_`: converts lap number _#_ to a course, dropping all other laps. All laps are converted if `lap` is omitted.
        `course_name => _$string_`: the name for the course. The name will be the lap's `StartTime` if a value is not specified.
        `filename => _$filename_`: will call `set_filename()` with this value.
        `work_dir => _$work_dir_`: if omitted, it will be set to the same as that of the current object.

- clone()

    Returns a deep copy of a `Geo::TCX` instance.

        $clone = $o->clone;

## Object Methods

- lap( # )

    Returns the lap object corresponding to the lap number _#_ specified. _#_ is one-indexed but negative numbers can be used to count from the end, e.g `-1` to get the last lap.

- laps( qw/ # # ... / )

    Returns a list of [Geo::TCX::Lap](https://metacpan.org/pod/Geo%3A%3ATCX%3A%3ALap) objects corresponding to the lap number(s) specified, or all laps if called without arguments. This method is useful as an access for the number of laps (i.e. without arguments in scalar context).

- merge\_laps( #1, #2 )

    Merges lap _#1_ with lap _#2_ and returns true. Both laps must be consecutive laps and the number of laps in the object decreases by one.

    The `TotalTimeSeconds` and `DistanceMeters` aggregates of the merged lap are adjusted. For Activity laps, performance metrics are also adjusted. For Course laps, `EndPosition` is also adjusted. See [Geo::TCX::Lap](https://metacpan.org/pod/Geo%3A%3ATCX%3A%3ALap).

- split\_lap( #, $trackpoint\_no )

    Splits lap number _#_ at the specified _$trackpoint\_no_ into two laps and returns true. The number of laps in the object increases by one.

- split\_lap\_at\_point\_closest\_to(#, $point or $trackpoint or $coord\_str )

    Equivalent to `split_lap()` but splits the specified lap _#_ at the trackpoint that lies closest to a given [Geo::Gpx::Point](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoint), [Geo::TCX::Trackpoint](https://metacpan.org/pod/Geo%3A%3ATCX%3A%3ATrackpoint),  or a string that can be interpreted as coordinates by `Geo::Gpx::Point->flex_coordinates`. Returns true.

- time\_add( @duration )
- time\_subtract( @duration )

    Perform [DateTime](https://metacpan.org/pod/DateTime) math on the timestamps of each trackpoint in the track by adding the specified time as per the syntax of [DateTime](https://metacpan.org/pod/DateTime)'s `add()` and `subtract()` methods. Returns true.

    Perform [Date::Time](https://metacpan.org/pod/Date%3A%3ATime) math on the timestamps of each lap's starttime and trackpoint by adding the specified time as per the syntax of [Date::Time](https://metacpan.org/pod/Date%3A%3ATime)'s `add()` method. Returns true.

- delete\_lap( # )
- keep\_lap( # )

    delete or keep the specified lap _#_ form the object. Returns the list of laps removed in both cases.

- save\_laps( \\@laplist , key/values )

    saves each lap as a separate \*.tcx file in the working directory as per &lt;set\_wd()>. The filenames will consist of the original source file's name, suffixed by the respective lap number.

    An array reference can be provided to save only a a subset of lap numbers.

    _key/values_ are:

        `course`: converts activity lap(s) as course files if true.
        `course_name => $string`: is only relevant with `course` and will set the name of the course to _$string_.
        `force`:  overwrites existing files if true, otherwise it won't.
        `indent`: adds white space and indents the xml mark-up in the saved file if true.
        `nosave`: no files are actually saved if true. Useful if only interested in the xml string of the last lap processed.

    `course_name` will be ignored if there is more than one lap and the lap's `StartTime` will be used instead. This is to avoid having multiple files with the same name given that devices use this tag when listing available courses. Acttvity files have an `Id` tag instead of `Name` and the laps's `StartTime` is used at all times.  It is easy to edit any of these tags manually in a text editor; just look for the `<Name>...</Name>` tag or `<Id>...</Id>` tags near the top of the files.

    Returns a string containing the xml of the last lap processed which can subsequently be passed directly to `Geo::TCX->new()` to construct a new instsance.

- save( key/values )

    saves the current instance.

    _key/values_ are:

        `filename`: the name of the file to be saved. Has the effect calling `set_filename()` and changes the name of the file in the current instance (e.g. akin to "save as" in many applications).
        `force`:  overwrites existing files if true, otherwise it won't.
        `indent`: adds white space and indents the xml mark-up in the saved file if true.

    Returns a string containing the xml representation of the file.

- set\_filename( $filename )

    Sets/gets the filename. Returns the name of the file with the complete path.

    If the instance was created from a FIT file, the filename is set to the same name but with a `.tcx` extension by default.

- set\_wd( $folder )

    Sets/gets the working directory for any eventual saving of the \*.tcx file and checks the validity of that path. It can be set as a relative path (i.e. relative to the actual [Cwd](https://metacpan.org/pod/Cwd)) or as an absolute path, but is always returned as a full path.

    This working directory is always defined. The previous one is also stored in memory, such that `set_wd('-')` switches back and forth between two directories. The module never actually `chdir`'s, it just keeps track of where the user wishes to save files.

- is\_activity()
- is\_course()

    True if the `Geo::TCX` instance is a of the type indicated by the method, false otherwise.

- activity( $string )

    Gets/sets the Activity type as detected from `\<Activity Sport="*"\`>, sets it to _$string_ if provided. Garmin devices (at least the Edge) record activities as being of types 'Running', 'Biking', 'MultiSport', etc.

- author( key/value )

    Gets/sets the fields of the Author tag. Supported keys are `Name`, `LangID`, `PartNumber` and all excpect a string as value.

    The `Build` field can also be accesses but the intent is to set it, the string supplied should be in the form of an xml string in the way this tag appears in a \*.tcx file (e.g. Version, VersionMajor, VersionMinor, Type, …). Simply access that key of the returned hash ref to see what is should look like.

    Returns a hash reference of key/value pairs.

    This method is under development and behaviour could change in the future.

# EXAMPLES

Coming soon.

# BUGS

Nothing to report yet.

# AUTHOR

Patrick Joly

# VERSION

1.06

# LICENSE AND COPYRIGHT

Copyright (c) 2022, Patrick Joly `<patjol@cpan.org>`. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# SEE ALSO

[Geo::Gpx](https://metacpan.org/pod/Geo%3A%3AGpx), [Geo::FIT](https://metacpan.org/pod/Geo%3A%3AFIT).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
