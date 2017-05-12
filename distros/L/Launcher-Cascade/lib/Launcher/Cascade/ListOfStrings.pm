package Launcher::Cascade::ListOfStrings;

=head1 NAME

Launcher::Cascade::ListOfStrings - a wrapper around an array to make it inherit from Launcher::Cascade::Printable

=head1 SYNOPSIS

    use Launcher::Cascade::ListOfStrings;

    my $l = new Launcher::Cascade::ListOfStrings
        -list => [ 'some', 'strings', 'to', 'start', 'with' ],
    ;

    push @$l, 'and', 'then', 'some';

    print $l->as_string;
    print "$l";   # same as above

    # alter the formatting
    $l->separator(q{, });
    $l->preparator(sub { qq{"$_"} });

    print "$l\n"; # prints quoted strings separated by comas

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade Launcher::Cascade::Printable );

=head2 Attributes

=over 4

=item B<preparator>

A coderef used to prepare each element in list() before including it the
generated string. The coderef will be invoked with C<$_> locally aliased to the
current element. By default, preparator() is the identity function (i.e., it
returns C<$_> untouched).

=item B<separator>

The string to insert between each element in list() when generating a string
(sort of like Perl's C<$"> built-in variable. See L<perlvar>). Defaults to the
empty string.

=item B<string_after>

=item B<string_before>

Strings to prepend and, respectively, append, to the string representation of
the list(). Both default to the empty string.

=cut

Launcher::Cascade::make_accessors_with_defaults
    string_before => q{},        # empty string
    string_after  => q{},        # empty string
    separator     => q{},        # empty string
    preparator    => sub { $_ }, # identity
;

=item B<list>

The reference to the array containing the elements. This can also be accessed
by dereferencing the object as if it were an array reference (see SYNOPSIS).

=cut

sub list {

    my $self = shift;

    my $old = $self->{_list} ||= [];
    $self->{_list} = $_[0] if @_;
    return $old;
}

use overload '@{}' => '_as_list';

sub _as_list {

    my $self = shift;
    $self->list();
}

=back

=head2 Methods

=over 4

=item B<as_string>

Returns a string representation of the object. Each element in list() is first
passed on to the coderef in preparator(), and the list of results from
preparator() is concatenated with the value of separator().

This method is called when the object is "stringified", i.e., when it is
interpolated in a double-quoted string.

=back

=head1 EXAMPLES

    my $l = new Launcher::Cascade::ListOfStrings -list => [ qw( frodo pippin merry sam ) ];

    $l->separator(q{, });
    $l->preparator(sub { ucfirst });

    print "$l\n"; # "Frodo, Pippin, Merry, Sam" and a newline

=cut

sub as_string {

    my $self = shift;

    return $self->string_before() . join($self->separator(), map $self->preparator()->(), @{$self->list()}) . $self->string_after();
}

=head1 SEE ALSO

L<Launcher::Cascade::Printable>

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::ListOfStrings
