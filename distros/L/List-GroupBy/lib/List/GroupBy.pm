package List::GroupBy;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.03";

use Exporter qw( import );

our @EXPORT_OK = qw( groupBy );

use Carp;

my $nop = sub { $_[0] };

sub groupBy {
    my ( $options, @list ) = @_;

    $options = ref $options eq "ARRAY" ? { keys => $options } : $options;

    croak "missing grouping keys" unless ref $options->{keys} eq "ARRAY";

    my @keys = @{ $options->{keys} };
    
    my $default = $options->{defaults} // {};

    croak "defaults should be a hashref" unless ref $default eq "HASH";

    $options->{operations} //= {};

    croak "operations should be a hashref" unless ref $options->{operations} eq "HASH";


    my %op = map {
        my $operation = $options->{operations}->{ $_ } // $nop;

        croak "operation defined should be an anonymous sub" unless ref $operation eq "CODE";

        $_ => $operation;
    } @keys;


    my $groupings = {};

    my $leaf = pop @keys;

    foreach my $item (@list) {
        my $current = $groupings;

        foreach my $key ( @keys ) {
            my $branch = $op{ $key }->( $item->{ $key } // $default->{ $key } // '' );

            $current = $current->{ $branch } //= {};
        }

        my $leafNode = $op{ $leaf }->( $item->{$leaf} // $default->{ $leaf } // '' );
        push @{ $current->{ $leafNode } }, $item;
    }
   
    return wantarray ? %$groupings : $groupings;
}


1;
__END__

=encoding utf-8

=head1 NAME

List::GroupBy - Group a list of hashref's to a multilevel hash of hashrefs of arrayrefs


=head1 SYNOPSIS

    use List::GroupBy qw( groupBy );

    my @list = (
        { firstname => 'Fred',   surname => 'Blogs', age => 20 },
        { firstname => 'George', surname => 'Blogs', age => 30 },
        { firstname => 'Fred',   surname => 'Blogs', age => 65 },
        { firstname => 'George', surname => 'Smith', age => 32 },
        { age => 99 },
    );

    my %groupedList = groupBy ( [ 'surname', 'firstname' ], @list );

    # %groupedList => (
    #     'Blogs' => {
    #         'Fred' => [
    #             { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    #             { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    #         ],
    #         'George' => [
    #             { firstname => 'George', surname => 'Blogs', age => 30 },
    #         ],
    #     },
    #     'Smith' => {
    #         'George' => [
    #             { firstname => 'George', surname => 'Smith', age => 32 },
    #         ],
    #     },
    #     '' => {
    #         '' => [
    #             { age => 99 },
    #         },
    #     },
    # )


    %groupedList = groupBy(
        {
            keys => [ 'surname', 'firstname' ],
            defaults => { surname => 'Blogs' }
        },
        @list
    );

    # %groupedList => (
    #     Blogs => {
    #         Fred => [
    #             { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    #             { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    #         ],
    #         George => [
    #             { firstname => 'George', surname => 'Blogs', age => 30 },
    #         ],
    #         '' => [
    #             { age => 99 },
    #         ],
    #     },
    #     Smith => {
    #         George => [
    #             { firstname => 'George', surname => 'Smith', age => 32 },
    #         ],
    #     },
    # )


    %groupedList = groupBy (
        {
            keys => [ 'surname', 'firstname' ],
            defaults => { surname => 'Blogs' },
            operations => { surname => sub { uc $_[0] } },
        },
        @list
    );

    # %groupedList => (
    #     BLOGS => {
    #         Fred => [
    #             { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    #             { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    #         ],
    #         George => [
    #             { firstname => 'George', surname => 'Blogs', age => 30 },
    #         ],
    #         '' => [
    #             { age => 99 },
    #         ],
    #     },
    #     SMITH => {
    #         George => [
    #             { firstname => 'George', surname => 'Smith', age => 32 },
    #         ],
    #     },
    # )


=head1 DESCRIPTION

List::GroupBy provides functions to group a list of hashrefs in to a hash of
hashrefs of arrayrefs.


=head1 FUNCTIONS

=over 4

=item C<< groupBy( [ 'primary key', 'secondary key', ... ], LIST ) >>

If called with and array ref as the first parameter then C<groupBy> will group
the list by the keys provided in the array ref.

Note: undefined values for a key will be defaulted to the empty string.

Returns:

=over 4

=item C<List Context> - a hash of hashrefs of arrayrefs

=item C<Scalar Context> - a hashref of hashrefs of arrayrefs

=back


=item C<< groupBy( { keys => [ 'key', ... ], defaults => { 'key' => 'default', ... }, operations => { 'key' => sub, ... }, LIST ) >>

More advanced options are available by calling C<groupBy> with a hash ref of
options as the first parameter.  Available options are:

=over 4

=item C<keys> (Required)

An array ref of the keys to use for grouping. The order of the keys dictates
the order of the grouping.  So the first key is the primary grouping, the
second key is used for the secondary grouping under the primary grouping an so
on.

=item C<defaults> (Optional)

A hash ref of defaults to use one or more keys.  If a key for an item is
undefined and there's an entry in the C<defaults> option then that will be
used. If no default value has been supplied for a key then the empty string
will be used.

=item C<operations> (Optional)

A hash ref mapping keys to a function to use to normalise value's when
grouping. If there's no entry for a key then the value is just used as is.

Each funtion is passed the value as it's only parameter and it's return
value is used for the key.

If you wish to make a grouping case-insensitive then you can use an operation
on that key that simply folds (C<fc()>)the case e.g.

    %groupedList = groupBy (
        {
            keys => [ 'surname', 'firstname' ],
            defaults => { surname => 'Blogs' },
            operations => {
                surname => sub { fc( $_[0] ) },
                firstname => sub { fc ( $_[0] ) },
            },
        },
        @list
    );


=back

Returns:

=over 4

=item C<List Context> - a hash of hashrefs of arrayrefs

=item C<Scalar Context> - a hashref of hashrefs of arrayrefs

=back

=back


=head1 LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

Jason Cooper E<lt>JLCOOPER@cpan.orgE<gt>

=cut

