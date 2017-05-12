use strict;
use warnings;
use Test::More qw/no_plan/;
use FormValidator::LazyWay::Utils;
use CGI;
use utf8;

my $q = CGI->new( { key => 'value' , oppai => [ 'ippai','oppai' ] } ) ;
my $hash =  FormValidator::LazyWay::Utils::get_input_as_hash( $q ) ;
is_deeply( $hash , { key => 'value' ,  oppai => [ 'ippai','oppai' ] } );

