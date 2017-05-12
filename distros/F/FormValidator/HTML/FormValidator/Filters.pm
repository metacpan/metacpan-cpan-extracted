#
#    Filters.pm - Common filters for use in HTML::FormValidator.
#
#    This file is part of FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
use strict;

package HTML::FormValidator::Filters;

=pod

=head1 NAME

HTML::FormValidator::Filters - Basic set of filters available in an HTML::FormValidor profile.


=head1 SYNOPSIS

In an HTML::Empberl page:

    use HTML::FormValidator;

    my $validator = new HTML::FormValidator( "/home/user/input_profiles.pl" );
    my ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  \%fdat, "customer_infos" );

=head1 DESCRIPTION

These are the builtin filters which may be specified as name in the
I<filters> and I<field_filters> parameters of the input profile.

=over

=item trim

Remove white space at the front and end of the fields.

=cut

sub filter_trim {
    my $value = shift;

    # Remove whitespace at the front
    $value =~ s/^\s+//g;

    # Remove whitespace at the end
    $value =~ s/\s+$//g;

    return $value;
}

=pod

=item strip

Runs of white space are replaced by a single space.

=cut

sub filter_strip {
    my $value = shift;

    # Strip whitespace
    $value =~ s/\s+/ /g;

    return $value;
}

=pod

=item digit

Remove non digits characters from the input.

=cut

sub filter_digit {
    my $value = shift;
    $value =~ s/\D//g;

    return $value;
}

=pod

=item alphanum

Remove non alphanumerical characters from the input.

=cut

sub filter_alphanum {
    my $value = shift;
    $value =~ s/\W//g;
    return $value;
}

=pod

=item integer

Extract from its input a valid integer number.

=cut

sub filter_integer {
    my $value = shift;
    $value =~ tr/0-9+-//dc;
    ($value) =~ m/([-+]?\d+)/;
    return $value;
}

=pod

=item pos_integer

Extract from its input a valid positive integer number.

=cut

sub filter_pos_integer {
    my $value = shift;
    $value =~ tr/0-9+//dc;
    ($value) =~ m/(\+?\d+)/;
    return $value;
}

=pod

=item pos_integer

Extract from its input a valid negative integer number.

=cut

sub filter_neg_integer {
    my $value = shift;
    $value =~ tr/0-9-//dc;
    ($value) =~ m/(-\d+)/;
    return $value;
}

=pod

=item decimal

Extract from its input a valid decimal number.

=cut

sub filter_decimal {
    my $value = shift;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/([-+]?\d+\.?\d*)/;
    return $value;
}

=pod

=item pos_decimal

Extract from its input a valid positive decimal number.

=cut

sub filter_pos_decimal {
    my $value = shift;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+//dc;
    ($value) =~ m/(\+?\d+\.?\d*)/;
    return $value;
}

=pod

=item neg_decimal

Extract from its input a valid negative decimal number.

=cut

sub filter_neg_decimal {
    my $value = shift;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.-//dc;
    ($value) =~ m/(-\d+\.?\d*)/;
    return $value;
}

=pod

=item dollars

Extract from its input a valid number to express dollars like currency.

=cut

sub filter_dollars {
    my $value = shift;
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/(\d+\.?\d?\d?)/;
    return $value;
}

=pod

=item phone

Filters out characters which aren't valid for an phone number. (Only
accept digits [0-9], space, comma, minus, parenthesis, period and pound [#].)

=cut

sub filter_phone {
    my $value = shift;
    $value =~ tr/0-9,().#- //dc;
    return $value;
}

=pod

=item sql_wildcard

Transforms shell glob wildcard (*) to the SQL like wildcard (%).

=cut

sub filter_sql_wildcard {
    my $value = shift;
    $value =~ tr/*/%/;
    return $value;
}

=pod

=item quotemeta

Calls the quotemeta (quote non alphanumeric character) builtin on its
input.

=cut

sub filter_quotemeta {
    quotemeta $_[0];
}

=pod

=item lc

Calls the lc (convert to lowercase) builtin on its input.

=cut

sub filter_lc {
    lc $_[0];
}

=pod

=item uc

Calls the uc (convert to uppercase) builtin on its input.

=cut

sub filter_uc {
    uc $_[0];
}

=pod

=item ucfirst

Calls the ucfirst (Uppercase first letter) builtin on its input.

=cut

sub filter_ucfirst {
    ucfirst $_[0];
}

1;
__END__

=pod

=back

=head1 SEE ALSO

HTML::FormValidator(3) HTML::FormValidator::Constraints(3)

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut

