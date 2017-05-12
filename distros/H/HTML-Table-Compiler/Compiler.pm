package HTML::Table::Compiler;

use strict;
use HTML::Table;
use Carp qw( croak );

use vars qw( @ISA $VERSION );

@ISA = qw( HTML::Table );
$VERSION = '0.01';


sub compile {
    my ($self, $data) = @_;

    unless ( defined($data) && ref $data && (ref $data eq 'ARRAY') ) {
        croak "build(): usage error";
    }
    my $cols_number = $self->getTableCols() or die "no table cols";
    my $rows_number = $self->getTableRows() or die "no table rows";

    if ( ($rows_number * $cols_number < @$data) && $self->{autogrow} ) {
        my $splits = @$data / $cols_number;
        $rows_number = (int ($splits) == $splits) ? $splits : $splits + 1;
    }

    my @table = ();
    for ( my $i=1; $i <= $rows_number; $i++ ) {
        my @row = ();
        for ( my $j=1; $j <= $cols_number; $j++ ) {
            push @row, $data->[ (($i-1) * $cols_number) + $j - 1 ];
            $self->setCell($i, $j, $row[-1]);
        }
        push @table, [@row];
    }
    return \@table;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

HTML::Table::Compiler - Extension for HTML::Table to tabularize data

=head1 SYNOPSIS

    use HTML::Table::Compiler;
    $table = HTML::Table::Compiler->new(2, 25);
    $table->compile([1..50]);
    print "$table";

=head1 DESCRIPTION

L<HTML::Table|HTML::Table>, while making it easy to create and manipulate tabular data, doesn't allow such obvious functionality as 
tabularizing existing array of data.

One comes across this challenge a lot in building Web applications such as galleries, where you know how many items you want to display, you know how many rows and columns you want. Challenge becomes to split the data set into rows and columns and display it as an HTML table.

HTML::Table::Compiler introduces this functionality through its compile() method.

=head2 EXPORT

None

=head2 METHODS

=over 4

=item compile(\@dataset)

Builds an HTML::Table::Compiler object (which really IS A L<HTML::Table|HTML::Table>) with elements of the \@dataset. Row and column numbers should be defined in new():

    @dataset = (1..50);

    $table = new HTML::Table::Compiler->new(2, 10);
    $table->compile(\@dataset);

In the above example HTML::Table::Compiler may add additional rows to accommodate all the data, otherwise only first 20 elements of the @dataset would be tabularized. If this is not a desired behavior, you should turn autoGrow() feature off:

    $table = new HTML::Table::Compiler->new(2, 10);
    $table->autoGrow(0);
    $table->compile(\@dataset);

For all the available methods consult L<HTML::Table's online manual|HTML::Table>.

=back

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt> http://author.handalak.com/

=head1 SEE ALSO

L<perl>.

=cut
