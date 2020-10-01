package Markdown::Table;

# ABSTRACT: Create and parse tables in Markdown

use strict;
use warnings;

use Moo;

use Text::ASCIITable 0.22;

our $VERSION = 0.03;

has cols => (
    is  => 'rwp',
    isa => sub { ref $_[0] and 'ARRAY' eq ref $_[0] },
);

has rows => (
    is  => 'rwp',
    isa => sub { ref $_[0] and 'ARRAY' eq ref $_[0] },
);

sub parse {
    my ($class, $markdown, $options) = @_;

    $options //= {};

    my @found_tables = $markdown =~ m{
        (
            ^\|[^\n]+\n
            ^\|(?:-{3,}\|)+\n
            (?:
                ^\|[^\n]+\n
            )+
        )
    }xmg;

    if ( $options->{nuclino} ) {
        push @found_tables, $markdown =~ m{
            ^\+(?:-+\+)+\n
            (
                (?:
                    ^\|[^\n]+\n
                    (?:^(?:\+(?:-+\+)+)\n)?
                )+
            )
            ^(?:\+(?:-+\+)+)
        }xmsg;
    }


    my @tables;

    for my $table ( @found_tables ) {
        my @lines = grep{ $_ =~ m{\A\|[^-]+} } split /\n/, $table;
     
        my $headerline = shift @lines;
        $headerline    =~ s{\A\|\s+}{};
        $headerline    =~ s{\s+\|$}{};
        my @cols       = split /\s+\|\s+/, $headerline;

        my @rows = map{
            $_ =~ s{\A\|\s+}{};
            $_ =~ s{\s+\|$}{};
            [ split /\s+\|\s+/, $_ ];
        } @lines;

        push @tables, $class->new(
            cols => \@cols,
            rows => \@rows,
        );
    }

    return @tables;
}

sub set_cols {
    my ($self, @cols) = @_;

    $self->_set_cols( \@cols );
    return $self->cols;
}

sub add_rows {
    my ($self, @new_rows) = @_;

    my $rows = $self->rows || [];
    push @{ $rows }, @new_rows; 
    $self->_set_rows( $rows );

    return $rows;
}

sub get_table {
    my ($self) = @_;

    my $ascii = Text::ASCIITable->new({
        hide_LastLine => 1,
        hide_FirstLine => 1,
    });

    $ascii->setCols( $self->cols );
    for my $row ( @{ $self->rows || [] } ) {
        $ascii->addRow( @{ $row } );
    }

    return $ascii->draw( undef, undef, [qw/| | - |/] );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdown::Table - Create and parse tables in Markdown

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To generate a table

    use Markdown::Table;

    my $table   = Markdown::Table->new;
    my @columns = qw(Id Name Role);
    $table->set_cols( @columns );

    my @data = (
        [ 1, 'John Smith', 'Testrole' ],
        [ 2, 'Jane Smith', 'Admin' ],
    );

    $table->add_rows( @data );

    print $table->get_table;

To get tables from an existing Markdown document

    use Markdown::Table;

    my $markdown = q~
    This table shows all employees and their role.

    | Id | Name | Role |
    |---|---|---|
    | 1 | John Smith | Testrole |
    | 2 | Jane Smith | Admin |
    ~;

    my @tables = Markdown::Table->parse(
        $markdown,
    );

    print $tables[0]->get_table;

=head1 ATTRIBUTES

These are read-only attributes

=over 4

=item * cols

=item * rows

=back

=head1 METHODS

=head2 new

Create a new object

    use Markdown::Table;

    my @columns = qw(Id Name Role);
    my @data = (
        [ 1, 'John Smith', 'Testrole' ],
        [ 2, 'Jane Smith', 'Admin' ],
    );


    my $table = Markdown::Table->new(
        cols => \@columns,
        rows => \@data,
    );

    # or

    my $table = Markdown::Table->new;
    $table->set_cols( @columns );
    $table->add_rows( @data );

=head2 set_cols

Set the columns of the table

    my @columns = qw(Id Name Role);
    $table->set_cols( @columns );

=head2 add_rows

Add a row to the table

    my @data = (
        [ 1, 'John Smith', 'Testrole' ],
        [ 2, 'Jane Smith', 'Admin' ],
    );
    $table->add_rows( @data );

=head2 get_table

Get the table in markdown format

    my $md_table = $table->get_table

=head2 parse

Parses the Markdown document and creates a L<Markdown::Table> object for each table found in the
document.

    use Markdown::Table;

    my $markdown = q~
    This table shows all employees and their role.

    | Id | Name | Role |
    +---+---+---+
    | 1 | John Smith | Testrole |
    | 2 | Jane Smith | Admin |
    ~;

    my @tables = Markdown::Table->parse(
        $markdown,
    );

    print $tables[0]->get_table;

=head1 SEE ALSO

If you just want to generate tables for Markdown documents, you can
use L<Text::ASCIITable>. This is the module, L<Markdown::Table> uses
for table generation, too.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
