#!perl
use strict;
use warnings;
use vars;
use Test2::V0;
use Test2::Formatter::TAP;
use Test2::Plugin::BailOnFail;
use Test2::Require::Module 'Pod::Coverage';
use Pod::Coverage;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use FindPerlFiles;
use Carp    qw/carp croak/;
use feature qw/signatures/;
no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

FindPerlFiles::check_perl_module_files( \&check_file, FindPerlFiles::get_lib_folder() );
done_testing();

sub check_file ( $full_path, $filename ) {
    my $package_name = substr(
        $filename =~ s{\/}{::}gr,
        0,
        -3    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    );
    local @INC = @INC;
    unshift @INC, substr( $full_path, 0, -length($filename) );

    #require $full_path;
    my $pc = Pod::Coverage->new( package => $package_name );

    if ( !defined( $pc->coverage ) ) {
        fail( sprintf( 'No coverage found for %s', $package_name ), $pc->why_unrated );
    }
    ok(
        $pc->coverage == 1,
        sprintf(
            'Check POD coverage of %s: %0.2f%%',
            $package_name,
            ( $pc->coverage * 100 )    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
        ),
        'Uncovered routines:',
        $pc->uncovered
    );
    return 1;
}
