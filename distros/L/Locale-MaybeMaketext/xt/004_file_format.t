#!perl
use strict;
use warnings;
use vars;
use Test2::V0;
use Test2::Plugin::BailOnFail;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use FindPerlFiles;
use Carp qw/carp croak/;
use Test2::Require::Module 'Test::EOL';
use Test2::Require::Module 'Test::NoTabs';
use Test::EOL();
use Test::NoTabs();
use feature qw/signatures/;
no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

FindPerlFiles::check_perl_files( \&check_file );
done_testing();

sub check_file ( $current_file, $filename ) {
    Test::EOL::eol_unix_ok( $current_file, { trailing_whitespace => 1 } );
    Test::NoTabs::notabs_ok($current_file);
    return 1;
}
