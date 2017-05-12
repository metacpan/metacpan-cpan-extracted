# Small utility functions used in testing the Maze code.

#  Make certain all of the lines of the maze are the same length.
sub normalize_maze
{
    my @lines = split( /\n/, shift );
    
    my $maxlen = 0;
    foreach my $len (map { length $_ } @lines)
    {
        $maxlen = $len if $len > $maxlen;
    }

    my $maxpad = ' ' x $maxlen;
    foreach my $line (@lines)
    {
        $line = substr( "$line$maxpad", 0, $maxlen ) if length $line;
    }
    
    join( "\n", @lines );
}


#
#  Split the maze into the form we will use for the transformations.
sub split_maze
{
    my $maze = shift;

    [ map { [ split //, $_ ] } split( /\n/, $maze ) ];
}

1;
