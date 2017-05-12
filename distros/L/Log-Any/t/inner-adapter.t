use strict;
use warnings;
use Test::More;

plan tests => 2;

our $BUF;

package MyApp::Log::Adapter;
use base qw(Log::Any::Adapter::Base);
foreach my $method ( Log::Any->logging_methods() ) {
    no strict 'refs';
    *$method = sub { $main::BUF .= "$_[1]\n"};
}
foreach my $method ( Log::Any->detection_methods() ) {
    no strict 'refs';
    *$method = sub { 1 };
}

package main;
use Log::Any::Adapter;
eval { Log::Any::Adapter->set('+MyApp::Log::Adapter') };
is( $@, "", "setting inner package as adapter is OK");

my $log = Log::Any->get_logger;

$log->critical("DIE DIE DIE");
is( $BUF, "DIE DIE DIE\n", "logged a message via inner adapter" );
