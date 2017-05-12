use Test::More;
use HTML::Lint;

sub checkit {
    my @expected = @{+shift};
    my @linesets = @_;

    plan( tests => 3*(scalar @expected) + 4 );

    my $lint = new HTML::Lint;
    isa_ok( $lint, 'HTML::Lint', 'Created lint object' );

    my $n;
    for my $set ( @linesets ) {
        ++$n;
        $lint->newfile( "Set #$n" );
        $lint->parse( $_ ) for @$set;
        $lint->eof;
    }

    my @errors = $lint->errors();
    is( scalar @errors, scalar @expected, 'Right # of errors' );

    while ( @errors && @expected ) {
        my $error = shift @errors;
        isa_ok( $error, 'HTML::Lint::Error' );

        my $expected = shift @expected;

        is( $error->errcode, $expected->[0], 'Error codes match' );
        my $match = $expected->[1];
        if ( ref $match eq "Regexp" ) {
            like( $error->as_string, $match, 'Error matches regex' );
        }
        else {
            is( $error->as_string, $match, 'Error matches string' );
        }
    }

    my $dump;

    is( scalar @errors, 0, 'No unexpected errors found' ) or $dump = 1;
    is( scalar @expected, 0, 'No expected errors missing' ) or $dump = 1;

    if ( $dump && @errors ) {
        diag( "Leftover errors..." ); 
        diag( $_->as_string ) for @errors;
    }
}

# Read in a set of sets of lines, where each "file" is separated by a
# blank line in <DATA>
sub get_paragraphed_files {
    local $/ = "";

    my @sets;

    while ( my $paragraph = <DATA> ) {
        my @lines = split /\n/, $paragraph;
        @lines = map { "$_\n" } @lines;
        push( @sets, [@lines] );
    }

    return @sets;
}

1; # happy
