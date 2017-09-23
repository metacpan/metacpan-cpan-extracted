# ========================================================================== #
# t/tests/Test/JPList.pm  - JPList Request test cases
# Copyright (C) 2017 Exceleron Software, LLC
# ========================================================================== #

package Test::JPList;

use Test::Most;
use base 'Test::Class';
use DBI;

our $SQLITEDB="$FindBin::Bin/sqlite3.test.db";

sub class { 'JPList' }

# ========================================================================== #

sub startup : Tests(startup => 6)
{
    my $test = shift;

    my $class = $test->class;

    use_ok $class;
    can_ok $class, 'new';

    my $dbh = DBI->connect("dbi:SQLite:$SQLITEDB",'','',
                       {RaiseError=>1, PrintError=>0, AutoCommit=>0});

    #$sth = $dbh->prepare('SELECT * FROM "Items"') or die("$!");
    #my $data = $dbh->selectall_arrayref($sth, {Slice => {}}) or die("$!");
    $test->{dbh} = $dbh;
}

# ========================================================================== #

sub jplist : Tests
{
    my $test = shift;

    my $total_count = 31;
    my @request_status;

    push(
        @request_status,
        {
            'desc' => 'Items First Page Loading',
            'request_params' => "%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Description%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22Keyword1%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22Keyword2%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'items_returned'    => 10,
            'total_count' => $total_count
        }
    );
    push(
        @request_status,
        {
            'desc' => 'Items Second Page Loading',
            'request_params' => "%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Description%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22Keyword1%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22Keyword2%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A1%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%5D",
            'items_returned'    => 10,
            'total_count' => $total_count
        }
    );
    push(
        @request_status,
        {
            'desc' => 'Items Filter by title',
            'request_params' => "%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22Arch%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Description%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22Keyword1%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22Keyword2%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A7%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'items_returned'    => 2,
            'total_count' => 2
        }
    );

    my $i = 1;
    foreach my $data (@request_status) {
        pass("$i - Decoding Request for : " . $data->{'desc'});

        my $jp_resultset;

        my $jplist = $test->class->new
            ({
                dbh  => $test->{dbh},
                db_table_name  => 'Items', 
                request_params => $data->{'request_params'}
            });
        $jp_resultset = $jplist->get_resultset();
        
        is(
            scalar(@{$jp_resultset->{data}}),
            $data->{items_returned},
            'JPList returned ' . $data->{items_returned} . ' resultset data'
        );

        is($jp_resultset->{count}, $data->{total_count}, 'JPList total Items count is matching');

    }

}

# cleaning up test data from db
sub clean_test_data : Tests( shutdown )
{
    my $test     = shift;
}

1;

__END__

=back
   
=head1 LICENSE

Copyright (C) 2017 Exceleron Software, LLC

=head1 AUTHORS

Sheeju Alex, <sheeju@exceleron.com>

=head1 SEE ALSO

=cut

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3