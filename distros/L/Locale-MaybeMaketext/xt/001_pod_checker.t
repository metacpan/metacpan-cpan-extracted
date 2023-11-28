#!perl
use strict;
use warnings;
use vars;
use Test2::V0;
use Test2::Plugin::BailOnFail;
use Test2::Require::Module 'Pod::Checker';
use Pod::Checker;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use FindPerlFiles;
use Carp    qw/carp croak/;
use feature qw/signatures/;
no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

FindPerlFiles::check_perl_module_files( \&check_file, );
done_testing();

sub check_file ( $current_file, $filename ) {
    my ($checker_results) = (q{});

    my $checker = Pod::Checker->new();
    if (
        !eval {

            #local *STDERR;
            open STDERR, '>>',
              \$checker_results || croak( sprintf( 'Unable to redirect stderr whilst processing %s', $current_file ) );
            $checker->parse_from_file( $current_file, \*STDERR );
            return 1;
        }
    ) {
        fail("POD: Failed to run POD checker on $current_file: $@");
        next;
    }
    my ( $num_errors, $num_warnings ) = ( $checker->num_errors(), $checker->num_warnings() );
    if ( $current_file =~ /\.pm\z/ ) {    # does it look like a package
        $filename = substr(
            $filename =~ s{\/}{::}gr,
            0,
            -3                            ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
        );
    }

    if ( $num_errors == 0 && $num_warnings == 0 ) {
        pass( sprintf( 'POD: %s: Passed', $filename ) );
    }
    elsif ( $num_errors < 0 ) {
        fail( sprintf( 'POD: %s: No POD documentation found', $filename ) );
    }
    else {
        $checker_results =~ s/$current_file/$filename/g;    # make the messages a bit shorter
        fail(
            sprintf( 'POD: %s: Failed with %d errors and %d warnings', $filename, $num_errors, $num_warnings ),
            $checker_results
        );
    }
    return 1;
}
