package Geo::Postcodes::NO;

use 5.008;
use strict;
use warnings;
use utf8;

use File::Spec ();
use Geo::Postcodes::NO::Check ();

our $VERSION           = '1.00';

our $SOURCE_URL        = 'https://www.bring.no/postnummerregister-ansi.txt';
our $DATA_VALID_FROM   = '2026-10-01';
our $DATA_FILE         = 'postnummerregister-ansi.txt';
our $DATA_ENV          = 'GEO_POSTCODES_NO_DATA';
our $DATA_ENCODING     = 'cp1252';
our $DATA_ENCODING_ENV = 'GEO_POSTCODES_NO_ENCODING';

my @VALID_FIELDS       = qw(postcode location borough borough_number county type type_verbose);
my %VALID_FIELD        = map { $_ => 1 } @VALID_FIELDS;

my %COUNTY = %{ Geo::Postcodes::NO::Check::county_table() };

my %BRING_CATEGORY_TO_TYPE = (
    G => 'ST',
    P => 'BX',
    B => 'STBX',
    S => 'SX',
);

my %TYPE_DESC = (
    BX   => 'Postboks',
    ST   => 'Gateadresse',
    SX   => 'Serviceboks',
    IO   => 'Kunde med eget postnummer',
    STBX => 'Både gateadresse og postboks',
    MU   => 'Flere bruksområder (felles)',
    PP   => 'Porto betalt av mottaker',
    PN   => 'Stedsnavn',
);

my %TYPE_DESC_EN = (
    BX   => 'Post Office box',
    ST   => 'Street address',
    SX   => 'Service box',
    IO   => 'Individual owner',
    STBX => 'Street Address and Post Office box',
    MU   => 'Multiple usage',
    PP   => 'Porto Paye receiver',
    PN   => 'Place name',
);

my %LEGAL_MODE = map { $_ => 1 } (
    'and',  'and not',
    'nand', 'nand not',
    'oldnand', 'oldnand not',
    'nor',  'nor not',
    'or',   'or not',
    'xnor', 'xnor not',
    'xor',  'xor not',
);

my %LEGAL_INITIAL_MODE = (
    %LEGAL_MODE,
    all  => 1,
    none => 1,
    not  => 1,
    one  => 1,
);

my (%LOCATION, %BOROUGH_NUMBER, %BOROUGH, %TYPE, %BRING_CATEGORY);
my ($LOADED_DATA_FILE, $LOADED_DATA_ENCODING, $LOADED_FROM_ENV);

_load_data();

sub new {
    my ($class, $postcode) = @_;

    return unless valid($postcode);

    return bless {
        postcode       => $postcode,
        location       => location_of($postcode),
        borough_number => borough_number_of($postcode),
        borough        => borough_of($postcode),
        county         => county_of($postcode),
        type           => type_of($postcode),
    }, $class;
}

sub postcode       { return _object_field($_[0], 'postcode') }
sub location       { return _object_field($_[0], 'location') }
sub borough_number { return _object_field($_[0], 'borough_number') }
sub borough        { return _object_field($_[0], 'borough') }
sub county         { return _object_field($_[0], 'county') }
sub type           { return _object_field($_[0], 'type') }

sub type_verbose {
    my $self = shift;
    return unless ref $self;
    return type2verbose($self->{type});
}

sub get_fields {
    return @VALID_FIELDS;
}

sub is_field {
    shift if @_ > 1 && _looks_like_invocant($_[0]);
    my $field = shift;

    return 0 unless defined $field;
    return $VALID_FIELD{$field} ? 1 : 0;
}

sub legal {
    my $postcode = shift;
    return 0 unless defined $postcode;
    return $postcode =~ /\A[0-9]{4}\z/ ? 1 : 0;
}

sub valid {
    my $postcode = shift;
    return 0 unless legal($postcode);
    return exists $LOCATION{$postcode} ? 1 : 0;
}

sub postcode_of {
    my $postcode = shift;
    return $postcode;
}

sub location_of {
    my $postcode = shift;
    return unless defined $postcode;
    return $LOCATION{$postcode};
}

sub borough_number_of {
    my $postcode = shift;
    return unless defined $postcode;
    return $BOROUGH_NUMBER{$postcode};
}

sub borough_number2borough {
    my $borough_number = shift;
    return unless defined $borough_number;
    return $BOROUGH{$borough_number};
}

sub borough_of {
    my $postcode = shift;
    return unless defined $postcode;

    my $borough_number = borough_number_of($postcode);
    return unless defined $borough_number;
    return borough_number2borough($borough_number);
}

sub county_of {
    my $postcode = shift;
    return unless defined $postcode;

    my $borough_number = borough_number_of($postcode);
    return unless defined $borough_number;
    return borough_number2county($borough_number);
}

sub borough_number2county {
    my $borough_number = shift;
    return unless defined $borough_number;
    return unless exists $BOROUGH{$borough_number};

    my ($county_number) = $borough_number =~ /\A([0-9]{2})/;
    return unless defined $county_number;
    return $COUNTY{$county_number};
}

sub type_of {
    my $postcode = shift;
    return unless defined $postcode;
    return $TYPE{$postcode};
}

sub type_verbose_of {
    my $postcode = shift;
    return unless defined $postcode;

    my $type = type_of($postcode);
    return unless defined $type;
    return type2verbose($type);
}

sub type2verbose {
    shift if @_ > 1 && _looks_like_invocant($_[0]);
    my $type = shift;

    return unless defined $type;
    return $TYPE_DESC{$type};
}

sub type2verbose_english {
    shift if @_ > 1 && _looks_like_invocant($_[0]);
    my $type = shift;

    return unless defined $type;
    return $TYPE_DESC_EN{$type};
}

sub get_types {
    return sort keys %TYPE_DESC;
}

sub get_postcodes {
    return keys %LOCATION;
}

sub bring_category_of {
    my $postcode = shift;
    return unless defined $postcode;
    return $BRING_CATEGORY{$postcode};
}

sub source_url {
    return $SOURCE_URL;
}

sub data_valid_from {
    return if $LOADED_FROM_ENV;
    return $DATA_VALID_FROM;
}

sub data_file {
    return defined $LOADED_DATA_FILE ? $LOADED_DATA_FILE : _data_path();
}

sub data_encoding {
    shift if @_ && _looks_like_invocant($_[0]);
    return $LOADED_DATA_ENCODING if defined $LOADED_DATA_ENCODING;
    return _data_encoding();
}

sub is_legal_selectionmode {
    shift if @_ > 1 && _looks_like_invocant($_[0]);
    my $mode = shift;

    return 0 unless defined $mode;
    return $LEGAL_MODE{$mode} ? 1 : 0;
}

sub is_legal_initial_selectionmode {
    shift if @_ > 1 && _looks_like_invocant($_[0]);
    my $mode = shift;

    return 0 unless defined $mode;
    return $LEGAL_INITIAL_MODE{$mode} ? 1 : 0;
}

sub get_selectionmodes {
    return sort keys %LEGAL_MODE;
}

sub get_initial_selectionmodes {
    return sort keys %LEGAL_INITIAL_MODE;
}

sub verify_selectionlist {
    shift if @_ && _looks_like_invocant($_[0]);
    return _verify_selectionlist(@_);
}

sub selection_loop {
    my $objects_requested = _shift_class_invocant(\@_);
    my $procedure = shift;

    return 0 unless $procedure && ref $procedure eq 'CODE';

    my @postcodes = _selection($objects_requested, @_);
    return 0 unless @postcodes;

    for my $postcode (@postcodes) {
        $procedure->($postcode);
    }

    return 1;
}

sub selection {
    my $objects_requested = _shift_class_invocant(\@_);
    return _selection($objects_requested, @_);
}

sub _verify_selectionlist {
    my @args   = @_;
    my $status = 1;
    my @out;
    my @verbose;

    return (0, 'No arguments') unless @args;

    if (is_legal_initial_selectionmode($args[0])) {
        my $mode = shift @args;

        if (@args && defined $args[0] && $args[0] eq 'not'
            && is_legal_initial_selectionmode("$mode $args[0]")) {
            $mode .= ' ' . shift @args;
        }

        push @out,     $mode;
        push @verbose, "Mode: '$mode' - ok";

        return (1, @out) if $mode eq 'all' || $mode eq 'none';
        return (1, @out) if $mode eq 'one' && @args == 0;
        return (0, @verbose, 'Missing method/value pair - not ok') unless @args >= 2;
    }

    while (@args) {
        my $argument = shift @args;

        if (is_field($argument)) {
            push @out,     $argument;
            push @verbose, "Field: '$argument' - ok";

            if (@args) {
                $argument = shift @args;
                push @out,     $argument;
                push @verbose, "String: '$argument' - ok";
            }
            else {
                push @verbose, 'Missing string - not ok';
                $status = 0;
                last;
            }
        }
        elsif (is_legal_selectionmode($argument)) {
            if (@args && defined $args[0] && $args[0] eq 'not'
                && is_legal_selectionmode("$argument $args[0]")) {
                $argument .= ' ' . shift @args;
            }

            push @out,     $argument;
            push @verbose, "Mode: '$argument' - ok";

            unless (@args >= 2) {
                push @verbose, 'Missing method/value pair - not ok';
                $status = 0;
                last;
            }
        }
        elsif (defined $argument && $argument eq 'procedure') {
            push @out,     $argument;
            push @verbose, "Field: 'procedure' - ok";

            my $procedure = shift @args;
            if (ref $procedure eq 'CODE') {
                if (_valid_procedure_pointer($procedure)) {
                    push @out,     $procedure;
                    push @verbose, "Procedure pointer: '$procedure' - ok";
                }
                else {
                    push @verbose, "No such procedure: '$procedure' - not ok";
                    $status = 0;
                    last;
                }
            }
            else {
                my $shown = defined $procedure ? $procedure : '';
                push @verbose, "Not a procedure pointer: '$shown' - not ok";
                $status = 0;
                last;
            }
        }
        else {
            my $shown = defined $argument ? $argument : '';
            push @verbose, "Illegal argument: '$shown' - not ok";
            $status = 0;
            last;
        }
    }

    return (1, @out) if $status;
    return (0, @verbose);
}

sub _selection {
    my ($objects_requested, @args) = @_;

    if (@args && defined $args[0] && $args[0] eq 'all') {
        my @all = sort(get_postcodes());
        return _maybe_objects($objects_requested, @all);
    }

    return if @args && defined $args[0] && $args[0] eq 'none';

    my $limit = 0;
    if (@args && defined $args[0] && $args[0] eq 'one') {
        $limit = 1;
        shift @args;
    }

    my $mode = 'and';
    my %out;
    my @all = get_postcodes();

    if (@args) {
        if (defined $args[0] && is_legal_initial_selectionmode($args[0])) {
            if (@args > 1 && defined $args[1] && $args[1] eq 'not'
                && is_legal_initial_selectionmode("$args[0] $args[1]")) {
                $mode = shift @args;
                $mode .= ' ' . shift @args;
            }
            else {
                $mode = shift @args;
            }
        }

        _apply_first_clause($mode, \%out, \@all, \@args) or return;
        $mode = 'and' if $mode eq 'not';
    }
    elsif ($limit) {
        %out = map { $_ => 1 } @all;
    }

    while (@args) {
        if (defined $args[0] && is_legal_selectionmode($args[0])) {
            if (@args > 1 && defined $args[1] && $args[1] eq 'not'
                && is_legal_selectionmode("$args[0] $args[1]")) {
                $mode = shift @args;
                $mode .= ' ' . shift @args;
            }
            else {
                $mode = shift @args;
            }
        }

        _apply_next_clause($mode, \%out, \@all, \@args) or return;
    }

    return unless %out;

    my @keys = keys %out;
    my @out  = $limit ? ($keys[int rand @keys]) : sort @keys;
    return _maybe_objects($objects_requested, @out);
}

sub _apply_first_clause {
    my ($mode, $out, $all, $args) = @_;
    my $field = shift @$args;

    return _apply_first_procedure_clause($mode, $out, $all, shift @$args)
        if defined $field && $field eq 'procedure';

    return 0 unless defined $field && is_field($field);

    my $value = shift @$args;
    return 0 unless defined $value && length $value;
    my $regex = _selection_regex($value);
    return 0 unless $regex;

    my $current_field = _field_reader($field);

    for my $postcode (@$all) {
        my $current_value = $current_field->($postcode);
        next unless defined $current_value && length $current_value;

        my $match = $current_value =~ $regex ? 1 : 0;
        if ($mode =~ /not/) {
            $out->{$postcode}++ unless $match;
        }
        else {
            $out->{$postcode}++ if $match;
        }
    }

    return 1;
}

sub _apply_first_procedure_clause {
    my ($mode, $out, $all, $procedure) = @_;
    return 0 unless _valid_procedure_pointer($procedure);

    for my $postcode (@$all) {
        my $match;
        eval { $match = $procedure->($postcode) ? 1 : 0 };
        return 0 if $@;

        if ($mode =~ /not/) {
            $out->{$postcode}++ unless $match;
        }
        else {
            $out->{$postcode}++ if $match;
        }
    }

    return 1;
}

sub _apply_next_clause {
    my ($mode, $out, $all, $args) = @_;
    my $field = shift @$args;
    my ($procedure, $current_field, $value);

    if (defined $field && $field eq 'procedure') {
        $procedure = shift @$args;
        return 0 unless _valid_procedure_pointer($procedure);
    }
    else {
        return 0 unless defined $field && is_field($field);

        $current_field = _field_reader($field);
        $value = shift @$args;
        return 0 unless defined $value && length $value;
        $value = _selection_regex($value);
        return 0 unless $value;
    }

    my @postcodes = _selection_postcodes_for_mode($mode, $out, $all);
    for my $postcode (@postcodes) {
        my $match;

        if ($procedure) {
            eval { $match = $procedure->($postcode) ? 1 : 0 };
            return 0 if $@;
        }
        else {
            my $current_value = $current_field->($postcode);
            next unless defined $current_value && length $current_value;
            $match = $current_value =~ $value ? 1 : 0;
        }

        if ($mode eq 'and') {
            delete $out->{$postcode} unless $match;
        }
        elsif ($mode eq 'and not') {
            delete $out->{$postcode} if $match;
        }
        # 'oldnand'/'oldnand not' reuse this logic; they differ from 'nand'
        # only in the iteration set (see _selection_postcodes_for_mode).
        elsif ($mode eq 'nand' || $mode eq 'oldnand') {
            if ($match && $out->{$postcode}) { delete $out->{$postcode} }
            else                             { $out->{$postcode}++     }
        }
        elsif ($mode eq 'nand not' || $mode eq 'oldnand not') {
            if (!$match && $out->{$postcode}) { delete $out->{$postcode} }
            else                              { $out->{$postcode}++     }
        }
        elsif ($mode eq 'or') {
            $out->{$postcode}++ if $match;
        }
        elsif ($mode eq 'or not') {
            $out->{$postcode}++ unless $match;
        }
        elsif ($mode eq 'nor') {
            if (!$match && !$out->{$postcode}) { $out->{$postcode}++ }
            else { delete $out->{$postcode} if $out->{$postcode} }
        }
        elsif ($mode eq 'nor not') {
            if ($match && !$out->{$postcode}) { $out->{$postcode}++ }
            else { delete $out->{$postcode} if $out->{$postcode} }
        }
        elsif ($mode eq 'xor') {
            next unless $match;
            $out->{$postcode} ? delete $out->{$postcode} : $out->{$postcode}++;
        }
        elsif ($mode eq 'xor not') {
            next if $match;
            $out->{$postcode} ? delete $out->{$postcode} : $out->{$postcode}++;
        }
        elsif ($mode eq 'xnor') {
            my $boolean = $out->{$postcode} ? 1 : 0;
            $match == $boolean ? $out->{$postcode}++ : delete $out->{$postcode};
        }
        elsif ($mode eq 'xnor not') {
            my $boolean = $out->{$postcode} ? 1 : 0;
            $match != $boolean ? $out->{$postcode}++ : delete $out->{$postcode};
        }
    }

    return 1;
}

sub _load_data {
    $LOADED_FROM_ENV = defined $ENV{$DATA_ENV} && length $ENV{$DATA_ENV} ? 1 : 0;

    my $path = _data_path();
    my $encoding = _data_encoding();
    $LOADED_DATA_FILE     = $path;
    $LOADED_DATA_ENCODING = $encoding;
    my ($records) = Geo::Postcodes::NO::Check::read_records(
        $path,
        $encoding,
        county_prefixes          => [ keys %COUNTY ],
        decode_subject           => "postcode data $path",
        line_errors_include_path => 1,
    );

    for my $record (@$records) {
        my ($postcode, $location, $borough_number, $borough, $category) = @$record;
        my $type = $BRING_CATEGORY_TO_TYPE{$category};

        $LOCATION{$postcode}       = $location;
        $BOROUGH_NUMBER{$postcode} = $borough_number;
        $BOROUGH{$borough_number}  = $borough;
        $TYPE{$postcode}           = $type;
        $BRING_CATEGORY{$postcode} = $category;
    }
}

sub _data_path {
    return $ENV{$DATA_ENV} if defined $ENV{$DATA_ENV} && length $ENV{$DATA_ENV};

    my $module_path = $INC{'Geo/Postcodes/NO.pm'} || __FILE__;
    my (undef, $module_dir) = File::Spec->splitpath($module_path);
    return File::Spec->catfile($module_dir, 'NO', $DATA_FILE);
}

sub _data_encoding {
    return $ENV{$DATA_ENCODING_ENV}
        if defined $ENV{$DATA_ENCODING_ENV} && length $ENV{$DATA_ENCODING_ENV};
    return $DATA_ENCODING;
}

sub _field_reader {
    my $field = shift;

    return \&postcode_of       if $field eq 'postcode';
    return \&location_of       if $field eq 'location';
    return \&borough_number_of if $field eq 'borough_number';
    return \&borough_of        if $field eq 'borough';
    return \&county_of         if $field eq 'county';
    return \&type_of           if $field eq 'type';
    return \&type_verbose_of   if $field eq 'type_verbose';

    return;
}

sub _maybe_objects {
    my ($objects_requested, @postcodes) = @_;
    return @postcodes unless $objects_requested;
    return map { __PACKAGE__->new($_) } @postcodes;
}

sub _object_field {
    my ($self, $field) = @_;
    return unless ref $self;
    return exists $self->{$field} ? $self->{$field} : undef;
}

sub _shift_class_invocant {
    my $args = shift;
    return 0 unless @$args;
    return 0 unless defined $args->[0] && !ref $args->[0] && $args->[0] eq __PACKAGE__;
    shift @$args;
    return 1;
}

sub _looks_like_invocant {
    my $value = shift;
    return 1 if ref $value;
    return 1 if defined $value && $value =~ /\AGeo::Postcodes::NO(?:\z|::)/;
    return 0;
}

sub _valid_procedure_pointer {
    my $ptr = shift;
    return 0 unless ref $ptr eq 'CODE';
    return defined &$ptr ? 1 : 0;
}

sub _selection_postcodes_for_mode {
    my ($mode, $out, $all) = @_;

    return keys %$out
        if $mode eq 'and'
        || $mode eq 'and not'
        || $mode eq 'oldnand'
        || $mode eq 'oldnand not';

    return @$all;
}

sub _selection_regex {
    my $value = shift;
    $value =~ s/%/.*/g;

    my $regex = eval { qr/^$value$/i };
    return if $@;
    return $regex;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Geo::Postcodes::NO - Norwegian postcodes with associated information

=head1 SYNOPSIS

  use Geo::Postcodes::NO;

  my $postcode = Geo::Postcodes::NO->new('1178');
  print $postcode->location;        # OSLO
  print $postcode->borough_number;  # 0301
  print $postcode->county;          # OSLO

  my @oslo = Geo::Postcodes::NO::selection(county => 'OSLO');

=head1 DESCRIPTION

This is a self-contained reimplementation of the historical
C<Geo::Postcodes::NO> interface using the current postcode table from Bring.
The module reads a local copy of Bring's downloaded postcode file directly at
load time. Bring publishes that file as ANSI/Windows-1252, and this module
decodes it to Perl's internal Unicode strings.

The supported fields are C<postcode>, C<location>, C<borough>,
C<borough_number>, C<county>, C<type>, and C<type_verbose>.

=head1 PROCEDURES AND METHODS

=head2 new

  my $postcode = Geo::Postcodes::NO->new('1178');

Returns a postcode object, or C<undef> if the postcode is not in use.

=head2 legal, valid

C<legal> checks the Norwegian postcode syntax, which is exactly four digits.
C<valid> also checks that the postcode exists in the bundled Bring file.

=head2 postcode_of, location_of, borough_number_of, borough_of, county_of, type_of, type_verbose_of

Procedural accessors for a postcode.

=head2 postcode, location, borough_number, borough, county, type, type_verbose

Object accessors for a postcode object.

=head2 selection, selection_loop, verify_selectionlist

Selection helpers based on the old C<Geo::Postcodes> interface. Selection values
are regular expressions; C<%> is expanded to C<.*>. Invalid regular expressions
return no selection instead of throwing an exception.

Binary modes combine the current result set C<A> with the next criterion C<B>:

=over 4

=item C<and>

Keep values in both C<A> and C<B>.

=item C<and not>

Keep values in C<A> and outside C<B>.

=item C<nand>

Mathematical NAND: keep values that are not in both C<A> and C<B>.

=item C<nand not>

Mathematical NAND with a negated right side: keep values that are not in both
C<A> and outside C<B>.

=item C<oldnand>

Legacy C<Geo::Postcodes> NAND behaviour. For a simple two-clause selection this
is equivalent to C<and not>.

=item C<oldnand not>

Legacy C<Geo::Postcodes> C<nand not> behaviour. For a simple two-clause
selection this is equivalent to C<and>.

=item C<or>, C<or not>, C<nor>, C<nor not>, C<xor>, C<xor not>, C<xnor>, C<xnor not>

Standard boolean set combinations over all postcodes. The C<not> variants negate
the next criterion C<B> before combining.

=back

The initial modes C<all>, C<none>, C<not>, and C<one> are also supported.

=head2 bring_category_of

Returns Bring's raw category letter for a postcode: C<G>, C<P>, C<B>, or C<S>.
The legacy C<type_of> method maps these to C<ST>, C<BX>, C<STBX>, and C<SX>.

=head2 get_fields

Returns the supported selection/accessor field names.

=head2 is_field

Returns true if the supplied field name is supported.

=head2 get_postcodes

Returns all loaded postcodes. The order is unspecified.

=head2 get_types

Returns the supported legacy postcode type codes.

=head2 type2verbose

Returns the Norwegian description for a legacy postcode type code.

=head2 type2verbose_english

Returns the English description for a legacy postcode type code.

=head2 borough_number2borough

Returns the municipality name for a municipality number.

=head2 borough_number2county

Returns the county name for a municipality number.

=head2 source_url

Returns the URL for Bring's postcode register source file.

=head2 get_selectionmodes

Returns the legal binary selection modes.

=head2 get_initial_selectionmodes

Returns the legal initial selection modes.

=head2 is_legal_selectionmode

Returns true if the supplied mode is a legal binary selection mode.

=head2 is_legal_initial_selectionmode

Returns true if the supplied mode is legal at the start of a selection.

=head2 data_file

Returns the postcode file path loaded by the module. Set
C<GEO_POSTCODES_NO_DATA> before loading the module to use a different local
Bring file instead of the bundled copy.

=head2 data_valid_from

Returns the validity date for the bundled postcode file. If
C<GEO_POSTCODES_NO_DATA> is set, the loaded file is user supplied and the module
returns C<undef> because it cannot know that file's validity date.

=head2 data_encoding

Returns the character encoding used when decoding the loaded postcode file. The
default is C<cp1252>, matching Bring's current C<Postnummerregister-ansi.txt>
file.

=head1 ENVIRONMENT

=head2 GEO_POSTCODES_NO_DATA

Set this environment variable before loading C<Geo::Postcodes::NO> to use an
alternative local postcode file. The file must use Bring's
C<Postnummerregister-ansi.txt> layout: one postcode per line and five
tab-separated fields: postcode, postal location, municipality number,
municipality name, and category.

  GEO_POSTCODES_NO_DATA=/var/lib/postnummerregister-ansi.txt perl app.pl

=head2 GEO_POSTCODES_NO_ENCODING

Set this environment variable before loading C<Geo::Postcodes::NO> if the
postcode file uses another character encoding than Bring's current
Windows-1252/ANSI format. Values are passed to Perl's C<Encode> module, so names
such as C<cp1252>, C<UTF-8>, and C<iso-8859-1> are accepted when supported by
the local Perl installation.

  GEO_POSTCODES_NO_DATA=/var/lib/postnummerregister.txt \
  GEO_POSTCODES_NO_ENCODING=UTF-8 \
  perl app.pl

=head1 MAINTENANCE

Use F<script/check-postcodes-no> to validate a downloaded Bring file before
pointing applications at it. The wrapper sets C<GEO_POSTCODES_NO_DATA> to its
file argument and runs C<Geo::Postcodes::NO::Check>, which validates the file
format and verifies that this module can load the same file with the same
encoding. Set
C<GEO_POSTCODES_NO_ENCODING> before running the wrapper when validating a file
that is not Windows-1252.

  script/check-postcodes-no /var/lib/postnummerregister-ansi.txt

=head1 DATA

The bundled postcode file is a local copy of
L<https://www.bring.no/postnummerregister-ansi.txt>. See
L<https://www.bring.no/tjenester/adressetjenester/postnummer> for Bring's
postcode table documentation.

Bring refreshes the table once a year (the bundled copy is valid from
2026-10-01), adds new postcodes from time to time, and may adjust the
municipalities when they change (typically on 1 January). The
C<data_valid_from> function returns the validity date of the bundled file.

=head1 SEE ALSO

L<Geo::Postcodes::NO::Tutorial> - a tutorial on using this module.

L<Geo::Postcodes::NO::Selection> - the selection procedure and method in detail.

L<Geo::Postcodes::NO::Check> - the standalone data-file validator.

=head1 AUTHOR

Arne Sommer <perl@bbop.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
