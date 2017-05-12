package Tests;

use Getopt::Long;

require Exporter;
use vars qw( @ISA @EXPORT );

@ISA = qw( Exporter );
@EXPORT = qw( $opt_verbose @tests @test_files );

use vars qw( $opt_verbose );
GetOptions qw( verbose );

@test_files = map { "eg/test$_.html" } ( 1 .. 4 );
@tests = (
    { q => 'some', paths => [ 'eg/test1.html', 'eg/test2.html' ] },
    { q => 'some OR stuff', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html' ] },
    { q => 'some stuff', paths => [ 'eg/test1.html', 'eg/test2.html' ] },
    { q => 'some AND stuff', paths => [ 'eg/test1.html', 'eg/test2.html' ] },
    { q => 'some and stuff', paths => [ 'eg/test1.html', 'eg/test2.html' ] },
    { q => 'some OR more', paths => [ 'eg/test1.html', 'eg/test2.html' ] },
    { q => 'some AND stuff AND NOT more', paths => [ 'eg/test1.html' ] },
    { q => 'some AND stuff AND NOT sample', paths => [ 'eg/test2.html' ] },
    { q => '( more AND stuff ) OR ( sample AND stuff )', paths => [ 'eg/test1.html', 'eg/test2.html', 'eg/test4.html' ] },
    { q => 'some AND more', paths => [ 'eg/test2.html' ] },
    { q => 'some AND sample AND stuff', paths => [ 'eg/test1.html' ] },
    { q => 'some AND NOT stuff', paths => [ ] },
    { q => 'hyphenated-word', paths => [ 'eg/test1.html' ] },
    { q => 'hyphenated AND word', paths => [ 'eg/test1.html' ] },
    { q => 'different', paths => [ 'eg/test3.html' ] },
    { q => 'invisible', paths => [ ] },
);

1;
