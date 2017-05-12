#!/usr/bin/perl

use strict;
use warnings;

package MockCGI;

sub new
{
    my $self = {};
    bless $self, shift;
    return $self;
}

sub redirect
{
    my ($self, $path) = (@_);
    return "ReDirect-To: $path";
}

sub script_name
{
    my $self = shift;
    return "{{{Script Name}}}";
}

package main;

use vars qw($exit_count);

BEGIN
{
    *CORE::GLOBAL::exit = sub { $exit_count++; };
}

use lib './t/lib';

use Test::More tests => 6;

use HTML::Widgets::NavMenu::Test::Data;
use HTML::Widgets::NavMenu::Test::Stdout;

use HTML::Widgets::NavMenu;

my $test_data = get_test_data();

{
    eval {
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "",
        @{$test_data->{'minimal'}},
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );
    };
    # TEST
    isa_ok ($@, "HTML::Widgets::NavMenu::Error::Redirect", "\$@");
    reset_out_buffer();
    $exit_count = 0;
    $@->CGIpm_perform_redirect(MockCGI->new());
    # TEST
    is(get_out_buffer(), "ReDirect-To: {{{Script Name}}}/",
        "Checking that redirect-to works");
    # TEST
    is($exit_count, 1, "Counting an exit");
}

{
    eval {
    my $nav_menu = HTML::Widgets::NavMenu->new(
        'path_info' => "/hello/world//",
        @{$test_data->{'minimal'}},
        'ul_classes' => [ "navbarmain", ("navbarnested") x 5 ],
    );
    };
    # TEST
    isa_ok ($@, "HTML::Widgets::NavMenu::Error::Redirect", "\$@");
    reset_out_buffer();
    $exit_count = 0;
    $@->CGIpm_perform_redirect(MockCGI->new());
    # TEST
    is(get_out_buffer(), "ReDirect-To: {{{Script Name}}}/hello/world/",
        "Checking that redirect-to works");
    # TEST
    is($exit_count, 1, "Counting an exit");
}

