use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 20;
    my $html = open_file('t/html/horizontal/simple-two-column-table.html');
    run_tests({
        html => $html,
        table_count => 1,
        header_spec => {
            'savings' => 1,
            'month' => 1
        },
        header_count => 2,
        filter_headers => ['savings', 'month'],
        after_header_count => 2,
        after_header_spec => {
            'savings' => 1,
            'month' => 1,
        },
        after_table_count => 1,
    });
    run_tests({
        html => $html,
        table_count => 1,
        header_spec => {
            'savings' => 1,
            'month' => 1
        },
        header_count => 2,
        filter_headers => ['savings'],
        after_header_count => 1,
        after_header_spec => {
            'savings' => 1
        },
        after_table_count => 1,
    });
};

subtest "simple_three_column_table" => sub {
    plan tests => 30;
    my $html = open_file('t/html/horizontal/simple-three-column-table.html');
    run_tests({
        html => $html,
        table_count => 1,
        header_spec => {
            'last name' => 1,
            'first name' => 1,
            'email' => 1
        },
        header_count => 3,
        filter_headers => ['first name', 'last name', 'email'],
        after_header_count => 3,
        after_header_spec => {
            'first name' => 1,
            'last name' => 1,
            'email' => 1,
        },
        after_table_count => 1,
    });
    run_tests({
        html => $html,
        table_count => 1,
         header_spec => {
            'last name' => 1,
            'first name' => 1,
            'email' => 1
        },
        header_count => 3,
        filter_headers => ['first name', 'email'],
        after_header_count => 2,
        after_header_spec => {
            'first name' => 1,
            'email' => 1,
        },
        after_table_count => 1,
    });
    run_tests({
        html => $html,
        table_count => 1,
        header_spec => {
            'last name' => 1,
            'first name' => 1,
            'email' => 1
        },
        header_count => 3,
        first_table_header_count => 3,
        filter_headers => ['email'],
        after_header_count => 1,
        after_header_spec => {
            'email' => 1,
        },
        after_table_count => 1,
    });
};

subtest "page_two_tables" => sub {
    plan tests => 20;
    my $html = open_file('t/html/horizontal/page-two-tables.html');
    run_tests({
        html => $html,
        table_count => 2,
        header_spec => {
            'expenditure' => 1,
            'savings' => 1,
            'month' => 2
        },
        filter_headers => [qw/expenditure month savings/],
        header_count => 2,
        after_header_count => 2,
        after_header_spec => {
            'expenditure' => 1,
            'month' => 2,
            'savings' => 1,
        },
        after_table_count => 2,
    });
    run_tests({
        html => $html,
        table_count => 2,
        header_spec => {
            'expenditure' => 1,
            'savings' => 1,
            'month' => 2
        },
        filter_headers => [qw/expenditure savings/],
        header_count => 2,
        after_header_count => 1,
        after_header_spec => {
            'expenditure' => 1,
            'savings' => 1,
        },       
        after_table_count => 2,
    });
};

subtest "page_three_tables" => sub {
    plan tests => 30;
    my $html = open_file('t/html/horizontal/page-three-tables.html');
    run_tests({
        html => $html,
        table_count => 3,
        header_spec => {
          'first name' => 3,
          'last name' => 3,
          'email' => 3
        },
        header_count => 3,
        filter_headers => ['first name', 'last name', 'email'],
        after_header_count => 3,
        after_header_spec => {
            'first name' => 3,
            'last name' => 3,
            'email' => 3,
        },
        after_table_count => 3,
    });
    run_tests({
        html => $html,
        table_count => 3,
        header_spec => {
          'first name' => 3,
          'last name' => 3,
          'email' => 3
        },      
        filter_headers => ['first name', 'last name'],
        header_count => 3,
        after_header_count => 2,
        after_header_spec => {
            'first name' => 3,
            'last name' => 3,
        },
        after_table_count => 3,
    });
    run_tests({
        html => $html,
        table_count => 3,
        header_spec => {
          'first name' => 3,
          'last name' => 3,
          'email' => 3
        },
        filter_headers => ['first name'],
        header_count => 3,
        after_header_count => 1,
        after_header_spec => {
            'first name' => 3
        },
        after_table_count => 3,
    });
};

subtest "page_three_tables" => sub {
    plan tests => 30;
    my $html = open_file('t/html/horizontal/page-random-tables.html');
    run_tests({
        html => $html,
        table_count => 3,
        header_spec => {
          'first name' => 1,
          'last name' => 1,
          'email' => 1,
          'year' => 2,
          'month' => 2,
          'savings' => 1,
          'expence' => 1,
        },
        filter_headers => ['first name', 'last name', 'email'],
        header_count => 3,
        after_header_count => 3,
        after_header_spec => {
            'first name' => 1,
            'last name' => 1,
            'email' => 1,
        }, 
        after_table_count => 1,
    });
    run_tests({
        html => $html,
        table_count => 3,
        header_spec => {
          'first name' => 1,
          'last name' => 1,
          'email' => 1,
          'year' => 2,
          'month' => 2,
          'savings' => 1,
          'expence' => 1,
        },
        filter_headers => ['first name'],
        header_count => 3,
        after_header_count => 1,
        after_header_spec => {
            'first name' => 1
        },      
        after_table_count => 1,
    });
    run_tests({
        html => $html,
        table_count => 3,
        header_spec => {
          'first name' => 1,
          'last name' => 1,
          'email' => 1,
          'year' => 2,
          'month' => 2,
          'savings' => 1,
          'expence' => 1,
        },
        filter_headers => [qw/year month savings/],
        header_count => 3,
        after_header_count => 3,
        after_header_spec => {
            'year' => 2,
            'month' => 2,
            'savings' => 1
        },
        after_table_count => 2,
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
    
    ok($t->parse($args->{html}), "parse html into HTML::TableContent");

    is($t->table_count, $args->{table_count}, "expected table count: $args->{table_count}");
    
    ok(my $header_spec = $t->headers_spec);
    
    is_deeply($header_spec, $args->{header_spec}, "expected header spec");

    is($t->tables->[0]->header_count, $args->{header_count}, "header count: $args->{header_count}");

    my @headers = $args->{filter_headers};

    ok($t->filter_tables(headers => @headers));    

    is($t->tables->[0]->header_count, $args->{after_header_count}, "expected after header count $args->{after_header_count}");

    ok($header_spec = $t->headers_spec);

    is_deeply($header_spec, $args->{after_header_spec}, "expected after header spec");
    
    is($t->table_count, $args->{after_table_count}, "expected after table count: $args->{after_table_count}");
}

1;
