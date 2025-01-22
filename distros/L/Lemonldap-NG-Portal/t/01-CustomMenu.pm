use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use URI;
use URI::QueryParam;
use JSON;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            customPlugins      => "t::CustomMenu",
            portalDisplayOrder =>
              "Appslist ChangePassword Custom LoginHistory OidcConsents Logout",
            skinTemplateDir => 't/templates/',
            customMenuRule  => '$uid eq "dwho"',
        }
    }
);

subtest "Test menu tab ordering" => sub {
    my $instance = $client->p->menu;

# Test data format: portalDisplayOrder, unsorted menu items, expected sorted list of items, comment
    my @tests = ( [
            'Appslist ChangePassword LoginHistory OidcConsents Logout',
'Appslist ChangePassword LoginHistory OidcConsents Logout MyCustomPlugin',
'Appslist ChangePassword LoginHistory OidcConsents Logout MyCustomPlugin',
            'Custom plugins is added at the end'
        ],
        [
            'Appslist ChangePassword LoginHistory OidcConsents _unknown Logout',
'Appslist ChangePassword LoginHistory OidcConsents Logout MyCustomPlugin',
'Appslist ChangePassword LoginHistory OidcConsents MyCustomPlugin Logout',
'Custom plugins is added where the _unknown placeholder is (before Logout)'
        ],
        [
            '_unknown Appslist ChangePassword LoginHistory OidcConsents Logout',
'Appslist ChangePassword LoginHistory OidcConsents Logout MyCustomPlugin',
'MyCustomPlugin Appslist ChangePassword LoginHistory OidcConsents Logout',
'Custom plugins is added where the _unknown placeholder is (beginning)'
        ],
        [
'Appslist MyCustomPlugin ChangePassword LoginHistory OidcConsents _unknown Logout',
'Appslist ChangePassword LoginHistory OidcConsents Logout MyCustomPlugin MyOtherPlugin',
'Appslist MyCustomPlugin ChangePassword LoginHistory OidcConsents MyOtherPlugin Logout',
            'Use both explicit placement and _unknown placement',
        ],

    );

    for my $testdata (@tests) {
        my ( $displayOrder, $unsorted_str, $expected_str, $comment ) =
          @$testdata;

        # Construct a fake menuModules array
        # we randomize the initial list to make sure sorting always works
        my %tmp = map { $_ => 1 } split( /[,\s]+/, $unsorted_str );
        my @random_list_of_modules = keys %tmp;
        my $unsorted_menu          = [
            map {
                [ $_, sub { 1 } ]
            } @random_list_of_modules
        ];

        # Sort menu
        my @sorted_menu =
          $instance->_sort_menu( $unsorted_menu, $displayOrder );

        # Compare result to expected items
        my @sorted_items   = map { $_->[0] } @sorted_menu;
        my @expected_items = split( /[,\s]+/, $expected_str );
        is_deeply( \@sorted_items, \@expected_items, $comment );

    }
};

subtest "Test custom tab display" => sub {
    my $id = $client->login("dwho");

    my $res =
      $client->_get( "/", accept => "text/html", cookie => "lemonldap=$id" );

    my @ids = expectXpath( $res, '//li[@class="nav-item"]//a/@href' )
      ->map( sub { $_[0]->getValue() } );
    is_deeply(
        \@ids,
        [ '#appslist', '#password', '#myplugin', '#loginHistory', '#logout' ],
        "Correct tab ordering"
    );

    expectXpath(
        $res,
        '//li[@class="nav-item"]//a[@href="#myplugin"]',
        "Found custom tab link in navbar"
    );
    expectXpath(
        $res,
        '//li[@class="nav-item"]//i[@class="fa fa-wrench"]',
        "Found custom tab icon in navbar"
    );
    expectXpath(
        $res,
        '//li[@class="nav-item"]//span[@trspan="myplugin"]',
        "Found custom tab label in navbar"
    );
    my $xml = expectXpath(
        $res,
        '//div[@id="myplugin"]//div[@id="customdiv"]',
        "Found custom div in HTML content"
    );

    is( $xml->pop()->textContent(),
        "dwho", "Template engine sees session attributes" );
};

subtest "Test custom tab not displayed for non-matching user" => sub {
    my $id = $client->login("rtyler");

    my $res =
      $client->_get( "/", accept => "text/html", cookie => "lemonldap=$id" );

    ok(
        !getHtmlElement(
            $res, '//li[@class="nav-item"]//a[@href="#myplugin"]'
        ),
        "Custom menu tab not displayed"
    );
};

#diag explain $res;

done_testing();
