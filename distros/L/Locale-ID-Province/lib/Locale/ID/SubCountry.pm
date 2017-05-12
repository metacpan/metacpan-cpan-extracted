package Locale::ID::SubCountry;
use Locale::ID::Province;

our $VERSION = '0.09'; # VERSION

our @ISA       = @Locale::ID::Province::ISA;
our @EXPORT    = @Locale::ID::Province::EXPORT;
our @EXPORT_OK = @Locale::ID::Province::EXPORT_OK;
our %SPEC      = %Locale::ID::Province::SPEC;
for my $f (keys %SPEC) {
    *{$f} = \&{"Locale::ID::Province::$f"};
}

1;
# ABSTRACT: Alias for Locale::ID::Province

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::ID::SubCountry - Alias for Locale::ID::Province

=head1 VERSION

This document describes version 0.09 of Locale::ID::SubCountry (from Perl distribution Locale-ID-Province), released on 2015-09-03.

=head1 FUNCTIONS


=head2 list_id_provinces(%args) -> [status, msg, result, meta]

Provinces in Indonesia.

REPLACE ME

Arguments ('*' denotes required arguments):

=over 4

=item * B<bps_code> => I<int>

Only return records where the 'bps_code' field equals specified value.

=item * B<bps_code.in> => I<array[int]>

Only return records where the 'bps_code' field is in the specified values.

=item * B<bps_code.is> => I<int>

Only return records where the 'bps_code' field equals specified value.

=item * B<bps_code.isnt> => I<int>

Only return records where the 'bps_code' field does not equal specified value.

=item * B<bps_code.max> => I<int>

Only return records where the 'bps_code' field is less than or equal to specified value.

=item * B<bps_code.min> => I<int>

Only return records where the 'bps_code' field is greater than or equal to specified value.

=item * B<bps_code.not_in> => I<array[int]>

Only return records where the 'bps_code' field is not in the specified values.

=item * B<bps_code.xmax> => I<int>

Only return records where the 'bps_code' field is less than specified value.

=item * B<bps_code.xmin> => I<int>

Only return records where the 'bps_code' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<eng_name> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.contains> => I<str>

Only return records where the 'eng_name' field contains specified text.

=item * B<eng_name.in> => I<array[str]>

Only return records where the 'eng_name' field is in the specified values.

=item * B<eng_name.is> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.isnt> => I<str>

Only return records where the 'eng_name' field does not equal specified value.

=item * B<eng_name.max> => I<str>

Only return records where the 'eng_name' field is less than or equal to specified value.

=item * B<eng_name.min> => I<str>

Only return records where the 'eng_name' field is greater than or equal to specified value.

=item * B<eng_name.not_contains> => I<str>

Only return records where the 'eng_name' field does not contain specified text.

=item * B<eng_name.not_in> => I<array[str]>

Only return records where the 'eng_name' field is not in the specified values.

=item * B<eng_name.xmax> => I<str>

Only return records where the 'eng_name' field is less than specified value.

=item * B<eng_name.xmin> => I<str>

Only return records where the 'eng_name' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<ind_capital_name> => I<str>

Only return records where the 'ind_capital_name' field equals specified value.

=item * B<ind_capital_name.contains> => I<str>

Only return records where the 'ind_capital_name' field contains specified text.

=item * B<ind_capital_name.in> => I<array[str]>

Only return records where the 'ind_capital_name' field is in the specified values.

=item * B<ind_capital_name.is> => I<str>

Only return records where the 'ind_capital_name' field equals specified value.

=item * B<ind_capital_name.isnt> => I<str>

Only return records where the 'ind_capital_name' field does not equal specified value.

=item * B<ind_capital_name.max> => I<str>

Only return records where the 'ind_capital_name' field is less than or equal to specified value.

=item * B<ind_capital_name.min> => I<str>

Only return records where the 'ind_capital_name' field is greater than or equal to specified value.

=item * B<ind_capital_name.not_contains> => I<str>

Only return records where the 'ind_capital_name' field does not contain specified text.

=item * B<ind_capital_name.not_in> => I<array[str]>

Only return records where the 'ind_capital_name' field is not in the specified values.

=item * B<ind_capital_name.xmax> => I<str>

Only return records where the 'ind_capital_name' field is less than specified value.

=item * B<ind_capital_name.xmin> => I<str>

Only return records where the 'ind_capital_name' field is greater than specified value.

=item * B<ind_island_name> => I<str>

Only return records where the 'ind_island_name' field equals specified value.

=item * B<ind_island_name.contains> => I<str>

Only return records where the 'ind_island_name' field contains specified text.

=item * B<ind_island_name.in> => I<array[str]>

Only return records where the 'ind_island_name' field is in the specified values.

=item * B<ind_island_name.is> => I<str>

Only return records where the 'ind_island_name' field equals specified value.

=item * B<ind_island_name.isnt> => I<str>

Only return records where the 'ind_island_name' field does not equal specified value.

=item * B<ind_island_name.max> => I<str>

Only return records where the 'ind_island_name' field is less than or equal to specified value.

=item * B<ind_island_name.min> => I<str>

Only return records where the 'ind_island_name' field is greater than or equal to specified value.

=item * B<ind_island_name.not_contains> => I<str>

Only return records where the 'ind_island_name' field does not contain specified text.

=item * B<ind_island_name.not_in> => I<array[str]>

Only return records where the 'ind_island_name' field is not in the specified values.

=item * B<ind_island_name.xmax> => I<str>

Only return records where the 'ind_island_name' field is less than specified value.

=item * B<ind_island_name.xmin> => I<str>

Only return records where the 'ind_island_name' field is greater than specified value.

=item * B<ind_name> => I<str>

Only return records where the 'ind_name' field equals specified value.

=item * B<ind_name.contains> => I<str>

Only return records where the 'ind_name' field contains specified text.

=item * B<ind_name.in> => I<array[str]>

Only return records where the 'ind_name' field is in the specified values.

=item * B<ind_name.is> => I<str>

Only return records where the 'ind_name' field equals specified value.

=item * B<ind_name.isnt> => I<str>

Only return records where the 'ind_name' field does not equal specified value.

=item * B<ind_name.max> => I<str>

Only return records where the 'ind_name' field is less than or equal to specified value.

=item * B<ind_name.min> => I<str>

Only return records where the 'ind_name' field is greater than or equal to specified value.

=item * B<ind_name.not_contains> => I<str>

Only return records where the 'ind_name' field does not contain specified text.

=item * B<ind_name.not_in> => I<array[str]>

Only return records where the 'ind_name' field is not in the specified values.

=item * B<ind_name.xmax> => I<str>

Only return records where the 'ind_name' field is less than specified value.

=item * B<ind_name.xmin> => I<str>

Only return records where the 'ind_name' field is greater than specified value.

=item * B<iso3166_2_code> => I<str>

Only return records where the 'iso3166_2_code' field equals specified value.

=item * B<iso3166_2_code.contains> => I<str>

Only return records where the 'iso3166_2_code' field contains specified text.

=item * B<iso3166_2_code.in> => I<array[str]>

Only return records where the 'iso3166_2_code' field is in the specified values.

=item * B<iso3166_2_code.is> => I<str>

Only return records where the 'iso3166_2_code' field equals specified value.

=item * B<iso3166_2_code.isnt> => I<str>

Only return records where the 'iso3166_2_code' field does not equal specified value.

=item * B<iso3166_2_code.max> => I<str>

Only return records where the 'iso3166_2_code' field is less than or equal to specified value.

=item * B<iso3166_2_code.min> => I<str>

Only return records where the 'iso3166_2_code' field is greater than or equal to specified value.

=item * B<iso3166_2_code.not_contains> => I<str>

Only return records where the 'iso3166_2_code' field does not contain specified text.

=item * B<iso3166_2_code.not_in> => I<array[str]>

Only return records where the 'iso3166_2_code' field is not in the specified values.

=item * B<iso3166_2_code.xmax> => I<str>

Only return records where the 'iso3166_2_code' field is less than specified value.

=item * B<iso3166_2_code.xmin> => I<str>

Only return records where the 'iso3166_2_code' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<str>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<tags> => I<str>

Only return records where the 'tags' field equals specified value.

=item * B<tags.contains> => I<str>

Only return records where the 'tags' field contains specified text.

=item * B<tags.in> => I<array[str]>

Only return records where the 'tags' field is in the specified values.

=item * B<tags.is> => I<str>

Only return records where the 'tags' field equals specified value.

=item * B<tags.isnt> => I<str>

Only return records where the 'tags' field does not equal specified value.

=item * B<tags.max> => I<str>

Only return records where the 'tags' field is less than or equal to specified value.

=item * B<tags.min> => I<str>

Only return records where the 'tags' field is greater than or equal to specified value.

=item * B<tags.not_contains> => I<str>

Only return records where the 'tags' field does not contain specified text.

=item * B<tags.not_in> => I<array[str]>

Only return records where the 'tags' field is not in the specified values.

=item * B<tags.xmax> => I<str>

Only return records where the 'tags' field is less than specified value.

=item * B<tags.xmin> => I<str>

Only return records where the 'tags' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Locale-ID-Province>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Locale-ID-Province>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-ID-Province>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
