use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 6;
    my $html = open_file('t/html/horizontal/page-two-tables.html');
    run_tests({
        html => $html,
        get_first_table => 1,
        get_first_header => 1,
        cell_count => 2,
        raw => {
          'text' => 'Month',
          'data' => [
                      'Month'
                    ],
          'class' => 'month'
        }, 
        get_first_cell => 1,
    });
};

subtest "basic_two_column_table_file" => sub {
    plan tests => 6;
    my $file = 't/html/horizontal/page-two-tables.html';
    run_tests({
        file => $file,
        get_first_table => 1,
        get_first_header => 1,
        cell_count => 2,
        raw => {
          'text' => 'Month',
          'data' => [
                      'Month'
                    ],
          'class' => 'month'
        },
        get_first_cell => 1,
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

    my $t = HTML::TableContent->new();
    
    if (my $html = $args->{html} ) {    
        ok($t->parse($args->{html}), "parse html into HTML::TableContent");
    } else {
        ok($t->parse_file($args->{file}, "parse file into HTML::TableContent"));
    }

    ok(my $table = $t->get_first_table, "get first table");
      
    ok(my $header = $table->get_first_header, "get first header");

    is($header->cell_count, $args->{cell_count}, "expected header cell count");

    is_deeply($header->raw, $args->{raw}, "expected header raw structure - current doesn't hash cells");
       
    ok( $header->get_first_cell, "okay get first cell" );
}

1;
