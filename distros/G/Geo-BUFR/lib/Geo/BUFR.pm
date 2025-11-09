package Geo::BUFR;

# Copyright (C) 2010-2025 MET Norway
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=begin General_remarks

Some general remarks on variables
---------------------------------

@data = data array
@desc = descriptor array

These 2 arrays are in one to one correspondence, but note that some C
descriptors (2.....) are included in @desc even though there is no
associated data value in message (the corresponding element in @data
is set to ''). These descriptors without value are printed in
dumpsection4 without line number, to distinguish them from 'real' data
descriptors.

$idesc = index of descriptor in @desc (and @data)
$bm_idesc = index of bit mapped descriptor in @data (and @desc, see below)

Variables related to bit maps:

$self->{BUILD_BITMAP}
$self->{BITMAP_INDEX}
$self->{NUM_BITMAPS}
$self->{BACKWARD_DATA_REFERENCE}

These are explained in sub new

$self->{BITMAP_OPERATORS}

Reference to an array containing operators in BUFR table C which are
associated with bit maps, i.e. one of 22[2-5]000 and 232000; the
operator being added when it is met in section 3 in message. Note that
an operator may occur multiple times, which is why we have to use an
array, not a hash.

$self->{CURRENT_BITMAP}

Reference to an array which contains the indexes of data values for
which data is marked as present in 031031 in the current used bit map.
E.g. [2,3,6] if bitmap = 1100110.

$self->{BITMAP_START}

Array containing for each bit map the index of the first element
descriptor for which the bit map relates.

$self->{BITMAPS}

Reference to an array, one element added for each bit map operator in
$self->{BITMAP_OPERATORS} and each subset (although for compression we
assume all subset have identical bitmaps and operate with subset 0
only, i.e. $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] instead of
...->[$isub]), the element being a reference to an array containing
consecutive pairs of indexes ($idesc, $bm_idesc), used to look up in
@data and @desc arrays for the value/descriptor and corresponding bit
mapped value/descriptor.

$self->{REUSE_BITMAP}

Gets defined when 237000 is met, undefined if 237255 or 235000 is met.
Originally for each subset (but defined for subset 0 only if
compression) set to reference an array of the indexes of data values
to which the last used bitmap relates (fetched from $self->{BITMAPS}),
then shifted as the new element in $self->{BITMAPS} is built up.

For operator 222000 ('Quality information follows') the bit mapped
descriptor should be a 033-descriptor. For 22[3-5]/232 the bit mapped
value should be the data value of the 22[3-5]255/232255 descriptors
following the operator in BUFR section 3, with bit mapped descriptor
$desc[bm_idesc] equal to $desc[$idesc] (with data width and reference
value changed for 225255)

=end General_remarks

=cut

require 5.006;
use strict;
use warnings;
use Carp;
use Cwd qw(getcwd);
use FileHandle;
use File::Spec::Functions qw(catfile);
use Scalar::Util qw(looks_like_number);
use Time::Local qw(timegm);
# Also requires Storable if sub copy_from() is called

require DynaLoader;
our @ISA = qw(DynaLoader);
our $VERSION = '1.41';

# This loads BUFR.so, the compiled version of BUFR.xs, which
# contains bitstream2dec, bitstream2ascii, dec2bitstream,
# ascii2bitstream and null2bitstream
bootstrap Geo::BUFR $VERSION;


# Some package globals
our $Verbose = 0;

# $Verbose or $self->{VERBOSE} > 0 leads to the following output, all
# except for level 6 on lines starting with 'BUFR.pm: ':
# 1 -> B,C,D tables used (full path)
# 2 -> Identifying stages of processing, displaying length of sections
#      and some additional data from section 1 and 3
# 3 -> All descriptors and values extracted
# 4 -> Operator specific information, including delayed replication
#      and repetition
# 5 -> BUFR compression specific information
# 6 -> Calling dumpsection0,1,3

our $Spew = 0; # To avoid the overhead of subroutine calls to _spew
               # (which is called a lot), $Spew is set to 1 if global
               # $Verbose or at least one object VERBOSE is set > 1.
               # This should speed up execution a bit in the common
               # situation when no verbose output (except possibly
               # the BUFR tables used) is requested
our $Nodata = 0; # If set to true will prevent decoding of section 4
our $Noqc = 0; # If set to true will prevent decoding (or encoding) of
               # any descriptors after 222000 is met
our $Reuse_current_ahl = 0;
               # If set to true will cause cet_current_ahl() to return
               # last AHL extracted and not undef if currently
               # processed BUFR message has no (immediately preceding)
               # AHL
our $Strict_checking = 0; # Ignore recoverable errors in BUFR format
                          # met during decoding. User might set
                          # $Strict_checking to 1: Issue warning
                          # (carp) but continue decoding, or to 2:
                          # Croak instead of carp

# The next 2 operators are separated for readability. Public interface should
# provide only set_show_all_operators() to set both of these (to the same value)
our $Show_all_operators = 0; # = 0: show just the most informative C operators in dumpsection4
                             # = 1: show all operators (as far as possible)
our $Show_replication = 0; # = 0: don't include replication descriptors (F=1) in dumpsection4
                           # = 1: include replication descriptors(F=1) in dumpsection4,
                           #  with X in FXY replaced with actual number X' of replicated descriptors.
                           #  X' is replaced by 0 if X' > 99

our %BUFR_table;
# Keys: PATH      -> full path to the chosen directory of BUFR tables
#       FORMAT    -> supported formats are BUFRDC and ECCODES
#       B$version -> hash containing the B table $BUFR_table/B$version
#                    key: element descriptor (6 digits)
#                    value: a \0 separated string containing the B table fields
#                            $name, $unit, $scale, $refval, $bits
#       C$version -> hash containing the C table $BUFR_table/C$version
#                    key: table B descriptor (6 digits) of the code/flag table
#                    value: a new hash, with keys the possible values listed in
#                           the code table, the value the corresponding text
#       D$version -> hash containing the D table $BUFR_table/D$version
#                    key: sequence descriptor
#                    value: a space separated string containing the element
#                    descriptors (6 digits) the sequence descriptor expands to
$BUFR_table{FORMAT} = 'BUFRDC'; # Default. Might in the future be changed to ECCODES

our %Descriptors_already_expanded;
# Keys: Text string "$table_version $unexpanded_descriptors"
# Values: Space separated string of expanded descriptors

sub _croak {
    my $msg = shift;
    croak "BUFR.pm ERROR: $msg";
}

## Carp or croak (or ignore) according to value of $Strict_checking
sub _complain {
    my $msg = shift;
    if ($Strict_checking == 1) {
        carp "BUFR.pm WARNING: $msg";
    } elsif ($Strict_checking > 1) {
        croak "BUFR.pm ERROR: $msg";
    }
    return;
}

sub _spew {
    my $self = shift;
    my $level = shift;
    if (ref($self)) {
        # Global $Verbose overrides object VERBOSE
        return if $level > $self->{VERBOSE} && $level > $Verbose;
    } else {
        return if $level > $Verbose;
    }
    my $format = shift;
    if (@_) {
        printf "BUFR.pm: $format\n", @_;
    } else {
        print "BUFR.pm: $format\n";
    }
    return;
}

## Object constructor
sub new {
    my $class = shift;
    my $self = {};
    $self->{VERBOSE} = 0;
    $self->{CURRENT_MESSAGE} = 0;
    $self->{CURRENT_SUBSET} = 0;
    $self->{BUILD_BITMAP} = 0; # Will be set to 1 if a bit map needs to
                               # be built
    $self->{BITMAP_INDEX} = 0; # Used for building up bit maps; will
                               # be incremented for each 031031
                               # encountered, then reset to 0 when bit
                               # map is finished built
    $self->{NUM_BITMAPS} = 0;  # Will be incremented each time an
                               # operator descriptor which uses a bit
                               # map is encountered in section 3
    $self->{BACKWARD_DATA_REFERENCE} = 1; # Number the first bitmap in
                               # a possible sequence of bitmaps which
                               # relate to the same scope of data
                               # descriptors. Starts as 1 when (or
                               # rather before) the first bitmap is
                               # constructed, will then be reset to
                               # the number of the next bitmap to be
                               # constructed each time 235000 is met
    $self->{NUM_CHANGE_OPERATORS} = 0; # Will be incremented for
                               # each of the operators CHANGE_WIDTH,
                               # CHANGE_CCITTIA5_WIDTH, CHANGE_SCALE,
                               # CHANGE_REFERENCE_VALUE (actually
                               # NEW_REFVAL_OF), CHANGE_SRW and
                               # DIFFERENCE_STATISTICAL_VALUE in effect

    # If number of arguments is odd, first argument is expected to be
    # a string containing the BUFR message(s)
    if (@_ % 2) {
        $self->{IN_BUFFER} = shift;
    }

    # This part is not documented in the POD. Better to remove it?
    while (@_) {
        my $parameter = shift;
        my $value = shift;
        $self->{$parameter} = $value;
    }
    bless $self, ref($class) || $class;
    return $self;
}

## Copy contents of the bufr object in first argument. With no extra
## arguments, will copy (clone) everything. With 'metadata' as second
## argument, will copy just the metadata in section 0, 1 and 3 (and
## all of section 2 if present)
sub copy_from {
    my $self = shift;
    my $bufr = shift;
    _croak("First argument to copy_from must be a Geo::BUFR object")
        unless ref($bufr) eq 'Geo::BUFR';
    my $what = shift || 'all';
    if ($what eq 'metadata') {
        for (qw(
            BUFR_EDITION
            MASTER_TABLE CENTRE SUBCENTRE UPDATE_NUMBER OPTIONAL_SECTION
            DATA_CATEGORY INT_DATA_SUBCATEGORY LOC_DATA_SUBCATEGORY
            MASTER_TABLE_VERSION LOCAL_TABLE_VERSION YEAR MONTH DAY
            HOUR MINUTE SECOND LOCAL_USE DATA_SUBCATEGORY YEAR_OF_CENTURY
            NUM_SUBSETS OBSERVED_DATA COMPRESSED_DATA DESCRIPTORS_UNEXPANDED
            SEC2_STREAM
            )) {
            if (exists $bufr->{$_}) {
                $self->{$_} = $bufr->{$_};
            } else {
                # This cleanup might be necessary if BUFR edition changes
                delete $self->{$_} if exists $self->{$_};
            }
        }
    } elsif ($what eq 'all') {
        %$self = ();
        while (my ($key, $value) = each %{$bufr}) {
            if ($key eq 'FILEHANDLE') {
                # If a file has been associated with the copied
                # object, make a new filehandle rather than just
                # copying the reference
                $self->fopen($bufr->{FILENAME});
            } elsif (ref($value) and $key !~ /[BCD]_TABLE/) {
                # Copy the whole structure, not merely the reference.
                # Using Clone would be cheaper, but unfortunately
                # Clone is not a core module, while Storable is
                require Storable;
                import Storable qw(dclone);
                $self->{$key} = dclone($value);
            } else {
                $self->{$key} = $value;
            }
        }
    } else {
        _croak("Don't recognize second argument '$what' to copy_from()");
    }
    return 1;
}


##  Set debug level. Also set $Spew to true if debug level > 1 is set
##  (we don't bother to reset $Spew to 0 if all debug levels later are
##  reset to 0 or 1)
sub set_verbose {
    my $self = shift;
    my $verbose = shift;
    if (ref($self)) {
        # Just myself
        $self->{VERBOSE} = $verbose;
        $self->_spew(2, "Verbosity level for object set to %d", $verbose);
    } else {
        # Whole class
        $Verbose = $verbose;
        Geo::BUFR->_spew(2, "Verbosity level for class set to %d", $verbose);
    }
    $Spew = $verbose if $verbose > 1;
    return 1;
}

##  Turn off (or on) decoding of section 4
sub set_nodata {
    my $self = shift;
    my $n = shift;
    $Nodata = defined $n ? $n : 1; # Default is 1
    Geo::BUFR->_spew(2, "Nodata set to %d", $Nodata);
    return 1;
}

##  Turn off (or on) decoding of quality information
sub set_noqc {
    my $self = shift;
    my $n = shift;
    $Noqc = defined $n ? $n : 1; # Default is 1
    Geo::BUFR->_spew(2, "Noqc set to %d", $Noqc);
    return 1;
}

##  Require strict checking of BUFR format
sub set_strict_checking {
    my $self = shift;
    my $n = shift;
    _croak "Value for strict checking not provided"
        unless defined $n;
    $Strict_checking = $n;
    Geo::BUFR->_spew(2, "Strict_checking set to %d", $Strict_checking);
    return 1;
}

## Show replication descriptors (with X in FXY replaced by actual
## number of descriptors replicated, adjusted to 0 if > 99) and all
## data description operators when calling dumpsection4
sub set_show_all_operators {
    my $self = shift;
    my $n = shift;
    $Show_all_operators = defined $n ? $n : 1; # Default is 1
    $Show_replication = $Show_all_operators;
    Geo::BUFR->_spew(2, "Show_all_operators set to %d", $Show_all_operators);
    return 1;
}

## Accessor methods for BUFR sec0-3 ##
sub get_bufr_length {
    my $self = shift;
    return defined $self->{BUFR_LENGTH} ? $self->{BUFR_LENGTH} : undef;
}
sub set_bufr_edition {
    my ($self, $bufr_edition) = @_;
    _croak "BUFR edition number not provided in set_bufr_edition"
        unless defined $bufr_edition;
    _croak "BUFR edition number must be an integer, is '$bufr_edition'"
        unless $bufr_edition =~ /^\d+$/;
    _croak "Not an allowed value for BUFR edition number: $bufr_edition"
        unless $bufr_edition >= 0 and $bufr_edition < 5;
        # BUFR edition 0 is in fact in use in ECMWF MARS archive
    $self->{BUFR_EDITION} = $bufr_edition;
    return 1;
}
sub get_bufr_edition {
    my $self = shift;
    return defined $self->{BUFR_EDITION} ? $self->{BUFR_EDITION} : undef;
}
sub set_master_table {
    my ($self, $master_table) = @_;
    _croak "BUFR master table not provided in set_master_table"
        unless defined $master_table;
    _croak "BUFR master table must be an integer, is '$master_table'"
        unless $master_table =~ /^\d+$/;
    # Max value that can be stored in 1 byte is 255
    _croak "BUFR master table exceeds limit 255, is '$master_table'"
        if $master_table > 255;
    $self->{MASTER_TABLE} = $master_table;
    return 1;
}
sub get_master_table {
    my $self = shift;
    return defined $self->{MASTER_TABLE} ? $self->{MASTER_TABLE} : undef;
}
sub set_centre {
    my ($self, $centre) = @_;
    _croak "Originating/generating centre not provided in set_centre"
        unless defined $centre;
    _croak "Originating/generating centre must be an integer, is '$centre'"
        unless $centre =~ /^\d+$/;
    # Max value that can be stored in 2 bytes is 65535
    _croak "Originating/generating centre exceeds limit 65535, is '$centre'"
        if $centre > 65535;
    $self->{CENTRE} = $centre;
    return 1;
}
sub get_centre {
    my $self = shift;
    return defined $self->{CENTRE} ? $self->{CENTRE} : undef;
}
sub set_subcentre {
    my ($self, $subcentre) = @_;
    _croak "Originating/generating subcentre not provided in set_subcentre"
        unless defined $subcentre;
    _croak "Originating/generating subcentre must be an integer, is '$subcentre'"
        unless $subcentre =~ /^\d+$/;
    _croak "Originating/generating subcentre exceeds limit 65535, is '$subcentre'"
        if $subcentre > 65535;
    $self->{SUBCENTRE} = $subcentre;
    return 1;
}
sub get_subcentre {
    my $self = shift;
    return defined $self->{SUBCENTRE} ? $self->{SUBCENTRE} : undef;
}
sub set_update_sequence_number {
    my ($self, $update_number) = @_;
    _croak "Update sequence number not provided in set_update_sequence_number"
        unless defined $update_number;
    _croak "Update sequence number must be a nonnegative integer, is '$update_number'"
        unless $update_number =~ /^\d+$/;
    _croak "Update sequence number exceeds limit 255, is '$update_number'"
        if $update_number > 255;
    $self->{UPDATE_NUMBER} = $update_number;
    return 1;
}
sub get_update_sequence_number {
    my $self = shift;
    return defined $self->{UPDATE_NUMBER} ? $self->{UPDATE_NUMBER} : undef;
}
sub set_optional_section {
    my ($self, $optional_section) = @_;
    _croak "Optional section (0 or 1) not provided in set_optional_section"
        unless defined $optional_section;
    _croak "Optional section must be 0 or 1, is '$optional_section'"
        unless $optional_section eq '0' or $optional_section eq '1';
    $self->{OPTIONAL_SECTION} = $optional_section;
    return 1;
}
sub get_optional_section {
    my $self = shift;
    return defined $self->{OPTIONAL_SECTION} ? $self->{OPTIONAL_SECTION} : undef;
}
sub set_data_category {
    my ($self, $data_category) = @_;
    _croak "Data category not provided in set_data_category"
        unless defined $data_category;
    _croak "Data category must be an integer, is '$data_category'"
        unless $data_category =~ /^\d+$/;
    _croak "Data category exceeds limit 255, is '$data_category'"
        if $data_category > 255;
    $self->{DATA_CATEGORY} = $data_category;
    return 1;
}
sub get_data_category {
    my $self = shift;
    return defined $self->{DATA_CATEGORY} ? $self->{DATA_CATEGORY} : undef;
}
sub set_int_data_subcategory {
    my ($self, $int_data_subcategory) = @_;
    _croak "International data subcategory not provided in set_int_data_subcategory"
        unless defined $int_data_subcategory;
    _croak "International data subcategory must be an integer, is '$int_data_subcategory'"
        unless $int_data_subcategory =~ /^\d+$/;
    _croak "International data subcategory exceeds limit 255, is '$int_data_subcategory'"
        if $int_data_subcategory > 255;
    $self->{INT_DATA_SUBCATEGORY} = $int_data_subcategory;
    return 1;
}
sub get_int_data_subcategory {
    my $self = shift;
    return defined $self->{INT_DATA_SUBCATEGORY} ? $self->{INT_DATA_SUBCATEGORY} : undef;
}
sub set_loc_data_subcategory {
    my ($self, $loc_data_subcategory) = @_;
    _croak "Local subcategory not provided in set_loc_data_subcategory"
        unless defined $loc_data_subcategory;
    _croak "Local data subcategory must be an integer, is '$loc_data_subcategory'"
        unless $loc_data_subcategory =~ /^\d+$/;
    _croak "Local data subcategory exceeds limit 255, is '$loc_data_subcategory'"
        if $loc_data_subcategory > 255;
    $self->{LOC_DATA_SUBCATEGORY} = $loc_data_subcategory;
    return 1;
}
sub get_loc_data_subcategory {
    my $self = shift;
    return defined $self->{LOC_DATA_SUBCATEGORY} ? $self->{LOC_DATA_SUBCATEGORY} : undef;
}
sub set_data_subcategory {
    my ($self, $data_subcategory) = @_;
    _croak "Data subcategory not provided in set_data_subcategory"
        unless defined $data_subcategory;
    _croak "Data subcategory must be an integer, is '$data_subcategory'"
        unless $data_subcategory =~ /^\d+$/;
    _croak "Data subcategory exceeds limit 255, is '$data_subcategory'"
        if $data_subcategory > 255;
    $self->{DATA_SUBCATEGORY} = $data_subcategory;
    return 1;
}
sub get_data_subcategory {
    my $self = shift;
    return defined $self->{DATA_SUBCATEGORY} ? $self->{DATA_SUBCATEGORY} : undef;
}
sub set_master_table_version {
    my ($self, $master_table_version) = @_;
    _croak "Master table version not provided in set_master_table_version"
        unless defined $master_table_version;
    _croak "BUFR master table version must be an integer, is '$master_table_version'"
        unless $master_table_version =~ /^\d+$/;
    _croak "BUFR master table version exceeds limit 255, is '$master_table_version'"
        if $master_table_version > 255;
    $self->{MASTER_TABLE_VERSION} = $master_table_version;
    return 1;
}
sub get_master_table_version {
    my $self = shift;
    return defined $self->{MASTER_TABLE_VERSION}
        ? $self->{MASTER_TABLE_VERSION} : undef;
}
sub set_local_table_version {
    my ($self, $local_table_version) = @_;
    _croak "Local table version not provided in set_local_table_version"
        unless defined $local_table_version;
    _croak "Local table version must be an integer, is '$local_table_version'"
        unless $local_table_version =~ /^\d+$/;
    _croak "Local table version exceeds limit 255, is '$local_table_version'"
        if $local_table_version > 255;
    $self->{LOCAL_TABLE_VERSION} = $local_table_version;
    return 1;
}
sub get_local_table_version {
    my $self = shift;
    return defined $self->{LOCAL_TABLE_VERSION}
        ? $self->{LOCAL_TABLE_VERSION} : undef;
}
sub set_year_of_century {
    my ($self, $year_of_century) = @_;
    _croak "Year of century not provided in set_year_of_century"
        unless defined $year_of_century;
    _croak "Year of century must be an integer, is '$year_of_century'"
        unless $year_of_century =~ /^\d+$/;
    _complain "year_of_century > 100 in set_year_of_century: $year_of_century"
        if $year_of_century > 100;
    # A common mistake is to set year_of_century for year 2000 to 0, should be 100
    $self->{YEAR_OF_CENTURY} = $year_of_century == 0 ? 100 : $year_of_century;
    return 1;
}
sub get_year_of_century {
    my $self = shift;
    if (defined $self->{YEAR_OF_CENTURY}) {
        return $self->{YEAR_OF_CENTURY};
    } elsif (defined $self->{YEAR}) {
        my $yy = $self->{YEAR} % 100;
        return $yy == 0 ? 100 : $yy;
    } else {
        return undef;
    }
}
sub set_year {
    my ($self, $year) = @_;
    _croak "Year not provided in set_year"
        unless defined $year;
    _croak "Year must be an integer, is '$year'"
        unless $year =~ /^\d+$/;
    _croak "Year exceeds limit 65535, is '$year'"
        if $year > 65535;
    $self->{YEAR} = $year;
    return 1;
}
sub get_year {
    my $self = shift;
    return defined $self->{YEAR} ? $self->{YEAR} : undef;
}
sub set_month {
    my ($self, $month) = @_;
    _croak "Month not provided in set_month"
        unless defined $month;
    _croak "Month must be an integer, is '$month'"
        unless $month =~ /^\d+$/;
    _complain "Month must be 1-12 in set_month, is '$month'"
        if $month == 0 || $month > 12;
    $self->{MONTH} = $month;
    return 1;
}
sub get_month {
    my $self = shift;
    return defined $self->{MONTH} ? $self->{MONTH} : undef;
}
sub set_day {
    my ($self, $day) = @_;
    _croak "Day not provided in set_day"
        unless defined $day;
    _croak "Day must be an integer, is '$day'"
        unless $day =~ /^\d+$/;
    _complain "Day must be 1-31 in set_day, is '$day'"
        if $day == 0 || $day > 31;
    $self->{DAY} = $day;
    return 1;
}
sub get_day {
    my $self = shift;
    return defined $self->{DAY} ? $self->{DAY} : undef;
}
sub set_hour {
    my ($self, $hour) = @_;
    _croak "Hour not provided in set_hour"
        unless defined $hour;
    _croak "Hour must be an integer, is '$hour'"
        unless $hour =~ /^\d+$/;
    _complain "Hour must be 0-23 in set_hour, is '$hour'"
        if $hour > 23;
    $self->{HOUR} = $hour;
    return 1;
}
sub get_hour {
    my $self = shift;
    return defined $self->{HOUR} ? $self->{HOUR} : undef;
}
sub set_minute {
    my ($self, $minute) = @_;
    _croak "Minute not provided in set_minute"
        unless defined $minute;
    _croak "Minute must be an integer, is '$minute'"
        unless $minute =~ /^\d+$/;
    _complain "Minute must be 0-59 in set_minute, is '$minute'"
        if $minute > 59;
    $self->{MINUTE} = $minute;
    return 1;
}
sub get_minute {
    my $self = shift;
    return defined $self->{MINUTE} ? $self->{MINUTE} : undef;
}
sub set_second {
    my ($self, $second) = @_;
    _croak "Second not provided in set_second"
        unless defined $second;
    _croak "Second must be an integer, is '$second'"
        unless $second =~ /^\d+$/;
    _complain "Second must be 0-59 in set_second, is '$second'"
        if $second > 59;
    $self->{SECOND} = $second;
    return 1;
}
sub get_second {
    my $self = shift;
    return defined $self->{SECOND} ? $self->{SECOND} : undef;
}
sub set_local_use {
    my ($self, $local_use) = @_;
    _croak "Local use not provided in set_local use"
        unless defined $local_use;
    $self->{LOCAL_USE} = $local_use;
    return 1;
}
sub get_local_use {
    my $self = shift;
    return defined $self->{LOCAL_USE} ? $self->{LOCAL_USE} : undef;
}
sub set_number_of_subsets {
    my ($self, $number_of_subsets) = @_;
    _croak "Number of subsets not provided in set_number_of_subsets"
        unless defined $number_of_subsets;
    _croak "Number of subsets must be an integer, is '$number_of_subsets'"
        unless $number_of_subsets =~ /^\d+$/;
    _croak "Number of subsets exceeds limit 65535, is '$number_of_subsets'"
        if $number_of_subsets > 65535;
    $self->{NUM_SUBSETS} = $number_of_subsets;
    return 1;
}
sub get_number_of_subsets {
    my $self = shift;
    return defined $self->{NUM_SUBSETS} ? $self->{NUM_SUBSETS} : undef;
}
sub set_observed_data {
    my ($self, $observed_data) = @_;
    _croak "Observed data (0 or 1) not provided in set_observed_data"
        unless defined $observed_data;
    _croak "Observed data must be 0 or 1, is '$observed_data'"
        unless $observed_data eq '0' or $observed_data eq '1';
    $self->{OBSERVED_DATA} = $observed_data;
    return 1;
}
sub get_observed_data {
    my $self = shift;
    return defined $self->{OBSERVED_DATA} ? $self->{OBSERVED_DATA} : undef;
}
sub set_compressed_data {
    my ($self, $compressed_data) = @_;
    _croak "Compressed data (0 or 1) not provided in set_compressed_data"
        unless defined $compressed_data;
    _croak "Compressed data must be 0 or 1, is '$compressed_data'"
        unless $compressed_data eq '0' or $compressed_data eq '1';
    _complain "Not allowed to use compression for one subset messages!"
        if $compressed_data
            and defined $self->{NUM_SUBSETS} and $self->{NUM_SUBSETS} == 1;
    $self->{COMPRESSED_DATA} = $compressed_data;
    return 1;
}
sub get_compressed_data {
    my $self = shift;
    return defined $self->{COMPRESSED_DATA} ? $self->{COMPRESSED_DATA} : undef;
}
sub set_descriptors_unexpanded {
    my ($self, $descriptors_unexpanded) = @_;
    _croak "Unexpanded descriptors not provided in set_descriptors_unexpanded"
        unless defined $descriptors_unexpanded;
    $self->{DESCRIPTORS_UNEXPANDED} = $descriptors_unexpanded;
    return 1;
}
sub get_descriptors_unexpanded {
    my $self = shift;
    return defined $self->{DESCRIPTORS_UNEXPANDED}
        ? $self->{DESCRIPTORS_UNEXPANDED} : undef;
}
#############################################
## End of accessor methods for BUFR sec0-3 ##
#############################################

sub get_current_subset_number {
    my $self = shift;
    return defined $self->{CURRENT_SUBSET} ? $self->{CURRENT_SUBSET} : undef;
}

sub get_current_message_number {
    my $self = shift;
    return defined $self->{CURRENT_MESSAGE} ? $self->{CURRENT_MESSAGE} : undef;
}

sub get_current_ahl {
    my $self = shift;
    return defined $self->{CURRENT_AHL} ? $self->{CURRENT_AHL} : undef;
}

sub get_current_gts_starting_line {
    my $self = shift;
    return defined $self->{CURRENT_GTS_STARTING_LINE} ? $self->{CURRENT_GTS_STARTING_LINE} : undef;
}

sub get_current_gts_eom {
    my $self = shift;
    return defined $self->{CURRENT_GTS_EOM} ? $self->{CURRENT_GTS_EOM} : undef;
}

sub set_filter_cb {
    my $self = shift;
    my $cb   = shift;

    if (ref $cb eq 'CODE') {
        $self->{FILTER_CB} = $cb;
        @{$self->{FILTER_ARGS}} = ($self, @_);
    } else {
        $self->{FILTER_CB} = undef;
        delete $self->{FILTER_ARGS};
    }
    return 1;
}

sub is_filtered {
    my $self = shift;
    return defined $self->{IS_FILTERED} ? $self->{IS_FILTERED} : undef;
}

sub bad_bufrlength {
    my $self = shift;
    return defined $self->{BAD_LENGTH} ? $self->{BAD_LENGTH} : undef;
}

sub set_tableformat {
    my $self = shift;

    my $format = shift;
    _croak "Table format not provided. Possible values are BUFRDC and ECCODES"
        unless defined $format;
    _croak "Supported table formats are BUFRDC and ECCODES"
        unless uc($format) eq 'BUFRDC' || uc($format) eq 'ECCODES';
    $BUFR_table{FORMAT} = uc($format);
    Geo::BUFR->_spew(2, "BUFR table format set to %s", $BUFR_table{FORMAT});
    return 1;
}

sub get_tableformat {
    my $self = shift;
    return exists $BUFR_table{FORMAT} ? $BUFR_table{FORMAT} : '';
}

##  Set the path for BUFR table files
##  Usage: Geo::BUFR->set_tablepath(directory_list)
##         where directory_list is a list of colon-separated strings.
##  Example: Geo::BUFR->set_tablepath("/foo/bar:/foo/baz", "/some/where/else")
sub set_tablepath {
    my $self = shift;

    $BUFR_table{PATH} = join ":", map {split /:/} @_;
    Geo::BUFR->_spew(2, "BUFR table path set to %s", $BUFR_table{PATH});
    return 1;
}

sub get_tablepath {
    my $self = shift;

    if (exists $BUFR_table{PATH}) {
        return wantarray ? split(/:/, $BUFR_table{PATH}) : $BUFR_table{PATH};
    } else {
        return '';
    }
}

## Return table version from table if provided, or else from section 1
## information in BUFR message. For BUFRDC, this is a stripped down
## version of table name. For ECCODES, this is last path of table
## location (e.g. '0/wmo/29'), and a stringified list of two such
## paths (master and local) if local tables are used
## (e.g. '0/wmo/29,0/local/8/78/236'). Returns undef/empty list if
## impossible to determine table version.
sub get_table_version {
    my $self = shift;
    my $table = shift;

    if ($table) {
        if ($BUFR_table{FORMAT} eq 'BUFRDC') {
            # First check if this actually is an attempt to load an ECCODES table
            if ($table =~ /wmo/ || $table =~ /local/) {
                _croak("$table cannot be a BUFRDC table. "
                       . "Did you forget to set tableformat to ECCODES?");
            }
            (my $version = $table) =~ s/^(?:[BCD]?)(.*?)(?:\.TXT)?$/$1/;
            return $version;
        } elsif ($BUFR_table{FORMAT} eq 'ECCODES') {
            # Mainly meant to catch attempts to load a BUFRDC table
            # with tableformat mistakingly set to ECCODES
            _croak("$table cannot be an ecCodes table")
                unless ($table =~ /wmo/ || $table =~ /local/);
            return $table;
        }
    }

    # No table provided. Decide version from section 1 information.
    # First check that the necessary metadata exist
    foreach my $metadata (qw(MASTER_TABLE LOCAL_TABLE_VERSION
                             CENTRE SUBCENTRE)) {
        return undef if ! defined $self->{$metadata};
    }

    # If master table version, use centre 0 and subcentre 0 (in ECMWF
    # BUFRDC this is the convention from version 320 onwards)
    my $centre = $self->{CENTRE};
    my $subcentre = $self->{SUBCENTRE};
    my $local_table_version = $self->{LOCAL_TABLE_VERSION};
    if ($local_table_version == 0 || $local_table_version == 255) {
        $centre = 0;
        $subcentre = 0;
        $local_table_version = 0;
    }

    my $master_table = $self->{MASTER_TABLE};
    my $master_table_version = $self->{MASTER_TABLE_VERSION};
    if ($BUFR_table{FORMAT} eq 'BUFRDC') {
        # naming convention used in BUFRDC version >= 000270
        return sprintf "%03d%05d%05d%03d%03d",
               $master_table,$subcentre,$centre,$master_table_version,$local_table_version;
    } elsif ($BUFR_table{FORMAT} eq 'ECCODES')  {
        if ($local_table_version == 0) {
            return catfile($master_table,'wmo',$master_table_version);
        } else {
            return catfile($master_table,'wmo',$master_table_version) . ',' .
                   catfile($master_table,'local',$local_table_version,$centre,$subcentre);
        }
    }
}

# Return table version for the latest master table found in tablepath,
# in the same format as get_table_version. For use when master table
# version is not known, e.g. in bufrresolve.pl.
sub get_max_table_version {
    my ($self) = @_;

    _croak "BUFR table path not set, did you forget to call set_tablepath()?"
        unless $BUFR_table{PATH};

    my $max_version = 0;
    if ($BUFR_table{FORMAT} eq 'BUFRDC') {
        foreach my $tabledir (split /:/, $BUFR_table{PATH}) {
            opendir(my $dh, $tabledir) || _croak "Couldn't open $tabledir: $!";
            my @btables = sort grep { /^B0000000000000\d{3}000.TXT/ } readdir $dh;
            closedir $dh;
            my $version = substr($btables[-1], 14, 3)
                || _croak "Wrong tablepath or tableformat?";
            if ($version > $max_version) {
                $max_version = $version;
            }
        }

        _croak "No WMO master table found" unless $max_version;

        return '0000000000000' . $max_version . '000';

    } elsif ($BUFR_table{FORMAT} eq 'ECCODES') {
        foreach my $tabledir (split /:/, $BUFR_table{PATH}) {
            my $dir = catfile($tabledir,'0/wmo');
            opendir(my $dh, $dir) || _croak "Cannot open $dir: $!";
            my @files = sort {$a <=> $b} grep { /^[0-9]+$/ } readdir $dh;
            closedir $dh;

            my $version = $files[-1];
            if ($version > $max_version) {
                $max_version = $version;
            }
        }

        _croak "No WMO master table found" unless $max_version;

        return catfile('0', 'wmo', $max_version);
    }
}

# Search through $BUFR_table{PATH} to find first path for which $fname
# exists, or (for BUFRDC) if no such path exists, first path for which the
# corresponding master file exists, in which case
# $self->{LOCAL_TABLES_NOT_FOUND} is set to the local table initially
# searched for (this variable should be undefined as soon as the
# message is finished processing). Returns empty list if no such path
# could be found, else returns the path and the table name for which
# path was found.
sub _locate_table {
    my ($self,$fname) = @_;

    _croak "BUFR table path not set, did you forget to call set_tablepath()?"
        unless $BUFR_table{PATH};

    my $path;
    foreach (split /:/, $BUFR_table{PATH}) {
        if (-e catfile($_, $fname)) {
            $path = $_;
            $path =~ s|/$||;
            return ($path,$fname);
        }
    }

    if ($BUFR_table{FORMAT} eq 'BUFRDC') {
        # Path couldn't be found for $fname. Then try again for master table
        my $master_table;
        ($master_table,$path) = $self->_locate_master_table($fname);
        if ($path) {
            $self->{LOCAL_TABLES_NOT_FOUND} = $fname;
            return ($path,$master_table);
        }
    }

    # No table found
    return;
}

# Return master table and path corresponding to local table $fname, or
# empty list if $fname actually is a master table or if no path for the
# master table could be found.
sub _locate_master_table {
    my ($self,$fname) = @_;

    my $master_table;
    if ($BUFR_table{FORMAT} eq 'BUFRDC') {
        _croak("$fname is not a valid name for BUFRDC tables")
            if length($fname) < 20;
        $master_table = substr($fname,0,4) . '00000' . '00000'
            . substr($fname,14,3) . '000.TXT';
    } elsif ($BUFR_table{FORMAT} eq 'ECCODES')  {
        foreach my $metadata (qw(MASTER_TABLE MASTER_TABLE_VERSION)) {
            return if ! defined $self->{$metadata};
        }
        $master_table = catfile($self->{MASTER_TABLE},'wmo',$self->{MASTER_TABLE_VERSION});
    }
    return if ($master_table eq $fname); # Already tried

    my $path;
    foreach (split /:/, $BUFR_table{PATH}) {
        if (-e catfile($_, $master_table)) {
            $path = $_;
            $path =~ s|/$||;
            return ($master_table,$path);
        }
    }
    return;
}

## Read in a B table file into a hash, e.g.
##  $B_table{'001001'} = "WMO BLOCK NUMBER\0NUMERIC\0  0\0           0\0  7"
## where the B table values for 001001 are \0 (NUL) separated
sub _read_B_table_bufrdc {
    my ($self,$version) = @_;

    my $fname = "B$version.TXT";
    my ($path,$tname) = $self->_locate_table($fname)
        or _croak "Couldn't find BUFR table $fname in $BUFR_table{PATH}."
        . " Wrong tablepath?";

    # If we are forced to try master table because local table
    # couldn't be found, check if this might already have been loaded
    if ($tname ne $fname) {
        my $master_version = substr($tname,1,-4);
        return $BUFR_table{"B$master_version"} if exists $BUFR_table{"B$master_version"};
    }

    my $tablefile = catfile($path,$tname);
    open(my $TABLE, '<', $tablefile)
        or _croak "Couldn't open BUFR table B $tablefile: $!";
    my $txt = "Reading table $tablefile";
    $txt .= " (since local table " . $self->{LOCAL_TABLES_NOT_FOUND}
    . " couldn't be found)" if $self->{LOCAL_TABLES_NOT_FOUND};
    $self->_spew(1, "%s", $txt);

    my %B_table;
    while (<$TABLE>) {
        my ($s1,$fxy,$s2,$name,$s3,$unit,$s4,$scale,$s5,$refval,$s6,$bits)
            = unpack('AA6AA64AA24AA3AA12AA3', $_);
        next unless defined $bits;
        $name =~ s/\s+$//;
        $refval =~ s/-\s+(\d+)/-$1/; # Remove blanks between minus sign and value
        $B_table{$fxy} = join "\0", $name, $unit, $scale, $refval, $bits;
    }
    # When installing Geo::BUFR on Windows Vista with Strawberry Perl,
    # close sometimes returned an empty string. Therefore removed
    # check on return value for close.
    close $TABLE; # or _croak "Closing $tablefile failed: $!";

    $BUFR_table{"B$version"} = \%B_table;
    return \%B_table;
}

sub _read_B_table_eccodes {
    my ($self,$version) = @_;

    my ($path,$tname) = $self->_locate_table(catfile($version,'element.table'));

    if (! $path) {
        if ($version =~ /wmo/) {
            _croak "Couldn't find BUFR table " . catfile($version,'element.table')
                . " in $BUFR_table{PATH}. Wrong tablepath?";
        } else {
            # This might actually not be an error, since local table
            # might be provided for D only. But if later a local
            # element descriptor is requested, we should complain
            $self->{LOCAL_TABLES_NOT_FOUND} = $version;
            return;
        }
    }
    my $tablefile = catfile($path,$tname);

    open(my $TABLE, '<', $tablefile)
        or _croak "Couldn't open BUFR table B $tablefile: $!";
    $self->_spew(1, "Reading table %s", $tablefile);

    my %B_table;
    while (<$TABLE>) {
        # Skip comments (expexted to be in first line only)
        next if /^#/;

        # $rest is crex_unit|crex_scale|crex_width
        my ($code,$abbreviation,$type,$name,$unit,$scale,$reference,$width,$rest)
            = split /[|]/;
        next unless defined $width; # shouldn't happen
        $unit = 'CCITTIA5' if $unit eq 'CCITT IA5';
        $B_table{$code} = join "\0", $name, $unit, $scale, $reference, $width;
    }
    close $TABLE;

    $BUFR_table{"B$version"} = \%B_table;
    return \%B_table;
}

## Reads a D table file into a hash, e.g.
##  $D_table->{307080} = '301090 302031 ...'
## There are two different types of lines in D*.TXT, e.g.
##  307080 13 301090 BUFR template for synoptic reports
##            302031
## We choose to ignore the number of lines in expansion (here 13)
## because this number is sometimes in error. Instead we consider a
## line starting with 5 spaces to be of the second type above, else of
## the first type
sub _read_D_table_bufrdc {
    my ($self,$version) = @_;

    my $fname = "D$version.TXT";
    my ($path,$tname) = $self->_locate_table($fname)
        or _croak "Couldn't find BUFR table $fname in $BUFR_table{PATH}."
            . "Wrong tablepath?";

    # If we are forced to try master table because local table
    # couldn't be found, check if this might already have been loaded
    if ($tname ne $fname) {
        my $master_version = substr($tname,1,-4);
        return $BUFR_table{"D$master_version"} if exists $BUFR_table{"D$master_version"};
    }

    my $tablefile = catfile($path,$tname);
    open(my $TABLE, '<', $tablefile)
        or _croak "Couldn't open BUFR table D $tablefile: $!";
    my $txt = "Reading table $tablefile";
    $txt .= " (since local table " . $self->{LOCAL_TABLES_NOT_FOUND}
    . " couldn't be found)" if $self->{LOCAL_TABLES_NOT_FOUND};
    $self->_spew(1, "%s", $txt);

    my (%D_table, $alias);
    while (my $line = <$TABLE>) {
        $line =~ s/\s+$//;
        next if $line =~ /^\s*$/; # Blank line

        if (substr($line,0,5) eq ' ' x 5) {
            $line =~ s/^\s+//;
            $D_table{$alias} .= " $line";
        } else {
            $line =~ s/^\s+//;
            # In table version 17 a descriptor with more than 100
            # entries occurs, causing no space between alias and
            # number of entries (so split /\s+/ doesn't work)
            my ($ali, $skip, $desc) = unpack('A6A4A6', $line);
            $alias = $ali;
            $D_table{$alias} = $desc;
        }
    }
    close $TABLE; # or _croak "Closing $tablefile failed: $!";

    $BUFR_table{"D$version"} = \%D_table;
    return \%D_table;
}

sub _read_D_table_eccodes {
    my ($self,$version) = @_;

    my ($path,$tname) = $self->_locate_table(catfile($version,'sequence.def'));

    if (! $path) {
        if ($version =~ /wmo/) {
            _croak "Couldn't find BUFR table " . catfile($version,'sequence.def')
                . " in $BUFR_table{PATH}. Wrong tablepath?";
        } else {
            # This might actually not be an error, since local table
            # might be provided for B only. But if later a local
            # sequence descriptor is requested, we should complain
            $self->{LOCAL_TABLES_NOT_FOUND} = $version;
        }
        return;
    }
    my $tablefile = catfile($path,$tname);

    open(my $TABLE, '<', $tablefile)
        or _croak "Couldn't open BUFR table B $tablefile: $!";
    $self->_spew(1, "Reading table %s", $tablefile);

## sequence.def is expected to contain lines like
#"301196" = [  301011, 301013, 301021 ]
## which should be converted to
# 301196  3 301011
#           301013
#           301021
## Must also handle descriptors spanning more than one line, like
#"301046" = [  001007, 001012, 002048, 021119, 025060, 202124, 002026, 002027, 202000, 005040
#               ]
## and
#"301058" = [  301011, 301012, 201152, 202135, 004006, 202000, 201000, 301021, 020111, 020112,
#               020113, 020114, 020115, 020116, 020117, 020118, 020119, 025035, 020121, 020122,
#               020123, 020124, 025175, 020023, 025063, 202136, 201136, 002121, 201000, 202000,
#               025061, 002184, 002189, 025036, 101000, 031002, 301059 ]
    my %D_table;
    my $txt;
    while (<$TABLE>) {
        if (substr($_,0,1) eq '"') {
            # New sequence descriptor, parse and store the previous
            _parse_sequence(\%D_table,$txt) if $txt;
            chomp;
            $txt = $_;
        } else {
            chomp;
            $txt .= $_;
        }
    }
    _parse_sequence(\%D_table,$txt) if $txt;

    close $TABLE; # or _croak "Closing $tablefile failed: $!";

    $BUFR_table{"D$version"} = \%D_table;
    return \%D_table;
}

sub _parse_sequence {
    my ($Dtable, $txt) = @_;

    my ($seq, $rest) = ($txt =~ /^"(\d{6})" = \[(.*)\]/);
    my @list = split(/,/, $rest);
    foreach (@list) {
        s/^ +//;
        s/ +$//;
    }
    $Dtable->{$seq} = join(' ', @list);
}

## Read the flag and code tables, which in ECMWF BUFRDC tables are
## put in tables C$version.TXT (not to be confused with BUFR C tables,
## which contain the operator descriptors). Note that even though
## number of code values and number of lines are included in the
## tables, we choose to ignore them, because these values are often
## found to be in error. Instead we trust that the text starts at
## fixed positions in file. Returns reference to the C table, or undef
## if failing to open table file.
sub _read_C_table {
    my ($self,$version) = @_;

    # For ECCODES loading 2 different codetables directories might be necessary
    if ($BUFR_table{FORMAT} eq 'ECCODES') {
        if ($version =~ /,/) {
            my ($master, $local) = (split /,/, $version);
            $self->_read_C_table_eccodes($master);
            return $self->_read_C_table_eccodes($local);
        } else {
            return $self->_read_C_table_eccodes($version);
        }
    }

    # Rest of code is for BUFRDC
    my $fname = "C$version.TXT";
    my ($path,$tname) = $self->_locate_table($fname);
    return undef unless $path;

    # If we are forced to try master table because local table
    # couldn't be found, check if this might already have been loaded
    if ($tname ne $fname) {
        my $master_version = substr($tname,1,-4);
        return $BUFR_table{"C$master_version"} if exists $BUFR_table{"C$master_version"};
    }

    my $tablefile = catfile($path,$tname);
    open(my $TABLE, '<', $tablefile)
        or _croak "Couldn't open BUFR table C $tablefile: $!";
    my $txt = "Reading table $tablefile";
    $txt .= " (since local table " . $self->{LOCAL_TABLES_NOT_FOUND}
    . " couldn't be found)" if $self->{LOCAL_TABLES_NOT_FOUND};
    $self->_spew(1, "%s", $txt);

    my (%C_table, $table, $value);
    while (my $line = <$TABLE>) {
        $line =~ s/\s+$//;
        next if $line =~ /^\s*$/; # Blank line

        if (substr($line,0,15) eq ' ' x 15) {
            $line =~ s/^\s+//;
            next if $line eq 'NOT DEFINED' || $line eq 'RESERVED';
            $C_table{$table}{$value} .= $line . "\n";
        } elsif (substr($line,0,10) eq ' ' x 10) {
            $line =~ s/^\s+//;
            my ($val, $nlines, $txt) = split /\s+/, $line, 3;
            $value = $val+0;
            next if !defined $txt || $txt eq 'NOT DEFINED' || $txt eq 'RESERVED';
            $C_table{$table}{$value} .= $txt . "\n";
        } else {
            my ($tbl, $nval, $val, $nlines, $txt) = split /\s+/, $line, 5;
            $table = sprintf "%06d", $tbl;
            # For tables listed 2 or more times, use last instance only.
            # This prevents $txt to be duplicated in $C_table{$table}{$value}
            undef $C_table{$table} if defined $C_table{$table};
            $value = $val+0;
            next if !defined $txt || $txt eq 'NOT DEFINED' || $txt eq 'RESERVED';
            $C_table{$table}{$value} = $txt . "\n";
        }
    }
    close $TABLE; # or _croak "Closing $tablefile failed: $!";

    $BUFR_table{"C$version"} = \%C_table;
    return \%C_table;
}

sub _read_C_table_eccodes {
    my ($self,$version) = @_;

    my ($path,$tname) = $self->_locate_table(catfile($version,'codetables'));

    if (! $path) {
        if ($version =~ /wmo/) {
            _croak "Couldn't find BUFR table " . catfile($version,'element.table')
                . " in $BUFR_table{PATH}. Wrong tablepath?"
                if (! $path && $version =~ /wmo/);
        } else {
            # This might actually not be an error, if none of the
            # local descriptors are of type code or flag table. So
            # prefer to keep silent in this case.
            return;
        }
    }

    my $tabledir = catfile($path,$tname);

    opendir(my $dh, $tabledir) || _croak "Couldn't open $tabledir: $!";
    my @table_files = grep { /table$/ } readdir $dh;
    closedir($dh);
    $self->_spew(1, "Reading tables in %s", $tabledir) if @table_files;

    my %C_table;
    foreach my $table_file (@table_files) {
        my ($table) = ($table_file =~ /(\d+)\.table$/);
        die "Unexpected name of table file: $table_file" unless $table;
        $table =  sprintf "%06d", $table;

        open my $IN, '<', catfile($tabledir, $table_file)
            or _croak "Couldn't open $table_file: $!";
        while (<$IN>) {
            chomp;
            my ($num, $val, $txt) = split(/ /, $_, 3);
            _complain("Unexpected: first 2 fields in $table_file in $tabledir are unequal: $num $val")
                if ($Strict_checking and $num ne $val);

            # Fix a common problem in ecCodes codetables with long
            # lines, hopefully not changing valid use of '"' in local
            # tables (e.g. 8/78/0/codetables/8198.table:  ""Nebenamtliche"" measurement
            $txt =~ s/(?<!")" +//;
##          $txt =~ s/" +//;

            $C_table{$table}{$val} = $txt . "\n";
        }

        _complain("$table_file in $tabledir is empty!")
            if ($Strict_checking and not $C_table{$table});
        close $IN;
    }

    $BUFR_table{"C$version"} = \%C_table;
    return \%C_table;
}

sub _get_tableid_eccodes {
    my $table_file = shift;
    my ($id) = ($table_file =~ /(\d+)\.table$/);
    return $id;
}


sub load_BDtables {
    my $self = shift;
    my $table = shift || '';

    my $version = $self->{TABLE_VERSION} = $self->get_table_version($table)
        or _croak "Not enough info to decide which tables to load";

    if ($BUFR_table{FORMAT} eq 'BUFRDC') {
        $self->{B_TABLE} = $BUFR_table{"B$version"} || $self->_read_B_table_bufrdc($version);
        $self->{D_TABLE} = $BUFR_table{"D$version"} || $self->_read_D_table_bufrdc($version);
    } elsif ($BUFR_table{FORMAT} eq 'ECCODES') {
        if ($version =~ /,/) {
            my ($master, $local) = (split /,/, $version);
            $self->{B_TABLE} = $BUFR_table{"B$master"} || $self->_read_B_table_eccodes($master);
            $self->{D_TABLE} = $BUFR_table{"D$master"} || $self->_read_D_table_eccodes($master);

            # Append local table to the master table (should work even if empty)
            my $local_Btable = (exists($BUFR_table{"B$local"})) ? $BUFR_table{"B$local"}
            : $self->_read_B_table_eccodes($local);
            @{$self->{B_TABLE}}{ keys %$local_Btable } = values %$local_Btable;
            my $local_Dtable = (exists($BUFR_table{"D$local"})) ? $BUFR_table{"D$local"}
            : $self->_read_D_table_eccodes($local);
            @{$self->{D_TABLE}}{ keys %$local_Dtable } = values %$local_Dtable;;

        } else {
            $self->{B_TABLE} = $BUFR_table{"B$version"} || $self->_read_B_table_eccodes($version);
            $self->{D_TABLE} = $BUFR_table{"D$version"} || $self->_read_D_table_eccodes($version);
        }
    }
    return $version;
}

sub load_Ctable {
    my $self = shift;
    my $table = shift || '';

    my $version = $self->get_table_version($table) || '';

    if ($version) {
        if ($BUFR_table{FORMAT} eq 'BUFRDC') {
            $self->{C_TABLE} = $BUFR_table{"C$version"} || $self->_read_C_table($version);
        } elsif ($BUFR_table{FORMAT} eq 'ECCODES') {
            if ($version =~ /,/) {
                my ($master, $local) = (split /,/, $version);
                $self->{C_TABLE} = $BUFR_table{"$master"} || $self->_read_C_table($master);

                # Append local table to the master table (should work even if empty)
                my $local_Ctable = (exists($BUFR_table{"C$local"})) ? $BUFR_table{"C$local"}
                : $self->_read_C_table_eccodes($local);
                @{$self->{C_TABLE}}{ keys %$local_Ctable } = values %$local_Ctable;

            } else {
                $self->{C_TABLE} = $BUFR_table{"C$version"} || $self->_read_C_table_eccodes($version);
            }
        }
    }

    if (not $self->{C_TABLE}) {
        # Was not able to load $table. Try latest master table instead.
        $version = $self->get_max_table_version()
            || _croak "No master tables found in tablepath";
        if ($BUFR_table{FORMAT} eq 'BUFRDC') {
            $self->{C_TABLE} = $BUFR_table{"C$version"} || $self->_read_C_table($version);
        } else {
            $self->{C_TABLE} = $BUFR_table{"C$version"} || $self->_read_C_table_eccodes($version);
        }
    }
    if (not $self->{C_TABLE}) {
        if ($BUFR_table{FORMAT} eq 'BUFRDC') {
            _croak "Unable to load C table (C$version.TXT)";
        } else {
            _croak "Unable to load codetables for $version";
        }
    }

    return $version;
}


##  Specify BUFR file to read
sub fopen {
    my $self = shift;
    my $filename = shift
        or _croak "fopen() called without an argument";
    _croak "File $filename doesn't exist!" unless -e $filename;
    _croak "$filename is not a plain file" unless -f $filename;

    # Open file for reading
    $self->{FILEHANDLE} = new FileHandle;
    open $self->{FILEHANDLE}, '<', $filename
        or _croak "Couldn't open file $filename for reading";

    $self->_spew(2, "File %s opened for reading", $filename);

    # For some OS this is necessary
    binmode $self->{FILEHANDLE};

    $self->{FILENAME} = $filename;
    return 1;
}

sub fclose {
    my $self = shift;
    if ($self->{FILEHANDLE}) {
        close $self->{FILEHANDLE}
            or _croak "Couldn't close BUFR file opened by fopen()";
        $self->_spew(2, "Closed file %s", $self->{FILENAME});
    }
    delete $self->{FILEHANDLE};
    delete $self->{FILENAME};
    # Much more might be considered deleted here, but usually the bufr
    # object goes out of scope immediately after a fclose anyway
    return 1;
}

sub eof {
    my $self = shift;
    return ($self->{EOF} || 0);
}

# Go to start of input buffer or start of file associated with the object
sub rewind {
    my $self = shift;
    if (exists $self->{FILEHANDLE}) {
        seek $self->{FILEHANDLE}, 0, 0 or _croak "Cannot seek: $!";
    } elsif (! $self->{IN_BUFFER}) {
        _croak "Cannot rewind: no file or input buffer associated with this object";
    }
    $self->{CURRENT_MESSAGE} = 0;
    $self->{CURRENT_SUBSET} = 0;
    delete $self->{START_POS};
    delete $self->{POS};
    delete $self->{EOF};
    return 1;
}

## Read in next BUFR message from file if $self->{FILEHANDLE} is set,
## else from $self->{IN_BUFFER} (string argument to
## constructor). Decodes section 0 and sets $self->{START_POS} to
## start of message and $self->{POS} to end of BUFR message (or after
## first 8 bytes of truncated/corrupt BUFR message for which we still
## want to attempt decoding). $self->{CURRENT_AHL} is updated if a GTS
## ahl is found (implemented for file reading only) and similarly for
## $self->{CURRENT_GTS_STARTING_LINE}, and $self->{EOF} is set if no
## more 'BUFR' in file/buffer. Croaks if an error occurs when reading
## BUFR message.

## Returns BUFR message from section 1 on, or undef if no BUFR message
## is found.
sub _read_message {
    my $self = shift;

    my $filehandle = $self->{FILEHANDLE} ? $self->{FILEHANDLE} : undef;
    my $in_buffer = $self->{IN_BUFFER} ? $self->{IN_BUFFER} : undef;
    _croak "_read_message: Neither BUFR file nor BUFR text is given"
        unless $filehandle or $in_buffer;

    # Locate next 'BUFR' and set $pos to this position in file/string,
    # also finding corresponding GTS ahl and starting line if exists
    # (for file only). Possibly sets $self->{EOF}
    my $pos = defined $self->{POS} ? $self->{POS} : 0;
    my ($ahl, $gts_start);
    ($pos, $ahl, $gts_start) = $self->_find_next_BUFR($filehandle, $in_buffer, $pos, '');
    return if $pos < 0;
    if ($ahl) {
        $self->{CURRENT_AHL} = $ahl;
        if ($gts_start) {
            $self->{CURRENT_GTS_STARTING_LINE} = $gts_start;
            $self->{GTS_CURRENT_EOM} = undef;
        }
    } else {
        $self->{CURRENT_AHL} = undef;
        $self->{CURRENT_GTS_STARTING_LINE} = undef;
    }

    # Remember start position of BUFR message in case we need to
    # rewind later because length of BUFR cannot be trusted
    $self->{START_POS} = $pos;

    # Report (if verbose setting) where we found the BUFR message
    $self->_spew(2, "BUFR message at position %d", $pos) if $Spew;

    # Read (rest) of Section 0 (length of BUFR message and edition number)
    my $sec0;                   # Section 0 is BUFR$sec0
    if ($filehandle) {
        if ((read $filehandle, $sec0, 8) != 8) {
            $self->{EOF} = 1;
            _croak "Error reading section 0 in file '$self->{FILENAME}', position "
                . tell($filehandle);
        }
        $sec0 = substr $sec0, 4;
    } else {
        if (length($in_buffer) < $pos+8) {
            $self->{EOF} = 1;
            _croak "Error reading section 0: this is not a BUFR message?"
        }
        $sec0 = substr $in_buffer, $pos+4, 4;
    }
    $self->{SEC0_STREAM}  = "BUFR$sec0";

    # Extract length and edition number
    my ($length, $edition) = unpack 'NC', "\0$sec0";
    $self->{BUFR_LENGTH}  = $length;
    $self->{BUFR_EDITION} = $edition;
    $self->_spew(2, "Message length: %d, Edition: %d", $length, $edition) if $Spew;
    _croak "Cannot handle BUFR edition $edition" if $edition < 2 || $edition > 4;

    # Read rest of BUFR message (section 1-5)
    my $msg;
    my $msgisOK = 1;
    if ($filehandle) {
        if ((read $filehandle, $msg, $length-8) != $length-8) {
            # Probably a corrupt or truncated BUFR message. We choose
            # to decode as much as possible (maybe the length in
            # section 0 is all that is wrong), but obviously we cannot
            # trust the stated length of BUFR message, so reset
            # position of filehandle to just after section 0
            $self->{BAD_LENGTH} = 1;
            $msgisOK = 0;
            seek $filehandle, $pos+8, 0;
            _complain("File %s not big enough to contain the stated"
                      . "length of BUFR message", $self->{FILENAME});
            $pos += 8;
        } else {
            $pos = tell($filehandle);
            if (substr($msg, -4) ne '7777') {
                $self->{BAD_LENGTH} = 1;
                _complain("BUFR length in sec 0 can't be correct, "
                          . "last 4 bytes are not '7777'");
            }
        }
    } else {
        if (length($in_buffer) < $pos+$length) {
            $self->{BAD_LENGTH} = 1;
            $msgisOK = 0;
            _complain("Buffer not big enough to contain the stated "
                      . "length of BUFR message");
            $msg = substr $in_buffer, $pos+8, $length-8;
            $pos += 8;
        } else {
            $msg = substr $in_buffer, $pos+8, $length-8;
            $pos += $length;
            if (substr($msg, -4) ne '7777') {
                $self->{BAD_LENGTH} = 1;
                _complain("BUFR length in sec 0 can't be correct, "
                          . "last 4 bytes are not '7777'");
            }
        }
    }
    if ($Spew) {
        if ($msgisOK) {
            $self->_spew(2, "Successfully read BUFR message; position now %d", $pos);
        } else {
            $self->_spew(2, "Resetting position to %d", $pos);
        }
    }

    # Reset $self->{POS} to end of BUFR message (or after first 8
    # bytes of truncated/corrupt BUFR message)
    $self->{POS} = $pos;

    # And then advance past GTS end of message if found
    my $gts_eom;
    if ($filehandle && ! $self->{BAD_LENGTH}) {
        if ((read $filehandle, $gts_eom, 4) == 4 && $gts_eom eq "\r\r\n\003") {
            $self->{CURRENT_GTS_EOM} = $gts_eom;
            $self->{POS} +=4;
        } else {
            # return to end of message position
            seek $filehandle, $pos, 0;
        }
    }

    return $msg;
}

# Note that our definition av AHL and GTS starting line differs
# slightly from that of the Manual on the GTS PART II. OPERATIONAL
# PROCEDURES FOR THE GLOBAL TELECOMMUNICATION SYSTEM (2.3.1 and 2.3.2)
# in that the Abbreviated heading in the Manual starts with \r\r\n
# which we have chosen to consider belonging to (the end of) the GTS
# starting line.

my $gts_start_regexp = qr{\001\r\r\n\d{3,5}\r\r\n};
# Allow both 3 and 5 digits channel sequence number

my $ahl_regex = qr{[A-Z]{4}\d\d [A-Z]{4} \d{6}(?: (?:(?:RR|CC|AA|PA)[A-Z])| COR| RTD)?};
# BBB=Pxx (segmentation) was allowed until 2007, but at least one
# centre still uses PAA as of 2014.  COR and RTD shouldn't be
# allowed (from ?), but are still used

## Advance to first occurrence of 'BUFR', or to the possibly preceding
## GTS envelope if this is requested in $at. Returns the new position
## and (if called in array context) the possibly preceding ahl and gts
## starting line. If no 'BUFR' is found, sets $self->{EOF} and returns
## -1 for the new position.
sub _find_next_BUFR {
    my $self = shift;
    my ($filehandle, $in_buffer, $pos, $at) = @_;

    my ($new_pos, $ahl, $gts_start);
    if ($filehandle) {
        my $oldeol = $/;
        $/ = "BUFR";
        my $slurp = <$filehandle> || '    ';
        $/ = $oldeol;
        if (CORE::eof($filehandle) or substr($slurp,-4) ne 'BUFR') {
            $self->{EOF} = 1;
        } else {
            # Get the GTS ahl (TTAAii CCCC DTG [BBB]) before 'BUFR',
            # if present. Use '\n+' not '\n' since adding an extra
            # '\n' in bulletin has been seen. Allow also for not
            # including \r\r (which might be how the bulletin file was
            # prepared originally, or might catch cases where ahl is
            # mistakingly included twice)
            my $reset = 4;
            if ($slurp =~ /(${gts_start_regexp}?)(${ahl_regex})((?:\r\r)?\n+BUFR)$/) {
                $gts_start = $1 || '';
                $ahl = $2;
                $reset = length($gts_start) + length($2) + length($3) if $at eq 'at_ahl';

                $self->_spew(2,"GTS ahl found: %s%s", $gts_start, $ahl) if $Spew;
            }
            # Reset position of filehandle to just before 'BUFR', or
            # if requested, before possible preceding AHL
            seek($filehandle, -$reset, 1);
            $new_pos = tell $filehandle;
        }
    } else {
        $new_pos = index($in_buffer, 'BUFR', $pos);
        if ($new_pos < 0) {
            $self->{EOF} = 1;
        } else {
            if (substr($in_buffer, $pos, $new_pos - $pos)
                =~ /(${gts_start_regexp}?)(${ahl_regex})((?:\r\r)?\n+)$/) {
                $gts_start = $1 || '';
                $ahl = $2;
                $self->_spew(2,"GTS ahl found: %s%s", $gts_start, $ahl) if $Spew;
                if ($at eq 'at_ahl') {
                    $new_pos -= length($gts_start) + length($2) + length($3);
                }
            }
        }
    }

    if ($self->{EOF}) {
        if ($pos == 0) {
            if ($filehandle) {
                $self->_spew(2,"No BUFR message in file %s", $self->{FILENAME})
                    if $Spew;
            } else {
                $self->_spew(2, "No BUFR message found") if $Spew;
            }
        }
        return -1;
    }

    return wantarray ? ($new_pos, $ahl, $gts_start) : $new_pos;
}

## Returns the BUFR message in raw (binary) form, '' if errors encountered
sub get_bufr_message {
    my $self = shift;

    if ($self->{BAD_LENGTH} || $self->{ERROR_IN_MESSAGE}) {
        $self->_spew(2, "Skipping erroneous BUFR message");
        return '';
    }
    if (!$self->{FILEHANDLE} && !$self->{IN_BUFFER}) {
        $self->_spew(2, "No file or input buffer associated with this object");
        return '';
    }
    if (!exists $self->{START_POS} || !$self->{BUFR_LENGTH}) {
        $self->_spew(2, "No bufr message to return");
        return '';
    }

    my $msg;
    if (exists $self->{FILEHANDLE}) {
        my $fh = $self->{FILEHANDLE};
        my $old_pos = tell($fh);
        seek($fh, $self->{START_POS}, 0);
        read($fh, $msg, $self->{BUFR_LENGTH});
        seek($fh, $old_pos, 0);
        $self->_spew(2, "BUFR message extracted from file");
    } elsif (exists $self->{IN_BUFFER}) {
        $msg = substr $self->{IN_BUFFER}, $self->{START_POS}, $self->{BUFR_LENGTH};
        $self->_spew(2, "BUFR message extracted");
    }

    return $msg;
}

## Decode section 1 to 5. Section 0 is already decoded in _read_message.
sub _decode_sections {
    my $self = shift;
    my $msg = shift;

    $self->{BUFR_STREAM}  = $msg;
    $self->{SEC1_STREAM}  = undef;
    $self->{SEC2_STREAM}  = undef;
    $self->{SEC3_STREAM}  = undef;
    $self->{SEC4_STREAM}  = undef;
    $self->{SEC5_STREAM}  = undef;

    # Breaking the rule that all debugging should be on lines starting
    # with 'BUFR.pm:', therefore using $verbose=6
    $self->_spew(6, "%s", $self->dumpsection0()) if $Spew;

    ##  Decode Section 1 (Identification Section)  ##

    $self->_spew(2, "Decoding section 1") if $Spew;

    # Extract Section 1 information
    if ($self->{BUFR_EDITION} < 4) {
        # N means 4 byte integer, so put an extra null byte ('\0') in
        # front of string to get first 3 bytes as integer
        my @sec1 =  unpack 'NC14', "\0" . $self->{BUFR_STREAM};

        # Check that stated length of section 1 makes sense
        _croak "Length of section 1 too small (< 17): $sec1[0]"
            if $sec1[0] < 17;
        _croak "Rest of BUFR message shorter (" . length($self->{BUFR_STREAM})
            . " bytes) than stated length of section 1 ($sec1[0] bytes)"
                if $sec1[0] > length($self->{BUFR_STREAM});

        push @sec1, (unpack 'a*', substr $self->{BUFR_STREAM},17,$sec1[0]-17);
        $self->{SEC1_STREAM} = substr $self->{BUFR_STREAM}, 0, $sec1[0];
        $self->{BUFR_STREAM} = substr $self->{BUFR_STREAM}, $sec1[0];
        $self->{SEC1}                 = \@sec1;
        $self->{MASTER_TABLE}         = $sec1[1];
        $self->{SUBCENTRE}            = $sec1[2];
        $self->{CENTRE}               = $sec1[3];
        $self->{UPDATE_NUMBER}        = $sec1[4];
        $self->{OPTIONAL_SECTION}     = vec($sec1[5] & 0x80,0,1); # 1. bit
        $self->{DATA_CATEGORY}        = $sec1[6];
        $self->{DATA_SUBCATEGORY}     = $sec1[7];
        $self->{MASTER_TABLE_VERSION} = $sec1[8];
        $self->{LOCAL_TABLE_VERSION}  = $sec1[9];
        $self->{YEAR_OF_CENTURY}      = $sec1[10];
        $self->{MONTH}                = $sec1[11];
        $self->{DAY}                  = $sec1[12];
        $self->{HOUR}                 = $sec1[13];
        $self->{MINUTE}               = $sec1[14];
        $self->{LOCAL_USE}            = $sec1[15];
        # In case previous message was edition 4
        foreach my $key (qw(INT_DATA_SUBCATEGORY LOC_DATA_SUBCATEGORY
                            YEAR SECOND)) {
            undef $self->{$key};
        }
    } elsif ($self->{BUFR_EDITION} == 4) {
        my @sec1 =  unpack 'NCnnC7nC5', "\0" . $self->{BUFR_STREAM};

        # Check that stated length of section 1 makes sense
        _croak "Length of section 1 too small (< 22): $sec1[0]"
            if $sec1[0] < 22;
        _croak "Rest of BUFR message shorter (" . length($self->{BUFR_STREAM})
            . " bytes) than stated length of section 1 ($sec1[0] bytes)"
                if $sec1[0] > length($self->{BUFR_STREAM});

        push @sec1, (unpack 'a*', substr $self->{BUFR_STREAM},22,$sec1[0]-22);
        $self->{SEC1_STREAM} = substr $self->{BUFR_STREAM}, 0, $sec1[0];
        $self->{BUFR_STREAM} = substr $self->{BUFR_STREAM}, $sec1[0];
        $self->{SEC1}                 = \@sec1;
        $self->{MASTER_TABLE}         = $sec1[1];
        $self->{CENTRE}               = $sec1[2];
        $self->{SUBCENTRE}            = $sec1[3];
        $self->{UPDATE_NUMBER}        = $sec1[4];
        $self->{OPTIONAL_SECTION}     = vec($sec1[5] & 0x80,0,1); # 1. bit
        $self->{DATA_CATEGORY}        = $sec1[6];
        $self->{INT_DATA_SUBCATEGORY} = $sec1[7];
        $self->{LOC_DATA_SUBCATEGORY} = $sec1[8];
        $self->{MASTER_TABLE_VERSION} = $sec1[9];
        $self->{LOCAL_TABLE_VERSION}  = $sec1[10];
        $self->{YEAR}                 = $sec1[11];
        $self->{MONTH}                = $sec1[12];
        $self->{DAY}                  = $sec1[13];
        $self->{HOUR}                 = $sec1[14];
        $self->{MINUTE}               = $sec1[15];
        $self->{SECOND}               = $sec1[16];
        $self->{LOCAL_USE} = ($sec1[0] > 22) ? $sec1[17] : undef;
        # In case previous message was edition 3 or lower
        foreach my $key (qw(DATA_SUBCATEGORY YEAR_OF_CENTURY)) {
            undef $self->{$key};
        }
    }
    $self->_spew(2, "BUFR edition: %d Optional section: %d Update sequence number: %d",
                $self->{BUFR_EDITION}, $self->{OPTIONAL_SECTION}, $self->{UPDATE_NUMBER}) if $Spew;
    $self->_spew(6, "%s", $self->dumpsection1()) if $Spew;

    $self->_validate_datetime() if ($Strict_checking);

    ##  Decode Section 2 (Optional Section) if present  ##

    $self->_spew(2, "Decoding section 2") if $Spew;

    if ($self->{OPTIONAL_SECTION}) {
        my @sec2 = unpack 'N', "\0" . $self->{BUFR_STREAM};

        # Check that stated length of section 2 makes sense
        _croak "Length of section 2 too small (< 4): $sec2[0]"
            if $sec2[0] < 4;
        _croak "Rest of BUFR message shorter (" . length($self->{BUFR_STREAM})
            . " bytes) than stated length of section 2 ($sec2[0] bytes)"
                if $sec2[0] > length($self->{BUFR_STREAM});

        push @sec2, substr $self->{BUFR_STREAM}, 4, $sec2[0]-4;
        $self->{SEC2_STREAM} = substr $self->{BUFR_STREAM}, 0, $sec2[0];
        $self->{BUFR_STREAM} = substr $self->{BUFR_STREAM}, $sec2[0];
        $self->{SEC2} = \@sec2;
        $self->_spew(2, "Length of section 2: %d", $sec2[0]) if $Spew;
    } else {
        $self->{SEC2} = undef;
        $self->{SEC2_STREAM} = undef;
    }

    ##  Decode Section 3 (Data Description Section)  ##

    $self->_spew(2, "Decoding section 3") if $Spew;

    my @sec3 = unpack 'NCnC', "\0".$self->{BUFR_STREAM};

    # Check that stated length of section 3 makes sense
    _croak "Length of section 3 too small (< 8): $sec3[0]"
        if $sec3[0] < 8;
    _croak "Rest of BUFR message shorter (" . length($self->{BUFR_STREAM})
        . " bytes) than stated length of section 3 ($sec3[0] bytes)"
            if $sec3[0] > length($self->{BUFR_STREAM});

    push @sec3, substr $self->{BUFR_STREAM},7,($sec3[0]-7)&0x0ffe; # $sec3[0]-7 will be reduced by one if odd integer,
                                                                   # so will not push last byte if length of sec3 is even,
                                                                   # which might happen for BUFR edition < 4 (padding byte)
    $self->{SEC3_STREAM} = substr $self->{BUFR_STREAM}, 0, $sec3[0];
    $self->{BUFR_STREAM} = substr $self->{BUFR_STREAM}, $sec3[0];

    $self->{SEC3}             = \@sec3;
    $self->{NUM_SUBSETS}      = $sec3[2];
    $self->{OBSERVED_DATA}    = vec($sec3[3] & 0x80,0,1); # extract 1. bit
    $self->{COMPRESSED_DATA}  = vec($sec3[3] & 0x40,1,1); # extract 2. bit
    $self->_spew(2, "Length of section 3: %d", $sec3[0]) if $Spew;
    $self->_spew(2, "Number of subsets: %d Observed data: %d Compressed data: %d",
                 $self->{NUM_SUBSETS}, $self->{OBSERVED_DATA}, $self->{COMPRESSED_DATA}) if $Spew;
    _complain("0 subsets in BUFR message")
        if ($Strict_checking and $self->{NUM_SUBSETS} == 0);
    _complain("Bits 3-8 in octet 7 in section 3 are not 0 (octet 7 = $sec3[3])")
        if ($Strict_checking and ($sec3[3] & 0x3f) != 0);
    if ($Spew == 6 || $Nodata) {
        my @unexpanded = _int2fxy(unpack 'n*', $self->{SEC3}[4]);
        $self->{DESCRIPTORS_UNEXPANDED} = @unexpanded ?
            join(' ', @unexpanded) : '';
        $self->_spew(6, "%s", $self->dumpsection3());
    }

    $self->{IS_FILTERED} = defined $self->{FILTER_CB}
        ? $self->{FILTER_CB}->(@{$self->{FILTER_ARGS}}) : 0;
    return if $self->{IS_FILTERED} || $Nodata;

    ##  Decode Section 4 (Data Section)  ##

    $self->_spew(2, "Decoding section 4") if $Spew;

    my $sec4_len = unpack 'N', "\0$self->{BUFR_STREAM}";
    $self->_spew(2, "Length of section 4: %d", $sec4_len) if $Spew;

    # Check that stated length of section 4 makes sense
    _croak "Length of section 4 too small (< 4): $sec4_len"
        if $sec4_len < 4;
    _croak "Rest of BUFR message (" . length($self->{BUFR_STREAM}) . " bytes)"
        . " shorter than stated length of section 4 ($sec4_len bytes)."
        . " Probably the BUFR message is truncated"
        if $sec4_len > length($self->{BUFR_STREAM});

    $self->{SEC4_STREAM}  = substr $self->{BUFR_STREAM}, 0, $sec4_len;
    $self->{SEC4_RAWDATA} = substr $self->{BUFR_STREAM}, 4, $sec4_len-4;
    $self->{BUFR_STREAM}  = substr $self->{BUFR_STREAM}, $sec4_len;

    ##  Decode Section 5 (End Section)  ##

    $self->_spew(2, "Decoding section 5") if $Spew;

    # Next 4 characters should be '7777' and these should be end of
    # message, but allow more characters (i.e. length of message in
    # section 0 has been set too big) if $Strict_checking not set
    my $str = $self->{BUFR_STREAM};
    my $len = length($str);
    if ($len > 4
        || ($len == 4 && substr($str,0,4) ne '7777')) {
        my $err_msg = "Section 5 is not '7777' but the $len"
            . " characters (in hex): "
                . join(' ', map {sprintf "0x%02X", $_} unpack('C*', $str));
        if ($len > 4 && substr($str,0,4) eq '7777') {
            _complain($err_msg);
        } elsif ($len == 4 && substr($str,0,4) ne '7777') {
            _croak($err_msg);
        }
    }

    return;
}

##  Read next BUFR message and decode. Set $self->{ERROR_IN_MESSAGE} if
##  anything goes seriously wrong, so that sub next_observation can use
##  this to skip to next message if user chooses to trap the call to
##  next_observation in an eval and then calls next_observation again.
sub _next_message {
    my $self = shift;

    $self->_spew(2, "Reading next BUFR message") if $Spew;

    $self->{ERROR_IN_MESSAGE} = 0;
    $self->{BAD_LENGTH} = 0;

    my $msg;
    eval {
        # Read BUFR message and decode section 0 (needed to get length
        # of message)
        $msg = $self->_read_message();

        # Unpack section 1-5
        $self->_decode_sections($msg) if $msg;
    };
    if ($@) {
        $self->{ERROR_IN_MESSAGE} = 1;
        $self->{CURRENT_MESSAGE}++;
        die $@;  # Could use croak, but then 2 "at ... line ..."  will
                 # be printed to STDERR
    }
    if (!$msg) {
        # Nothing to decode. $self->{EOF} should have been set
        $self->_spew(2, "No more BUFR messages found") if $Spew;
        return;
    }

    $self->{CURRENT_MESSAGE}++;

    return if $Nodata || $self->{IS_FILTERED};

    # Load the relevant code tables
    my $table_version;
    eval { $table_version = $self->load_BDtables() };
    if ($@) {
        $self->{ERROR_IN_MESSAGE} = 1;
        die $@;
    }

    # Get the data descriptors and expand them
    my @unexpanded = _int2fxy(unpack 'n*', $self->{SEC3}[4]);
    _croak "No data description in section 3" if !defined $unexpanded[0];
    # Using master table because local tables couldn't be found is
    # risky, so catch missing descriptors here to be able to give
    # informative error messages
    $self->_check_descriptors(\@unexpanded) if $self->{LOCAL_TABLES_NOT_FOUND};
    $self->{DESCRIPTORS_UNEXPANDED} = join ' ', @unexpanded;
    $self->_spew(2, "Unexpanded data descriptors: %s", $self->{DESCRIPTORS_UNEXPANDED}) if $Spew;

    $self->_spew(2, "Expanding data descriptors") if $Spew;
    my $alias = "$table_version " . $self->{DESCRIPTORS_UNEXPANDED};
    if (exists $Descriptors_already_expanded{$alias}) {
        $self->{DESCRIPTORS_EXPANDED} = $Descriptors_already_expanded{$alias};
    } else {
        eval {
            $Descriptors_already_expanded{$alias} = $self->{DESCRIPTORS_EXPANDED}
                = join " ", _expand_descriptors($self->{D_TABLE}, @unexpanded);
        };
        if ($@) {
            $self->{ERROR_IN_MESSAGE} = 1;
            die $@;
        }
    }

    # Unpack data from bitstream
    $self->_spew(2, "Unpacking data") if $Spew;
    eval {
        if ($self->{COMPRESSED_DATA}) {
            $self->_decompress_bitstream();
        } else {
            $self->_decode_bitstream();
        }
    };
    if ($@) {
        $self->{ERROR_IN_MESSAGE} = 1;
        die $@;
    }

    return;
}

## Check if all element and sequence descriptors given are found in
## B/D-tables (but skip check for those preceded by 206-operator)
sub _check_descriptors {
    my ($self,$unexpanded) = @_;

    my $B_table = $self->{B_TABLE};
    my $D_table = $self->{D_TABLE};
    my $skip_next = 0;
    foreach my $id (@{$unexpanded}) {
        # Skip descriptors preceded by 206-operator
        if ($skip_next) {
            $skip_next = 0;
        } elsif (substr($id,0,3) eq '206') {
            $skip_next = 1;
        } elsif ( (substr($id,0,1) eq '0' && ! exists $B_table->{$id})
            || (substr($id,0,1) eq '3' && ! exists $D_table->{$id}) ) {
            my $version = ($BUFR_table{FORMAT} eq 'BUFRDC')
                ? substr($self->{LOCAL_TABLES_NOT_FOUND},1,-4)
                : $self->{LOCAL_TABLES_NOT_FOUND};
            undef $BUFR_table{"B$version"};
            undef $BUFR_table{"D$version"};
            $self->{ERROR_IN_MESSAGE} = 1;
            _croak("Data descriptor $id is not in master table."
                . " You need to get the local tables B/D$version.TXT");
        }
    }
    return;
}

##  Get next observation, i.e. next subset in current BUFR message or
##  first subset in next message. Returns (reference to) data and
##  descriptors, or empty list if either no observation is found (in
##  which case $self->{EOF} should have been set) or if decoding of
##  section 4 is not requested (in which case all of sections 0-3 have
##  been decoded in next message).
sub next_observation {
    my $self = shift;

    $self->_spew(2, "Fetching next observation") if $Spew;

    # If an error occurred during decoding of previous message, we
    # don't know if stated length in section 0 is to be trusted,
    # so rewind to next 'BUFR', or setting EOF if no such exists
    if ($self->{ERROR_IN_MESSAGE}) {
        # First rewind to right after 'BUFR' in previous (faulty)
        # message. We cannot go further if file/buffer starts as
        # 'BUFRBUFR'
        my $pos = $self->{START_POS} + 4;
        seek($self->{FILEHANDLE}, $pos, 0) if $self->{FILEHANDLE};
        $self->_spew(2, "Error in processing BUFR message (check STDERR for "
                     . "details), rewinding to next 'BUFR'") if $Spew;
        # Prepare for (a possible) next call to _read_message by
        # advancing to next 'BUFR', not skipping a preceding ahl
        my $new_pos = $self->_find_next_BUFR($self->{FILEHANDLE},
                                                    $self->{IN_BUFFER},$pos,'at_ahl');
        if ($self->{EOF}) {
            $self->_spew(2, "Last BUFR message (reached end of file)") if $Spew;
            return;
        } else {
            $self->{POS} = $new_pos;
        }
    }

    # Read next BUFR message
    if ($self->{CURRENT_MESSAGE} == 0
        or $self->{ERROR_IN_MESSAGE}
        or $self->{CURRENT_SUBSET} >= $self->{NUM_SUBSETS}) {

        $self->{CURRENT_SUBSET} = 0;
        # The bit maps must be rebuilt for each message
        undef $self->{BITMAPS};
        undef $self->{BITMAP_OPERATORS};
        undef $self->{BITMAP_START};
        undef $self->{REUSE_BITMAP};
        $self->{NUM_BITMAPS} = 0;
        $self->{BACKWARD_DATA_REFERENCE} = 1;
        # Some more tidying after decoding of previous message might
        # be necessary
        $self->{NUM_CHANGE_OPERATORS} = 0;
        undef $self->{CHANGE_WIDTH};
        undef $self->{CHANGE_CCITTIA5_WIDTH};
        undef $self->{CHANGE_SCALE};
        undef $self->{CHANGE_REFERENCE_VALUE};
        undef $self->{NEW_REFVAL_OF};
        undef $self->{CHANGE_SRW};
        undef $self->{ADD_ASSOCIATED_FIELD};
        undef $self->{LOCAL_TABLES_NOT_FOUND};
        undef $self->{DATA};
        undef $self->{DESC};
        # Note that we should NOT undef metadata in section 1-3 here,
        # since if the next call (_next_message) finds no more
        # messages, we don't want to lose the metadata of the last
        # valid message extracted. sub join_subsets is based on this
        # assumption

        $self->_next_message();
        return if $self->{EOF};

        if ($Nodata || $self->{IS_FILTERED}) {
            # Make a simple check that section 4 and 5 are complete
            if ($self->{BAD_LENGTH}) {
                # We could have set $self->{ERROR_IN_MESSAGE} here and
                # let next_observation() take care of the rewinding.
                # But we don't want error messages to be displayed if
                # e.g. message is to be filtered
                $self->{POS} = $self->{START_POS} + 4;
                seek($self->{FILEHANDLE}, $self->{POS}, 0) if $self->{FILEHANDLE};
                $self->_spew(2, "Possibly truncated message found (last 4 bytes"
                             . " are not '7777'), so rewinding to position %d",
                             $self->{POS}) if $Spew;
            }
            # This will ensure next call to next_observation to read next message
            $self->{CURRENT_SUBSET} = $self->{NUM_SUBSETS};
            return;
        }
    }

    $self->{CURRENT_SUBSET}++;

    # Return references to data and descriptor arrays
    if ($self->{COMPRESSED_DATA}) {
        return ($self->{DATA}[$self->{CURRENT_SUBSET}],
                $self->{DESC});
    } else {
        return ($self->{DATA}[$self->{CURRENT_SUBSET}],
                $self->{DESC}[$self->{CURRENT_SUBSET}]);
    }
}

# Dumping contents of a subset (including section 0, 1 and 3 if this is
# first subset) in a BUFR message, also displaying message number and
# ahl (if found) and subset number
sub dumpsections {
    my $self = shift;
    my $data = shift;
    my $descriptors = shift;
    my $options = shift || {};

    my $width = $options->{width} || 15;
    my $bitmap = exists $options->{bitmap} ? $options->{bitmap} : 1;

    my $current_subset_number = $self->get_current_subset_number();
    my $current_message_number = $self->get_current_message_number();
    my $current_ahl = $self->get_current_ahl() || '';

    my $txt;
    if ($current_subset_number == 1) {
        $txt = "\nMessage $current_message_number";
        $txt .= defined $current_ahl ? "  $current_ahl\n" : "\n";
        $txt .= $self->dumpsection0() . $self->dumpsection1() . $self->dumpsection3();
    }

    # If this is last message and there is a BUFR formatting error
    # caught by user with eval, we might end up here with current
    # subset number 0 (and no section 4 to dump)
    if ($current_subset_number > 0) {
        $txt .= "\nSubset $current_subset_number\n";
        $txt .= $bitmap ? $self->dumpsection4_with_bitmaps($data,$descriptors,
                                 $current_subset_number,$width)
                        : $self->dumpsection4($data,$descriptors,$width);
    }

    return $txt;
}

sub dumpsection0 {
    my $self = shift;
    _croak "BUFR object not properly initialized to call dumpsection0. "
        . "Did you forget to call next_observation()?" unless $self->{BUFR_LENGTH};

    my $txt = <<"EOT";

Section 0:
    Length of BUFR message:            $self->{BUFR_LENGTH}
    BUFR edition:                      $self->{BUFR_EDITION}
EOT
    return $txt;
}

sub dumpsection1 {
    my $self = shift;
    _croak "BUFR object not properly initialized to call dumpsection1. "
        . "Did you forget to call next_observation()?" unless $self->{SEC1_STREAM};

    my $txt;
    if ($self->{BUFR_EDITION} < 4) {
        $txt = <<"EOT";

Section 1:
    Length of section:                 @{[ length $self->{SEC1_STREAM} ]}
    BUFR master table:                 $self->{MASTER_TABLE}
    Originating subcentre:             $self->{SUBCENTRE}
    Originating centre:                $self->{CENTRE}
    Update sequence number:            $self->{UPDATE_NUMBER}
    Optional section present:          $self->{OPTIONAL_SECTION}
    Data category (table A):           $self->{DATA_CATEGORY}
    Data subcategory:                  $self->{DATA_SUBCATEGORY}
    Master table version number:       $self->{MASTER_TABLE_VERSION}
    Local table version number:        $self->{LOCAL_TABLE_VERSION}
    Year of century:                   $self->{YEAR_OF_CENTURY}
    Month:                             $self->{MONTH}
    Day:                               $self->{DAY}
    Hour:                              $self->{HOUR}
    Minute:                            $self->{MINUTE}
EOT
    } else {
        $txt = <<"EOT";

Section 1:
    Length of section:                 @{[ length $self->{SEC1_STREAM} ]}
    BUFR master table:                 $self->{MASTER_TABLE}
    Originating centre:                $self->{CENTRE}
    Originating subcentre:             $self->{SUBCENTRE}
    Update sequence number:            $self->{UPDATE_NUMBER}
    Optional section present:          $self->{OPTIONAL_SECTION}
    Data category (table A):           $self->{DATA_CATEGORY}
    International data subcategory:    $self->{INT_DATA_SUBCATEGORY}
    Local data subcategory:            $self->{LOC_DATA_SUBCATEGORY}
    Master table version number:       $self->{MASTER_TABLE_VERSION}
    Local table version number:        $self->{LOCAL_TABLE_VERSION}
    Year:                              $self->{YEAR}
    Month:                             $self->{MONTH}
    Day:                               $self->{DAY}
    Hour:                              $self->{HOUR}
    Minute:                            $self->{MINUTE}
    Second:                            $self->{SECOND}
EOT
    }
    # Last part of section 1: "Reserved for local use by ADP centres"
    # is considered so uninteresting (and rare), that it is displayed
    # only if verbose >= 2, in a _spew statement. Note that for BUFR
    # edition < 4 there is always one byte here (to make an even
    # number of bytes in section 1).
    $self->_spew(2, "Reserved for local use:             0x@{[unpack('H*', $self->{LOCAL_USE})]}")
        if $self->{LOCAL_USE} and length $self->{LOCAL_USE} > 1;

    return $txt;
}

sub dumpsection2 {
    my $self = shift;
    return '' if not defined $self->{SEC2};

    my $sec2_code_ref = shift;
    _croak "dumpsection2: no code ref provided"
        unless defined $sec2_code_ref && ref($sec2_code_ref) eq 'CODE';

    my $txt = <<"EOT";

Section 2:
    Length of section:                 @{[ length $self->{SEC2_STREAM} ]}
EOT

    return $txt . $sec2_code_ref->($self->{SEC2_STREAM}) . "\n";
}

sub dumpsection3 {
    my $self = shift;
    _croak "BUFR object not properly initialized to call dumpsection3. "
        . "Did you forget to call next_observation()?" unless $self->{SEC3_STREAM};
    $self->{DESCRIPTORS_UNEXPANDED} ||= '';

    my $txt = <<"EOT";

Section 3:
    Length of section:                 @{[ length $self->{SEC3_STREAM} ]}
    Number of data subsets:            $self->{NUM_SUBSETS}
    Observed data:                     $self->{OBSERVED_DATA}
    Compressed data:                   $self->{COMPRESSED_DATA}
    Data descriptors unexpanded:       $self->{DESCRIPTORS_UNEXPANDED}
EOT
    return $txt;
}

sub dumpsection4 {
    my $self = shift;
    my $data = shift;
    my $descriptors = shift;
    my $width = shift || 15;    # Optional argument
    # Since last (optional) argument to dumpsection() is an anonymous
    # hash, check that this is not mistakenly applied here also
    _croak "Last optional argument to dumpsection4 should be integer"
        if ref($width) || $width !~ /^\d+$/;

    my $txt = "\n";
    my $B_table = $self->{B_TABLE};
    # Add the artificial descriptor for associated field
    $B_table->{999999} = "ASSOCIATED FIELD\0NUMERIC";
    my $C_table = $self->{C_TABLE} || '';
    my $idx = 0;
    my $line_no = 0;    # Precede each line with a line number, except
                        # for replication descriptors and for operator
                        # descriptors with no data value in section 4
  ID:
    foreach my $id (@{$descriptors}) {
        my $value = defined $data->[$idx] ? $data->[$idx] : 'missing';
        $idx++;
        my $f = substr($id, 0, 1);
        if ($f == 1) {
            $txt .= sprintf "        %6d\n", $id;
            next ID;
        } elsif ($f == 2) {
            if ($id =~ /^205/) {    # Character information operator
                $txt .= sprintf "%6d  %06d  %${width}.${width}s  %s\n",
                    ++$line_no, $id, $value, "CHARACTER INFORMATION";
                next ID;
            } else {
                my $operator_name = _get_operator_name($id);
                if ($operator_name) {
                    $txt .= sprintf "        %06d  %${width}.${width}s  %s\n",
                        $id, "", $operator_name;
                }
                next ID;
            }
        } elsif ($f == 9 && $id != 999999) {
            $txt .= sprintf "%6d  %06d  %${width}.${width}s  %s %06d\n",
                ++$line_no, $id, $value, 'NEW REFERENCE VALUE FOR', $id - 900000;
            next ID;
        } elsif ($id == 31031) { # This is the only data descriptor
                                 # where all bits set to one should
                                 # not be rendered as missing value
                                 # (for replication/repetition factors in
                                 # class 31 $value has been adjusted already)
            $value = 1 if $value eq 'missing';
        }
        _croak "Data descriptor $id is not present in BUFR table B"
            unless exists $B_table->{$id};
        my ($name, $unit, $bits) = (split /\0/, $B_table->{$id})[0,1,4];
        # Code or flag table number equals $id, so no need to display this in [unit]
        my $short_unit = $unit;
        my $unit_start = uc(substr($unit, 0, 4));
        if ($unit_start eq 'CODE') {
            $short_unit = 'CODE TABLE';
        } elsif ($unit_start eq 'FLAG') {
            $short_unit = 'FLAG TABLE';
        }
        $txt .= sprintf "%6d  %06d  %${width}.${width}s  %s\n",
            ++$line_no, $id, $value, "$name [$short_unit]";

        # Check for illegal flag value
        if ($Strict_checking && $short_unit eq 'FLAG TABLE' && $bits > 1) {
            if ($value ne 'missing' && $value % 2) {
                $bits += 0; # get rid of spaces
                my $max_value = 2**$bits - 1;
                _complain("$id - $value: rightmost bit $bits is set indicating missing value"
                          . " but then value should be $max_value");
            }
        }

        # Resolve flag and code table values if code table is loaded
        # (but don't bother about 031031 - too much uninformative output)
        if ($C_table && $id != 31031 && $value ne 'missing') {
            my $num_spaces = $width + 18;
            $txt .= _get_code_table_txt($id,$value,$unit,$B_table,$C_table,$num_spaces)
        }
    }
    return $txt;
}

# Operators which should always be displayed in dumpsection4
my %OPERATOR_NAME_A =
    ( 222000 => 'QUALITY INFORMATION FOLLOW',
      223000 => 'SUBSTITUTED VALUES FOLLOW',
      224000 => 'FIRST ORDER STATISTICS FOLLOW',
      225000 => 'DIFFERENCE STATISTICAL VALUES FOLLOW',
      232000 => 'REPLACE/RETAINED VALUES FOLLOW',
      235000 => 'CANCEL BACKWARD DATA REFERENCE',
      236000 => 'DEFINE DATA PRESENT BIT MAP',
      237000 => 'USE PREVIOUSLY DEFINED BIT MAP',
 );
# Operators which should normally not be displayed in dumpsection4
my %OPERATOR_NAME_B =
    ( 201000 => 'CANCEL CHANGE DATA WIDTH',
      202000 => 'CANCEL CHANGE SCALE',
      203000 => 'CANCEL CHANGE REFERENCE VALUES',
      207000 => 'CANCEL INCREASE SCALE, REFERENCE VALUE AND DATA WIDTH',
      208000 => 'CANCEL CHANGE WIDTH OF CCITT IA5 FIELD',
      203255 => 'STOP CHANGING REFERENCE VALUES',
      223255 => 'SUBSTITUTED VALUES MARKER OPERATOR',
      224255 => 'FIRST ORDER STATISTICAL VALUES MARKER OPERATOR',
      225255 => 'DIFFERENCE STATISTICAL STATISTICAL VALUES MARKER OPERATOR',
      232255 => 'REPLACED/RETAINED VALUES MARKER OPERATOR',
      237255 => 'CANCEL DEFINED DATA PRESENT BIT MAP',
 );
# Operator classes which should normally not be displayed in dumpsection4
my %OPERATOR_NAME_C =
    ( 201 => 'CHANGE DATA WIDTH',
      202 => 'CHANGE SCALE',
      203 => 'CHANGE REFERENCE VALUES',
      204 => 'ADD ASSOCIATED FIELD',
      # This one is displayed, treated specially (and named CHARACTER INFORMATION)
##      205 => 'SIGNIFY CHARACTER',
      206 => 'SIGNIFY DATA WIDTH FOR THE IMMEDIATELY FOLLOWING LOCAL DESCRIPTOR',
      207 => 'INCREASE SCALE, REFERENCE VALUE AND DATA WIDTH',
      208 => 'CHANGE WIDTH OF CCITT IA5 FIELD',
      221 => 'DATA NOT PRESENT',
 );
sub _get_operator_name {
    my $id = shift;
    my $operator_name = '';
    if ($OPERATOR_NAME_A{$id}) {
        $operator_name = $OPERATOR_NAME_A{$id}
    } elsif ($Show_all_operators) {
        if ($OPERATOR_NAME_B{$id}) {
            $operator_name = $OPERATOR_NAME_B{$id}
        } else {
            my $fx = substr $id, 0, 3;
            if ($OPERATOR_NAME_C{$fx}) {
                $operator_name = $OPERATOR_NAME_C{$fx};
            }
        }
    }
    return $operator_name;
}

## Display bit mapped values on same line as the original value. This
## offer a much shorter and easier to read dump of section 4 when bit
## maps has been used (i.e. for 222000 quality information, 223000
## substituted values, 224000 first order statistics, 225000
## difference statistics, 232000 replaced/retained values). '*******'
## is displayed if data is not present in bit map (bit set to 1 in
## 031031 or data not covered by the 031031 descriptors), 'missing' is
## displayed if value is missing.  But note that we miss other
## descriptors like 001031 and 001032 if these come after 222000 etc
## with the current implementation. And there are more shortcomings,
## described in CAVEAT section in POD for bufrread.pl
sub dumpsection4_with_bitmaps {
    my $self = shift;
    my $data = shift;
    my $descriptors = shift;
    my $isub = shift;
    my $width = shift || 15;    # Optional argument

    # If no bit maps call the ordinary dumpsection4
    if (not defined $self->{BITMAPS}) {
        return $self->dumpsection4($data, $descriptors, $width);
    }

    # $Show_all_operators must be turned off for this sub to work correctly
    _croak "Cannot dump section 4 properly with bitmaps"
        . " when Show_all_operators is set" if $Show_all_operators;

    # The kind of bit maps (i.e. the operator descriptors) used in BUFR message
    my @bitmap_desc = @{ $self->{BITMAP_OPERATORS} };

    my @bitmap_array; # Will contain for each bit map a reference to a hash with
                      # key: index (in data and descriptor arrays) for data value
                      # value: index for bit mapped value

    # For compressed data all subsets use same bit map (we assume)
    $isub = 0 if $self->{COMPRESSED_DATA};

    my $txt = "\n";
    my $space = ' ';
    my $line = $space x (17 + $width);
    foreach my $bitmap_num (0..$#bitmap_desc) {
        $line .= "  $bitmap_desc[$bitmap_num]";
        # Convert the sequence of ($data_idesc,$bitmapped_idesc) pairs into a hash
        my %hash = @{ $self->{BITMAPS}->[$bitmap_num + 1]->[$isub] };
        $bitmap_array[$bitmap_num] = \%hash;
    }
    # First make a line showing the operator descriptors using bit maps
    $txt .= "$line\n";

    my $B_table = $self->{B_TABLE};
    # Add the artificial descriptor for associated field
    $B_table->{999999} = "ASSOCIATED FIELD\0Numeric";
    my $C_table = $self->{C_TABLE} || '';

    my $idx = 0;
    # Loop over data descriptors
  ID:
    foreach my $id (@{$descriptors}) {
        # Stop printing when the bit map part starts
        last ID if (substr($id,0,1) eq '2'
                        and ($id =~ /^22[2-5]/ || $id =~ /^232/));

        # Get the data value
        my $value = defined $data->[$idx] ? $data->[$idx] : 'missing';
        _croak "Data descriptor $id is not present in BUFR table B"
            unless exists $B_table->{$id};
        my ($name, $unit, $bits) = (split /\0/, $B_table->{$id})[0,1,4];
        $line = sprintf "%6d  %06d  %${width}.${width}s ",
            $idx+1, $id, $value;

        # Then get the corresponding bit mapped values, using '*******'
        # if 'data not present' in bit map
        my $max_len = 7;
        foreach my $bitmap_num (0..$#bitmap_desc) {
            my $val;
            if ($bitmap_array[$bitmap_num]->{$idx}) {
                # data marked as 'data present' in bitmap
                my $bitmapped_idesc = $bitmap_array[$bitmap_num]->{$idx};
                $val = defined $data->[$bitmapped_idesc]
                    ? $data->[$bitmapped_idesc] : 'missing';
                $max_len = length($val) if length($val) > $max_len;
            } else {
                $val = '*******';
            }
            # If $max_len has been increased, this might not always
            # print very pretty, but at least there is no truncation
            # of digits in value
            $line .= sprintf " %${max_len}.${max_len}s", $val;
        }
        # Code or flag table number equals $id, so no need to display this in [unit]
        my $short_unit = $unit;
        my $unit_start = uc(substr($unit, 0, 4));
        if ($unit_start eq 'CODE') {
            $short_unit = 'CODE TABLE';
        } elsif ($unit_start eq 'FLAG') {
            $short_unit = 'FLAG TABLE';
        }
        $line .=  sprintf "  %s\n", "$name [$short_unit]";
        $txt .= $line;

        # Check for illegal flag value
        if ($Strict_checking && $short_unit eq 'FLAG TABLE' && $bits > 1) {
            if ($value ne 'missing' and $value % 2) {
                my $max_value = 2**$bits - 1;
                $bits += 0; # get rid of spaces
                _complain("$id - $value: rightmost bit $bits is set indicating missing value"
                          . " but then value should be $max_value");
            }
        }

        # Resolve flag and code table values if code table is loaded
        if ($C_table && $value ne 'missing') {
            my $num_spaces = $width + 19 + 7*@bitmap_desc;
            $txt .= _get_code_table_txt($id,$value,$unit,$B_table,$C_table,$num_spaces)
        }
        $idx++;
    }
    return $txt;
}

## Return the text found in flag or code tables for value $value of
## descriptor $id. The empty string is returned if $unit is neither
## CODE TABLE nor FLAG TABLE, or if $unit is CODE TABLE but for this
## $value there is no text in C table. Returns a "... does not exist!"
## message if flag/code table is not found. If $check_illegal is
## defined, an 'Illegal value' message is returned if $value is bigger
## than allowed or has highest bit set without having all other bits
## set.
sub _get_code_table_txt {
    my ($id,$value,$unit,$B_table,$C_table,$num_spaces,$check_illegal) = @_;

    my $txt = '';
    # Need case insensitive matching, since local tables from at least
    # DWD use 'Code table', not 'CODE TABLE', in the ECMWF ecCodes
    # distribution
    if ($unit =~ m/^CODE[ ]?TABLE/i) {
        my $code_table = sprintf "%06d", $id;
        return "Code table $code_table does not exist!\n"
            if ! exists $C_table->{$code_table};
        if ($C_table->{$code_table}{$value}) {
            my @lines = split "\n", $C_table->{$code_table}{$value};
            foreach (@lines) {
                $txt .= sprintf "%s   %s\n", ' ' x ($num_spaces), lc $_;
            }
        }
    } elsif ($unit =~ m/^FLAG[ ]?TABLE/i) {
        my $flag_table = sprintf "%06d", $id;
        return "Flag table $flag_table does not exist!\n"
            if ! exists $C_table->{$flag_table};

        my $width = (split /\0/, $B_table->{$flag_table})[4];
        $width += 0;            # Get rid of spaces
        # Cannot handle more than 32 bits flags with current method
        _croak "Unable to handle > 32 bits flag; $id has width $width"
            if $width > 32;

        my $max_value = 2**$width - 1;

        if (defined $check_illegal and $value > $max_value) {
            $txt = "Illegal value: $value is bigger than maximum allowed ($max_value)\n";
        } elsif ($value == $max_value) {
            $txt = sprintf "%s=> %s", ' ' x ($num_spaces), "bit $width set:"
                . sprintf "%s   %s\n", ' ' x ($num_spaces), "missing value\n";
        } else {
            # Convert to bitstring and localize the 1 bits
            my $binary = pack "N", $value; # Packed as 32 bits in big-endian order
            my $bitstring = substr unpack('B*',$binary), 32-$width;
            for my $i (1..$width) {
                if (substr($bitstring, $i-1, 1) == 1) {
                    $txt .= sprintf "%s=> %s", ' ' x ($num_spaces),
                        "bit $i set";
                    if ($C_table->{$flag_table}{$i}) {
                        my @lines = split "\n", $C_table->{$flag_table}{$i};
                        $txt .= ': ' . lc (shift @lines) . "\n";
                        foreach (@lines) {
                            $txt .= sprintf "%s   %s\n", ' ' x ($num_spaces), lc $_;
                        }
                    } else {
                        $txt .= "\n";
                    }
                }
            }
            if (defined $check_illegal and $txt =~ /bit $width set/) {
                $txt = "Illegal value ($value): bit $width is set indicating missing value,"
                    . " but then value should be $max_value\n";
            }
        }
    }
    return $txt;
}

##  Convert from integer to descriptor
sub _int2fxy {
    my @fxy = map {sprintf("%1d%02d%03d", ($_>>14)&0x3, ($_>>8)&0x3f, $_&0xff)} @_;
    return @_ > 1 ? @fxy : $fxy[0];
}

##  Expand a list of descriptors using BUFR table D, also expanding
##  simple replication but not delayed replication
sub _expand_descriptors {
    my $D_table = shift;
    my @expanded = ();

    for (my $di = 0; $di < @_; $di++) {
        my $descriptor = $_[$di];
        _croak "$descriptor is not a BUFR descriptor"
            if $descriptor !~ /^\d{6}$/;
        my $f = int substr($descriptor, 0, 1);
        if ($f == 1) {
            my $x = substr $descriptor, 1, 2; # Replicate next $x descriptors
            my $y = substr $descriptor, 3;    # Number of replications
            if ($y > 0) {
                # Simple replication (replicate next x descriptors y times)
                _croak "Cannot expand: Not enough descriptors following "
                    . "replication descriptor $descriptor (or there is "
                    . "a problem in nesting of replication)" if $di+$x+1 > @_;
                my @r = ();
                push @r, @_[($di+1)..($di+$x)] for (1..$y);
                # Recursively expand replicated descriptors $y times
                my @s = ();
                @s = _expand_descriptors($D_table, @r) if @r;
                if ($Show_replication) {
                    # Adjust x since replicated descriptors might have been expanded
                    # Unfortunately _spew is not available here to report the x>99 -> x=0 hack
                    my $z =  @s/$y > 99 ? 0 : @s/$y;
                    substr($_[$di], 1, 2) = sprintf "%02d", $z;
                    push @expanded, $_[$di];
                }
                push @expanded, @s if @s;
                $di += $x;
            } else {
                # Delayed replication. Next descriptor ought to be the
                # delayed descriptor replication (and data repetition)
                # factor, i.e. one of 0310(00|01|02|11|12), followed
                # by the x descriptors to be replicated
                if ($di+2 == @_ && $_[$di+1] =~ /^0310(00|01|02|11|12)$/) {
                    _complain "Missing the $x descriptors which should follow"
                        . " $descriptor $_[$di+1]";
                    push @expanded, @_[$di,$di+1];
                    last;
                }
                _croak "Cannot expand: Not enough descriptors following delayed"
                    . " replication descriptor $descriptor (or there is "
                    . "a problem in nesting of replication)" if $di+$x+1 > @_;
                _croak "Cannot expand: Delayed replication descriptor "
                    . "$descriptor is not followed by one of "
                    . "0310(00|01|02|11|12) but by $_[$di+1]"
                        if $_[$di+1] !~ /^0310(00|01|02|11|12)$/;
                my @r = @_[($di+2)..($di+$x+1)];
                # Here we just expand the D descriptors in the
                # descriptors to be replicated. The final expansion
                # using delayed replication factor has to wait until
                # data part is decoded
                my @s = ();
                @s = _expand_descriptors($D_table, @r) if @r;
                # Must adjust x since replicated descriptors might have been expanded
                substr($_[$di], 1, 2) = sprintf "%02d", scalar @s;
                push @expanded, @_[$di,$di+1], @s;
                $di += 1+$x; # NOTE: 1 is added to $di on next iteration
            }
            next;
        } elsif ($f == 3) {
            _croak "No sequence descriptor $descriptor in BUFR table D"
                if not exists $D_table->{$descriptor};
            # Expand recursively, if necessary
            push @expanded,
                _expand_descriptors($D_table, split /\s/, $D_table->{$descriptor});
        } else { # f=0,2
            push @expanded, $descriptor;
        }
    }

    return @expanded;
}

## Return a text string suitable for printing information about the given
## BUFR table descriptors
##
## $how = 'fully': Expand all D descriptors fully into B descriptors,
## with name, unit, scale, reference value and width (each on a
## numbered line, except for replication operators which are not
## numbered).
##
## $how = 'partially': Like 'fully, but expand D descriptors only once
## and ignore replication.
##
## $how = 'noexpand': Like 'partially', but do not expand D
## descriptors at all.
##
## $how = 'simply': Like 'partially', but list the descriptors on one
## single line with no extra information provided.
sub resolve_descriptor {
    my $self = shift;
    my $how = shift;
    foreach (@_) {
        _croak("'$_' is not an integer argument to resolve_descriptor!")
            unless /^\d+$/;
    }
    my @desc = map { sprintf "%06d", $_ } @_;

    my @allowed_hows = qw( simply fully partially noexpand );
    _croak "First argument in resolve_descriptor must be one of"
        . " '@allowed_hows', is: '$how'"
            unless grep { $how eq $_ } @allowed_hows;

    if (! $self->{B_TABLE}) {
        if ($BUFR_table{FORMAT} eq 'ECCODES' && $self->{LOCAL_TABLES_NOT_FOUND}) {
            _croak "Local table " . $self->{LOCAL_TABLES_NOT_FOUND} . " couldn't be found,"
                . " or you might need to load WMO master table also?";
        } else {
            _croak "No B table is loaded - did you forget to call load_BDtables?";
        }
    }
    my $B_table = $self->{B_TABLE};

    # Some local tables are provided only for element descriptors, and
    # we might in fact not need the sequence descriptors for resolving
    my $D_table;
    my $need_Dtable = 0;
    foreach my $id (@desc) {
        if (substr($id,0,1) eq '3') {
            $need_Dtable = 1;
        }
    }
    if ($need_Dtable && ! $self->{D_TABLE}) {
        if ($BUFR_table{FORMAT} eq 'ECCODES' && $self->{LOCAL_TABLES_NOT_FOUND}) {
            _croak "Local table " . $self->{LOCAL_TABLES_NOT_FOUND} . " couldn't be found,"
                . " or you might need to load WMO master table also?";
        } else {
            _croak "No D table is loaded - did you forget to call load_BDtables?";
        }
    } else {
        # Could consider omitting this if $need_Dtable = 0 ...
        $D_table = $self->{D_TABLE};
    }

    my $txt = '';

    if ($how eq 'simply' or $how eq 'partially') {
        my @expanded;
        foreach my $id (@desc) {
            my $f = substr $id, 0, 1;
            if ($f == 3) {
                _croak "$id is not in table D, unable to expand"
                    unless $D_table->{$id};
                push @expanded, split /\s/, $D_table->{$id};
            } else {
                push @expanded, $id;
            }
        }
        if ($how eq 'simply') {
            return $txt = "@expanded\n";
        } else {
            @desc = @expanded;
        }
    }
    if ($how eq 'fully') {
        if (@desc == 1 and $desc[0] =~ /^1/) {
            # This is simply a replication descriptor; do not try to expand
        } else {
            @desc = _expand_descriptors($D_table, @desc);
        }
    }

    my $count = 0;
    foreach my $id (@desc) {
        if ($id =~ /^[123]/) {
            $txt .= sprintf "    %06d\n", $id;
        } elsif ($B_table->{$id}) {
            my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$id};
            $txt .= sprintf "%3d %06d  %s [%s] %d %d %d\n",
                ++$count,$id,$name,$unit,$scale,$refval,$width;
        } else {
            $txt .= sprintf "%3d %06d  Not in table B\n",
                ++$count,$id;
        }
    }
    return $txt;
}

## Return BUFR table B information for an element descriptor for the
## last table loaded, as an array of name, unit, scale, reference
## value and data width in bits. Returns false if the descriptor is
## not found or no data width is defined, or croaks if no table B has
## been loaded.
sub element_descriptor {
    my $self = shift;
    my $desc = shift;
    _croak "Argument to element_descriptor must be an integer\n"
        unless $desc =~ /^\d+$/;
    $desc = sprintf "%06d", $desc;
    _croak "No BUFR B table loaded\n" unless defined $self->{B_TABLE};
    return unless defined $self->{B_TABLE}->{$desc};
    my ($name, $unit, $scale, $refval, $width)
        = split /\0/, $self->{B_TABLE}->{$desc};
    return unless defined $width && $width =~ /\d+$/;
    return ($name, $unit, $scale+0, $refval+0, $width+0);
}

## Return BUFR table D information for a sequence descriptor for the
## last table loaded, as a space separated string of the descriptors
## in the direct (nonrecursive) lookup in table D. Returns false if
## the sequence descriptor is not found, or croaks if no table D has
## been loaded.
sub sequence_descriptor {
    my $self = shift;
    my $desc = shift;
    _croak "Argument to element_descriptor must be an integer\n"
        unless $desc =~ /^\d+$/;
    _croak "No BUFR D table loaded\n" unless defined $self->{D_TABLE};
    return unless defined $self->{D_TABLE}->{$desc};
    if (wantarray) {
        return split / /, $self->{D_TABLE}->{$desc};
    } else {
        return $self->{D_TABLE}->{$desc};
    }
}

## Return a text string telling which bits are set and the meaning of
## the bits set when $value is interpreted as a flag value, also
## checking for illegal values. The empty string is returned if $value=0.
sub resolve_flagvalue {
    my $self = shift;
    my ($value, $flag_table, $table, $num_leading_spaces) = @_;
    _croak "Flag value can't be negative!\n" if $value < 0;
    $num_leading_spaces ||= 0;  # Default value

    $self->load_Ctable($table);
    my $C_table = $self->{C_TABLE};

    # Number of bits used for the flag is hard to extract from C
    # table; it is much easier to obtain from B table
    $self->load_BDtables($table);
    my $B_table = $self->{B_TABLE};

    my $unit = 'FLAG TABLE';
    return _get_code_table_txt($flag_table,$value,$unit,
                               $B_table,$C_table,$num_leading_spaces,'check_illegal');
}

## Return the contents of code table $code_table, or empty string if
## code table is not found
sub dump_codetable {
    my $self = shift;
    my ($code_table, $table) = @_;
    _croak("code_table '$code_table' is not a (positive) integer in dump_codetable()")
        unless $code_table =~ /^\d+$/;
    $code_table = sprintf "%06d", $code_table;

    $self->load_Ctable($table);
    my $C_table = $self->{C_TABLE};

    return '' unless $C_table->{$code_table};

    my $dump;
    foreach my $value (sort {$a <=> $b} keys %{ $C_table->{$code_table} }) {
        my $txt = $C_table->{$code_table}{$value};
        chomp $txt;
        $txt =~ s/\n/\n       /g;
        $dump .= sprintf "%3d -> %s\n", $value, $txt;
    }
    return $dump;
}

## Decode bitstream (data part of section 4) while working through the
## (expanded) descriptors in section 3. The final data and
## corresponding descriptors are put in $self->{DATA} and
## $self->{DESC} (indexed by subset number)
sub _decode_bitstream {
    my $self = shift;
    $self->{CODING} = 'DECODE';
    my $bitstream = $self->{SEC4_RAWDATA} . "\0\0\0\0";
    my $maxpos = 8*length($self->{SEC4_RAWDATA});
    my $pos = 0;
    my @operators;
    my $ref_values_ref; # Hash ref to reference values with descriptors as keys;
                        # to be implemented later (not used yet)
    my @subset_data; # Will contain data values for subset 1,2...
    my @subset_desc; # Will contain the set of descriptors for subset 1,2...
                     # expanded to be in one to one correspondance with the data
    my $repeat_X; # Set to number of descriptors to be repeated if
                  # delayed descriptor and data repetition factor is
                  # in effect
    my $repeat_factor; # Set to number of times descriptors (and data)
                       # are to be repeated if delayed descriptor and
                       # data repetition factor is in effect
    my @repeat_desc; # The descriptors to be repeated
    my @repeat_data; # The data to be repeated
    my $B_table = $self->{B_TABLE};

    # Has to fully expand @desc for each subset in turn, as delayed
    # replication factors might be different for each subset,
    # resulting in different full expansions. During the expansion the
    # effect of operator descriptors are taken into account, causing
    # most of them to be eliminated (unless $Show_all_operators is
    # set), so that @desc and the equivalent $subset_desc[$isub] ends
    # up being in one to one correspondence with the data values in
    # $subset_data[$isub] (the operators included having data value
    # '')
  S_LOOP: foreach my $isub (1..$self->{NUM_SUBSETS}) {
        $self->_spew(2, "Decoding subset number %d", $isub) if $Spew;

        # Bit maps might vary from subset to subset, so must be rebuilt
        undef $self->{BITMAP_OPERATORS};
        undef $self->{BITMAP_START};
        undef $self->{REUSE_BITMAP};
        $self->{NUM_BITMAPS} = 0;
        $self->{BACKWARD_DATA_REFERENCE} = 1;
        $self->{NUM_CHANGE_OPERATORS} = 0;

        my @desc = split /\s/, $self->{DESCRIPTORS_EXPANDED};

        # Note: @desc as well as $idesc may be changed during this loop,
        # so we cannot use a foreach loop instead
      D_LOOP: for (my $idesc = 0; $idesc < @desc; $idesc++) {
            my $id = $desc[$idesc];
            my $f = substr($id,0,1);
            my $x = substr($id,1,2)+0;
            my $y = substr($id,3,3)+0;

            if ($f == 1) {
                if ($Show_replication) {
                    push @{$subset_desc[$isub]}, $id;
                    push @{$subset_data[$isub]}, '';
                    $self->_spew(4, "X=0 in $id for F=1, might have been > 99 in expansion")
                        if $Spew && $x == 0;
                }
                next D_LOOP if $y > 0; # Nothing more to do for normal replication

                if ($x == 0) {
                    _complain("Nonsensical replication of zero descriptors ($id)");
                    $idesc++;
                    next D_LOOP;
                }

                $_ = $desc[$idesc+1];
                _croak "$id Erroneous replication factor"
                    unless /^0310(00|01|02|11|12)/ && exists $B_table->{$_};

                my $width = (split /\0/, $B_table->{$_})[-1];
                my $factor = bitstream2dec($bitstream, $pos, $width);
                $pos += $width;
                # Delayed descriptor replication factors (and
                # associated fields) are the only values in section 4
                # where all bits being 1 is not to be interpreted as a
                # missing value
                if (not defined $factor) {
                    $factor = 2**$width - 1;
                }
                if ($Spew) {
                    if ($_ eq '031011' || $_ eq '031012') {
                        $self->_spew(4, "$_  Delayed repetition factor: %s", $factor);
                    } else {
                        $self->_spew(4, "$_  Delayed replication factor: %s", $factor);
                    }
                }
                # Include the delayed replication in descriptor and data list
                splice @desc, $idesc++, 0, $_;
                push @{$subset_desc[$isub]}, $_;
                push @{$subset_data[$isub]}, $factor;

                if ($_ eq '031011' || $_ eq '031012') {
                    # For delayed repetition, descriptor *and* data are
                    # to be repeated
                    $repeat_X = $x;
                    $repeat_factor = $factor;
                }
                my @r = ();
                push @r, @desc[($idesc+2)..($idesc+$x+1)] while $factor--;
                splice @desc, $idesc, 2+$x, @r;

                if ($repeat_factor) {
                    # Skip to the last set to be repeated, which will
                    # then be included $repeat_factor times
                    $idesc += $x * ($repeat_factor - 1);
                    $self->_spew(4, "Delayed repetition ($id $_ -> @r)") if $Spew;
                } else {
                    $self->_spew(4, "Delayed replication ($id $_ -> @r)") if $Spew;
                }
                if ($idesc < @desc) {
                    redo D_LOOP;
                } else {
                    last D_LOOP; # Might happen if delayed factor is 0
                }

            } elsif ($f == 2) {
                my $flow;
                my $bm_idesc;
                ($pos, $flow, $bm_idesc, @operators)
                    = $self->_apply_operator_descriptor($id, $x, $y, $pos, $isub,
                                                        $desc[$idesc+1], @operators);
                if ($flow eq 'redo_bitmap') {
                    # Data value is associated with the descriptor
                    # defined by bit map. Remember original and new
                    # index in descriptor array for the bit mapped
                    # values ('dr' = data reference)
                    my $dr_idesc;
                    if (!defined $bm_idesc) {
                        $dr_idesc = shift @{$self->{REUSE_BITMAP}->[$isub]};
                    } elsif (!$Show_all_operators) {
                        $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                            + $bm_idesc;
                    } else {
                        $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}];
                        # Skip operator descriptors
                        while ($bm_idesc-- > 0) {
                            $dr_idesc++;
                            $dr_idesc++ while ($desc[$dr_idesc] >= 200000);
                        }
                    }
                    push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[$isub] },
                         $dr_idesc, $idesc;
                    if ($Show_all_operators) {
                        push @{$subset_desc[$isub]}, $id;
                        push @{$subset_data[$isub]}, '';
                    }
                    $desc[$idesc] = $desc[$dr_idesc];
                    redo D_LOOP;
                } elsif ($flow eq 'signify_character') {
                    push @{$subset_desc[$isub]}, $id;
                    # Extract ASCII string
                    my $value = bitstream2ascii($bitstream, $pos, $y);
                    $pos += 8*$y;
                    # Trim string, also removing nulls
                    $value = _trim($value, $id);
                    push @{$subset_data[$isub]}, $value;
                    next D_LOOP;
                } elsif ($flow eq 'no_value') {
                    # Some operator descriptors ought to be included
                    # in expanded descriptors even though they have no
                    # corresponding data value, because they contain
                    # valuable information to be displayed in
                    # dumpsection4 (e.g. 222000 'Quality information follows')
                    push @{$subset_desc[$isub]}, $id;
                    push @{$subset_data[$isub]}, '';
                    next D_LOOP;
                }

                if ($Show_all_operators) {
                    push @{$subset_desc[$isub]}, $id;
                    push @{$subset_data[$isub]}, '';
                } else {
                    # Remove operator descriptor from @desc
                    splice @desc, $idesc--, 1;
                }

                next D_LOOP if $flow eq 'next';
                last D_LOOP if $flow eq 'last';
                if ($flow eq 'skip') {
                    $idesc++;
                    next D_LOOP;
                }
            }

            if ($self->{CHANGE_REFERENCE_VALUE}) {
                # The data descriptor is to be associated with a new
                # reference value, which is fetched from data stream
                _croak "Change reference operator 203Y is not followed by element"
                    . " descriptor, but $id" if $f > 0;
                my $num_bits = $self->{CHANGE_REFERENCE_VALUE};
                my $new_refval = bitstream2dec($bitstream, $pos, $num_bits);
                $pos += $num_bits;
                # Negative value if most significant bit is set (one's complement)
                $new_refval = $new_refval & (1<<$num_bits-1)
                    ? -($new_refval & ((1<<$num_bits-1)-1))
                        : $new_refval;
                $self->_spew(4, "$id * Change reference value: ".
                             ($new_refval > 0 ? "+" : "")."$new_refval") if $Spew;
                $self->{NEW_REFVAL_OF}{$id}{$isub} = $new_refval;
                # Identify new reference values by setting f=9
                push @{$subset_desc[$isub]}, $id + 900000;
                push @{$subset_data[$isub]}, $new_refval;
                next D_LOOP;
            }

            # If operator 204$y 'Add associated field is in effect',
            # each data value is preceded by $y bits which should be
            # decoded separately. We choose to provide a descriptor
            # 999999 in this case (like the ECMWF BUFRDC software)
            if ($self->{ADD_ASSOCIATED_FIELD} and $id ne '031021') {
                # First extract associated field
                my $width = $self->{ADD_ASSOCIATED_FIELD};
                my $value = bitstream2dec($bitstream, $pos, $width);
                # All bits set to 1 for associated field is NOT
                # interpreted as missing value
                $value = 2**$width - 1 if ! defined $value;
                $pos += $width;
                push @{$subset_desc[$isub]}, 999999;
                push @{$subset_data[$isub]}, $value;
                $self->_spew(4, "Added associated field: %s", $value) if $Spew;
            }

            # We now have a "real" data descriptor
            push @{$subset_desc[$isub]}, $id;

            # For quality information, if this relates to a bit map we
            # need to store index of the data ($data_idesc) for which
            # the quality information applies, as well as the new
            # index ($idesc) in the descriptor array for the bit
            # mapped values
            if (substr($id,0,3) eq '033'
                && defined $self->{BITMAP_OPERATORS}
                && $self->{BITMAP_OPERATORS}->[-1] eq '222000') {
                if (defined $self->{REUSE_BITMAP}) {
                    my $data_idesc = shift @{ $self->{REUSE_BITMAP}->[$isub] };
                    _croak "$id: Not enough quality values provided"
                        if not defined $data_idesc;
                    push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[$isub] },
                         $data_idesc, $idesc;
                } else {
                    my $data_idesc = shift @{ $self->{CURRENT_BITMAP} };
                    _croak "$id: Not enough quality values provided"
                        if not defined $data_idesc;
                    push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[$isub] },
                         $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                             + $data_idesc, $idesc;
                }
            }

            # Find the relevant entry in BUFR table B
            _croak "Data descriptor $id is not present in BUFR table B"
                unless exists $B_table->{$id};
            my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$id};
            $self->_spew(3, "%6s  %-20s  %s", $id, $unit, $name) if $Spew;

            # Override Table B values if Data Description Operators are in effect
            if ($self->{NUM_CHANGE_OPERATORS} > 0) {
                if ($unit ne 'CCITTIA5' && $unit !~ /^(CODE|FLAG)/) {
                    if (defined $self->{CHANGE_SRW}) {
                        $scale += $self->{CHANGE_SRW};
                        $width += int((10*$self->{CHANGE_SRW}+2)/3);
                        $refval *= 10*$self->{CHANGE_SRW};
                    } else {
                        $scale += $self->{CHANGE_SCALE} if defined $self->{CHANGE_SCALE};
                        $width += $self->{CHANGE_WIDTH} if defined $self->{CHANGE_WIDTH};
                    }
                } elsif ($unit eq 'CCITTIA5' && defined $self->{CHANGE_CCITTIA5_WIDTH}) {
                    $width = $self->{CHANGE_CCITTIA5_WIDTH}
                }
                # To prevent autovivification (see perldoc -f exists) we
                # need this laborious test for defined
                $refval = $self->{NEW_REFVAL_OF}{$id}{$isub} if defined $self->{NEW_REFVAL_OF}{$id}
                    && defined $self->{NEW_REFVAL_OF}{$id}{$isub};
                # Difference statistical values use different width and reference value
                if ($self->{DIFFERENCE_STATISTICAL_VALUE}) {
                    $width += 1;
                    $refval = -2**$width;
                    undef $self->{DIFFERENCE_STATISTICAL_VALUE};
                    $self->{NUM_CHANGE_OPERATORS}--;
                }
            }
            _croak "$id Data width <= 0" if $width <= 0;

            my $value;
            if ($unit eq 'CCITTIA5') {
                # Extract ASCII string
                _croak "Width for unit CCITTIA5 must be integer bytes\n"
                    . "is $width bits for descriptor $id" if $width % 8;
                $value = bitstream2ascii($bitstream, $pos, $width/8);
                $self->_spew(3, "  %s", defined $value ? $value : 'missing') if $Spew;
                # Trim string, also removing nulls
                $value = _trim($value, $id);
            } else {
                $value = bitstream2dec($bitstream, $pos, $width);
                if (defined $value) {
                    # Compute and format decoded value
                    ($scale) = $scale =~ /(-?\d+)/; # untaint
                    $value = $scale <= 0 ? ($value + $refval)/10**$scale
                        : sprintf "%.${scale}f", ($value + $refval)/10**$scale;
                }
                $self->_spew(3, "  %s", defined $value ? $value : 'missing') if $Spew;
            }
            $pos += $width;
            push @{$subset_data[$isub]}, $value;
            # $value = undef if missing value

            if ($repeat_X) {
                # Delayed repetition factor (030011/030012) is in
                # effect, so descriptors and data are to be repeated
                push @repeat_desc, $id;
                push @repeat_data, $value;
                if (--$repeat_X == 0) {
                    # Store $repeat_factor repetitions of data and descriptors
                    # (one repetition has already been included)
                    while (--$repeat_factor) {
                        push @{$subset_desc[$isub]}, @repeat_desc;
                        push @{$subset_data[$isub]}, @repeat_data;
                    }
                    @repeat_desc = ();
                    @repeat_data = ();
                }
            }

            if ($id eq '031031' and $self->{BUILD_BITMAP}) {
                # Store the index of expanded descriptors if data is
                # marked as present in data present indicator: 0 is
                # 'present', 1 (undef value) is 'not present'. E.g.
                # bitmap = 1100110 => (2,3,6) is stored in $self->{CURRENT_BITMAP}
                if (defined $value) {
                    push @{$self->{CURRENT_BITMAP}}, $self->{BITMAP_INDEX};
                }
                $self->{BITMAP_INDEX}++;
                if ($self->{BACKWARD_DATA_REFERENCE} == $self->{NUM_BITMAPS}) {
                    my $numb = $self->{NUM_BITMAPS};
                    if (!defined $self->{BITMAP_START}[$numb]) {
                        # Look up the element descriptor immediately
                        # preceding the bitmap operator
                        my $i = $idesc;
                        $i-- while ($desc[$i] ne $self->{BITMAP_OPERATORS}->[-1]
                                    && $i >=0);
                        $i-- while ($desc[$i] > 100000 && $i >=0);
                        _croak "No element descriptor preceding bitmap" if $i < 0;
                        $self->{BITMAP_START}[$numb] = $i;
                    } else {
                        $self->{BITMAP_START}[$numb]--;
                        _croak "Bitmap too big"
                            if $self->{BITMAP_START}[$numb] < 0;
                    }
                }
            } elsif ($self->{BUILD_BITMAP} and $self->{BITMAP_INDEX} > 0) {
                # We have finished building the bit map
                $self->{BUILD_BITMAP} = 0;
                $self->{BITMAP_INDEX} = 0;
                if ($self->{BACKWARD_DATA_REFERENCE} != $self->{NUM_BITMAPS}) {
                    $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                        = $self->{BITMAP_START}[$self->{BACKWARD_DATA_REFERENCE}];
                }
            }
        } # End D_LOOP
    } # END S_LOOP

    # Check that length of section 4 corresponds to what expected from section 3
    $self->_check_section4_length($pos,$maxpos);

    $self->{DATA} = \@subset_data;
    $self->{DESC} = \@subset_desc;
    return;
}

## Decode bitstream (data part of section 4 encoded using BUFR
## compression) while working through the (expanded) descriptors in
## section 3. The final data and corresponding descriptors are put in
## $self->{DATA} and $self->{DESC} (the data indexed by subset number)
sub _decompress_bitstream {
    my $self = shift;
    $self->{CODING} = 'DECODE';
    my $bitstream = $self->{SEC4_RAWDATA}."\0\0\0\0";
    my $nsubsets = $self->{NUM_SUBSETS};
    my $B_table = $self->{B_TABLE};
    my $maxpos = 8*length($self->{SEC4_RAWDATA});
    my $pos = 0;
    my @operators;
    my @subset_data;     # Will contain data values for subset 1,2...,
                         # i.e. $subset[$i] is a reference to an array
                         # containing the data values for subset $i
    my @desc_exp;        # Will contain the set of descriptors for one
                         # subset, expanded to be in one to one
                         # correspondance with the data, i.e. element
                         # descriptors only
    my $repeat_X; # Set to number of descriptors to be repeated if
                  # delayed descriptor and data repetition factor is
                  # in effect. Will be decremented while (repeated)
                  # data sets are extracted
    my $repeat_XX; # Like $repeat_X, but will not be decremented
    my $repeat_factor; # Set to number of times descriptors (and data)
                       # are to be repeated if delayed descriptor and
                       # data repetition factor is in effect
    my @repeat_desc; # The descriptors to be repeated
    my @repeat_data; # The data to be repeated (reference to an array
                     # containing the data values for subset $i)

    _complain("Compression set in section 1 for one subset message")
        if $nsubsets == 1;

    $#subset_data = $nsubsets;

    my @desc = split /\s/, $self->{DESCRIPTORS_EXPANDED};
    # This will be further expanded to be in one to one correspondance
    # with the data, taking replication and table C operators into account

    # All subsets in a compressed BUFR message must have exactly the same
    # fully expanded section 3, i.e. all replications factors must be the same
    # in all subsets. So, as opposed to noncompressed messages, it is enough
    # to run through the set of descriptors once.
  D_LOOP: for (my $idesc = 0; $idesc < @desc; $idesc++) {
        my $id = $desc[$idesc];
        my $f = substr($id,0,1);
        my $x = substr($id,1,2)+0;
        my $y = substr($id,3,3)+0;

        if ($f == 1) {
            if ($Show_replication) {
                push @desc_exp, $id;
                foreach my $isub (1..$nsubsets) {
                    push @{$subset_data[$isub]}, '';
                }
                $self->_spew(4, "X=0 in $id for F=1, might have been > 99 in expansion")
                    if $Spew && $x == 0;
            }
            next D_LOOP if $y > 0; # Nothing more to do for normal replication

            if ($x == 0) {
                _complain("Nonsensical replication of zero descriptors ($id)");
                $idesc++;
                next D_LOOP;
            }

            $_ = $desc[$idesc+1];
            _croak "$id Erroneous replication factor"
                unless /^0310(00|01|02|11|12)/ && exists $B_table->{$_};

            my $width = (split /\0/, $B_table->{$_})[-1];
            my $factor = bitstream2dec($bitstream, $pos, $width);
            $pos += $width + 6; # 6 bits for the bit count (which we
                                # skip because we know it has to be 0
                                # for delayed replication)
            # Delayed descriptor replication factors (and associated
            # fields) are the only values in section 4 where all bits
            # being 1 is not interpreted as a missing value
            if (not defined $factor) {
                $factor = 2**$width - 1;
            }
            # Include the delayed replication in descriptor and data list
            push @desc_exp, $_;
            splice @desc, $idesc++, 0, $_;
            foreach my $isub (1..$nsubsets) {
                push @{$subset_data[$isub]}, $factor;
            }

            if ($_ eq '031011' || $_ eq '031012') {
                # For delayed repetition, descriptor *and* data is
                # to be repeated
                $repeat_X = $repeat_XX = $x;
                $repeat_factor = $factor;
                $self->_spew(4, "$_  Delayed repetition factor: $factor") if $Spew;
            } else {
                $self->_spew(4, "$_  Delayed replication factor: $factor") if $Spew;
            }
            my @r = ();
            push @r, @desc[($idesc+2)..($idesc+$x+1)] while $factor--;
            splice @desc, $idesc, 2+$x, @r;
            if ($Spew) {
                if ($repeat_factor) {
                    $self->_spew(4, "$_  Delayed repetition ($id $_ -> @r)");
                } else {
                    $self->_spew(4, "$_  Delayed replication ($id $_ -> @r)");
                }
            }

            if ($idesc < @desc) {
                redo D_LOOP;
            } else {
                last D_LOOP; # Might happen if delayed factor is 0
            }

        } elsif ($f == 2) {
            my $flow;
            my $bm_idesc;
            ($pos, $flow, $bm_idesc, @operators)
                = $self->_apply_operator_descriptor($id, $x, $y, $pos, 0,
                                                    $desc[$idesc+1], @operators);
            if ($flow eq 'redo_bitmap') {
                # Data value is associated with the descriptor
                # defined by bit map. Remember original and new
                # index in descriptor array for the bit mapped
                # values ('dr' = data reference)
                my $dr_idesc;
                if (!defined $bm_idesc) {
                    $dr_idesc = shift @{ $self->{REUSE_BITMAP}->[0] };
                } elsif (!$Show_all_operators) {
                    $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                        + $bm_idesc;
                } else {
                    $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}];
                    # Skip operator descriptors
                    while ($bm_idesc-- > 0) {
                        $dr_idesc++;
                        $dr_idesc++ while ($desc[$dr_idesc] >= 200000);
                    }
                }
                push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] },
                     $dr_idesc, $idesc;
                if ($Show_all_operators) {
                    push @desc_exp, $id;
                    foreach my $isub (1..$nsubsets) {
                        push @{$subset_data[$isub]}, '';
                    }
                }
                $desc[$idesc] = $desc[$dr_idesc];
                redo D_LOOP;
            } elsif ($flow eq 'signify_character') {
                push @desc_exp, $id;
                $pos = $self->_extract_compressed_value($id, $idesc, $pos, $bitstream,
                                                $nsubsets, \@subset_data);
                next D_LOOP;
            } elsif ($flow eq 'no_value') {
                # Some operator descriptors ought to be included
                # in expanded descriptors even though they have no
                # corresponding data value, because they contain
                # valuable information to be displayed in
                # dumpsection4 (e.g. 222000 'Quality information follows')
                push @desc_exp, $id;
                foreach my $isub (1..$nsubsets) {
                    push @{$subset_data[$isub]}, '';
                }
                next D_LOOP;
            }

            if ($Show_all_operators) {
                push @desc_exp, $id;
                foreach my $isub (1..$nsubsets) {
                    push @{$subset_data[$isub]}, '';
                }
            } else {
                # Remove operator descriptor from @desc
                splice @desc, $idesc--, 1;
            }

            next D_LOOP if $flow eq 'next';
            last D_LOOP if $flow eq 'last';
            if ($flow eq 'skip') {
                $idesc++;
                next D_LOOP;
            }
        }

        if ($self->{CHANGE_REFERENCE_VALUE}) {
            # The data descriptor is to be associated with a new
            # reference value, which is fetched from data stream
            _croak "Change reference operator 203Y is not followed by element"
                . " descriptor, but $id" if $f > 0;
            my $num_bits = $self->{CHANGE_REFERENCE_VALUE};
            my $new_refval = bitstream2dec($bitstream, $pos, $num_bits);
            $pos += $num_bits + 6;
            # Negative value if most significant bit is set (one's complement)
            $new_refval = $new_refval & (1<<$num_bits-1)
                ? -($new_refval & ((1<<$num_bits-1)-1))
                    : $new_refval;
            $self->_spew(4, "$id * Change reference value: ".
                         ($new_refval > 0 ? "+" : "")."$new_refval") if $Spew;
            $self->{NEW_REFVAL_OF}{$id} = $new_refval;
            # Identify new reference values by setting f=9
            push @desc_exp, $id + 900000;
            foreach my $isub (1..$nsubsets) {
                push @{$subset_data[$isub]}, $new_refval;
            }
            next D_LOOP;
        }

        # If operator 204$y 'Add associated field is in effect',
        # each data value is preceded by $y bits which should be
        # decoded separately. We choose to provide a descriptor
        # 999999 in this case (like the ECMWF BUFRDC software)
        if ($self->{ADD_ASSOCIATED_FIELD} and $id ne '031021') {
            # First extract associated field
            push @desc_exp, 999999;
            $pos = $self->_extract_compressed_value(999999, $idesc, $pos, $bitstream,
                                                    $nsubsets, \@subset_data);
        }

        # We now have a "real" data descriptor, so add it to the descriptor list
        push @desc_exp, $id;

        $pos = $self->_extract_compressed_value($id, $idesc, $pos, $bitstream,
                                                $nsubsets, \@subset_data, \@desc);
        if ($repeat_X) {
            # Delayed repetition factor (030011/030012) is in
            # effect, so descriptors and data are to be repeated
            push @repeat_desc, $id;
            foreach my $isub (1..$nsubsets) {
                push @{$repeat_data[$isub]}, $subset_data[$isub]->[-1];
            }
            if (--$repeat_X == 0) {
                # Store $repeat_factor repetitions of data and descriptors
                # (one repetition has already been included)
                while (--$repeat_factor) {
                    push @desc_exp, @repeat_desc;
                    foreach my $isub (1..$nsubsets) {
                        push @{$subset_data[$isub]}, @{$repeat_data[$isub]};
                    }
                    $idesc += $repeat_XX;
                }
                @repeat_desc = ();
                @repeat_data = ();
                $repeat_XX = 0;
            }
        }
    }

    # Check that length of section 4 corresponds to what expected from section 3
    $self->_check_section4_length($pos,$maxpos);

    $self->{DATA} = \@subset_data;
    $self->{DESC} = \@desc_exp;
    return;
}

## Extract the data values for descriptor $id (with index $idesc in
## the final expanded descriptor array) for each subset, into
## $subset_data_ref->[$isub], $isub = 1...$nsubsets (number of
## subsets). Extraction starts at position $pos in $bitstream.
sub _extract_compressed_value {
    my $self = shift;
    my ($id, $idesc, $pos, $bitstream, $nsubsets, $subset_data_ref, $desc_ref) = @_;
    my $B_table = $self->{B_TABLE};

    # For quality information, if this relates to a bit map we
    # need to store index of the data ($data_idesc) for which
    # the quality information applies, as well as the new
    # index ($idesc) in the descriptor array for the bit
    # mapped values
    if (substr($id,0,3) eq '033'
        && defined $self->{BITMAP_OPERATORS}
        && $self->{BITMAP_OPERATORS}->[-1] eq '222000') {
        if (defined $self->{REUSE_BITMAP}) {
            my $data_idesc = shift @{ $self->{REUSE_BITMAP}->[0] };
            _croak "$id: Not enough quality values provided"
                if not defined $data_idesc;
            push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] },
                 $data_idesc, $idesc;
        } else {
            my $data_idesc = shift @{ $self->{CURRENT_BITMAP} };
            _croak "$id: Not enough quality values provided"
                if not defined $data_idesc;
            push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] },
                 $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                     + $data_idesc, $idesc;
        }
    }

    # Find the relevant entry in BUFR table B
    my ($name,$unit,$scale,$refval,$width);
    if ($id == 999999) {
        $name = 'ASSOCIATED FIELD';
        $unit = 'NUMERIC';
        $scale = 0;
        $refval = 0;
        $width = $self->{ADD_ASSOCIATED_FIELD};
    } elsif ($id =~ /^205(\d\d\d)/) { # Signify character
        $name = 'CHARACTER INFORMATION';
        $unit = 'CCITTIA5';
        $scale = 0;
        $refval = 0;
        $width = 8*$1;
    } else {
        _croak "Data descriptor $id is not present in BUFR table B"
            if not exists $B_table->{$id};
        ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$id};

        # Override Table B values if Data Description Operators are in effect
        if ($self->{NUM_CHANGE_OPERATORS} > 0) {
            if ($unit ne 'CCITTIA5' && $unit !~ /^(CODE|FLAG)/) {
                if (defined $self->{CHANGE_SRW}) {
                    $scale += $self->{CHANGE_SRW};
                    $width += int((10*$self->{CHANGE_SRW}+2)/3);
                    $refval *= 10*$self->{CHANGE_SRW};
                } else {
                    $scale += $self->{CHANGE_SCALE} if defined $self->{CHANGE_SCALE};
                    $width += $self->{CHANGE_WIDTH} if defined $self->{CHANGE_WIDTH};
                }
            } elsif ($unit eq 'CCITTIA5' && defined $self->{CHANGE_CCITTIA5_WIDTH}) {
                $width = $self->{CHANGE_CCITTIA5_WIDTH}
            }
            $refval = $self->{NEW_REFVAL_OF}{$id} if defined $self->{NEW_REFVAL_OF}{$id};
            # Difference statistical values use different width and reference value
            if ($self->{DIFFERENCE_STATISTICAL_VALUE}) {
                $width += 1;
                $refval = -2**$width;
                undef $self->{DIFFERENCE_STATISTICAL_VALUE};
                $self->{NUM_CHANGE_OPERATORS}--;
            }
        }
    }
    $self->_spew(3, "%6s  %-20s   %s", $id, $unit, $name) if $Spew;
    _croak "$id Data width <= 0" if $width <= 0;

    if ($unit eq 'CCITTIA5') {
        # Extract ASCII string ('minimum value')
        _croak "Width for unit CCITTIA5 must be integer bytes\n"
            . "is $width bits for descriptor $id" if $width % 8;
        my $minval = bitstream2ascii($bitstream, $pos, $width/8);
        if ($Spew) {
            if ($minval eq "\0" x ($width/8)) {
                $self->_spew(5, " Local reference value has all bits zero");
            } else {
                $self->_spew(5, " Local reference value: %s", $minval);
            }
        }
        $pos += $width;
        # Extract number of bytes for next subsets
        my $deltabytes = bitstream2dec($bitstream, $pos, 6);
        $self->_spew(5, " Increment width (bytes): %d", $deltabytes) if $Spew;
        $pos += 6;
        if ($deltabytes && defined $minval) {
            # Extract compressed data for all subsets. According
            # to 94.6.3 (2) (i) in FM 94 BUFR, the first value for
            # character data shall be set to all bits zero
            my $nbytes = $width/8;
            _complain("Local reference value for compressed CCITTIA5 data "
                      . "hasn't all bits set to zero, but is '$minval'")
                if $Strict_checking and $minval ne "\0" x $nbytes;
            my $incr_values;
            foreach my $isub (1..$nsubsets) {
                my $string = bitstream2ascii($bitstream, $pos, $deltabytes);
                if ($Spew) {
                    $incr_values .= defined $string ? "$string," : ',';
                }
                # Trim string, also removing nulls
                $string = _trim($string, $id);
                push @{$subset_data_ref->[$isub]}, $string;
                $pos += 8*$deltabytes;
            }
            if ($Spew) {
                chop $incr_values;
                $self->_spew(5, " Increment values: %s", $incr_values);
            }
        } else {
            # If min value is defined => All subsets set to min value
            # If min value is undefined => Data in all subsets are undefined
            my $value = defined $minval ? $minval : undef;
            # Trim string, also removing nulls
            $value = _trim($value, $id);
            foreach my $isub (1..$nsubsets) {
                push @{$subset_data_ref->[$isub]}, $value;
            }
            $pos += $nsubsets*8*$deltabytes;
        }
        $self->_spew(3, "  %s", join ',',
             map { defined($subset_data_ref->[$_][-1]) ?
                 $subset_data_ref->[$_][-1] : 'missing'} 1..$nsubsets) if $Spew;
    } else {
        # Extract minimum value
        my $minval = bitstream2dec($bitstream, $pos, $width);
        $minval += $refval if defined $minval;
        $pos += $width;
        $self->_spew(5, " Local reference value: %d", $minval) if $Spew && defined $minval;

        # Extract number of bits for next subsets
        my $deltabits = bitstream2dec($bitstream, $pos, 6);
        $pos += 6;
        $self->_spew(5, " Increment width (bits): %d", $deltabits) if $Spew;

        if ($deltabits && defined $minval) {
            # Extract compressed data for all subsets
            my $incr_values;
            foreach my $isub (1..$nsubsets) {
                my $value = bitstream2dec($bitstream, $pos, $deltabits);
                _complain("value " . ($value + $minval) . " in subset $isub for "
                          . "$id too big to be encoded without compression")
                    if ($Strict_checking && defined $value &&
                        ($value + $minval) > 2**$width);
                $incr_values .= defined $value ? "$value," : ',' if $Spew;
                if (defined $value) {
                    # Compute and format decoded value
                    ($scale) = $scale =~ /(-?\d+)/; # untaint
                    $value = $scale <= 0 ? ($value + $minval)/10**$scale
                        : sprintf "%.${scale}f", ($value + $minval)/10**$scale;
                }
                # All bits set to 1 for associated field is NOT
                # interpreted as missing value
                if ($id == 999999 and ! defined $value) {
                    $value = 2**$width - 1;
                }
                push @{$subset_data_ref->[$isub]}, $value;
                $pos += $deltabits;
            }
            if ($Spew) {
                chop $incr_values;
                $self->_spew(5, " Increment values: %s", $incr_values);
            }
        } else {
            # If minimum value is defined => All subsets set to minimum value
            # If minimum value is undefined => Data in all subsets are undefined
            my $value;
            if (defined $minval) {
                # Compute and format decoded value
                ($scale) = $scale =~ /(-?\d+)/; # untaint
                $value = $scale <= 0 ? $minval/10**$scale
                    : sprintf "%.${scale}f", $minval/10**$scale;
            }
            # Exception: all bits set to 1 for associated field is NOT
            # interpreted as missing value
            if ($id == 999999 and ! defined $value) {
                $value = 2**$width - 1;
            }
            foreach my $isub (1..$nsubsets) {
                push @{$subset_data_ref->[$isub]}, $value;
            }
            $pos += $nsubsets*$deltabits if defined $deltabits;
        }

        # Bit maps need special treatment. We are only able to
        # handle those where all subsets have exactly the same
        # bit map with the present method.
        if ($id eq '031031' and $self->{BUILD_BITMAP}) {
            _croak "$id: Unable to handle bit maps which differ between subsets"
                . " in compressed data" if $deltabits;
            # Store the index of expanded descriptors if data is
            # marked as present in data present indicator: 0 is
            # 'present', 1 (undef value) is 'not present'
            if (defined $minval) {
                push @{$self->{CURRENT_BITMAP}}, $self->{BITMAP_INDEX};
            }
            $self->{BITMAP_INDEX}++;
            if ($self->{BACKWARD_DATA_REFERENCE} == $self->{NUM_BITMAPS}) {
                my $numb = $self->{NUM_BITMAPS};
                if (!defined $self->{BITMAP_START}[$numb]) {
                    # Look up the element descriptor immediately
                    # preceding the bitmap operator
                    my $i = $idesc;
                    $i-- while ($desc_ref->[$i] ne $self->{BITMAP_OPERATORS}->[-1]
                                && $i >=0);
                    $i-- while ($desc_ref->[$i] > 100000 && $i >=0);
                    _croak "No element descriptor preceding bitmap" if $i < 0;
                    $self->{BITMAP_START}[$numb] = $i;
                } else {
                    if ($Show_all_operators) {
                        my $i = $self->{BITMAP_START}[$numb] - 1;
                        $i-- while ($desc_ref->[$i] > 100000 && $i >=0);
                        $self->{BITMAP_START}[$numb] = $i;
                    } else {
                        $self->{BITMAP_START}[$numb]--;
                    }
                    _croak "Bitmap too big"
                        if $self->{BITMAP_START}[$numb] < 0;
                }
            }
        } elsif ($self->{BUILD_BITMAP} and $self->{BITMAP_INDEX} > 0) {
            # We have finished building the bit map
            $self->{BUILD_BITMAP} = 0;
            $self->{BITMAP_INDEX} = 0;
            if ($self->{BACKWARD_DATA_REFERENCE} != $self->{NUM_BITMAPS}) {
                $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                    = $self->{BITMAP_START}[$self->{BACKWARD_DATA_REFERENCE}];
            }
        }
        $self->_spew(3, "  %s", join ' ',
             map { defined($subset_data_ref->[$_][-1]) ?
                 $subset_data_ref->[$_][-1] : 'missing'} 1..$nsubsets) if $Spew;
    }
    return $pos;
}

## Takes a text $decoded_message as argument and returns BUFR messages
## which would give the same output as $decoded_message when running
## dumpsection0(), dumpsection1(), dumpsection3() and dumpsection4() in
## turn on each of the reencoded BUFR messages
sub reencode_message {
    my $self = shift;
    my $decoded_message = shift;
    my $width = shift || 15;    # Optional argument
    # Data values usually start at column 31, but if a $width
    # different from 15 was used in dumpsection4 you should use the
    # same value here

    my @lines = split /\n/, $decoded_message;
    my $bufr_messages = '';
    my $i = 0;

  MESSAGE: while ($i < @lines) {
        # Some tidying after decoding of previous message might be
        # necessary
        $self->{NUM_CHANGE_OPERATORS} = 0;
        undef $self->{CHANGE_WIDTH};
        undef $self->{CHANGE_CCITTIA5_WIDTH};
        undef $self->{CHANGE_SCALE};
        undef $self->{CHANGE_REFERENCE_VALUE};
        undef $self->{NEW_REFVAL_OF};
        undef $self->{CHANGE_SRW};
        undef $self->{ADD_ASSOCIATED_FIELD};
        undef $self->{BITMAPS};
        undef $self->{BITMAP_OPERATORS};
        undef $self->{REUSE_BITMAP};
        $self->{NUM_BITMAPS} = 0;
        # $self->{LOCAL_USE} is always set for BUFR edition < 4 in _encode_sec1
        undef $self->{LOCAL_USE};

        # Extract section 0 info
        $i++ while $lines[$i] !~ /^Section 0/ and $i < @lines-1;
        last MESSAGE if $i >= @lines-1; # Not containing any decoded BUFR message
        $i++; # Skip length of BUFR message
        ($self->{BUFR_EDITION}) = $lines[++$i]
            =~ /BUFR edition:\s+(\d+)/;
        _croak "BUFR edition number not provided or is not a number"
            unless defined $self->{BUFR_EDITION};

        # Extract section 1 info
        $i++ while $lines[$i] !~ /^Section 1/;
        _croak "reencode_message: Don't find decoded section 1" if $i >= @lines;
        $i++; # Skip length of section 1
        if ($self->{BUFR_EDITION} < 4 ) {
            ($self->{MASTER_TABLE}) = $lines[++$i]
                =~ /BUFR master table:\s+(\d+)/;
            ($self->{SUBCENTRE}) = $lines[++$i]
                =~ /Originating subcentre:\s+(\d+)/;
            ($self->{CENTRE}) = $lines[++$i]
                =~ /Originating centre:\s+(\d+)/;
            ($self->{UPDATE_NUMBER}) = $lines[++$i]
                =~ /Update sequence number:\s+(\d+)/;
            ($self->{OPTIONAL_SECTION}) = $lines[++$i]
                =~ /Optional section present:\s+(\d+)/;
            ($self->{DATA_CATEGORY}) = $lines[++$i]
                =~ /Data category \(table A\):\s+(\d+)/;
            ($self->{DATA_SUBCATEGORY}) = $lines[++$i]
                =~ /Data subcategory:\s+(\d+)/;
            ($self->{MASTER_TABLE_VERSION}) = $lines[++$i]
                =~ /Master table version number:\s+(\d+)/;
            ($self->{LOCAL_TABLE_VERSION}) = $lines[++$i]
                =~ /Local table version number:\s+(\d+)/;
            ($self->{YEAR_OF_CENTURY}) = $lines[++$i]
                =~ /Year of century:\s+(\d+)/;
            ($self->{MONTH}) = $lines[++$i]
                =~ /Month:\s+(\d+)/;
            ($self->{DAY}) = $lines[++$i]
                =~ /Day:\s+(\d+)/;
            ($self->{HOUR}) = $lines[++$i]
                =~ /Hour:\s+(\d+)/;
            ($self->{MINUTE}) = $lines[++$i]
                =~ /Minute:\s+(\d+)/;
            _croak "reencode_message: Something seriously wrong in decoded section 1"
                unless defined $self->{MINUTE};
        } elsif ($self->{BUFR_EDITION} == 4) {
            ($self->{MASTER_TABLE}) = $lines[++$i]
                =~ /BUFR master table:\s+(\d+)/;
            ($self->{CENTRE}) = $lines[++$i]
                =~ /Originating centre:\s+(\d+)/;
            ($self->{SUBCENTRE}) = $lines[++$i]
                =~ /Originating subcentre:\s+(\d+)/;
            ($self->{UPDATE_NUMBER}) = $lines[++$i]
                =~ /Update sequence number:\s+(\d+)/;
            ($self->{OPTIONAL_SECTION}) = $lines[++$i]
                =~ /Optional section present:\s+(\d+)/;
            ($self->{DATA_CATEGORY}) = $lines[++$i]
                =~ /Data category \(table A\):\s+(\d+)/;
            ($self->{INT_DATA_SUBCATEGORY}) = $lines[++$i]
                =~ /International data subcategory:\s+(\d+)/;
            ($self->{LOC_DATA_SUBCATEGORY}) = $lines[++$i]
                =~ /Local data subcategory:\s+(\d+)/;
            ($self->{MASTER_TABLE_VERSION}) = $lines[++$i]
                =~ /Master table version number:\s+(\d+)/;
            ($self->{LOCAL_TABLE_VERSION}) = $lines[++$i]
                =~ /Local table version number:\s+(\d+)/;
            ($self->{YEAR}) = $lines[++$i]
                =~ /Year:\s+(\d+)/;
            ($self->{MONTH}) = $lines[++$i]
                =~ /Month:\s+(\d+)/;
            ($self->{DAY}) = $lines[++$i]
                =~ /Day:\s+(\d+)/;
            ($self->{HOUR}) = $lines[++$i]
                =~ /Hour:\s+(\d+)/;
            ($self->{MINUTE}) = $lines[++$i]
                =~ /Minute:\s+(\d+)/;
            ($self->{SECOND}) = $lines[++$i]
                =~ /Second:\s+(\d+)/;
            _croak "reencode_message: Something seriously wrong in decoded section 1"
                unless defined $self->{SECOND};
        }

        # Extract section 3 info
        $i++ while $lines[$i] !~ /^Section 3/;
        _croak "reencode_message: Don't find decoded section 3" if $i >= @lines;
        $i++; # Skip length of section 3

        ($self->{NUM_SUBSETS}) = $lines[++$i]
            =~ /Number of data subsets:\s+(\d+)/;
        _croak "Don't support reencoding of 0 subset message"
            if $self->{NUM_SUBSETS} == 0;
        ($self->{OBSERVED_DATA}) = $lines[++$i]
            =~ /Observed data:\s+(\d+)/;
        ($self->{COMPRESSED_DATA}) = $lines[++$i]
            =~ /Compressed data:\s+(\d+)/;
        ($self->{DESCRIPTORS_UNEXPANDED}) = $lines[++$i]
            =~ /Data descriptors unexpanded:\s+(\d+.*)/;
        _croak "reencode_message: Something seriously wrong in decoded section 3"
            unless defined $self->{DESCRIPTORS_UNEXPANDED};

        # Extract data values to use in section 4
        my ($data_refs, $desc_refs);
        my $subset = 0;
      SUBSET: while ($i < @lines-1) {
            $_ = $lines[++$i];
            next SUBSET if /^$/ or /^Subset/;
            last SUBSET if /^Message/;
            $_ = substr $_, 0, $width + 16;
            s/^\s+//;
            next SUBSET if not /^\d/;
            my ($n, $desc, $value) = split /\s+/, $_, 3;
            $subset++ if $n == 1;
            if (defined $value) {
                $value =~ s/\s+$//;
                $value = undef if $value eq '' or $value eq 'missing';
            } else {
                # Some descriptors are not numbered (like 222000)
                $desc = $n;
                $value = '';
            }
            push @{$data_refs->[$subset]}, $value;
            push @{$desc_refs->[$subset]}, $desc;
        }

        # If optional section is present, pretend it is not, because we
        # are not able to encode this section
        if ($self->{OPTIONAL_SECTION}) {
            $self->{OPTIONAL_SECTION} = 0;
            carp "Warning: 'Optional section present' changed from 1 to 0'\n";
        }

        $bufr_messages .= $self->encode_message($data_refs, $desc_refs);
    }

    return $bufr_messages;
}


## Encode a new BUFR message. All relevant metadata
## ($self->{BUFR_EDITION} etc) must have been initialized already or
## else the _encode_sec routines will croak.
sub encode_message {
    my $self = shift;
    my ($data_refs, $desc_refs) = @_;

    _croak "encode_message: No data/descriptors provided" unless $desc_refs;

    $self->{MESSAGE_NUMBER}++;
    $self->_spew(2, "Encoding message number %d", $self->{MESSAGE_NUMBER}) if $Spew;

    $self->load_BDtables();

    $self->_spew(2, "Encoding section 1-3") if $Spew;
    my $sec1_stream = $self->_encode_sec1();
    my $sec2_stream = $self->_encode_sec2();
    my $sec3_stream = $self->_encode_sec3();
    $self->_spew(2, "Encoding section 4") if $Spew;
    my $sec4_stream = $self->_encode_sec4($data_refs, $desc_refs);

    # Compute length of whole message and encode section 0
    my $msg_len = 8 + length($sec1_stream) + length($sec2_stream)
        + length($sec3_stream) + length($sec4_stream) + 4;
    my $msg_len_binary = pack("N", $msg_len);
    my $bufr_edition_binary = pack('n', $self->{BUFR_EDITION});
    my $sec0_stream = 'BUFR' . substr($msg_len_binary,1,3)
                             . substr($bufr_edition_binary,1,1);

    my $new_message = $sec0_stream . $sec1_stream . $sec2_stream
        . $sec3_stream  . $sec4_stream  . '7777';
    return $new_message;
}

## Encode and return section 1
sub _encode_sec1 {
    my $self = shift;

    my $bufr_edition = $self->{BUFR_EDITION} or
        _croak "_encode_sec1: BUFR edition not defined";

    my @keys = qw( MASTER_TABLE  CENTRE  SUBCENTRE  UPDATE_NUMBER
                   OPTIONAL_SECTION  DATA_CATEGORY  MASTER_TABLE_VERSION
                   LOCAL_TABLE_VERSION  MONTH  DAY  HOUR  MINUTE );
    if ($bufr_edition < 4) {
        push @keys, qw( DATA_SUBCATEGORY  YEAR_OF_CENTURY );
    } elsif ($bufr_edition == 4) {
        push @keys, qw( INT_DATA_SUBCATEGORY  LOC_DATA_SUBCATEGORY  YEAR  SECOND );
    }

    # Check that the required variables for section 1 are provided
    foreach my $key (@keys) {
        _croak "_encode_sec1: $key not given"
            unless defined $self->{$key};
    }

    $self->_validate_datetime() if ($Strict_checking);

    my $sec1_stream;
    # Byte 4-
    if ($bufr_edition < 4) {
        $self->{LOCAL_USE} = "\0" if !defined $self->{LOCAL_USE};
        $sec1_stream = pack 'C14a*',
            $self->{MASTER_TABLE},
            $self->{SUBCENTRE},
            $self->{CENTRE},
            $self->{UPDATE_NUMBER},
            $self->{OPTIONAL_SECTION} ? 128 : 0,
            $self->{DATA_CATEGORY},
            $self->{DATA_SUBCATEGORY},
            $self->{MASTER_TABLE_VERSION},
            $self->{LOCAL_TABLE_VERSION},
            $self->{YEAR_OF_CENTURY},
            $self->{MONTH},
            $self->{DAY},
            $self->{HOUR},
            $self->{MINUTE},
            $self->{LOCAL_USE};
    } elsif ($bufr_edition == 4) {
        $sec1_stream = pack 'CnnC7nC5',
            $self->{MASTER_TABLE},
            $self->{CENTRE},
            $self->{SUBCENTRE},
            $self->{UPDATE_NUMBER},
            $self->{OPTIONAL_SECTION} ? 128 : 0,
            $self->{DATA_CATEGORY},
            $self->{INT_DATA_SUBCATEGORY},
            $self->{LOC_DATA_SUBCATEGORY},
            $self->{MASTER_TABLE_VERSION},
            $self->{LOCAL_TABLE_VERSION},
            $self->{YEAR},
            $self->{MONTH},
            $self->{DAY},
            $self->{HOUR},
            $self->{MINUTE},
            $self->{SECOND};
        $sec1_stream .= pack 'a*', $self->{LOCAL_USE}
            if defined $self->{LOCAL_USE};
    }

    my $sec1_len = 3 + length $sec1_stream;
    if ($bufr_edition < 4) {
        # Each section should be an even number of octets
        if ($sec1_len % 2) {
            $sec1_stream .= "\0";
            $sec1_len++;
        }
    }

    # Byte 1-3
    my $sec1_len_binary = substr pack("N", $sec1_len), 1, 3;

    return $sec1_len_binary . $sec1_stream;
}

## Encode and return section 2 (empty string if no optional section)
sub _encode_sec2 {
    my $self = shift;
    if ($self->{OPTIONAL_SECTION}) {
        _croak "_encode_sec2: No optional section provided"
            unless defined  $self->{SEC2_STREAM};
        return $self->{SEC2_STREAM};
    } else {
        return '';
    }
}

## Encode and return section 3
sub _encode_sec3 {
    my $self = shift;

    # Check that the required variables for section 3 are provided
    foreach my $key (qw(NUM_SUBSETS OBSERVED_DATA COMPRESSED_DATA
                        DESCRIPTORS_UNEXPANDED)) {
        _croak "_encode_sec3: $key not given"
            unless defined $self->{$key};
    }

    my @desc = split / /, $self->{DESCRIPTORS_UNEXPANDED};

    # Byte 5-6
    my $nsubsets_binary = pack "n", $self->{NUM_SUBSETS};

    # Byte 7
    my $flag = pack 'C', $self->{OBSERVED_DATA}*128 +
                         $self->{COMPRESSED_DATA}*64;

    # Byte 8-
    my $desc_binary = "\0\0" x @desc;
    my $pos = 0;
    foreach my $desc (@desc) {
        my $f = substr($desc,0,1);
        my $x = substr($desc,1,2)+0;
        my $y = substr($desc,3,3)+0;
        dec2bitstream($f, $desc_binary, $pos, 2);
        $pos += 2;
        dec2bitstream($x, $desc_binary, $pos, 6);
        $pos += 6;
        dec2bitstream($y, $desc_binary, $pos, 8);
        $pos += 8;
    }

    my $sec3_len = 7 + length $desc_binary;
    if ($self->{BUFR_EDITION} < 4) {
        # Each section should be an even number of octets
        if ($sec3_len % 2) {
            $desc_binary .= "\0";
            $sec3_len++;
        }
    }

    # Byte 1-4
    my $sec3_len_binary = pack("N", $sec3_len);
    my $sec3_start = substr($sec3_len_binary, 1, 3) . "\0";

    return $sec3_start . $nsubsets_binary . $flag . $desc_binary;
}

## Encode and return section 4
sub _encode_sec4 {
    my $self = shift;
    my ($data_refs, $desc_refs) = @_;

    # Check that dimension of argument arrays agrees with number of
    # subsets in section 3
    my $nsubsets = $self->{NUM_SUBSETS};
    _croak "Wrong number of subsets ($nsubsets) in section 3?\n"
        . "Disagrees with dimension of descriptor array used as argument "
            . "to encode_message()"
                unless @$desc_refs == $nsubsets + 1;

    my ($bitstream, $byte_len) = $self->{COMPRESSED_DATA}
        ? $self->_encode_compressed_bitstream($data_refs, $desc_refs)
            : $self->_encode_bitstream($data_refs, $desc_refs);

    my $sec4_len = $byte_len + 4;
    my $sec4_len_binary = pack("N", $sec4_len);
    my $sec4_stream = substr($sec4_len_binary, 1, 3) . "\0" . $bitstream;

    return $sec4_stream;
}

## Encode a nil message, i.e. all values set to missing except delayed
## replication factors and the (descriptor, value) pairs in the hash
## ref $stationid_ref. Delayed replication factors will all be set to
## 1 unless $delayed_repl_ref is provided, in which case the
## descriptors 031001 and 031002 will get the values contained in
## @$delayed_repl_ref. Note that data in section 1 and 3 must have
## been set before calling this method.
sub encode_nil_message {
    my $self = shift;
    my ($stationid_ref, $delayed_repl_ref) = @_;

    _croak "encode_nil_message: No station descriptors provided"
        unless $stationid_ref;

    my $bufr_edition = $self->{BUFR_EDITION} or
        _croak "encode_nil_message: BUFR edition not defined";

    # Since a nil message necessarily is a one subset message, some
    # metadata might need to be adjusted (saving the user for having
    # to remember this)
    $self->set_number_of_subsets(1);
    $self->set_compressed_data(0);

    $self->load_BDtables();

    $self->_spew(2, "Encoding NIL message") if $Spew;
    my $sec1_stream = $self->_encode_sec1();
    my $sec3_stream = $self->_encode_sec3();
    my $sec4_stream = $self->_encode_nil_sec4($stationid_ref,
                                              $delayed_repl_ref);

    # Compute length of whole message and encode section 0
    my $msg_len = 8 + length($sec1_stream) + length($sec3_stream)
        + length($sec4_stream) + 4;
    my $msg_len_binary = pack("N", $msg_len);
    my $bufr_edition_binary = pack('n', $bufr_edition);
    my $sec0_stream = 'BUFR' . substr($msg_len_binary,1,3)
                             . substr($bufr_edition_binary,1,1);

    my $new_message = $sec0_stream . $sec1_stream . $sec3_stream . $sec4_stream
        . '7777';
    return $new_message;
}

## Encode and return section 4 with all values set to missing except
## delayed replication factors and the (descriptor, value) pairs in
## the hash ref $stationid_ref. Delayed replication factors will all
## be set to 1 unless $delayed_repl_ref is provided, in which case the
## descriptors 031001 and 031002 will get the values contained in
## @$delayed_repl_ref (in that order).
sub _encode_nil_sec4 {
    my $self = shift;
    $self->{CODING} = 'ENCODE';
    my ($stationid_ref, $delayed_repl_ref) = @_;
    my @delayed_repl = defined $delayed_repl_ref ? @$delayed_repl_ref : ();

    # Get the expanded list of descriptors (i.e. expanded with table D)
    if (not $self->{DESCRIPTORS_EXPANDED}) {
        _croak "_encode_nil_sec4: DESCRIPTORS_UNEXPANDED not given"
            unless $self->{DESCRIPTORS_UNEXPANDED};
        my @unexpanded = split / /, $self->{DESCRIPTORS_UNEXPANDED};
        _croak "_encode_nil_sec4: D_TABLE not given"
            unless $self->{D_TABLE};
        my $alias = "$self->{TABLE_VERSION} " . $self->{DESCRIPTORS_UNEXPANDED};
        if (exists $Descriptors_already_expanded{$alias}) {
            $self->{DESCRIPTORS_EXPANDED} = $Descriptors_already_expanded{$alias};
        } else {
            $Descriptors_already_expanded{$alias} = $self->{DESCRIPTORS_EXPANDED}
                = join " ", _expand_descriptors($self->{D_TABLE}, @unexpanded);
        }
    }

    # The rest is very similar to sub _decode_bitstream, except that we
    # now are encoding, not decoding a bitstream, with most values set
    # to missing value, and we do not need to fully expand the
    # descriptors.
    my $B_table = $self->{B_TABLE};
    my @operators;
    my $bitstream = chr(255) x 65536; # one bits only
    my $pos = 0;

    my @desc = split /\s/, $self->{DESCRIPTORS_EXPANDED};
  D_LOOP: for (my $idesc = 0; $idesc < @desc; $idesc++) {

        my $id = $desc[$idesc];
        my $f = substr($id,0,1);
        my $x = substr($id,1,2)+0;
        my $y = substr($id,3,3)+0;

        if ($f == 1) {
            # Delayed replication
            if ($x == 0) {
                _complain("Nonsensical replication of zero descriptors ($id)");
                $idesc++;
                next D_LOOP;
            }
            _croak "$id _expand_descriptors() did not do its job"
                if $y > 0;

            $_ = $desc[$idesc+1];
            _croak "$id Erroneous replication factor"
                unless /^0310(00|01|02|11|12)/ && exists $B_table->{$_};
            my $factor = 1;
            if (@delayed_repl && /^03100(1|2)/) {
                $factor = shift @delayed_repl;
                _croak "Delayed replication factor must be positive integer in "
                    . "encode_nil_message, is '$factor'"
                        if ($factor !~ /^\d+$/ || $factor == 0);
            }
            my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$_};
            if ($Spew) {
                $self->_spew(3, "%6s  %-20s   %s", $id, $unit, $name);
                $self->_spew(3, "  %s", $factor);
            }
            dec2bitstream($factor, $bitstream, $pos, $width);
            $pos += $width;
            # Include the delayed replication in descriptor list
            splice @desc, $idesc++, 0, $_;

            my @r = ();
            push @r, @desc[($idesc+2)..($idesc+$x+1)] while $factor--;
            $self->_spew(4, "Delayed replication ($id $_ -> @r)") if $Spew;
            splice @desc, $idesc, 2+$x, @r;

            if ($idesc < @desc) {
                redo D_LOOP;
            } else {
                last D_LOOP; # Might happen if delayed factor is 0
            }

        } elsif ($f == 2) {
            my $next_id = $desc[$idesc+1];
            my $flow;
            my $bm_idesc;
            ($pos, $flow, $bm_idesc, @operators)
                = $self->_apply_operator_descriptor($id, $x, $y, $pos, 0,
                                                    $next_id, @operators);
            next D_LOOP if $flow eq 'next';
        }

        # We now have a "real" data descriptor

        # Find the relevant entry in BUFR table B
        _croak "Data descriptor $id is not present in BUFR table B"
            unless exists $B_table->{$id};
        my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$id};
        $self->_spew(3, "%6s  %-20s   %s", $id, $unit, $name) if $Spew;

        # Override Table B values if Data Description Operators are in effect
        if ($self->{NUM_CHANGE_OPERATORS} > 0) {
            if ($unit ne 'CCITTIA5' && $unit !~ /^(CODE|FLAG)/) {
                if (defined $self->{CHANGE_SRW}) {
                    $scale += $self->{CHANGE_SRW};
                    $width += int((10*$self->{CHANGE_SRW}+2)/3);
                    $refval *= 10*$self->{CHANGE_SRW};
                } else {
                    $scale += $self->{CHANGE_SCALE} if defined $self->{CHANGE_SCALE};
                    $width += $self->{CHANGE_WIDTH} if defined $self->{CHANGE_WIDTH};
                }
            } elsif ($unit eq 'CCITTIA5' && defined $self->{CHANGE_CCITTIA5_WIDTH}) {
                $width = $self->{CHANGE_CCITTIA5_WIDTH}
            }
            $refval = $self->{NEW_REFVAL_OF}{$id} if defined $self->{NEW_REFVAL_OF}{$id};
        }
        _croak "$id Data width <= 0" if $width <= 0;

        if ($stationid_ref->{$id}) {
            my $value = $stationid_ref->{$id};
            $self->_spew(3, "  %s", $value) if $Spew;
            if ($unit eq 'CCITTIA5') {
                # Encode ASCII string in $width bits (left justified,
                # padded with spaces)
                my $num_bytes = int($width/8);
                _croak "Ascii string too long to fit in $width bits: $value"
                    if length($value) > $num_bytes;
                $value .= ' ' x ($num_bytes - length($value));
                ascii2bitstream($value, $bitstream, $pos, $num_bytes);
            } else {
                # Encode value as integer in $width bits
                $value = int($value * 10**$scale - $refval + 0.5);
                _croak "Data value no $id is negative: $value"
                    if $value < 0;
                dec2bitstream($value, $bitstream, $pos, $width);
            }
        } else {
            # Missing value is encoded as 1 bits
        }
        $pos += $width;
    }

    # Pad with 0 bits if necessary to get an even or integer number of
    # octets, depending on bufr edition
    my $padnum = $self->{BUFR_EDITION} < 4 ? (16-($pos%16)) % 16 : (8-($pos%8)) % 8;
    if ($padnum > 0) {
        null2bitstream($bitstream, $pos, $padnum);
    }
    my $len = ($pos + $padnum)/8;
    $bitstream = substr $bitstream, 0, $len;

    # Encode section 4
    my $sec4_len_binary = pack("N", $len + 4);
    my $sec4_stream = substr($sec4_len_binary, 1, 3) . "\0" . $bitstream;

    return $sec4_stream;
}

## Encode bitstream using the data values in $data_refs, first
## expanding section 3 fully (and comparing with $desc_refs to check
## for consistency). This sub is very similar to sub _decode_bitstream
sub _encode_bitstream {
    my $self = shift;
    $self->{CODING} = 'ENCODE';
    my ($data_refs, $desc_refs) = @_;

    # Expand section 3 except for delayed replication and operator descriptors
    my @unexpanded = split / /, $self->{DESCRIPTORS_UNEXPANDED};
    my $alias = "$self->{TABLE_VERSION} " . $self->{DESCRIPTORS_UNEXPANDED};
    if (exists $Descriptors_already_expanded{$alias}) {
        $self->{DESCRIPTORS_EXPANDED} = $Descriptors_already_expanded{$alias};
    } else {
        $Descriptors_already_expanded{$alias} = $self->{DESCRIPTORS_EXPANDED}
            = join " ", _expand_descriptors($self->{D_TABLE}, @unexpanded);
    }

    my $nsubsets = $self->{NUM_SUBSETS};
    my $B_table = $self->{B_TABLE};
    my $maxlen = 1024;
    my $bitstream = chr(255) x $maxlen; # one bits only
    my $pos = 0;
    my @operators;

  S_LOOP: foreach my $isub (1..$nsubsets) {
        $self->_spew(2, "Encoding subset number %d", $isub) if $Spew;

        # Bit maps might vary from subset to subset, so must be rebuilt
        undef $self->{BITMAP_OPERATORS};
        undef $self->{BITMAP_START};
        undef $self->{REUSE_BITMAP};
        $self->{NUM_BITMAPS} = 0;
        $self->{BACKWARD_DATA_REFERENCE} = 1;
        $self->{NUM_CHANGE_OPERATORS} = 0;

        # The data values to use for this subset
        my $data_ref = $data_refs->[$isub];
        # The descriptors from expanding section 3
        my @desc = split /\s/, $self->{DESCRIPTORS_EXPANDED};
        # The descriptors to compare with for this subset
        my $desc_ref = $desc_refs->[$isub];

        # Note: @desc as well as $idesc may be changed during this loop,
        # so we cannot use a foreach loop instead
      D_LOOP: for (my $idesc = 0; $idesc < @desc; $idesc++) {
            my $id = $desc[$idesc]
                || _croak("No descriptor no. $idesc defined. Consider using --strict_checking 2"
                          . " or --verbose 4 to explore what went wrong in the encoding");
            my $f = substr($id,0,1);
            my $x = substr($id,1,2)+0;
            my $y = substr($id,3,3)+0;

            if ($f == 1) {
                # Delayed replication
                if ($x == 0) {
                    _complain("Nonsensical replication of zero descriptors ($id)");
                    $idesc++;
                    next D_LOOP;
                }
                _croak "$id _expand_descriptors() did not do its job"
                    if $y > 0;

                my $next_id = $desc[$idesc+1];
                _croak "$id Erroneous replication factor"
                    unless $next_id =~ /^0310(00|01|02|11|12)/ && exists $B_table->{$next_id};
                _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected $next_id"
                    if $desc_ref->[$idesc] != $next_id;
                my $factor = $data_ref->[$idesc];
                my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$next_id};
                if ($Spew) {
                    $self->_spew(3, "%6s  %-20s  %s", $next_id, $unit, $name);
                    $self->_spew(3, "  %s", $factor);
                }
                ($bitstream, $pos, $maxlen)
                    = $self->_encode_value($factor,$isub,$unit,$scale,$refval,
                                           $width,$next_id,$bitstream,$pos,$maxlen);
                # Include the delayed replication/repetition in descriptor list
                splice @desc, $idesc++, 0, $next_id;

                my @r = ();
                push @r, @desc[($idesc+2)..($idesc+$x+1)] while $factor--;
                splice @desc, $idesc, 2+$x, @r;

                if ($next_id eq '031011' || $next_id eq '031012') {
                    # For delayed repetition we should include data just
                    # once, so skip to the last set in data array
                    $idesc += $x * ($data_ref->[$idesc-1] - 1);
                    # We ought to check that the data sets we skipped are
                    # indeed equal to the last set!
                    $self->_spew(4, "Delayed repetition ($id $next_id -> @r)") if $Spew;
                } else {
                    $self->_spew(4, "Delayed replication ($id $next_id -> @r)") if $Spew;
                }
                if ($idesc < @desc) {
                    redo D_LOOP;
                } else {
                    last D_LOOP; # Might happen if delayed factor is 0
                }

            } elsif ($f == 2) {
                my $flow;
                my $bm_idesc;
                ($pos, $flow, $bm_idesc, @operators)
                    = $self->_apply_operator_descriptor($id, $x, $y, $pos, $isub,
                                                        $desc[$idesc+1], @operators);
                if ($flow eq 'redo_bitmap') {
                    # Data value is associated with the descriptor
                    # defined by bit map. Remember original and new
                    # index in descriptor array for the bit mapped
                    # values ('dr' = data reference)
                    my $dr_idesc;
                    if (!defined $bm_idesc) {
                        $dr_idesc = shift @{ $self->{REUSE_BITMAP}->[$isub]};
                    } elsif (!$Show_all_operators) {
                        $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                            + $bm_idesc;
                    } else {
                        $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}];
                        # Skip operator descriptors
                        while ($bm_idesc-- > 0) {
                            $dr_idesc++;
                            $dr_idesc++ while ($desc[$dr_idesc] >= 200000);
                        }
                    }
                    push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[$isub] },
                         $dr_idesc, $idesc;
                    $desc[$idesc] = $desc[$dr_idesc];
                    redo D_LOOP;
                } elsif ($flow eq 'signify_character') {
                    _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected $id"
                        if $desc_ref->[$idesc] != $id;
                    # Get ASCII string
                    my $value = $data_ref->[$idesc];
                    my $name = 'SIGNIFY CHARACTER';
                    my $unit = 'CCITTIA5';
                    my ($scale, $refval, $width) = (0, 0, 8*$y);
                    ($bitstream, $pos, $maxlen)
                        = $self->_encode_value($value,$isub,$unit,$scale,$refval,$width,"205$y",$bitstream,$pos,$maxlen);
                    next D_LOOP;
                } elsif ($flow eq 'no_value') {
                    next D_LOOP;
                }

                # Remove operator descriptor from @desc
                splice @desc, $idesc--, 1;

                next D_LOOP if $flow eq 'next';
                last D_LOOP if $flow eq 'last';
            }

            if ($self->{CHANGE_REFERENCE_VALUE}) {
                # The data descriptor is to be associated with a new
                # reference value, which is fetched from data stream,
                # possibly with f=9 instead of f=0 for descriptor
                $id -= 900000 if $id =~ /^9/;
                _croak "Change reference operator 203Y is not followed by element"
                    . " descriptor, but $id" if $f > 0;
                my $new_refval = $data_ref->[$idesc];
                $self->{NEW_REFVAL_OF}{$id}{$isub} = $new_refval;
                ($bitstream, $pos, $maxlen)
                    = $self->_encode_reference_value($new_refval,$id,$bitstream,$pos,$maxlen);
                next D_LOOP;
            }

            # If operator 204$y 'Add associated field' is in effect,
            # each data value is preceded by $y bits which should be
            # encoded separately. We choose to provide a descriptor
            # 999999 in this case (like the ECMWF BUFRDC software)
            if ($self->{ADD_ASSOCIATED_FIELD} and $id ne '031021') {
                # First encode associated field
                _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected 999999"
                    if $desc_ref->[$idesc] != 999999;
                my $value = $data_ref->[$idesc];
                my $name = 'ASSOCIATED FIELD';
                my $unit = 'NUMERIC';
                my ($scale, $refval) = (0, 0);
                my $width = $self->{ADD_ASSOCIATED_FIELD};
                $self->_spew(4, "Added associated field: %s", $value) if $Spew;
                ($bitstream, $pos, $maxlen)
                    = $self->_encode_value($value,$isub,$unit,$scale,$refval,$width,999999,$bitstream,$pos,$maxlen);
                # Insert the artificial 999999 descriptor for the
                # associated value and increment $idesc to prepare for
                # handling the 'real' value below
                splice @desc, $idesc++, 0, 999999;
            }



            # For quality information, if this relates to a bit map we
            # need to store index of the data ($data_idesc) for which
            # the quality information applies, as well as the new
            # index ($idesc) in the descriptor array for the bit
            # mapped values
            if (substr($id,0,3) eq '033'
                && defined $self->{BITMAP_OPERATORS}
                && $self->{BITMAP_OPERATORS}->[-1] eq '222000') {
                if (defined $self->{REUSE_BITMAP}) {
                    my $data_idesc = shift @{ $self->{REUSE_BITMAP}->[$isub] };
                    _croak "$id: Not enough quality values provided"
                        if not defined $data_idesc;
                    push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[$isub] },
                         $data_idesc, $idesc;
                } else {
                    my $data_idesc = shift @{ $self->{CURRENT_BITMAP} };
                    _croak "$id: Not enough quality values provided"
                        if not defined $data_idesc;
                    push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[$isub] },
                         $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                             + $data_idesc, $idesc;
                }
            }

            my $value = $data_ref->[$idesc];

            if ($id eq '031031' and $self->{BUILD_BITMAP}) {
                # Store the index of expanded descriptors if data is
                # marked as present in data present indicator: 0 is
                # 'present', 1 (undef value) is 'not present'. E.g.
                # bitmap = 1100110 => (2,3,6) is stored in $self->{CURRENT_BITMAP}
                if (defined $value and $value == 0) {
                    push @{$self->{CURRENT_BITMAP}}, $self->{BITMAP_INDEX};
                }
                $self->{BITMAP_INDEX}++;
                if ($self->{BACKWARD_DATA_REFERENCE} == $self->{NUM_BITMAPS}) {
                    my $numb = $self->{NUM_BITMAPS};
                    if (!defined $self->{BITMAP_START}[$numb]) {
                        # Look up the element descriptor immediately
                        # preceding the bitmap operator
                        my $i = $idesc;
                        $i-- while ($desc[$i] ne $self->{BITMAP_OPERATORS}->[-1]
                                    && $i >=0);
                        $i-- while ($desc[$i] > 100000 && $i >=0);
                        _croak "No element descriptor preceding bitmap" if $i < 0;
                        $self->{BITMAP_START}[$numb] = $i;
                    } else {
                        $self->{BITMAP_START}[$numb]--;
                        _croak "Bitmap too big"
                            if $self->{BITMAP_START}[$numb] < 0;
                    }
                }
            } elsif ($self->{BUILD_BITMAP} and $self->{BITMAP_INDEX} > 0) {
                # We have finished building the bit map
                $self->{BUILD_BITMAP} = 0;
                $self->{BITMAP_INDEX} = 0;
                if ($self->{BACKWARD_DATA_REFERENCE} != $self->{NUM_BITMAPS}) {
                    $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                        = $self->{BITMAP_START}[$self->{BACKWARD_DATA_REFERENCE}];
                }
            }

            _croak "Not enough descriptors provided (expected no $idesc to be $id)"
                unless exists $desc_ref->[$idesc];
            _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected $id"
                    if $desc_ref->[$idesc] != $id;

            # Find the relevant entry in BUFR table B
            _croak "Error: Data descriptor $id is not present in BUFR table B"
                unless exists $B_table->{$id};
            my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$id};
            $refval = $self->{NEW_REFVAL_OF}{$id}{$isub} if defined $self->{NEW_REFVAL_OF}{$id}
                && defined $self->{NEW_REFVAL_OF}{$id}{$isub};
            if ($Spew) {
                $self->_spew(3, "%6s  %-20s  %s", $id, $unit, $name);
                $self->_spew(3, "  %s", defined $value ? $value : 'missing');
            }
########### call to_encode_value inlined for speed
    # Override Table B values if Data Description Operators are in
    # effect (except for associated fields)
    if ($self->{NUM_CHANGE_OPERATORS} > 0 && $id != 999999) {
        if ($unit ne 'CCITTIA5' && $unit !~ /^(CODE|FLAG)/) {
            if (defined $self->{CHANGE_SRW}) {
                $scale += $self->{CHANGE_SRW};
                $width += int((10*$self->{CHANGE_SRW}+2)/3);
                $refval *= 10*$self->{CHANGE_SRW};
            } else {
                $scale += $self->{CHANGE_SCALE} if defined $self->{CHANGE_SCALE};
                $width += $self->{CHANGE_WIDTH} if defined $self->{CHANGE_WIDTH};
            }
        } elsif ($unit eq 'CCITTIA5' && defined $self->{CHANGE_CCITTIA5_WIDTH}) {
            $width = $self->{CHANGE_CCITTIA5_WIDTH}
        }
        _croak "$id Data width is $width which is <= 0" if $width <= 0;
        $refval = $self->{NEW_REFVAL_OF}{$id}{$isub} if defined $self->{NEW_REFVAL_OF}{$id}
        && defined $self->{NEW_REFVAL_OF}{$id}{$isub};
        # Difference statistical values use different width and reference value
        if ($self->{DIFFERENCE_STATISTICAL_VALUE}) {
            $width += 1;
            $refval = -2**$width;
            undef $self->{DIFFERENCE_STATISTICAL_VALUE};
            $self->{NUM_CHANGE_OPERATORS}--;
        }
    }

    # Ensure that bitstream is big enough to encode $value
    while ($pos + $width > $maxlen*8) {
        $bitstream .= chr(255) x $maxlen;
        $maxlen *= 2;
    }

    if (not defined($value)) {
        # Missing value is encoded as 1 bits
        $pos += $width;
    } elsif ($unit eq 'CCITTIA5') {
        # Encode ASCII string in $width bits (left justified,
        # padded with spaces)
        my $num_bytes = int ($width/8);
        _croak "Ascii string too long to fit in $width bits: $value"
            if length($value) > $num_bytes;
        $value .= ' ' x ($num_bytes - length($value));
        ascii2bitstream($value, $bitstream, $pos, $num_bytes);
        $pos += $width;
    } else {
        # Encode value as integer in $width bits
        _croak "Value '$value' is not a number for descriptor $id"
            unless looks_like_number($value);
        $value = int($value * 10**$scale - $refval + 0.5);
        _croak "Encoded data value for $id is negative: $value" if $value < 0;
        my $max_value = 2**$width - 1;
        _croak "Encoded data value for $id is too big to fit in $width bits: $value"
            if $value > $max_value;
        # Check for illegal flag value
        if ($Strict_checking && $unit =~ /^FLAG[ ]?TABLE/ && $width > 1
            && $value < $max_value && $value % 2) {
            _complain("$id - $value: rightmost bit $width is set indicating missing value"
                      . " but then value should be $max_value");
        }
        dec2bitstream($value, $bitstream, $pos, $width);
        $pos += $width;
    }
########### end inlining of_encode_value
        } # End D_LOOP
    } # END S_LOOP




    # Pad with 0 bits if necessary to get an even or integer number of
    # octets, depending on bufr edition
    my $padnum = $self->{BUFR_EDITION} < 4 ? (16-($pos%16)) % 16 : (8-($pos%8)) % 8;
    if ($padnum > 0) {
        null2bitstream($bitstream, $pos, $padnum);
    }
    my $len = ($pos + $padnum)/8;
    $bitstream = substr $bitstream, 0, $len;

    return ($bitstream, $len);
}

sub _encode_reference_value {
    my $self = shift;
    my ($refval,$id,$bitstream,$pos,$maxlen) = @_;

    my $width = $self->{CHANGE_REFERENCE_VALUE};

    # Ensure that bitstream is big enough to encode $value
    while ($pos + $width > $maxlen*8) {
        $bitstream .= chr(255) x $maxlen;
        $maxlen *= 2;
    }

    $self->_spew(4, "Encoding new reference value %d for %6s in %d bits",
                 $refval, $id, $width) if $Spew;
    if ($refval >= 0) {
        _croak "Encoded reference value for $id is too big to fit "
            . "in $width bits: $refval"
                if $refval > 2**$width - 1;
        dec2bitstream($refval, $bitstream, $pos, $width);
    } else {
        # Negative reference values should be encoded by setting first
        # bit to 1 and then encoding absolute value
        _croak "Encoded reference value for $id is too big to fit "
            . "in $width bits: $refval"
                if -$refval > 2**($width-1) - 1;
        dec2bitstream(-$refval, $bitstream, $pos+1, $width-1);
    }
    $pos += $width;

    return ($bitstream, $pos, $maxlen);
}

sub _encode_value {
    my $self = shift;
    my ($value,$isub,$unit,$scale,$refval,$width,$id,$bitstream,$pos,$maxlen) = @_;

    # Override Table B values if Data Description Operators are in
    # effect (except for associated fields)
    if ($self->{NUM_CHANGE_OPERATORS} > 0 && $id != 999999) {
        if ($unit ne 'CCITTIA5' && $unit !~ /^(CODE|FLAG)/) {
            if (defined $self->{CHANGE_SRW}) {
                $scale += $self->{CHANGE_SRW};
                $width += int((10*$self->{CHANGE_SRW}+2)/3);
                $refval *= 10*$self->{CHANGE_SRW};
            } else {
                $scale += $self->{CHANGE_SCALE} if defined $self->{CHANGE_SCALE};
                $width += $self->{CHANGE_WIDTH} if defined $self->{CHANGE_WIDTH};
            }
        } elsif ($unit eq 'CCITTIA5' && defined $self->{CHANGE_CCITTIA5_WIDTH}) {
            $width = $self->{CHANGE_CCITTIA5_WIDTH}
        }
        _croak "$id Data width is $width which is <= 0" if $width <= 0;
        $refval = $self->{NEW_REFVAL_OF}{$id}{$isub} if defined $self->{NEW_REFVAL_OF}{$id}
        && defined $self->{NEW_REFVAL_OF}{$id}{$isub};
        # Difference statistical values use different width and reference value
        if ($self->{DIFFERENCE_STATISTICAL_VALUE}) {
            $width += 1;
            $refval = -2**$width;
            undef $self->{DIFFERENCE_STATISTICAL_VALUE};
            $self->{NUM_CHANGE_OPERATORS}--;
        }
    }

    # Ensure that bitstream is big enough to encode $value
    while ($pos + $width > $maxlen*8) {
        $bitstream .= chr(255) x $maxlen;
        $maxlen *= 2;
    }

    if (not defined($value)) {
        # Missing value is encoded as 1 bits
        $pos += $width;
    } elsif ($unit eq 'CCITTIA5') {
        # Encode ASCII string in $width bits (left justified,
        # padded with spaces)
        my $num_bytes = int ($width/8);
        _croak "Ascii string too long to fit in $width bits: $value"
            if length($value) > $num_bytes;
        $value .= ' ' x ($num_bytes - length($value));
        ascii2bitstream($value, $bitstream, $pos, $num_bytes);
        $pos += $width;
    } else {
        # Encode value as integer in $width bits
        _croak "Value '$value' is not a number for descriptor $id"
            unless looks_like_number($value);
        $value = int($value * 10**$scale - $refval + 0.5);
        _croak "Encoded data value for $id is negative: $value" if $value < 0;
        my $max_value = 2**$width - 1;
        _croak "Encoded data value for $id is too big to fit in $width bits: $value"
            if $value > $max_value;
        # Check for illegal flag value
        if ($Strict_checking && $unit =~ /^FLAG[ ]?TABLE/ && $width > 1
            && $value < $max_value && $value % 2) {
            _complain("$id - $value: rightmost bit $width is set indicating missing value"
                      . " but then value should be $max_value");
        }
        dec2bitstream($value, $bitstream, $pos, $width);
        $pos += $width;
    }

    return ($bitstream, $pos, $maxlen);
}

# Encode reference value using BUFR compression, assuming all subsets
# have same reference value
sub _encode_compressed_reference_value {
    my $self = shift;
    my ($refval,$id,$nsubsets,$bitstream,$pos,$maxlen) = @_;

    my $width = $self->{CHANGE_REFERENCE_VALUE};

    # Ensure that bitstream is big enough to encode $value
    while ($pos + ($nsubsets+1)*$width + 6 > $maxlen*8) {
        $bitstream .= chr(255) x $maxlen;
        $maxlen *= 2;
    }

    $self->_spew(4, "Encoding new reference value %d for %6s in %d bits",
                 $refval, $id, $width) if $Spew;
    # Encode value as integer in $width bits
    if ($refval >= 0) {
        _croak "Encoded reference value for $id is too big to fit "
            . "in $width bits: $refval" if $refval > 2**$width - 1;
        dec2bitstream($refval, $bitstream, $pos, $width);
    } else {
        # Negative reference values should be encoded by setting first
        # bit to 1 and then encoding absolute value
        _croak "Encoded reference value for $id is too big to fit "
            . "in $width bits: $refval" if -$refval > 2**($width-1) - 1;
        dec2bitstream(-$refval, $bitstream, $pos+1, $width-1);
    }
    $pos += $width;

    # Increment width set to 0
    dec2bitstream(0, $bitstream, $pos, 6);
    $pos += 6;

    return ($bitstream, $pos, $maxlen);
}

sub _encode_compressed_value {
    my $self = shift;
    my ($bitstream,$pos,$maxlen,$unit,$scale,$refval,$width,$id,$data_refs,$idesc,$nsubsets) = @_;

    # Override Table B values if Data Description Operators are in
    # effect (except for associated fields)
    if ($self->{NUM_CHANGE_OPERATORS} > 0 && $id != 999999) {
        if ($unit ne 'CCITTIA5' && $unit !~ /^(CODE|FLAG)/) {
            if (defined $self->{CHANGE_SRW}) {
                $scale += $self->{CHANGE_SRW};
                $width += int((10*$self->{CHANGE_SRW}+2)/3);
                $refval *= 10*$self->{CHANGE_SRW};
            } else {
                $scale += $self->{CHANGE_SCALE} if defined $self->{CHANGE_SCALE};
                $width += $self->{CHANGE_WIDTH} if defined $self->{CHANGE_WIDTH};
            }
        } elsif ($unit eq 'CCITTIA5' && defined $self->{CHANGE_CCITTIA5_WIDTH}) {
            $width = $self->{CHANGE_CCITTIA5_WIDTH}
        }
        _croak "$id Data width <= 0" if $width <= 0;
        $refval = $self->{NEW_REFVAL_OF}{$id} if defined $self->{NEW_REFVAL_OF}{$id};
        # Difference statistical values use different width and reference value
        if ($self->{DIFFERENCE_STATISTICAL_VALUE}) {
            $width += 1;
            $refval = -2**$width;
            undef $self->{DIFFERENCE_STATISTICAL_VALUE};
            $self->{NUM_CHANGE_OPERATORS}--;
        }
    }

    # Ensure that bitstream is big enough to encode $value
    while ($pos + ($nsubsets+1)*$width + 6 > $maxlen*8) {
        $bitstream .= chr(255) x $maxlen;
        $maxlen *= 2;
    }

    # Get all values for this descriptor
    my @values;
    my $first_value = $data_refs->[1][$idesc];
    my $all_equal = 1;        # Set to 0 if at least 2 elements differ
    foreach my $value (map { $data_refs->[$_][$idesc] } 2..$nsubsets) {
        if (defined $value && $unit ne 'CCITTIA5' && !looks_like_number($value)) {
            _croak "Value '$value' is not a number for descriptor $id"
        }
        # This used to be a sub (_check_equality), but inlined for speed
        if ($all_equal) {
            if (defined $value && defined $first_value) {
                if ($unit eq 'CCITTIA5') {
                    $all_equal = 0 if $value ne $first_value;
                } else {
                    $all_equal = 0 if $value != $first_value;
                }
            } elsif (defined $value || defined $first_value) {
                $all_equal = 0;
            }
        }
        if (not defined $value) {
            push @values, undef;
        } elsif ($unit eq 'CCITTIA5') {
            push @values, $value;
        } else {
            push @values, int($value * 10**$scale - $refval + 0.5);
        }
        # Check for illegal flag value
        if ($Strict_checking and $unit =~ /^FLAG[ ]?TABLE/ and $width > 1) {
            if (defined $value and $value ne 'missing' and $value % 2) {
                my $max_value = 2**$width - 1;
                _complain("$id - value $value in subset $_:\n"
                          . "rightmost bit $width is set indicating missing value"
                          . " but then value should be $max_value");
            }
        }
    }

    if ($all_equal) {
        # Same value in all subsets. No need to calculate or store increments
        if (defined $first_value) {
            if ($unit eq 'CCITTIA5') {
                # Encode ASCII string in $width bits (left justified,
                # padded with spaces)
                my $num_bytes = int ($width/8);
                _croak "Ascii string too long to fit in $width bits: $first_value"
                    if length($first_value) > $num_bytes;
                $first_value .= ' ' x ($num_bytes - length($first_value));
                ascii2bitstream($first_value, $bitstream, $pos, $num_bytes);
            } else {
                # Encode value as integer in $width bits
                _croak "First value '$first_value' is not a number for descriptor $id"
                    unless looks_like_number($first_value);
                $first_value = int($first_value * 10**$scale - $refval + 0.5);
                _croak "Encoded data value for $id is negative: $first_value"
                    if $first_value < 0;
                _croak "Encoded data value for $id is too big to fit "
                    . "in $width bits: $first_value"
                        if $first_value > 2**$width - 1;
                dec2bitstream($first_value, $bitstream, $pos, $width);
            }
        } else {
            # Missing value is encoded as 1 bits, but bitstream is
            # padded with 1 bits already
        }
        $pos += $width;
        # Increment width set to 0
        dec2bitstream(0, $bitstream, $pos, 6);
        $pos += 6;
    } else {
        if ($unit eq 'CCITTIA5') {
            unshift @values, $first_value;
            # Local reference value set to 0 bits
            null2bitstream($bitstream, $pos, $width);
            $pos += $width;
            # Do not store more characters than needed: remove leading
            # and trailing spaces, then right pad with spaces so that
            # all strings has same length as largest string
            my $largest_length = _trimpad(\@values);
            dec2bitstream($largest_length, $bitstream, $pos, 6);
            $pos += 6;
            # Store the character values
            foreach my $value (@values) {
                if (defined $value) {
                    # Encode ASCII string in $largest_length bytes
                    ascii2bitstream($value, $bitstream, $pos, $largest_length);
                } else {
                    # Missing value is encoded as 1 bits, but
                    # bitstream is padded with 1 bits already
                }
                $pos += $largest_length * 8;
            }
        } else {
            _croak "First value '$first_value' is not a number for descriptor $id"
                if defined($first_value) && !looks_like_number($first_value);
            unshift @values, defined $first_value
                ? int($first_value * 10**$scale - $refval + 0.5)
                    : undef;
            # Numeric data. First find minimum value
            my ($min_value, $isub) = _minimum(\@values);
            _croak "Encoded data value for $id and subset $isub is negative: $min_value"
                if $min_value < 0;
            my @inc_values =
                map { defined $_ ? $_ - $min_value : undef } @values;
            # Find how many bits are required to hold the increment
            # values (or rather: the highest increment value pluss one
            # (except for associated values), to be able to store
            # missing values also)
            my $max_inc = _maximum(\@inc_values);
            my $deltabits = ($id eq '999999')
                ?_get_number_of_bits_to_store($max_inc)
                    : _get_number_of_bits_to_store($max_inc + 1);
            # Store local reference value
            $self->_spew(5, " Local reference value: %d", $min_value) if $Spew;
            dec2bitstream($min_value, $bitstream, $pos, $width);
            $pos += $width;
            # Store increment width
            $self->_spew(5, " Increment width (bits): %d", $deltabits) if $Spew;
            dec2bitstream($deltabits, $bitstream, $pos, 6);
            $pos += 6;
            # Store values
            $self->_spew(5, " Increment values: %s",
                         join(',', map { defined $inc_values[$_]
                         ? $inc_values[$_] : ''} 0..$#inc_values))
                         if $Spew;
            foreach my $value (@inc_values) {
                if (defined $value) {
                    _complain("value " . ($value + $min_value) . " for $id too big"
                              . " to be encoded without compression")
                        if ($Strict_checking && ($value + $min_value) > 2**$width -1);
                    dec2bitstream($value, $bitstream, $pos, $deltabits);
                } else {
                    # Missing value is encoded as 1 bits, but
                    # bitstream is padded with 1 bits already
                }
                $pos += $deltabits;
            }
        }
    }

    return ($bitstream, $pos, $maxlen);
}

## Encode bitstream using the data values in $data_refs, first
## expanding section 3 fully (and comparing with $desc_refs to check
## for consistency). This sub is very similar to sub
## _decompress_bitstream
sub _encode_compressed_bitstream {
    my $self = shift;
    $self->{CODING} = 'ENCODE';
    my ($data_refs, $desc_refs) = @_;

    # Expand section 3 except for delayed replication and operator
    # descriptors. This expansion is the same for all subsets, since
    # delayed replication has to be the same (this needs to be
    # checked) for compression to be possible
    my @unexpanded = split / /, $self->{DESCRIPTORS_UNEXPANDED};
    my $alias = "$self->{TABLE_VERSION} " . $self->{DESCRIPTORS_UNEXPANDED};
    if (exists $Descriptors_already_expanded{$alias}) {
        $self->{DESCRIPTORS_EXPANDED} = $Descriptors_already_expanded{$alias};
    } else {
        $Descriptors_already_expanded{$alias} = $self->{DESCRIPTORS_EXPANDED}
            = join " ", _expand_descriptors($self->{D_TABLE}, @unexpanded);
    }
    my @desc = split /\s/, $self->{DESCRIPTORS_EXPANDED};

    my $nsubsets = $self->{NUM_SUBSETS};
    my $B_table = $self->{B_TABLE};
    my $maxlen = 1024;
    my $bitstream = chr(255) x $maxlen; # one bits only
    my $pos = 0;
    my @operators;

    my $desc_ref = $desc_refs->[1];

    # All subsets should have same set of expanded descriptors. This
    # is checked later, but we also need to check that the number of
    # descriptors in each subset is the same for all subsets
    my $num_desc = @{$desc_ref};
    foreach my $isub (2..$nsubsets) {
        my $num_d = @{$desc_refs->[$isub]};
        _croak "Compression impossible: Subset 1 contains $num_desc descriptors,"
            . " while subset $isub contains $num_d descriptors"
                if $num_d != $num_desc;
    }


  D_LOOP: for (my $idesc = 0; $idesc < @desc; $idesc++) {
        my $id = $desc[$idesc];
        my $f = substr($id,0,1);
        my $x = substr($id,1,2)+0;
        my $y = substr($id,3,3)+0;

        if ($f == 1) {
            # Delayed replication
            if ($x == 0) {
                _complain("Nonsensical replication of zero descriptors ($id)");
                $idesc++;
                next D_LOOP;
            }
            _croak "$id _expand_descriptors() did not do its job"
                if $y > 0;

            my $next_id = $desc[$idesc+1];
            _croak "$id Erroneous replication factor"
                unless $next_id =~ /^0310(00|01|02|11|12)/ && exists $B_table->{$next_id};
            _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected $next_id"
                if $desc_ref->[$idesc] != $next_id;
            my $factor = $data_refs->[1][$idesc];
            my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$next_id};
            if ($Spew) {
                $self->_spew(3, "%6s  %-20s  %s", $next_id, $unit, $name);
                $self->_spew(3, "  %s", $factor);
            }
            ($bitstream, $pos, $maxlen)
                = $self->_encode_compressed_value($bitstream,$pos,$maxlen,
                                                  $unit,$scale,$refval,$width,
                                                  $next_id,$data_refs,$idesc,$nsubsets);
            # Include the delayed replication/repetition in descriptor list
            splice @desc, $idesc++, 0, $next_id;

            my @r = ();
            push @r, @desc[($idesc+2)..($idesc+$x+1)] while $factor--;
            splice @desc, $idesc, 2+$x, @r;

            if ($next_id eq '031011' || $next_id eq '031012') {
                # For delayed repetition we should include data just
                # once, so skip to the last set in data array
                $idesc += $x * ($data_refs->[1][$idesc-1] - 1);
                # We ought to check that the data sets we skipped are
                # indeed equal to the last set!
                $self->_spew(4, "Delayed repetition ($id $next_id -> @r)") if $Spew;
            } else {
                $self->_spew(4, "Delayed replication ($id $next_id -> @r)") if $Spew;
            }
            if ($idesc < @desc) {
                redo D_LOOP;
            } else {
                last D_LOOP; # Might happen if delayed factor is 0
            }

        } elsif ($f == 2) {
            my $flow;
            my $bm_idesc;
            ($pos, $flow, $bm_idesc, @operators)
                = $self->_apply_operator_descriptor($id, $x, $y, $pos, 0,
                                                    $desc[$idesc+1], @operators);
            if ($flow eq 'redo_bitmap') {
                # Data value is associated with the descriptor
                # defined by bit map. Remember original and new
                # index in descriptor array for the bit mapped
                # values ('dr' = data reference)
                my $dr_idesc;
                if (!defined $bm_idesc) {
                    $dr_idesc = shift @{ $self->{REUSE_BITMAP}->[0] };
                } elsif (!$Show_all_operators) {
                    $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                        + $bm_idesc;
                } else {
                    $dr_idesc = $self->{BITMAP_START}[$self->{NUM_BITMAPS}];
                    # Skip operator descriptors
                    while ($bm_idesc-- > 0) {
                        $dr_idesc++;
                        $dr_idesc++ while ($desc[$dr_idesc] >= 200000);
                    }
                }
                push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] },
                     $dr_idesc, $idesc;
                $desc[$idesc] = $desc[$dr_idesc];
                redo D_LOOP;
            } elsif ($flow eq 'signify_character') {
                _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected $id"
                    if $desc_ref->[$idesc] != $id;
                # Get ASCII string
                my @values = map { $data_refs->[$_][$idesc] } 1..$nsubsets;
                my $name = 'SIGNIFY CHARACTER';
                my $unit = 'CCITTIA5';
                my ($scale, $refval, $width) = (0, 0, 8*$y);
                ($bitstream, $pos, $maxlen)
                    = $self->_encode_compressed_value($bitstream,$pos,$maxlen,
                                                      $unit,$scale,$refval,$width,
                                                      "205$y",$data_refs,$idesc,$nsubsets);
                next D_LOOP;
            } elsif ($flow eq 'no_value') {
                next D_LOOP;
            }

            # Remove operator descriptor from @desc
            splice @desc, $idesc--, 1;

            next D_LOOP if $flow eq 'next';
            last D_LOOP if $flow eq 'last';
        }

        if ($self->{CHANGE_REFERENCE_VALUE}) {
            # The data descriptor is to be associated with a new
            # reference value, which is fetched from data stream,
            # possibly with f=9 instead of f=0 for descriptor
            $id -= 900000 if $id =~ /^9/;
            _croak "Change reference operator 203Y is not followed by element"
                . " descriptor, but $id" if $f > 0;
            my @new_ref_values = map { $data_refs->[$_][$idesc] } 1..$nsubsets;
            my $new_refval = $new_ref_values[0];
            # Check that they are all the same
            foreach my $val (@new_ref_values[1..$#new_ref_values]) {
                _croak "Change reference value differ between subsets"
                    . " which cannot be combined with BUFR compression"
                        if $val != $new_refval;
            }
            $self->{NEW_REFVAL_OF}{$id} = $new_refval;
            ($bitstream, $pos, $maxlen)
                = $self->_encode_compressed_reference_value($new_refval,$id,$nsubsets,$bitstream,$pos,$maxlen);
            next D_LOOP;
        }

        # If operator 204$y 'Add associated field' is in effect,
        # each data value is preceded by $y bits which should be
        # encoded separately. We choose to provide a descriptor
        # 999999 in this case (like the ECMWF BUFRDC software)
        if ($self->{ADD_ASSOCIATED_FIELD} and $id ne '031021') {
            # First encode associated field
            _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected 999999"
                if $desc_ref->[$idesc] != 999999;
            my @values = map { $data_refs->[$_][$idesc] } 1..$nsubsets;
            my $name = 'ASSOCIATED FIELD';
            my $unit = 'NUMERIC';
            my ($scale, $refval) = (0, 0);
            my $width = $self->{ADD_ASSOCIATED_FIELD};
            if ($Spew) {
                $self->_spew(3, "%6s  %-20s  %s", $id, $unit, $name);
                $self->_spew(3, "  %s", 999999);
            }
            ($bitstream, $pos, $maxlen)
                = $self->_encode_compressed_value($bitstream,$pos,$maxlen,
                                                  $unit,$scale,$refval,$width,
                                                  999999,$data_refs,$idesc,$nsubsets);
            # Insert the artificial 999999 descriptor for the
            # associated value and increment $idesc to prepare for
            # handling the 'real' value below
            splice @desc, $idesc++, 0, 999999;
        }



        # For quality information, if this relates to a bit map we
        # need to store index of the data ($data_idesc) for which
        # the quality information applies, as well as the new
        # index ($idesc) in the descriptor array for the bit
        # mapped values
        if (substr($id,0,3) eq '033'
            && defined $self->{BITMAP_OPERATORS}
            && $self->{BITMAP_OPERATORS}->[-1] eq '222000') {
            if (defined $self->{REUSE_BITMAP}) {
                my $data_idesc = shift @{ $self->{REUSE_BITMAP}->[0] };
                _croak "$id: Not enough quality values provided"
                    if not defined $data_idesc;
                push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] },
                     $data_idesc, $idesc;
            } else {
                my $data_idesc = shift @{ $self->{CURRENT_BITMAP} };
                _croak "$id: Not enough quality values provided"
                    if not defined $data_idesc;
                push @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}]->[0] },
                     $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                         + $data_idesc, $idesc;
            }
        }

        if ($id eq '031031' and $self->{BUILD_BITMAP}) {
            # Store the index of expanded descriptors if data is
            # marked as present in data present indicator: 0 is
            # 'present', 1 (undef value) is 'not present'. E.g.
            # bitmap = 1100110 => (2,3,6) is stored in $self->{CURRENT_BITMAP}

            # NB: bit map might vary betwen subsets!!!!????
            if ($data_refs->[1][$idesc] == 0) {
                push @{$self->{CURRENT_BITMAP}}, $self->{BITMAP_INDEX};
            }
            $self->{BITMAP_INDEX}++;
            if ($self->{BACKWARD_DATA_REFERENCE} == $self->{NUM_BITMAPS}) {
                my $numb = $self->{NUM_BITMAPS};
                if (!defined $self->{BITMAP_START}[$numb]) {
                    # Look up the element descriptor immediately
                    # preceding the bitmap operator
                    my $i = $idesc;
                    $i-- while ($desc[$i] ne $self->{BITMAP_OPERATORS}->[-1]
                                && $i >=0);
                    $i-- while ($desc[$i] > 100000 && $i >=0);
                    _croak "No element descriptor preceding bitmap" if $i < 0;
                    $self->{BITMAP_START}[$numb] = $i;
                } else {
                    $self->{BITMAP_START}[$numb]--;
                    _croak "Bitmap too big"
                        if $self->{BITMAP_START}[$numb] < 0;
                }
            }
        } elsif ($self->{BUILD_BITMAP} and $self->{BITMAP_INDEX} > 0) {
            # We have finished building the bit map
            $self->{BUILD_BITMAP} = 0;
            $self->{BITMAP_INDEX} = 0;
            if ($self->{BACKWARD_DATA_REFERENCE} != $self->{NUM_BITMAPS}) {
                $self->{BITMAP_START}[$self->{NUM_BITMAPS}]
                    = $self->{BITMAP_START}[$self->{BACKWARD_DATA_REFERENCE}];
            }
        }

        # We now have a "real" data descriptor
        _croak "Descriptor no $idesc is $desc_ref->[$idesc], expected $id"
            if $desc_ref->[$idesc] != $id;

        # Find the relevant entry in BUFR table B
        _croak "Data descriptor $id is not present in BUFR table B"
            unless exists $B_table->{$id};
        my ($name,$unit,$scale,$refval,$width) = split /\0/, $B_table->{$id};
        if ($Spew) {
            $self->_spew(3, "%6s  %-20s  %s", $id, $unit, $name);
            $self->_spew(3, "  %s", join ' ',
                         map { defined($data_refs->[$_][$idesc]) ?
                                   $data_refs->[$_][$idesc] : 'missing'} 1..$nsubsets );
        }
        ($bitstream, $pos, $maxlen)
            = $self->_encode_compressed_value($bitstream,$pos,$maxlen,
                                              $unit,$scale,$refval,$width,
                                              $id,$data_refs,$idesc,$nsubsets);
    } # End D_LOOP

    # Pad with 0 bits if necessary to get an even or integer number of
    # octets, depending on bufr edition
    my $padnum = $self->{BUFR_EDITION} < 4 ? (16-($pos%16)) % 16 : (8-($pos%8)) % 8;
    if ($padnum > 0) {
        null2bitstream($bitstream, $pos, $padnum);
    }
    my $len = ($pos + $padnum)/8;
    $bitstream = substr $bitstream, 0, $len;

    return ($bitstream, $len);
}

## Check that the length of data section computed from expansion of
## section 3 ($comp_len) equals actual length of data part of section
## 4, allowing for padding zero bits according to BUFR Regulation 94.1.3
## Strict checking should also check that padding actually consists of
## zero bits only.
sub _check_section4_length {
    my $self = shift;
    my ($comp_len, $actual_len) = @_;

    if ($comp_len > $actual_len) {
        _croak "More descriptors in expansion of section 3"
            . " than what can fit in the given length of section 4"
                . " ($comp_len versus $actual_len bits)";
    } else {
        return if not $Strict_checking; # Excessive bytes in section 4
                                        # does not prevent further decoding
        return if $Noqc;  # No more sensible checks to do in this case

        my $bufr_edition = $self->{BUFR_EDITION};
        my $actual_bytes = $actual_len/8; # This is sure to be an integer
        if ($bufr_edition < 4 and $actual_bytes % 2) {
            _complain("Section 4 is odd number ($actual_bytes) of bytes,"
                      . " which is an error in BUFR edition $bufr_edition");
        }
        my $comp_bytes = int($comp_len/8);
        $comp_bytes++ if $comp_len % 8; # Need to pad with zero bits
        $comp_bytes++ if $bufr_edition < 4 and $comp_bytes % 2; # Need to pad with an extra byte of zero bits
        if ($actual_bytes > $comp_bytes) {
            _complain("Binary data part of section 4 longer ($actual_bytes bytes)"
                      . " than expected from section 3 ($comp_bytes bytes)");
        }
    }
    return;
}

# Trim string, also removing nulls (and _complain if nulls found).
# If strict_checking, checks also for bit 1 set in each character
sub _trim {
    my ($str, $id) = @_;
    return unless defined $str;
    if ($str =~ /\0/) {
        (my $str2 = $str) =~ s|\0|\\0|g;
        _complain("Nulls (" . '\0'
                  . ") found in string '$str2' for descriptor $id");
        $str =~ s/\0//g;
    } elsif ($Strict_checking && $str =~/^ +$/) {
        _complain("Only spaces ('$str') found for descriptor $id, "
                  . "ought to have been encoded as missing value ");
    }

    $str =~ s/\s+$//;
    $str =~ s/^\s+//;

    if ($Strict_checking && $str ne '') {
        foreach my $char (split //, $str) {
            if (ord($char) > 127) {
                _complain("Character $char (ascii value " . ord($char) .
                          ") in string '$str' is not allowed in CCITTIA5");
                last; # Don't want to warn for every bad character
            }
        }
    }
    return $str;
}

## Remove leading and trailing spaces in the strings provided, then add
## spaces if necessary so that all strings have same length as largest
## trimmed string. This length (in bytes) is returned
sub _trimpad {
    my $string_ref = shift;
    my $largest_length = 0;
    foreach my $string (@{$string_ref}) {
        if (defined $string) {
            $string =~ s/^\s+//;
            $string =~ s/\s+$//;
            if (length $string > $largest_length) {
                $largest_length = length $string;
            }
        }
    }
    foreach my $string (@{$string_ref}) {
        if (defined $string) {
            $string .= ' ' x ($largest_length - length $string);
        }
    }
    return $largest_length;
}

## Use timegm in Time::Local to validate date and time in section 1
sub _validate_datetime {
    my $self = shift;
    my $bufr_edition = $self->{BUFR_EDITION};
    my $year = $bufr_edition < 4 ? $self->{YEAR_OF_CENTURY} + 2000
                                 : $self->{YEAR};
    my $month = $self->{MONTH} - 1;
    my $second = $bufr_edition == 4 ? $self->{SECOND} : 0;

    # All datetime variables set to 0 should be considered ok
    return if ($self->{MINUTE} == 0 && $self->{HOUR} == 0
           && $self->{DAY} == 0 && $self->{MONTH} == 0
           && $second == 0 && ($year == 0 || $year == 2000));

    eval {
        my $dummy = timegm($second,$self->{MINUTE},$self->{HOUR},
                           $self->{DAY},$month,$year);
    };

    _complain("Invalid date in section 1: $@") if $@;
}

## Return number of bits necessary to store the nonnegative number $n
## (1 for 0,1, 2 for 2,3, 3 for 4,5,6,7 etc)
sub _get_number_of_bits_to_store {
    my $n = shift;
    return 1 if $n == 0;
    my $x = 1;
    my $i = 0;
    while ($x < $n) {
        $i++;
        $x *= 2;
    }
    return $x==$n ? $i+1 : $i;
}

## Find minimum value among set of numbers (undefined values
## permitted, but at least one value must be defined). Also returns
## for which number the minimum occurs (counting from 1).
sub _minimum {
    my $v_ref = shift;
    my $min = 2**63;
    my $idx = 0;
    my $i=0;
    foreach my $v (@{$v_ref}) {
        $i++;
        next if not defined $v;
        if ($v < $min) {
            $min = $v;
            $idx = $i;
        }
    }
    return ($min, $idx);
}

## Find maximum value among set of nonnegative numbers or undefined values
sub _maximum {
    my $v_ref = shift;
    my $max = 0;
    foreach my $v (@{$v_ref}) {
        next if not defined $v;
        if ($v > $max) {
            $max = $v;
        }
    }
    _croak "Internal error: Found no maximum value" if $max < 0;
    return $max;
}

## Return index of first occurrence av $value in $list, undef if no match
sub _get_index_in_list {
    my ($list, $value) = @_;
    for (my $i=0; $i <= $#{$list}; $i++) {
        if ($list->[$i] eq $value) { # Match
            return $i;
        }
    }
    # No match
    return undef;
}

## Apply the operator descriptor $id, adjusting $pos and
## @operators. Also returning $bm_idesc (explained in start of module)
## and a hint of what to do next in $flow
sub _apply_operator_descriptor {
    my $self = shift;
    my ($id, $x, $y, $pos, $isub, $next_id, @operators) = @_;
    # $isub should be 0 for compressed messages, else subset number

    my $flow = '';
    my $bm_idesc = '';

    if ($y == 0 && $x =~ /^[12378]$/) {
        # 20[12378]000 Cancellation of a data descriptor operator
        _complain("$id Cancelling unused operator")
            if $Strict_checking and !grep {$_ == $x} @operators;
        @operators = grep {$_ != $x} @operators;
        if ($x == 1) {
            $self->{NUM_CHANGE_OPERATORS}-- if $self->{CHANGE_WIDTH};
            undef $self->{CHANGE_WIDTH};
        } elsif ($x == 2) {
            $self->{NUM_CHANGE_OPERATORS}-- if $self->{CHANGE_SCALE};
            undef $self->{CHANGE_SCALE};
        } elsif ($x == 3) {
            $self->{NUM_CHANGE_OPERATORS}-- if $self->{NEW_REFVAL_OF};
            undef $self->{NEW_REFVAL_OF};
        } elsif ($x == 7) {
            $self->{NUM_CHANGE_OPERATORS}-- if $self->{CHANGE_SRW};
            undef $self->{CHANGE_SRW};
        } elsif ($x == 8) {
            $self->{NUM_CHANGE_OPERATORS}-- if $self->{CHANGE_CCITTIA5_WIDTH};
            undef $self->{CHANGE_CCITTIA5_WIDTH};
        }
        $self->_spew(4, "$id * Reset %s",
                     ("width of CCITTIA5 field","data width","scale","reference values",0,0,0,
                     "increase of scale, reference value and data width")[$x % 8]) if $Spew;
        $flow = 'next';
    } elsif ($x == 1) {
        # ^201 Change data width
        _croak "201 operator cannot be nested within 207 operator"
            if grep {$_ == 7} @operators;
        $self->{NUM_CHANGE_OPERATORS}++ if !$self->{CHANGE_WIDTH};
        $self->{CHANGE_WIDTH} = $y-128;
        $self->_spew(4, "$id * Change data width: %d", $self->{CHANGE_WIDTH}) if $Spew;
        push @operators, $x;
        $flow = 'next';
    } elsif ($x == 2) {
        # ^202 Change scale
        _croak "202 operator cannot be nested within 207 operator"
            if grep {$_ == 7} @operators;
        $self->{NUM_CHANGE_OPERATORS}++ if !$self->{CHANGE_SCALE};
        $self->{CHANGE_SCALE} = $y-128;
        $self->_spew(4, "$id * Change scale: %d", $self->{CHANGE_SCALE}) if $Spew;
        push @operators, $x;
        $flow = 'next';
    } elsif ($x == 3 && $y == 255) {
        # 203255 Terminate change reference value definition
        $self->_spew(4, "$id * Terminate reference value definition %s",
                     '203' . (defined $self->{CHANGE_REFERENCE_VALUE}
                     ? sprintf("%03d", $self->{CHANGE_REFERENCE_VALUE}) : '???')) if $Spew;
        _complain("$id no current change reference value to terminate")
            unless defined $self->{CHANGE_REFERENCE_VALUE};
        undef $self->{CHANGE_REFERENCE_VALUE};
        $flow = 'next';
    } elsif ($x == 3) {
        # ^203 Change reference value
        _croak "203 operator cannot be nested within 207 operator"
            if grep {$_ == 7} @operators;
        $self->_spew(4, "$id * Change reference value") if $Spew;
        # Get reference value from data stream ($y == number of bits)
        $self->{NUM_CHANGE_OPERATORS}++ if !$self->{CHANGE_REFERENCE_VALUE};
        $self->{CHANGE_REFERENCE_VALUE} = $y;
        push @operators, $x;
        $flow = 'next';
    } elsif ($x == 4) {
        # ^204 Add associated field
        if ($y > 0) {
            _croak "$id Nesting of Add associated field is not implemented"
                if $self->{ADD_ASSOCIATED_FIELD};
            $self->{ADD_ASSOCIATED_FIELD} = $y;
            $flow = 'next';
        } else {
            _complain "$id No previous Add associated field"
                unless defined $self->{ADD_ASSOCIATED_FIELD};
            undef $self->{ADD_ASSOCIATED_FIELD};
            $flow = 'next';
        }
    } elsif ($x == 5) {
        # ^205 Signify character (i.e. the following $y bytes is
        # character information)
        $flow = 'signify_character';
    } elsif ($x == 6) {
        # ^206 Signify data width for the immediately following local
        # descriptor. If we find this local descriptor in BUFR table B
        # with data width $y bits, we assume we can use this table
        # entry to decode/encode the value properly, and can just
        # ignore the operator descriptor. Else we skip the local
        # descriptor and the corresponding value if decoding, or have
        # to give up if encoding
        my $ff = substr($next_id,0,1);
        _croak("Descriptor $next_id following Signify data width"
                  . "  operator $_ is not an element descriptor")
            if $ff != 0;
        if ($Strict_checking) {
            my $xx = substr($next_id,1,2);
            my $yy = substr($next_id,3,3);
            _complain("Descriptor $next_id following Signify data width"
                  . "  operator $id is not a local descriptor")
                if ($xx < 48 && $yy < 192);
        }
        if (exists $self->{B_TABLE}->{$next_id}
            and (split /\0/, $self->{B_TABLE}->{$next_id})[-1] == $y) {
            $self->_spew(4, "Found $next_id with data width $y, ignoring $id") if $Spew;
            $flow = 'next';
        } else {
            _croak "Cannot encode descriptor $next_id (following $id), not found in table B"
                if $self->{CODING} eq 'ENCODE';
            $self->_spew(4, "$_: Did not find $next_id in table B."
                         . " Skipping $id and $next_id.") if $Spew;
            $pos += $y;  # Skip next $y bits in bitstream if decoding
            $flow = 'skip';
        }

    } elsif ($x == 7) {
        # ^207 Increase scale, reference value and data width
        _croak "207 operator cannot be nested within 201/202/203 operators"
            if grep {$_ == 1 || $_ == 2 || $_ == 3} @operators;
        $self->{NUM_CHANGE_OPERATORS}++ if !$self->{CHANGE_SRW};
        $self->{CHANGE_SRW} = $y;
        $self->_spew(4, "$id * Increase scale, reference value and data width: %d", $y) if $Spew;
        push @operators, $x;
        $flow = 'next';
    } elsif ($x == 8) {
        # ^208 Change data width for ascii data
        $self->{NUM_CHANGE_OPERATORS}++ if !$self->{CHANGE_CCITTIA5_WIDTH};
        $self->{CHANGE_CCITTIA5_WIDTH} = $y*8;
        $self->_spew(4, "$id * Change width for CCITTIA5 field: %d bytes", $y) if $Spew;
        push @operators, $x;
        $flow = 'next';
    } elsif ($x == 9) {
        # ^209 IEEE floating point representation
        _croak "$id IEEE floating point representation (not implemented)";
    } elsif ($x == 21) {
        # ^221 Data not present
        _croak "$id Data not present (not implemented)";
    } elsif ($x == 22 && $y == 0) {
        # 222000 Quality information follows
        push @{ $self->{BITMAP_OPERATORS} }, '222000';
        $self->{NUM_BITMAPS}++;
        # Mark that a bit map probably needs to be built
        $self->{BUILD_BITMAP} = 1;
        $self->{BITMAP_INDEX} = 0;
        $flow = $Noqc ? 'last' : 'no_value';
    } elsif ($x == 23 && $y == 0) {
        # 223000 Substituted values follow, each one following a
        # descriptor 223255. Which value they are a substitute for is
        # defined by a bit map, which already may have been defined
        # (if descriptor 23700 is encountered), or will shortly be
        # defined by data present indicators (031031)
        push @{ $self->{BITMAP_OPERATORS} }, '223000';
        $self->{NUM_BITMAPS}++;
        # Mark that a bit map probably needs to be built
        $self->{BUILD_BITMAP} = 1;
        $self->{BITMAP_INDEX} = 0;
        $flow = 'no_value';
    } elsif ($x == 23 && $y == 255) {
        # 223255 Substituted values marker operator
        _croak "$id No bit map defined"
            unless (defined $self->{CURRENT_BITMAP} || defined $self->{REUSE_BITMAP})
            && $self->{BITMAP_OPERATORS}[-1] eq '223000';
        if (defined $self->{REUSE_BITMAP}) {
            _croak "More 223255 encountered than current bit map allows"
                unless @{ $self->{REUSE_BITMAP}->[$isub] };
            $bm_idesc = undef;
        } else {
            _croak "More 223255 encountered than current bit map allows"
                unless @{$self->{CURRENT_BITMAP}};
            $bm_idesc = shift @{$self->{CURRENT_BITMAP}};
        }
        $flow = 'redo_bitmap';
    } elsif ($x == 24 && $y == 0) {
        # 224000 First order statistical values follow
        push @{ $self->{BITMAP_OPERATORS} }, '224000';
        $self->{NUM_BITMAPS}++;
        # Mark that a bit map probably needs to be built
        $self->{BUILD_BITMAP} = 1;
        $self->{BITMAP_INDEX} = 0;
        $flow = 'no_value';
    } elsif ($x == 24 && $y == 255) {
        # 224255 First order statistical values marker operator
        _croak "$id No bit map defined"
            unless (defined $self->{CURRENT_BITMAP} || defined $self->{REUSE_BITMAP})
            && $self->{BITMAP_OPERATORS}[-1] eq '224000';
        if (defined $self->{REUSE_BITMAP}) {
            _croak "More 224255 encountered than current bit map allows"
                unless @{ $self->{REUSE_BITMAP}->[$isub] };
            $bm_idesc = undef;
        } else {
            _croak "More 224255 encountered than current bit map allows"
                unless @{$self->{CURRENT_BITMAP}};
            $bm_idesc = shift @{$self->{CURRENT_BITMAP}};
        }
        $flow = 'redo_bitmap';
    } elsif ($x == 25 && $y == 0) {
        # 225000 Difference statistical values follow
        push @{ $self->{BITMAP_OPERATORS} }, '225000';
        $self->{NUM_BITMAPS}++;
        # Mark that a bit map probably needs to be built
        $self->{BUILD_BITMAP} = 1;
        $self->{BITMAP_INDEX} = 0;
        $flow = 'no_value';
    } elsif ($x == 25 && $y == 255) {
        # 225255 Difference statistical values marker operator
        _croak "$id No bit map defined\n"
            unless (defined $self->{CURRENT_BITMAP} || defined $self->{REUSE_BITMAP})
            && $self->{BITMAP_OPERATORS}[-1] eq '225000';
        if (defined $self->{REUSE_BITMAP}) {
            _croak "More 225255 encountered than current bit map allows"
                unless @{ $self->{REUSE_BITMAP}->[$isub] };
            $bm_idesc = undef;
        } else {
            _croak "More 225255 encountered than current bit map allows"
                unless @{$self->{CURRENT_BITMAP}};
            $bm_idesc = shift @{$self->{CURRENT_BITMAP}};
        }
        # Must remember to change data width and reference value
        $self->{NUM_CHANGE_OPERATORS}++ if !$self->{DIFFERENCE_STATISTICAL_VALUE};
        $self->{DIFFERENCE_STATISTICAL_VALUE} = 1;
        $flow = 'redo_bitmap';
    } elsif ($x == 32 && $y == 0) {
        # 232000 Replaced/retained values follow, each one following a
        # descriptor 232255. Which value they are a replacement for is
        # defined by a bit map, which already may have been defined
        # (if descriptor 23700 is encountered), or will shortly be
        # defined by data present indicators (031031)
        push @{ $self->{BITMAP_OPERATORS} }, '232000';
        $self->{NUM_BITMAPS}++;
        # Mark that a bit map probably needs to be built
        $self->{BUILD_BITMAP} = 1;
        $self->{BITMAP_INDEX} = 0;
        $flow = 'no_value';
    } elsif ($x == 32 && $y == 255) {
        # 232255 Replaced/retained values marker operator
        _croak "$id No bit map defined"
            unless (defined $self->{CURRENT_BITMAP} || defined $self->{REUSE_BITMAP})
            && $self->{BITMAP_OPERATORS}[-1] eq '232000';
        if (defined $self->{REUSE_BITMAP}) {
            _croak "More 232255 encountered than current bit map allows"
                unless @{ $self->{REUSE_BITMAP}->[$isub] };
            $bm_idesc = undef;
        } else {
            _croak "More 232255 encountered than current bit map allows"
                unless @{$self->{CURRENT_BITMAP}};
            $bm_idesc = shift @{$self->{CURRENT_BITMAP}};
        }
        $flow = 'redo_bitmap';
    } elsif ($x == 35 && $y == 0) {
        # 235000 Cancel backward data reference
        undef $self->{REUSE_BITMAP};
        $self->{BACKWARD_DATA_REFERENCE} = $self->{NUM_BITMAPS} + 1;
        $flow = 'no_value';
    } elsif ($x == 36 && $y == 0) {
        # 236000 Define data present bit map
        undef $self->{CURRENT_BITMAP};
        $self->{BUILD_BITMAP} = 1;
        $self->{BITMAP_INDEX} = 0;
        $flow = 'no_value';
    } elsif ($x == 37 && $y == 0) {
        # 237000 Use defined data present bit map
        _croak "$id No previous bit map defined"
            unless defined $self->{BITMAPS};
        my %hash = @{ $self->{BITMAPS}->[$self->{NUM_BITMAPS}-1]->[$isub] };
        $self->{REUSE_BITMAP}->[$isub] = [sort {$a <=> $b} keys %hash];
        $flow = 'no_value';
    } elsif ($x == 37 && $y == 255) {
        # 237255 Cancel 'use defined data present bit map'
        _complain("$id No data present bit map to cancel")
            unless defined $self->{REUSE_BITMAP};
        undef $self->{REUSE_BITMAP};
        $flow = 'next';
    } elsif ($x == 41 && $y == 0) {
        # 241000 Define event
        _croak "$id Define event (not implemented)";
    } elsif ($x == 41 && $y == 255) {
        # 241255 Cancel define event
        _croak "$id Cancel define event (not implemented)";
    } elsif ($x == 42 && $y == 0) {
        # 242000 Define conditioning event
        _croak "$id Define conditioning event (not implemented)";
    } elsif ($x == 42 && $y == 255) {
        # 242255 Cancel define conditioning event
        _croak "$id Cancel define conditioning event (not implemented)";
    } elsif ($x == 43 && $y == 0) {
        # 243000 Categorial forecast values follow
        _croak "$id Categorial forecast values follow (not implemented)";
    } elsif ($x == 43 && $y == 255) {
        # 243255 Cancel categorial forecast values follow
        _croak "$id Cancel categorial forecast values follow (not implemented)";
    } else {
        _croak "$id Unknown data description operator";
    }

    return ($pos, $flow, $bm_idesc, @operators);
}

## Extract data from selected subsets in selected bufr objects, joined
## into a single ($data_refs, $desc_refs), to later be able to make a
## single BUFR message by calling encode_message. Also returns number
## of subsets extracted.
sub join_subsets {
    my $self = shift;
    my (@bufr, @subset_list);
    my $last_arg_was_bufr;
    my $num_objects = 0;
    while (@_) {
        my $arg = shift;
        if (ref($arg) eq 'Geo::BUFR') {
            $bufr[$num_objects++] = $arg;
            $last_arg_was_bufr = 1;
        } elsif (ref($arg) eq 'ARRAY') {
            _croak "Wrong input (multiple array refs) to join_subsets"
                unless $last_arg_was_bufr;
            $subset_list[$num_objects-1] = $arg;
            $last_arg_was_bufr = 0;
        } else {
            _croak "Input is not Geo::BUFR object or array ref in join_subsets";
        }
    }

    my ($data_refs, $desc_refs);
    my $n = 1; # Number of subsets included
    # Ought to check for common section 3 also?
    for (my $i=0; $i < $num_objects; $i++) {
        $bufr[$i]->rewind();
        my $isub = 1;
        if (!exists $subset_list[$i]) { # grab all subsets from this object
            while (not $bufr[$i]->eof()) {
                my ($data, $descriptors) = $bufr[$i]->next_observation();
                last if !$data;
                $self->_spew(2, "Joining subset %d from bufr object %d", $isub, $i) if $Spew;
                $data_refs->[$n] = $data;
                $desc_refs->[$n++] = $descriptors;
                $isub++;
            }
        } else { # grab the subsets specified, also inserting them in the specified order
            my $num_found = 0;
            while (not $bufr[$i]->eof()) {
                my ($data, $descriptors) = $bufr[$i]->next_observation();
                last if !$data;
                my $index = _get_index_in_list($subset_list[$i], $isub);
                if (defined $index) {
                    $self->_spew(2, "Joining subset %d from subset %d"
                                 . " in bufr object %d", $isub, $index, $i) if $Spew;
                    $data_refs->[$n + $index] = $data;
                    $desc_refs->[$n + $index] = $descriptors;
                    $num_found++;
                }
                $isub++;
            }
            _croak "Mismatch between number of subsets found ($num_found) and "
                . "expected from argument [@{$subset_list[$i]}] to join_subsets"
                    if $num_found != @{$subset_list[$i]};
            $n += $num_found;
        }
        $bufr[$i]->rewind();
    }
    $n--;
    return ($data_refs, $desc_refs, $n)
}

1;  # Make sure require or use succeeds.


__END__
# Below is documentation for the module. You'd better read it!

=pod

=encoding utf8

=head1 NAME

Geo::BUFR - Perl extension for handling of WMO BUFR files.

=head1 SYNOPSIS

  # A simple program to print decoded contents of a BUFR file. Note
  # that a more sophisticated program (bufrread.pl) is included in the
  # package

  use Geo::BUFR;

  Geo::BUFR->set_tableformat('BUFRDC'); # ECCODES is also possible
  Geo::BUFR->set_tablepath('path to BUFR tables');

  my $bufr = Geo::BUFR->new();

  $bufr->fopen('name of BUFR file');

  while (not $bufr->eof()) {
      my ($data, $descriptors) = $bufr->next_observation();
      print $bufr->dumpsections($data, $descriptors) if $data;
  }

  $bufr->fclose();


=head1 DESCRIPTION

B<BUFR> = B<B>inary B<U>niversal B<F>orm for the B<R>epresentation of
meteorological data. BUFR is approved by WMO (World Meteorological
Organization) as the standard universal exchange format for
meteorological observations, gradually replacing a lot of older
alphanumeric data formats.

This module provides methods for decoding and encoding BUFR messages,
and for displaying information in BUFR B and D tables and in BUFR flag
and code tables.

Installing this module also installs some programs: C<bufrread.pl>,
C<bufrresolve.pl>, C<bufrextract.pl>, C<bufrencode.pl>,
C<bufr_reencode.pl> and C<bufralter.pl>. See
L<https://wiki.met.no/bufr.pm/start> for examples of use. For the
majority of potential users of Geo::BUFR I would expect these programs
to be all that you will need Geo::BUFR for.

BUFR tables are not included in this module and must be installed
separately, see L</"BUFR TABLE FILES">.

Note that the core routines for encoding and decoding bitstreams are
implemented in C for speed.


=head1 METHODS

The C<get_> methods will return undef if the requested information is
not available. The C<set_> methods as well as C<fopen>, C<fclose>,
C<copy_from> and C<rewind> will always return 1, or croak if failing.

Create a new object:

  $bufr = Geo::BUFR->new();
  $bufr = Geo::BUFR->new($BUFRmessages);

The second form of C<new> is useful if you want to provide the BUFR
messages to decode directly as an input buffer (string). Note that
merely calling C<new($BUFRmessages)> will not decode anything in the
BUFR messages, for that you need to call C<next_observation()> from
the newly created object. You also have the option of providing the
BUFR messages in a file, using the no argument form of C<new()> and
then calling C<fopen>.

Associate the object with a file for reading of BUFR messages:

  $bufr->fopen($filename);

Close the associated file that was opened by fopen:

  $bufr->fclose();

Check for end-of-file (or end of the input buffer provided as argument
to C<new>):

  $bufr->eof();

Returns true if end-of-file (or end of input buffer) is reached, false
if not.

Ensure that next call to C<next_observation> will decode first subset
in first BUFR message:

  $bufr->rewind();

Copy from an existing object:

  $bufr1->copy_from($bufr2,$what);

If $what is 'all' or not provided, will copy everything in $bufr2 into
$bufr1, i.e. making a clone. If $what is 'metadata', only the metadata
in section 0, 1 and 3 will be copied (and all of section 2 if present).

Load B and D tables:

  $bufr->load_BDtables($table);

$table is optional, and should for BUFRDC be (base)name of a file
containing a BUFR table B or D, using the ECMWF BUFRDC naming
convention, i.e. [BD]'table_version'.TXT. For ECCODES, use last part
of path, e.g. on UNIX-like systems '0/wmo/18' for master tables and
'0/local/8/78/236' for local tables, or both if that is needed,
e.g. '0/wmo/18,0/local/8/78/236'. If no argument is provided,
C<load_BDtables()> will use BUFR section 1 information in the $bufr
object to decide which tables to load (which for ECCODES might be up
to 4 table files, both local and master tables). Previously loaded
tables are kept in memory, and C<load_BDtables> will return
immediately if the tables already have been loaded. Will die (croak)
if tables cannot be found, but (in the no argument version) not if
these are local tables (Local table version number > 0) and the
corresponding master tables exist (Local table version number = 0),
which then will be loaded instead. Returns table version for the
tables loaded (see C<get_table_version>).

Load C table:

  $bufr->load_Ctable($table);

$table is optional. This will load the flag and code tables (if not
already loaded), which in ECMWF BUFRDC are put in tables
C'table_version'.TXT (not to be confused with WMO BUFR table C, which
contains the operator descriptors). For $table in ECCODES, use (just
like for C<load_BDtables>) last part of path, e.g. on UNIX-like
systems '0/wmo/18' for master tables and '0/local/8/78/236' for local
tables, or both if that is needed,
e.g. '0/wmo/18,0/local/8/78/236'. Will for ECCODES then load all
tables in the codetables subdirectory. If no arguments are provided,
C<load_Ctable()> will use BUFR section 1 information in the $bufr
object to decide which table(s) to load. Will die (croak) if table
cannot be found, but not if this is a local table and the
corresponding master table exists, which then will be loaded
instead. Returns table version for the table loaded.

Get next observation (next subset in current BUFR message or first subset
in next message):

  ($data, $descriptors) = $bufr->next_observation();

where $descriptors is a reference to the array of fully expanded
descriptors for this subset, $data is a reference to the corresponding
values. This method is meant to be used to iterate through all BUFR
messages in the file or input buffer (see C<new>) associated with the
$bufr object, see example program in L</SYNOPSIS>. Whenever a new BUFR
message is reached, section 0-3 will also be decoded, the contents of
which is then available through the access methods listed below. This
is the main BUFR decoding routine in Geo::BUFR, and will call
C<load_BDtables()> internally (unless decoding of section 4 has been
turned off by use of C<set_nodata> or C<set_filter_db>), but not
C<load_Ctable>. Consult L</"DECODING/ENCODING"> if you want more
precise info about what is returned in $data and $descriptors.

C<next_observation> will return the empty list (so both $data and
$descriptors will be undef) in the following cases: if there are no
more BUFR messages in file/input buffer (so next call to C<eof()> will
return false), if no decoding of section 4 was requested in
C<set_nodata>, if filtering was turned on in C<set_filter_db> and the
BUFR message met the filter criteria in the user defined callback
function, or if the BUFR message contained 0 subsets. If you need to
distinguish the first case from the rest, one way would be to check
C<get_current_subset_number()> which will return 0 only in this first
case.

If an error is met during decoding, it is possible to trap the error
in an eval and then continue calling C<next_observation> (as
demonstrated in source code of C<bufrread.pl>). Care has been taken
that BUFR messages with incorrectly stated BUFR length should not
cause later proper BUFR messages to be skipped. But the possibility of
an erroneous last BUFR message in file led to abandonment of the
convenient feature retained until Geo::BUFR version 1:25 of C<eof>
always returning false if there were no more BUFR messages in
file/input buffer. Instead you should expect last call to
C<next_observation> to return false (empty list).

Filter BUFR messages:

  $bufr->set_filter_cb(\&callback,@args);

Here user is responsible for defining the callback subroutine. This
subroutine will then be called in C<next_observation> (with arguments
@args if provided) right after section 3 is decoded, and, if returning
true, will cause C<next_observation> to return immediately, without
even trying to decode section 4 (the data section). Here is a simple
example of such a callback (without arguments), filtering on AHL and
Data category (table A) of the BUFR message.

  sub callback {
      my $obj = shift;
      return 1 if $obj->get_data_category != 0;
      my $ahl = $obj->get_current_ahl() || '';
      return ($ahl =~ /^IS.... (ENMI|TEST)/);
  }

Check result of filtering:

  $bufr->is_filtered();

Will return true (1) if C<next_observation> returned immediately as
described for C<set_filter_cb> above. But calling C<is_filtered>
should rarely be needed, as in most cases the simple check 'next if
!$data' after calling C<next_observation> would be the natural way to
proceed.

Print the contents of a subset in BUFR message:

  print $bufr->dumpsections($data,$descriptors,$options);

$options is optional. If this is first subset in message, will start
by printing message number and, if this is first message in a GTS
bulletin, AHL (Abbreviated Header Line), as well as contents of
sections 0, 1 and 3. For section 4, will also print subset
number. $options should be an anonymous hash with possible keys
'width' and 'bitmap', e.g. { width => 20, bitmap => 0 }. 'bitmap'
controls which of C<dumpsection4> and C<dumpsection4_with_bitmaps>
will be called internally by C<dumpsections>. Default value for
'bitmap' is 1, causing C<dumpsection4_with_bitmaps> to be
called. 'width' controls the value of $width used by the
C<dumpsection4...> methods, default is 15. If you intend to provide
the output from C<dumpsections> as input to C<reencode_message>, be
sure to set 'bitmap' to 0, and 'width' not smaller than the largest
data width in bytes among the descriptors with unit CCITTIA5 occuring
in the message.

Normally C<dumpsections> is called after C<next_observation>, with
same arguments $data,$descriptors as returned from this call. From the
examples given at L<https://wiki.met.no/bufr.pm/start#bufrreadpl> you
can get an impression of what the output might look like. If
C<dumpsections> does not give you exactly what you want, you might
prefer to instead call the individual dumpsection methods below.

Print the contents of sections 0-3 in BUFR message:

  print $bufr->dumpsection0();
  print $bufr->dumpsection1();
  print $bufr->dumpsection2($sec2_code_ref);
  print $bufr->dumpsection3();

C<dumpsection2> returns an empty string if there is no optional
section in the message. The argument should be a reference to a
subroutine which takes the optional section as (a string) argument and
returns the text you want displayed after the 'Length of section:'
line. For general BUFR messages probably the best you can do is
displaying a hex dump, in which case

  sub {return '    Hex dump:' . ' 'x26 . unpack('H*',substr(shift,4))}

might be a suitable choice for $sec2_code_ref. For most applications
there should be no real need to call C<dumpsection2>.

Print the data of a subset (descriptor, value, name and unit):

  print $bufr->dumpsection4($data,$descriptors,$width);
  print $bufr->dumpsection4_with_bitmaps($data,$descriptors,$width);

$width fixes the number of characters used for displaying the data
values, and is optional (defaults to 15). $data and $descriptors are
references to arrays of data values and BUFR descriptors respectively,
likely to have been fetched from C<next_observation>. Code and flag
values will be resolved if a C table has been loaded, i.e. if
C<load_Ctable> has been called earlier on. C<dumpsection4_with_bitmaps>
will display the bit-mapped values side by side with the corresponding
data values. If there is no bit-map in the BUFR message,
C<dumpsection4_with_bitmaps> will provide same output as
C<dumpsection4>. See L</"DECODING/ENCODING"> for some more information
about what is printed, and
L<https://wiki.met.no/bufr.pm/start#bufrreadpl> for real life examples
of output.

Set verbose level:

  Geo::BUFR->set_verbose($level); # 0 <= $level <= 6
  $bufr->set_verbose($level);

Some info about what is going on in Geo::BUFR will be printed to
STDOUT if $level > 0. With $level set to 1, all that is printed is the
B, C and D tables used (with full path). Each line of verbose output
starts with 'BUFR.pm: ', except for the level 6 specific
output. Setting verbose level > 1 might be helpful when debugging, or
for example if you want to extract as much information as possible
from an incorrectly formatted BUFR message.

No decoding of section 4 (data section):

  Geo::BUFR->set_nodata($n);
 - $n=1 (or not provided): Skip decoding of section 4 (might speed up
   processing considerably if only metadata in section 1-3 is sought for)
 - $n=0: Decode section 4 (default in Geo::BUFR)

No decoding of quality information:

  Geo::BUFR->set_noqc($n);
 - $n=1 (or not provided): Don't decode quality information (more
   specifically: skip all descriptors after 222000)
 - $n=0: Decode quality information (default in Geo::BUFR)

Enable/disable strict checking of BUFR format for recoverable errors
(like using BUFR compression for one subset message etc):

  Geo::BUFR->set_strict_checking($n);
 - $n=0: disable checking (default in Geo::BUFR)
 - $n=1: warn (carp) if error but continue decoding
 - $n=2: die (croak) if error

Confer L</STRICT CHECKING> for details of what is being checked if
strict checking is enabled.

Show all BUFR table C operators (data description operators, F=2) as well
as all replication descriptors (F=1) when calling dumpsection4:

  Geo::BUFR->set_show_all_operators($n);
 - $n=1 (or not provided): Show replication descriptors and all operators
 - $n=0: Show no replication descriptors and only the really informative
         data description operators (default in Geo::BUFR)

C<set_show_all_operators(1)> cannot be combined with C<dumpsections>
with bitmap option set (which is the default).

Set or get tableformat:

  Geo::BUFR->set_tableformat($tableformat);
  $tableformat = Geo::BUFR->get_tableformat();

Set or get tablepath:

  Geo::BUFR->set_tablepath($tablepath);
  $tablepath = Geo::BUFR->get_tablepath();

Get table version:

  $table_version = $bufr->get_table_version($table);

$table is optional. Return table version from $table if provided, or
else from section 1 information in the currently processed BUFR
message. For BUFRDC, this is a stripped down version of table name. If
for example $table = 'B0000000000088013001.TXT', will return
'0000000000088013001'. For ECCODES, this is last path of table
location (e.g. '0/wmo/29'), and a stringified list of two such paths
(master and local) if local tables are used
(e.g. '0/wmo/29,0/local/8/78/236'). Returns undef if impossible to
determine table version.

Get max master table version available:

  $table_version = $bufr->get_max_table_version();

Return table version for the latest master table found in tablepath,
in the same format as get_table_version. For use when master table
version is not known, e.g. in bufrresolve.pl.

Get number of subsets:

  $nsubsets = $bufr->get_number_of_subsets();

Get current subset number:

  $subset_no = $bufr->get_current_subset_number();

If decoding of section 4 has been skipped (due to use of C<set_nodata>
or C<set_filter_cb>), will return number of subsets. For a BUFR
message with 0 subsets, will actually return 1 (a bit weird perhaps,
but then this is a really weird kind of BUFR message to handle).

Get current message number:

  $message_no = $bufr->get_current_message_number();

Get current BUFR message:

    $binary_msg = get_bufr_message();

This returns the original raw (binary, not the decoded) BUFR
message. An empty string will be returned if no BUFR message is found,
or if the currently processed BUFR message is erroneous (even if
section 4 is not decoded, there will at least be a check for finding
'7777' at expected end of BUFR message, as calculated from length of
BUFR message decoded from section 0).

Get Abbreviated Header Line (AHL) before current message:

  $ahl = $bufr->get_current_ahl();

Get GTS starting line before current message:

  $ahl = $bufr->get_current_gts_starting_line();

Get GTS end of message after current message:

  $ahl = $bufr->get_current_gts_eom();

Currently supporting the notation of the International Alphabet No. 5,
i.e.  \001\r\r\n<csn>\r\r\n for GTS starting line with 3 or 5 digits for
<csn> (channel sequence number), and \r\r\n\003 for GTS end of message.
But ZCZC/NNNN notation (International Telegraph Alphabet No. 2) might be
provided in a future version of Geo::BUFR if requested.

Note that the definition of GTS starting line and AHL used in
Geo::BUFR differs slightly from that of the Manual on the GTS. In the
Manual the Abbreviated heading actually starts with \r\r\n, which in
Geo::BUFR for convenience is considered part of the GTS starting
line, since this provides for nicer output when displaying AHLs.

Check length of BUFR message (as stated in section 0):

    $bufr->bad_bufrlength();

Will return true (1) if no '7777' is found at the end of BUFR message
(as calculated from the stated length of BUFR message in section 0),
which usually means that the BUFR message is badly corrupted
(e.g. truncated). But note that there should be no need to call
C<bad_bufrlength> if section 4 is decoded, as in this case you should
expect C<next_observation> to die with a more precise error message
describing the kind of corruption found. If no decoding of section 4
is done (because C<set_nodata> or C<set_filter_cb> were called),
however, C<next_observation> is likely not to throw an error, and you
can use C<bad_bufrlength> to decide what to do next (see source code of
C<bufrextract.pl> for example of use).

Accessor methods for section 0-3:

  $bufr->set_<variable>($variable);
  $variable = $bufr->get_<variable>();

where E<lt>variableE<gt> is one of

  bufr_length (get only)
  bufr_edition
  master_table
  subcentre
  centre
  update_sequence_number
  optional_section (0 or 1)
  data_category
  int_data_subcategory
  loc_data_subcategory
  data_subcategory
  master_table_version
  local_table_version
  year_of_century
  year
  month
  day
  hour
  minute
  second
  local_use
  number_of_subsets
  observed_data (0 or 1)
  compressed_data (0 or 1)
  descriptors_unexpanded

C<set_year_of_century(0)> will set year of century to 100.
C<get_year_of_century> will for BUFR edition 4 calculate year of
century from year in section 1.


Encode a new BUFR message:

  $new_message = $bufr->encode_message($data_refs,$desc_refs);

where $desc_refs->[$i] is a reference to the array of fully expanded
descriptors for subset number $i ($i=1 for first subset),
$data_refs->[$i] is a reference to the corresponding values, using
undef for missing values. The required metadata in section 0, 1 and 3
must have been set in $bufr before calling this method. See
L</"DECODING/ENCODING"> for meaning of 'fully expanded descriptors'.

Encode a (single subset) NIL message:

  $new_message = $bufr->encode_nil_message($stationid_ref,$delayed_repl_ref);

$delayed_repl_ref is optional. In section 4 all values will be set to
missing except delayed replication factors and the (descriptor, value)
pairs in the hashref $stationid_ref. $delayed_repl_ref (if provided)
should be a reference to an array of data values for all descriptors
031001 and 031002 occuring in the message (these values must all be
nonzero), e.g. [3,1,2] if there are 3 such descriptors which should
have values 3, 1 and 2, in that succession. If $delayed_repl_ref is
omitted, all delayed replication factors will be set to 1. The
required metadata in section 0, 1 and 3 must have been set in $bufr
before calling this method (although number of subsets and BUFR
compression will automatically be set to 1 and 0 respectively,
whatever value they had before).

Reencode BUFR message(s):

  $new_messages = $bufr->reencode_message($decoded_messages,$width);

$width is optional. Takes a text $decoded_messages as argument and
returns a (binary) string of BUFR messages which, when printed to file
and then processed by C<bufrread.pl> with no output modifying options set
(except possibly C<--width>), would give output equal to
$decoded_messages. If C<bufrread.pl> is to be called with C<--width
$width>, this $width must be provided to C<reencode_message> also.

Join subsets from several messages:

 ($data_refs,$desc_refs,$nsub) = Geo::BUFR->join_subsets($bufr_1,$subset_ref_1,
     ... $bufr_n,$subset_ref_n);

where each $subset_ref_i is optional. Will return the data and
descriptors needed by C<encode_message> to encode a multi subset
message, extracting the subsets from the first message of each $bufr_i
object. All subsets in (first message of) $bufr_i will be used, unless
next argument is an array reference $subset_ref_i, in which case only
the subset numbers listed will be included, in the order specified. On
return $nsub will contain the total number of subsets thus
extracted. After a call to C<join_subsets>, the metadata (of the first
message) in each object will be available through the C<get_>-methods,
while a call to C<next_observation> will start extracting the first
subset in the first message. Here is an example of use, fetching first
subset from bufr object 1, all subsets from bufr object 2, and subsets
4 and 2 from bufr object 3, then building up a new multi subset BUFR
message (which will succeed only if the bufr objects all have the same
descriptors in section 3):

  my ($data_refs,$desc_refs,$nsub) = Geo::BUFR->join_subsets($bufr1,
      [1],$bufr2,$bufr3,[4,2]);
  my $new_bufr = Geo::BUFR->new();
  # Get metadata from one of the objects, then reset those metadata
  # which might not be correct for the new message
  $new_bufr->copy_from($bufr1,'metadata');
  $new_bufr->set_number_of_subsets($nsub);
  $new_bufr->set_update_sequence_number(0);
  $new_bufr->set_compressed_data(0);
  my $new_message = $new_bufr->encode_message($data_refs,$desc_refs);

Extract BUFR table B information for an element descriptor:

  ($name,$unit,$scale,$refval,$width) = $bufr->element_descriptor($desc);

Will fetch name, unit, scale, reference value and data width in bits
for element descriptor $desc in the last table B loaded in the $bufr
object. Returns false if the descriptor is not found.

Extract BUFR table D information for a sequence descriptor:

  @descriptors = $bufr->sequence_descriptor($desc);
  $string = $bufr->sequence_descriptor($desc);

Will return the descriptors in a direct (nonrecursive) lookup for the
sequence descriptor $desc in the last table D loaded in the $bufr
object. In scalar context the descriptors will be returned as a space
separated string. Returns false if the descriptor is not found.

Resolve BUFR table descriptors (for printing):

  print $bufr->resolve_descriptor($how,@descriptors);

where $how is one of 'fully', 'partially', 'simply' and 'noexpand'.
Returns a text string suitable for printing information about the BUFR
table descriptors given. $how = 'fully': Expand all D descriptors
fully into B descriptors, with name, unit, scale, reference value and
width (each on a numbered line, except for replication operators which
are not numbered). $how = 'partially': Like 'fully', but expand D
descriptors only once and ignore replication. $how = 'noexpand': Like
'partially', but do not expand D descriptors at all. $how = 'simply':
Like 'partially', but list the descriptors on one single line with no
extra information provided. The relevant B/D table must have been
loaded before calling C<resolve_descriptor>.

Resolve flag table value (for printing):

  print $bufr->resolve_flagvalue($value,$flag_table,$B_table,$num_leading_spaces);

Last argument is optional and defaults to 0.  Examples:

  print $bufr->resolve_flagvalue(4,8006,'B0000000000098013001.TXT') # BUFRDC
  print $bufr->resolve_flagvalue(4,8006,'0/wmo/13')       # ECCODES, master table
  print $bufr->resolve_flagvalue(4,8193,'0/local/1/98/0') # ECCODES, local table

Print the contents of BUFR code (or flag) table:

  print $bufr->dump_codetable($code_table,$table);

where in BUFRDC $table is (base)name of the C...TXT file containing
the code tables, or just $version as returned by C<get_table_version>
or C<get_max_table_version>. For ECCODES $table is path to the
codetables, like for C<resolve_flagvalue>, see examples above.

C<resolve_flagvalue> and C<dump_codetable> will return empty string if
flag value or code table is not found.


Manipulate binary data (these are implemented in C for speed and primarily
intended as module internal subroutines):

  $value = Geo::BUFR->bitstream2dec($bitstream,$bitpos,$num_bits);

Extracts $num_bits bits from $bitstream, starting at bit $bitpos. The
extracted bits are interpreted as a nonnegative integer.  Returns
undef if all bits extracted are 1 bits.

  $ascii = Geo::BUFR->bitstream2ascii($bitstream,$bitpos,$num_bytes);

Extracts $num_bytes bytes from bitstream, starting at $bitpos, and
interprets the extracted bytes as an ascii string. Returns undef if
the extracted bytes are all 1 bits.

  Geo::BUFR->dec2bitstream($value,$bitstream,$bitpos,$bitlen);

Encodes nonnegative integer value $value in $bitlen bits in
$bitstream, starting at bit $bitpos. Last byte will be padded with 1
bits. $bitstream must have been initialized to a string long enough to
hold $value. The parts of $bitstream before $bitpos and after last
encoded byte are not altered.

  Geo::BUFR->ascii2bitstream($ascii,$bitstream,$bitpos,$width);

Encodes ASCII string $ascii in $width bytes in $bitstream, starting at
$bitpos. Last byte will be padded with 1 bits. $bitstream must have
been initialized to a string long enough to hold $ascii. The parts of
$bitstream before $bitpos and after last encoded byte are not altered.

  Geo::BUFR->null2bitstream($bitstream,$bitpos,$num_bits);

Sets $num_bits bits in bitstream starting at bit $bitpos to 0 bits.
Last byte affected will be padded with 1 bits. $bitstream must be at
least $bitpos + $num_bits bits long. The parts of $bitstream before
$bitpos and after last encoded byte are not altered.

=head1 DECODING/ENCODING

The term 'fully expanded descriptors' used in the description of
C<encode_message> (and C<next_observation>) in L</METHODS> might need
some clarification. The short version is that the list of descriptors
should be exactly those which will be written out by running
C<dumpsection4> (or C<bufrread.pl> without any modifying options set)
on the encoded message. If you don't have a similar BUFR message at
hand to use as an example when wanting to encode a new message, you
might need a more specific prescription. Which is that for every data
value which occurs in the section 4 bitstream, you should include the
corresponding BUFR descriptor, using the artificial 999999 for
associated fields following the 204Y operator, I<and> including the
data operator descriptors 22[2345]000 and 23[2567]000 with data value
set to the empty string, if these occurs among the descriptors in
section 3 (rather: in the expansion of these, use C<bufrresolve.pl> to
check!). Element descriptors defining new reference values (following
the 203Y operator) will have F=0 (first digit in descriptor) replaced
with F=9 in C<next_observation>, while in C<encode_message> both F=0
and F=9 will be accepted for new reference values. When encoding
delayed repetition you should repeat the set of data (and descriptors)
to be repeated the number of times indicated by 031011 or 031012 (if
given the feedback that this is considered cumbersome, an option for
including the set of data/descriptors just once might be added later,
both for encoding end decoding).

Some words about the procedure used for decoding and encoding data in
section 4 might shed some light on this choice of design.

When decoding section 4 for a subset, first of all the BUFR
descriptors provided in section 3 are expanded as far as possible
without looking at the actual bitstream, i.e. by eliminating
nondelayed replication descriptors (F=1) and by using BUFR table D to
expand sequence descriptors (F=3). Then, for each of the thus expanded
descriptors, the data value is fetched from the bitstream according to
the prescriptions in BUFR table B, applying the data operator
descriptors (F=2) from BUFR table C as they are encountered, and
reexpanding the remaining descriptors every time a delayed replication
factor is fetched from bitstream. The resulting set of data values is
returned in an array @data, with the corresponding B (and sometimes
also some C) BUFR table descriptors in an array
@descriptors. C<next_observation> returns references to these two
arrays. For convenience, some of the data operator descriptors without
a corresponding data value (like 222000) are included in the
@descriptors because they are considered to provide valuable
information to the user, with corresponding value in @data set to the
empty string. These descriptors without a value are written by the
dumpsection4 methods on unnumbered lines, thereby distinguishing them
from descriptors corresponding to 'real' data values in section 4,
which are numbered consecutively.

Encoding a subset is done in a very similar way, by expanding the
descriptors in section 3 as described above, but instead fetching the
data values from the @data array that the user supplies (actually
@{$data_refs->{$i}} where $i is subset number), and then finally
encoding this value to bitstream.

The input parameter $desc_ref to C<encode_message> is in fact not
strictly necessary to be able to encode a new BUFR message. But there
is a good reason for requiring it. During encoding the descriptors
from expanding section 3 will consecutively be compared with the
descriptors in the user supplied $desc_ref, and if these at some point
differ, encoding will be aborted with an error message stating the
first descriptor which deviated from the expected one. By requiring
$desc_ref as input, the risk for encoding an erroneous section 4 is
thus greatly reduced, and also provides the user with highly valuable
debugging information if encoding fails.

When decoding character data (unit CCITTIA5), any null characters
found are silently (unless $Strict_checking is set) removed, as well
as leading and trailing white space.

=head1 BUFR TABLE FILES

The BUFR table files should follow the format and naming conventions
used by one of these two ECMWF software packages: either BUFRDC
(download from https://confluence.ecmwf.int/display/BUFR/Releases), or
ecCodes (download from https://confluence.ecmwf.int/display/ECC/Releases).

The utility programs in Geo::BUFR will look for table files by default
in the standard installation directories, which in Unix-like systems
will be /usr/local/lib/bufrtables for BUFRDC and
/usr/local/share/eccodes/definitions/bufr/tables for ecCodes. You can
change that behaviour by either providing the environment variable
BUFR_TABLES, or setting path explicitly by using the
C<--tablepath>. Note that while BUFR_TABLES is a well known concept in
BUFRDC software, the closest you get in ecCodes is probably
ECCODES_DEFINITION_PATH (see
e.g. https://confluence.ecmwf.int/display/ECC/BUFR%3A+Local+configuration),
for which BUFR_TABLES should (or could) be set to
ECCODES_DEFINITION_PATH/bufr/tables (again in Unix-like systems).

=head1 STRICT CHECKING

The package global $Strict_checking defaults to

  0: Ignore recoverable errors in BUFR format met during decoding or encoding

but can be changed to

  1: Issue warning (carp) but continue decoding/encoding

  2: Croak (die) instead of carp

by calling C<set_strict_checking>. The following is checked for when
$Strict_checking is set to 1 or 2:

=over

=item *

Total length of BUFR message as stated in section 0 bigger than actual length

=item *

Excessive bytes in section 4 (section longer than computed from section 3)

=item *

Compression set in section 3 for one subset message (BUFR reg. 94.6.3.2)

=item *

Bits 3-8 in octet 7 in section 3 not set to zero

=item *

Local reference value for compressed character data not having all
bits set to zero (94.6.3.2.i)

=item *

Illegal flag values (rightmost bit set for non-missing values) (Note (9)
to Table B in FM 94 BUFR)

=item *

Character data not being CCITTIA5 (Note (9) in FM 94 BUFR first page)

=item *

Null characters in CCITTIA5 data (Note (4) to Table B in FM 94 BUFR)

=item *

Missing CCITTIA5 value encoded as spaces

=item *

Invalid date and/or time in section 1

=item *

Cancellation operators (20[1-4]00, 203255 etc) when there is nothing to cancel

=item *

0 subsets in message. This may not break any formal rules, but is
likely to cause problems in further data processing (and Geo::BUFR
will not allow you to encode or reencode such a message anyway).

=item *

Leaving out descriptors to be repeated when corresponding delayed
replication/repetition factor in section 4 is 0 and this is last data
item. E.g. ending 'Data descriptors unexpanded' in section 3 with
'106000 031001' when data value for 031001 is 0. This (mal)practice,
however, defies the very point of replication operations (BUFR
reg. 94.5.4). Presumably the purpose is to save some space in the BUFR
message, but then why not leave out also '106000 031001' and the (0)
data value for 031001?

=item *

Value encoded using BUFR compression which would be too big to encode
without compression. For example, for a data descriptor with data
width 9 bits a value of 510 ought to be the biggest value possible to
encode, but in a multisubset message using BUFR compression it is
possible to encode almost arbitrarily large values in single subsets
as long as the average over all subsets is contained within 9
bits. This is not breaking any formal rules, but almost certainly not
desirable.

=back

Plus some few more checks not considered interesting enough to be
mentioned here.

=begin more_on_strict_checking

These are:
- Replication of 0 descriptors (F=1, X=0)
- year_of_century > 100
- 206Y operator is not followed by a local descriptor


=end more_on_strict_checking

=head1 BUGS OR MISSING FEATURES

Some BUFR table C operators are not implemented or are untested,
mainly because I do not have access to BUFR messages containing such
operators. If you happen to come over a BUFR message which the current
module fails to decode properly, I would therefore highly appreciate
if you could mail me this.

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 CREDITS

I am very grateful to Alvin Brattli, who (while employed as a
researcher at the Norwegian Meteorological Institute) wrote the first
version of this module, with the sole purpose of being able to decode
some very specific BUFR satellite data, but still provided the main
framework upon which this module is built.

=head1 SEE ALSO

Guide to WMO Table Driven Code Forms: FM 94 BUFR and FM 95 CREX; Layer 3:
Detailed Description of the Code Forms (for programmers of encoder/decoder
software)

L<https://wiki.met.no/bufr.pm/start>

=head1 COPYRIGHT

Copyright (C) 2010-2025 MET Norway

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
