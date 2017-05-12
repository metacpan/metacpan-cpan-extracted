package HTML::TableContent;

use Carp qw/croak carp/;
use Moo;

use HTML::TableContent::Parser;
use HTML::TableContent::Table;

our $VERSION = '0.18';

has parser => (
    is      => 'rw',
    lazy => 1,
    default => sub { return HTML::TableContent::Parser->new() },
);

has tables => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);

sub all_tables { return @{ $_[0]->tables }; }

sub add_table {
    my $table = HTML::TableContent::Table->new($_[1]);
    push @{ $_[0]->tables }, $table;
    return $table;
}

sub add_caption_selectors { return push (@{ $_[0]->parser->caption_selectors }, @{ $_[1] }); }

sub get_table { return $_[0]->tables->[ $_[1] ]; }

sub get_first_table { return $_[0]->get_table(0); }

sub get_last_table { return $_[0]->get_table($_[0]->table_count - 1); }

sub clear_table { return splice @{ $_[0]->tables }, $_[1], 1; }

sub clear_first_table { return shift @{ $_[0]->tables }; }

sub clear_last_table { return $_[0]->clear_table( $_[0]->table_count - 1 ); } 

sub table_count { return scalar @{ $_[0]->tables }; }

sub filter_tables {
    my ( $self, %args ) = @_;

    my $tables = [];

    my @headers = ();
    if ( defined $args{headers} ) {
        push @headers, @{ $args{headers} };
    }
    elsif ( defined $args{header} ) {
        push @headers, $args{header};
    }

    foreach my $table ( $self->all_tables ) {
        if ( $table->header_exists(@headers) ) {
            $table->_filter_headers(@headers);
            push @{$tables}, $table;
        }
    }

    if ( $args{flex} && !scalar @{$tables} ) {
        carp 'none of the passed headers exist in any of the tables aborting filter - %s',
          join q{ }, @headers;
        return;
    }

    return $self->tables($tables);
}

sub headers_spec {
    my $self = shift;

    my $headers = {};
    for my $table ( $self->all_tables ) {
        for ( $table->all_headers ) { $headers->{ $_->lc_text }++ }
    }

    return $headers;
}

sub headers_exist {
    my ( $self, @headers ) = @_;

    my $header_spec = $self->headers_spec;

    for (@headers) { return 1 if $header_spec->{ lc $_ } }

    return 0;
}

sub raw {
    my $self = shift;

    my @tables = map { $_->raw } $self->all_tables;
    return \@tables;
}

sub render {
    my $self = shift;

    my @tables = map { $_->render } $self->all_tables;
    my $html = sprintf '%s' x @tables, @tables;
    return $html;
}

sub parse {
    my ( $self, $data ) = @_;

    $data =~ s/\<\!--|--\!\>//g;
    $self->parser->clear_current_tables;
    my $current_tables = $self->parser->parse($data);
    push @{ $self->tables }, @{$current_tables};
    return $current_tables;
}

sub parse_file {
    my ( $self, $file ) = @_;

    $self->parser->clear_current_tables;
    my $current_tables = $self->parser->parse_file($file);
    push @{ $self->tables }, @{$current_tables};
    return $current_tables;
}

sub create_table {
    my ($self, $options) = @_; 

    my $table_options = delete $options->{table} || { };

    my $table = $self->add_table($table_options);
    
    if ( exists $options->{aoa} ) {
        $table = $self->_create_from_aoa($table, $options);
    }
    elsif ( exists $options->{aoh} ) {
       $table = $self->_create_from_aoh($table, $options);
    }
    else {
        croak 'create_tables currently requires an array of arrays or an array of hashes representing the data.';
     }

    return $table;
}

sub _create_from_aoh {
    my ($self, $table, $options) = @_;

    my $aoh = $options->{aoh};
    my @headers = keys %{ $aoh->[0] };
    
    if (my $order = $options->{order}){
        my @heads = ( );
        foreach my $header (@{ $order }) {
            push @heads, grep { $_ =~ m/$header/ixms } @headers;
        }
        @headers = @heads;
    }

    unless ( defined $options->{no_headers} ) {
        for (@headers) {
            my $header_options = $self->_create_options('header', $options);
            $header_options->{text} = $_;
            $table->add_header($header_options);
        }
        @headers = $table->all_headers;
    }

    foreach my $hash ( @{ $aoh } ) {
        $options->{cells} =  $options->{rows}->[0]->{cells}; 
        my $row_options = $self->_create_options('row', $options);
        my $row = $table->add_row($row_options);
        for (@headers) {
            my $text = defined $options->{no_headers} ? $_ : $_->text;
            my $cell_options = $self->_create_options('cell', $options);
            $cell_options->{text} = $hash->{$text};
            my $cell = $row->add_cell($cell_options);
            unless ( defined $options->{no_headers} ) {
                $cell->header($_);
                push @{ $_->cells }, $cell;
            }
        }
    }

    return $table;
}

sub _create_from_aoa {
    my ($self, $table, $options) = @_;

    my @aoa = @{ $options->{aoa}};

    unless ( defined $options->{no_headers} ) {
        my $headers = shift @aoa;

        foreach my $header ( @{ $headers }) {
            my $header_options = $self->_create_options('header', $options);

            $header_options->{text} = $header;
            $table->add_header($header_options);
        }
    }

    for my $array ( @aoa ) {
        $options->{cells} = $options->{rows}->[0]->{cells};
        my $row_options = $self->_create_options('row', $options);
        my $row = $table->add_row($row_options);
        
        for my $text ( @{ $array } ) {
            my $cell_options = $self->_create_options('cell', $options);
            
            $cell_options->{text} = $text;
            
            my $cell = $row->add_cell($cell_options);
            $table->parse_to_column($cell);
        }
    }

    return $table;
}

sub _create_options {
    my ($self, $element, $options) = @_;

    my $element_options = { };
    
    if ( my $base = $options->{$element} ) {
        for ( keys %{ $base } ) {
            $element_options->{$_} = $base->{$_};
        }
    }

    my $elements = $element . 's';

    if ( my $custom = $options->{$elements} ) {
        my $first = shift @{ $options->{$elements} };
        for ( keys %{ $first } ) {
            $element_options->{$_} = $first->{$_};
        }
    }

    return $element_options;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::TableContent - HTML tables.

=head1 VERSION

Version 0.18 

=cut

=head1 SYNOPSIS

    use HTML::TableContent;
    my $t = HTML::TableContent->new();
    
    $t->parse_file('test.html'); 
   
    my @cell_ids = ( );
    foreach my $table ($t->all_tables) {
        push @cell_ids, map { $_->id } @{ $table->get_col('Email') };
    }

    .....

    $t->parse($html);

    my $first_table = $t->get_first_table;
    my $first_row = $first_table->get_first_row;
    
    foreach my $row ($first_table->all_rows) {
        push @column, $row->cells->[0];
    }

=head1 DESCRIPTION

Extract content from HTML tables. Create HTML tables from content.

=head1 SUBROUTINES/METHODS

=head2 parse

Parse $string as a chunk of html.

    $t->parse($string);

=head2 parse_file

Parse a file that contains html.

    $t->parse_file($string);

=head2 raw

Return underlying data structure

    $t->raw;   

=head2 render

Render all tables as HTML.

    $t->render;

=head2 tables

Array Ref containing L<HTML::TableContent::Table>'s

    $t->tables;

=head2 all_tables

Array containing L<HTML::TableContent::Table>'s

    $t->all_tables;

=head2 add_table

Add a new L<HTML::TableContent::Table>.

    $t->add_table({ id => 'my-first-table', class => 'something' });

=head2 table_count

Count number of tables found/stored.
    
    $t->table_count;

=head2 get_table

Get table by index.

    $t->get_table($index);

=head2 get_first_table

Get first table.

    $t->get_first_table;

=head2 get_last_table

Get last table.

    $t->get_last_table;

=head2 clear_table

Clear table by array index.

    $t->clear_table($index);

=head2 clear_first_table

Clear first table

    $t->clear_first_table;

=head2 clear_last_table

Clear last table.

    $t->clear_last_table;

=head2 headers_spec

Hash containing all table headers and their occurrence count.

    $t->headers_spec;

=head2 filter_tables

Filter all tables by a list of headers, only one header in the list has to match for the filter to run.

    $t->filter_tables(headers => qw/Name Email/);

Filter all tables for a single column.

    $t->filter_tables(header => 'Name');

Sometimes you want a little more flexibility.. i.e you want to keep your tables if none of the headers exist.

    $t->filter_tables(headers => qw/Name Email/, flex => 1);

=head2 headers_exist

Pass an Array of headers, if one of the headers match the truth is returned.

    $t->headers_exist(qw/Name Email/);

=head2 add_caption_selectors

The majority of people don't use captions, but a title above the table.

This method accepts an array of 'tags', 'ids' or 'classes' and will try to do something
sensible which generally means mapping the text to the selector it finds closest to the table. 

    my $t = HTML::TableContent->new();

    $t->add_caption_selectors(qw/id-1 id-2 id-3/);

    $t->parse($html);


=head2 create_table

Accepts a HashRef of options, it currently requires an Array of Arrays or an Array or Hashes as its data.

    $t->create_table({ aoa => $aoa });

    ...

    $t->create_table({ aoh => $aoh });

It will Assume the first array in the array of arrays is the array containing table headers, or for a hash its keys.
You can turn off headers by including the no_headers flag.

    $t->create_table({ aoa => $aoa, no_headers => 1 });

Hashes have no orderd, so to overcome this pass in an array of headers.

    $t->create_table({ aoh => $aoh, order => qw/id name address/ });

You can also set class, id, colspan, rowspan, style.

    my $options = {
        aoa => $aoa,
        table => { id => 'first-table' }, # set the table id
        header => { class => 'headers-class' }, # class 'headers-class' will be set on all headers'
        row => { class => 'rows-class' } # class 'row-class' will be set on all rows'
        cell => { class => 'cells-class' } # class 'cells-class' will be set on all cells'
        rows => [ 
            {
                id => 'first' # id for the first row
                cells => [ # cells belong to rows
                    {
                        id => 'one' # set id on the first cell inside the first row
                    }
                    ...
                ]
            }
            ...
        ],
        headers => [
            {
                id => 'first-header' # set id on the first header
            }
            ...
        ]
    };

    my $table = $t->create_table($options);

=head2 EXAMPLES

Text::CSV_XS

    use HTML::TableContent;
    use Text::CSV_XS qw( csv );

    my $aoa = csv ( in => 'test.csv' );

    my $tc = HTML::TableContent->new();

    my $table = $tc->create_table({ aoa => $aoa });

    $table->render;

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 DEPENDENCIES

L<Moo>,
L<HTML::Parser>,

L<HTML::TableContent::Parser>,
L<HTML::TableContent::Table>,
L<HTML::TableContent::Table::Caption>,
L<HTML::TableContent::Table::Header>,
L<HTML::TableContent::Table::Row>,
L<HTML::TableContent::Table::Row::Cell>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-html-tablecontentparser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-TableContent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::TableContent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-TableContent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-TableContent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-TableContent>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-TableContent/>

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT 

=head1 INCOMPATIBILITIES

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

