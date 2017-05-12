package File::SimpleQuery;

use warnings;
use strict;

use Carp qw/croak/;

=head1 NAME

File::SimpleQuery - Query flat-files, simply!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Have you ever wanted to make queries against a flat-file, similar to a
database, but did not want to setup all the necessary database
machinery?  Enter File::SimpleQuery, which is intended to allow you to
make simple sql-like queries against a file you specify.


Intended to make querying simple files easier.  The file in question
is expected to have the first row be a header row, which is how it
knows whichs fields to select from.

    use File::SimpleQuery;

    my $delimiter = ',';
    my $filename = 'test_file';
    my $q = File::SimpleQuery->new($filename, $delimiter);

    my @results = $q->select(
        [ qw/ field1 fieldn / ],
        sub { my $fields = shift; return 1 if $fields->{field1} eq 'foo' },
    );


=head1 FUNCTIONS

=head2 new

The constructor.  You must specify the filename and the delimiter between rows

=cut

sub new
{
    my ($class, $filename, $delim) = @_;
    my $fh;
    open($fh, '<', $filename) or croak "Unable to open file $filename\n";
    my $headers = <$fh>;
    chomp $headers;
    return bless {
        file    => $fh,
        delim   => $delim,
        headers => [ split /$delim/, $headers ]
    }, $class;
}

=head2 select ( \@field_names_to_select, \&where_sub, \@group_by_fields )

Returns a list of hash-refs that match the lines in the file where the
where_sub evaluates to true, groupped by the group_by_fields

=cut

sub select
{
    my ($self, $fields, $where_sub, $group_by) = @_;
    my $fh = $self->{file};

    my @rows;

    while ( my $line = <$fh> ) {
        chomp $line;
        my %fields = $self->_parse_line($line);
        push @rows, { $self->_add_fields($fields, \%fields) }
            if $where_sub->(\%fields);
    }

    seek($fh, 0, 0);
    # to skip headers;
    <$fh>;

    return @rows;
}

=head1 AUTHOR

Ben Prew, C<< <btp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-simplequery at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-SimpleQuery>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::SimpleQuery

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-SimpleQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-SimpleQuery>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-SimpleQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/File-SimpleQuery>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Ben Prew, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


sub _parse_line
{
    my ($self, $line) = @_;
    my $delim = $self->{delim};

    return _interleave(
        $self->{headers},
        [ split /$delim/, $line ]
    );
}

sub _interleave
{
    my ($arr1, $arr2) = @_;

    my @interleaved;

    for (my $i = 0; $i < scalar @$arr1; $i++) {
        push @interleaved, $arr1->[$i], $arr2->[$i];
    }

    return @interleaved;
}

sub _add_fields
{
    my ($self, $fields_needed, $fields_and_values) = @_;

    return map { $_ => $fields_and_values->{$_} } @$fields_needed;
}

1; # End of File::SimpleQuery
