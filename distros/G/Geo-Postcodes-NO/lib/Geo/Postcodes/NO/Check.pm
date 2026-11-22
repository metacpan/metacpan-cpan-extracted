package Geo::Postcodes::NO::Check;

use 5.008;
use strict;
use warnings;
use utf8;

use Encode qw(decode FB_CROAK);

our $VERSION = '1.00';

my $DATA_ENV          = 'GEO_POSTCODES_NO_DATA';
my $DATA_ENCODING_ENV = 'GEO_POSTCODES_NO_ENCODING';
my $DEFAULT_ENCODING  = 'cp1252';

my %COUNTY = (
    '03' => 'OSLO',
    '11' => 'ROGALAND',
    '15' => 'MØRE OG ROMSDAL',
    '18' => 'NORDLAND',
    '21' => 'SVALBARD',
    '22' => 'JAN MAYEN',
    '31' => 'ØSTFOLD',
    '32' => 'AKERSHUS',
    '33' => 'BUSKERUD',
    '34' => 'INNLANDET',
    '39' => 'VESTFOLD',
    '40' => 'TELEMARK',
    '42' => 'AGDER',
    '46' => 'VESTLAND',
    '50' => 'TRØNDELAG',
    '55' => 'TROMS',
    '56' => 'FINNMARK',
);

sub county_table {
    return \%COUNTY;
}

sub main {
    shift if @_ && defined $_[0] && $_[0] eq __PACKAGE__;

    if (@_ != 1) {
        print STDERR "Usage: check-postcodes-no /path/to/postnummerregister-ansi.txt\n";
        return 64;
    }

    my $path = shift;
    $ENV{$DATA_ENV} = $path;

    my $ok = eval { check($path); 1 };
    if (!$ok) {
        print STDERR $@;
        return 1;
    }

    return 0;
}

sub check {
    my $path = shift;

    $ENV{$DATA_ENV} = $path if defined $path && length $path;
    $path = $ENV{$DATA_ENV}
        or die "$DATA_ENV is not set\n";

    my $encoding = $ENV{$DATA_ENCODING_ENV} || $DEFAULT_ENCODING;
    my ($records, $seen) = read_records($path, $encoding, county_prefixes => [ keys %COUNTY ]);
    my $record_count = @$records;

    require Geo::Postcodes::NO;

    my $loaded_path = Geo::Postcodes::NO::data_file();
    die "Geo::Postcodes::NO loaded '$loaded_path', expected '$path'\n"
        unless $loaded_path eq $path;

    my $loaded_encoding = Geo::Postcodes::NO::data_encoding();
    die "Geo::Postcodes::NO used encoding '$loaded_encoding', expected '$encoding'\n"
        unless $loaded_encoding eq $encoding;

    my @loaded = Geo::Postcodes::NO::get_postcodes();
    die "Geo::Postcodes::NO loaded " . scalar(@loaded) . " postcodes, expected $record_count\n"
        unless @loaded == $record_count;

    for my $postcode (sort keys %$seen) {
        die "Postcode $postcode was validated but not loaded by Geo::Postcodes::NO\n"
            unless Geo::Postcodes::NO::valid($postcode);

        die "Postcode $postcode has no county in Geo::Postcodes::NO\n"
            unless defined Geo::Postcodes::NO::county_of($postcode);
    }

    print "OK: $record_count postcodes loaded from $path using $encoding\n";
    return $record_count;
}

sub validate_file {
    my ($path, $encoding) = @_;
    my ($records, $seen) = read_records($path, $encoding);
    return (scalar @$records, $seen);
}

sub read_records {
    my ($path, $encoding, %option) = @_;
    $encoding = $DEFAULT_ENCODING unless defined $encoding && length $encoding;

    open my $fh, '<:raw', $path or die "Cannot read postcode data $path: $!\n";
    my $raw = do { local $/; <$fh> };

    my $decode_subject = defined $option{decode_subject} ? $option{decode_subject} : $path;
    my $data = eval { decode($encoding, $raw, FB_CROAK) };
    die "Cannot decode $decode_subject as $encoding: $@" if $@;

    $data =~ s/\r\n?/\n/g;

    my %county_prefix = map { $_ => 1 } @{ $option{county_prefixes} || [] };
    my @records;
    my %seen;
    my %borough_name;
    my $line_no = 0;

    for my $line (split /\n/, $data) {
        ++$line_no;
        next unless length $line;

        my @fields = split /\t/, $line, -1;
        _line_error($line_no, $path, $option{line_errors_include_path}, 'expected 5 tab-separated fields')
            unless @fields == 5;

        my ($postcode, $location, $borough_number, $borough, $category) = @fields;

        _line_error($line_no, $path, $option{line_errors_include_path}, "invalid postcode '$postcode'")
            unless defined $postcode && $postcode =~ /\A[0-9]{4}\z/;
        _line_error($line_no, $path, $option{line_errors_include_path}, "empty location for postcode $postcode")
            unless defined $location && length $location;
        _line_error($line_no, $path, $option{line_errors_include_path}, "invalid borough number '$borough_number'")
            unless defined $borough_number && $borough_number =~ /\A[0-9]{4}\z/;
        _line_error($line_no, $path, $option{line_errors_include_path}, "empty borough for postcode $postcode")
            unless defined $borough && length $borough;
        _line_error($line_no, $path, $option{line_errors_include_path}, "invalid category '$category'")
            unless defined $category && $category =~ /\A[GPBS]\z/;
        _line_error($line_no, $path, $option{line_errors_include_path}, "duplicate postcode '$postcode'")
            if $seen{$postcode}++;
        _line_error($line_no, $path, $option{line_errors_include_path},
            "conflicting borough names for number '$borough_number': '$borough_name{$borough_number}' vs '$borough'")
            if defined $borough_name{$borough_number} && $borough_name{$borough_number} ne $borough;
        $borough_name{$borough_number} = $borough;

        if (%county_prefix) {
            _line_error($line_no, $path, $option{line_errors_include_path}, "unknown county for borough number '$borough_number'")
                unless $county_prefix{substr($borough_number, 0, 2)};
        }

        push @records, [ $postcode, $location, $borough_number, $borough, $category ];
    }

    die "No postcode records found in $path\n" unless @records;

    return (\@records, \%seen);
}

sub _line_error {
    my ($line_no, $path, $include_path, $message) = @_;
    my $where = $include_path ? "Line $line_no in $path" : "Line $line_no";
    die "$where: $message\n";
}

1;

__END__

=encoding UTF-8

=head1 NAME

Geo::Postcodes::NO::Check - Validate Bring postcode files for Geo::Postcodes::NO

=head1 SYNOPSIS

  check-postcodes-no /path/to/postnummerregister-ansi.txt

=head1 DESCRIPTION

Internal validator used by the C<check-postcodes-no> shell wrapper. It validates
Bring postcode files before they are used through C<GEO_POSTCODES_NO_DATA> and
verifies that C<Geo::Postcodes::NO> can load the same file with the same
encoding. C<Geo::Postcodes::NO> also uses this module when loading its data, so
the command-line checker and runtime loader share the same field validation.

=head1 FUNCTIONS

=head2 main

Command-line entry point used by F<script/check-postcodes-no>.

=head2 check

  Geo::Postcodes::NO::Check::check($path);

Validates the file, including known county prefixes, sets C<GEO_POSTCODES_NO_DATA>
when C<$path> is supplied, and checks that C<Geo::Postcodes::NO> loads the same
postcode count.

=head2 county_table

  my $table = Geo::Postcodes::NO::Check::county_table();

Returns a reference to the hash mapping two-digit county prefixes to county
names. This is the single source of truth for which county prefixes are valid;
C<Geo::Postcodes::NO> derives its county table from it.

=head2 validate_file

  my ($records, $seen) = Geo::Postcodes::NO::Check::validate_file($path, $encoding);

Validates the file and returns the record count and a hash reference of seen
postcodes.

=head2 read_records

  my ($records, $seen) = Geo::Postcodes::NO::Check::read_records($path, $encoding);

Parses and validates the file. C<$records> is an array reference containing one
array reference per postcode row.

=head1 ENVIRONMENT

=head2 GEO_POSTCODES_NO_DATA

Set by the wrapper to the postcode file argument.

=head2 GEO_POSTCODES_NO_ENCODING

Optional encoding name passed to C<Encode>. Defaults to C<cp1252>.

=head1 AUTHOR

Arne Sommer <perl@bbop.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
