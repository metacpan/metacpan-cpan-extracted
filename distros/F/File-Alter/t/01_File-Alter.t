use Test::More 'no_plan';
use strict;

BEGIN { chdir 't' if -d 't'; }
BEGIN { use File::Spec; require lib;
        lib->import( File::Spec->catdir(qw[.. lib]), 'inc' );
}        

sub _contents { return join '', map { "$_$/" } @_ };

my $Class   = 'File::Alter';
my $Input   = File::Spec->catfile( qw[inc in] );


use_ok( $Class );

### check we got a proper file back, right object, etc
{   my $fh = $Class->new( $Input );

    ok( $fh,                    "Opened $Input" );
    isa_ok( $fh,                $Class );
    
    for my $meth (qw[new alter remove insert as_string]) {
        can_ok( $Class,         $meth );
    }
    
    is( $fh->as_string, _contents(1..6),
                                "   Content as expected" );
}    

### test inserting a line
{   my $fh = $Class->new( $Input );
    ok( $fh->insert( 3 => $$ . $/ ),
                                "Added line $$" );
    is( $fh->as_string, _contents( 1..2, $$, 3..6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );

    ok( $fh->insert( 7 => $$ . $$ . $/ ),
                                "Added line ". $$.$$ );
    is( $fh->as_string, _contents( 1..2, $$, 3..5, $$.$$, 6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );                                
}                                


### test replacing a line
{   my $fh = $Class->new( $Input );
    ok( $fh->alter( qr/3/, qq/$$/, '$LINE == 3' ),
                                "Alter on condition" );

    is( $fh->as_string, _contents( 1..2, $$, 4..6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );
    
    ok( $fh->alter( qr/^1$/, qq/ONE/ ),
                                "Alter without condition" );

    is( $fh->as_string, _contents( 'ONE', 2, $$, 4..6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );

}

### test removing a line
{   my $fh = $Class->new( $Input );
    ok( $fh->remove( '$LINE == 3' ),
                                "Remove on condition" );
    is( $fh->as_string, _contents( 1..2, 4..6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );
    
    ok( $fh->remove( 1 ),       "Remove on line" );
    is( $fh->as_string, _contents( 2, 4..6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );
}

### test all accesses
{   my $fh = $Class->new( $Input );
    ok( $fh->alter(qr/1/,'ONE'),"Alter without condition" );
    ok( $fh->remove( 2 ),       "Remove on line" );
    ok( $fh->insert(2 => 'TWO' . $/),
                                "Insert on line" );

    is( $fh->as_string, _contents( qw[ONE TWO], 3..6 ),
                                "   Content as expected" );
    is( $fh->tell, 0,           "   Position reset" );
}

