# ========================================================================== #
# t/tests/Test/JPList/Request.pm  - JPList Request test cases
# Copyright (C) 2017 Exceleron Software, LLC
# ========================================================================== #

package Test::JPList::Request;

use Test::Most;
use base 'Test::Class';
use Data::Dumper;

sub class { 'JPList::Request' }

# ========================================================================== #

sub startup : Tests(startup => 3)
{
    my $test = shift;

    my $class = $test->class;

    use_ok $class;

    $test->{jplist_req} = new_ok $class;
}

sub requests : Tests
{
    my $test = shift;

    my @request_status;

    #First visit
    push(
        @request_status,
        {
            'desc' => 'First Visit',
            'request_params' =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'sort_data' => [
                {
                    'column' => 'default',
                    'order'  => 'asc'
                }
            ],
            'pagination_data' => {
                'number' => '10'
            },
            'filter_data' => []
        }
    );

    #2nd page
    push(
        @request_status,
        {
            'desc' => 'Paging 2',
            'request_params' =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'filter_data'     => [],
            'pagination_data' => {
                'number' => '10'
            },
            'sort_data' => [
                {
                    'column' => 'default',
                    'order'  => 'asc'
                }
            ],
        }
    );

    #3rd page grid view
    push(
        @request_status,
        {
            desc => '3rd page grid view',
            request_params =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-grid-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A2%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%5D",
            'pagination_data' => {
                'number'      => '10',
                'currentPage' => 2
            },
            'sort_data' => [
                {
                    'column' => 'default',
                    'order'  => 'asc'
                }
            ],
            'filter_data' => [],
        }
    );

    #3rd filter by title arch
    push(
        @request_status,
        {
            desc => '3rd filter by title arch',
            request_params =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22Arc%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-grid-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A7%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A2%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'filter_data' => [
                {
                    'column' => 'title',
                    'value' => 'Arc',
                    'type' => 'like'               
                }
            ],
            'sort_data' => [
                {
                    'column' => 'default',
                    'order'  => 'asc'
                }
            ],
            'pagination_data' => {
                'number'      => '10',
                'currentPage' => 2
            }
        }
    );

    #filter by title category architecture
    push(
        @request_status,
        {
            desc => 'filter by title category architecture',
            request_params =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-grid-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22.architecture%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A7%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'pagination_data' => {
                'number' => '10'
            },
            'sort_data' => [
                {
                    'order'  => 'asc',
                    'column' => 'default'
                }
            ],
            'filter_data' => [
                {
                    'value'  => 'architecture',
                    'column' => 'category-dropdown-filter'
                }
            ],
        }
    );

    #filter by title category christmas
    push(
        @request_status,
        {
            desc => 'filter by title category christmas',
            request_params =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22type%22%3A%22%22%2C%22order%22%3A%22%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22.christmas%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A7%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'pagination_data' => {
                'number' => '10'
            },
            'sort_data' => [
                {
                    'column' => 'default',
                    'order'  => 'asc'
                }
            ],
            'filter_data' => [
                {
                    'column' => 'category-dropdown-filter',
                    'value'  => 'christmas'
                }
            ]
        }
    );

    #sort in desc order
    push(
        @request_status,
        {
            desc => 'sort in desc order',
            request_params =>
"%5B%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%2210%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A0%7D%2C%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22type%22%3A%22text%22%2C%22order%22%3A%22desc%22%2C%22dateTimeFormat%22%3A%22%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22title-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.title%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22desc-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.desc%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22views%22%2C%22name%22%3A%22views%22%2C%22type%22%3A%22views%22%2C%22data%22%3A%7B%22view%22%3A%22jplist-list-view%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22category-dropdown-filter%22%2C%22type%22%3A%22filter-drop-down%22%2C%22data%22%3A%7B%22path%22%3A%22default%22%2C%22filterType%22%3A%22path%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A5%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22themes%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22colors%22%2C%22type%22%3A%22checkbox-group-filter%22%2C%22data%22%3A%7B%22pathGroup%22%3A%5B%5D%2C%22filterType%22%3A%22pathGroup%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A8%7D%5D",
            'filter_data' => [],
            'sort_data'   => [
                {
                    'column' => 'title',
                    'order'  => 'desc'
                }
            ],
            'pagination_data' => {
                'number' => '10'
            },
        }
    );

    #meters_with_missing_usage sort in desc order "meternumber"
    push(
        @request_status,
        {
            desc => 'sort in desc order "meternumber"',
            request_params =>
"%5B%7B%22action%22%3A%22sort%22%2C%22name%22%3A%22sort%22%2C%22type%22%3A%22sort-select%22%2C%22data%22%3A%7B%22path%22%3A%22.MeterNumber%22%2C%22type%22%3A%22text%22%2C%22order%22%3A%22desc%22%2C%22dateTimeFormat%22%3A%22%7Bmonth%7D%2F%7Bday%7D%2F%7Byear%7D%22%2C%22ignore%22%3A%22%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22id-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Id%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A1%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22meternumber-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.MeterNumber%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A2%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22metertype-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.MeterType%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A3%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22accountname-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.AccountName%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A4%7D%2C%7B%22action%22%3A%22filter%22%2C%22name%22%3A%22balance-filter%22%2C%22type%22%3A%22textbox%22%2C%22data%22%3A%7B%22path%22%3A%22.Balance%22%2C%22ignore%22%3A%22%5B~!%40%23%24%25%5E%26*()%2B%3D%60'%5C%22%2F%5C%5C_%5D%2B%22%2C%22value%22%3A%22%22%2C%22mode%22%3A%22contains%22%2C%22filterType%22%3A%22TextFilter%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22items-per-page-drop-down%22%2C%22data%22%3A%7B%22number%22%3A%225%22%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%2C%22initialIndex%22%3A6%7D%2C%7B%22action%22%3A%22paging%22%2C%22name%22%3A%22paging%22%2C%22type%22%3A%22pagination%22%2C%22data%22%3A%7B%22currentPage%22%3A0%2C%22paging%22%3Anull%7D%2C%22inStorage%22%3Atrue%2C%22inAnimation%22%3Atrue%2C%22isAnimateToTop%22%3Afalse%2C%22inDeepLinking%22%3Atrue%7D%5D",
            'filter_data' => [],
            'sort_data'   => [
                {
                    'column' => 'MeterNumber',
                    'order'  => 'desc'
                }
            ],
            'pagination_data' => {
                'number' => '5'
            },
        }
    );

    my $i = 1;
    foreach my $data (@request_status) {
        pass("$i - Decoding Request for : " . $data->{'desc'});

        my $jplist_req = JPList::Request->new(request_params => $data->{'request_params'});
        $jplist_req->decode_data();

        #print Dumper $jplist_req;

        is_deeply($jplist_req->filter_data,     $data->{filter_data},     "$i - filter_data matched");
        is_deeply($jplist_req->sort_data,       $data->{sort_data},       "$i - sort_data matched");
        is_deeply($jplist_req->pagination_data, $data->{pagination_data}, "$i - pagination_data matched");

        $i++;
    }
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

