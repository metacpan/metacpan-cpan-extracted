use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic three header vertical table" => sub {
    plan tests => 20;
    run_tests({
        file => 't/html/vertical/basic.html',
        table_count => 1,
        row_count => 1,
        header_count => 3,
        first_header_text => 'Name:',
        first_header_cell_count => 1,
        first_header_cell_text => 'Bill Thing'
    });
};

subtest "two basic three header vertical table" => sub {
    plan tests => 20;
    run_tests({
        file => 't/html/vertical/two-basic.html',
        table_count => 2,
        row_count => 1,
        header_count => 3,
        first_header_text => 'Telephone:',
        first_header_cell_count => 1,
        first_header_cell_text => '555 77 854'
    });
};

subtest "three basic three header vertical table" => sub {
    plan tests => 20;
    run_tests({
        file => 't/html/vertical/three-basic.html',
        table_count => 3,
        row_count => 1,
        header_count => 3,
        first_header_text => 'Naam:',
        first_header_cell_count => 1,
        first_header_cell_text => 'Bill Ding'
    });
};

done_testing();

sub open_file {
    my $file = shift;

    open ( my $fh, '<', $file ) or croak "could not open html: $file"; 
    my $html = do { local $/; <$fh> };
    close $fh;
    
    return $html;
}

sub run_tests {
    my $args = shift;

    my $file = $args->{file};
    
    my @loops = qw/parse parse_file/;

    foreach my $loop ( @loops ) {
        my $t = HTML::TableContent->new();
        if ( $loop eq 'parse' ) {
            my $html = open_file($file);
            ok($t->parse($html));
        }
        else {
            ok($t->parse_file($file));
        }

        is($t->table_count, $args->{table_count}, "correct table count $args->{table_count}");

        ok(my $table = $t->get_first_table, "get first table");

        is($table->header_count, $args->{header_count}, "correct header count: $args->{header_count}");

        is($table->row_count, $args->{row_count}, "correct row count: $args->{row_count}");

        ok(my $header = $table->get_first_header, "get first header");

        is($header->text, $args->{first_header_text}, "first header text: $args->{first_header_text}");

        is($header->cell_count, $args->{first_header_cell_count}, "cell count: $args->{first_header_cell_count}");

        ok(my $first_cell = $header->get_first_cell, "get first header cell");

        is($first_cell->text, $args->{first_header_cell_text}, "first header cell text: $args->{first_header_cell_text}");
    }
}

1;
