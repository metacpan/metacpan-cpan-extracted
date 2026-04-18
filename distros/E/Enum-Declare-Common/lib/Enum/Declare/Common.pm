package Enum::Declare::Common;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.02';

1;

=head1 NAME

Enum::Declare::Common - A curated collection of commonly-needed enums

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Enum::Declare::Common::HTTP;
    use Enum::Declare::Common::Calendar;

    # HTTP status codes
    my $meta = StatusCode();
    say OK;          # 200
    say NotFound;    # 404

    # HTTP methods
    say GET;         # "get"

    # Calendar
    say Monday;      # 1
    say January;     # 1

=head1 DESCRIPTION

Enum::Declare::Common provides a collection of frequently used enums built on
L<Enum::Declare>. Each submodule declares standard enums with proper
constants, export support, and meta objects for introspection and
exhaustive matching.

=head1 MODULES

=over 4

=item * L<Enum::Declare::Common::HTTP> — HTTP status codes, methods, and helpers

=item * L<Enum::Declare::Common::Calendar> — Weekday, WeekdayFlag (bitmask), Month

=item * L<Enum::Declare::Common::Country> — ISO 3166-1 alpha-2/3 codes to country names

=item * L<Enum::Declare::Common::CountryISO> — ISO 3166-1 alpha-2/3 code-to-code constants

=item * L<Enum::Declare::Common::Currency> — ISO 4217 currency codes to names

=item * L<Enum::Declare::Common::CurrencyISO> — ISO 4217 code-to-code constants

=item * L<Enum::Declare::Common::MIME> — 48 common MIME types

=item * L<Enum::Declare::Common::Color> — 148 named CSS colours with hex values

=item * L<Enum::Declare::Common::Sort> — Direction (Asc/Desc) and NullHandling

=item * L<Enum::Declare::Common::Bool> — YesNo, OnOff, TrueFalse, Bit

=item * L<Enum::Declare::Common::Priority> — Level (1-5) and Severity strings

=item * L<Enum::Declare::Common::Timezone> — Timezone abbreviation constants

=item * L<Enum::Declare::Common::TimezoneOffset> — UTC offsets in seconds

=item * L<Enum::Declare::Common::Locale> — Language/locale tag constants

=item * L<Enum::Declare::Common::FileType> — File type constants

=item * L<Enum::Declare::Common::Encoding> — Character encoding names

=item * L<Enum::Declare::Common::Permission> — Unix permission bits and masks

=item * L<Enum::Declare::Common::Environment> — Application environment names

=item * L<Enum::Declare::Common::LogLevel> — Numeric log levels for comparison

=item * L<Enum::Declare::Common::Status> — Lifecycle status strings

=back

=head1 USING WITH Object::Proto

Every enum in this collection is declared with the C<:Type> attribute,
which automatically registers it as an L<Object::Proto> type at load time.
This means you can use any enum name directly as a slot type:

    use Enum::Declare::Common::HTTP qw(:StatusCode :Method);
    use Enum::Declare::Common::LogLevel qw(:Level);
    use Object::Proto;

    object 'APIRequest',
        'method:Method:required',
        'status:StatusCode',
        'log_level:Level:default(' . Info . ')',
    ;

    my $req = new APIRequest method => GET;
    $req->status(OK);             # accepts valid enum value
    $req->status(9999);           # dies — not a valid StatusCode

Enum types support coercion, so case-insensitive name lookups work
automatically:

    $req->status(200);            # coerces integer to OK

B<Note:> Enum names must be unique across all loaded modules. For example,
C<Enum::Declare::Common::Bool> and C<Enum::Declare::Common::Permission>
both declare an enum named C<Bit>, so loading both in the same program
will cause a conflict. Import only the specific tags you need.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION C<< <email@lnation.org> >>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Enum::Declare::Common
