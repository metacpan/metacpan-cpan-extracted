package Geo::TigerLine::Record::Parser;

use Carp::Assert;
use vars qw($VERSION);
$VERSION = '0.01';

=pod

=head1 NAME

Geo::TigerLine::Record::Parser - Parsing superclass for TIGER/Line records.


=head1 SYNOPSIS

  package Geo::TigerLine::Record::23;
  use base qw(Geo::TigerLine::Record::Parser);

  @records = __PACKAGE__->parse_file($fh);
  __PACKAGE__->parse_file($fh, \&callback);

  $record = __PACKAGE__->parse($row);


=head1 DESCRIPTION

Parses raw TIGER/Line data into Geo::TigerLine::Record objects.  This
is intended to be used as a superclass of Geo::TigerLine::Record
objects and not used directly.

You shouldn't be here.


=head2 Methods

=over 4

=item B<parse_file>

    @records = __PACKAGE__->parse_file($fh);
    __PACKAGE__->parse_file($fh, \&callback);

Parses a given filehandle as a TIGER/Line data file.  The data
definition is taken from __PACKAGE__->Pack_Tmpl, __PACKAGE__->Dict and
__PACKAGE__->Fields.  Returns an array of objects of type __PACKAGE__.

&callback will be called for each record and given a record object and
its position in the file (ie. 1 for the first, 2 for the second, etc...).
A sample callback...

    sub callback {
        my($record, $pos) = @_;

        printf "Record #$pos is %s\n", $record->tlid;
    }

If a &callback is given, a list of records will B<NOT> be returned.
It is assumed you'll be taking care of arrangements to store the
records in your callback and @records can eat up huge amounds of
memory for a typical TIGER/Line data file.

=cut

#'#
sub parse_file {
    my($proto, $fh, $callback) = @_;
    my($class) = ref $proto || $proto;

    my @records = ();

    my $num = 1;
    while(<$fh>) {
        chomp;
        my $record = $class->parse($_);

        if( defined $callback ) {
            $callback->($record, $num);
        }
        else {
            push @records, $record;
        }

        $num++;
    }

    return @records;
}

=pod

=item B<parse>

    $record = __PACKAGE__->parse($line);

Parses a single record of TIGER/Line data.

=cut

sub parse {
    my($proto, $line) = @_;
    my($class) = ref $proto || $proto;

    my $data_def = $class->Dict;
    my $data_fields = $class->Fields;
    my @fields = unpack($class->Pack_Tmpl, $line);

    assert(@fields == keys %$data_def);

    my %fields = map { ($_ => shift @fields) } @$data_fields;

    # Clip leading whitespace off right justified fields.
    foreach my $field ( map { $_->{field} } grep { $_->{fmt} eq 'R' }
                                              values %$data_def )
    {
        $fields{$field} =~ s/^\s+//;
    }

    my $obj =  $class->new(\%fields);
    return $obj;
}

=pod

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Geo::TigerLine>

=cut

1;

