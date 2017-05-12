package HTML::Robot::Scrapper::Writer::TestWriter;
use Moose;

=head1 DESCRIPTION

The Writer will handle collected data and save it anywhere you want.. ie disk, db, queue etc.

The idea is: 

- keep 'parser/reading' stuff into "Reader" classes

- keep 'saving/writing' stuff into "Writer" classes

That way its possible to replace the Writer class any time... 

and many Readers can use the same Writer class

=cut

my $FIELDS = {
    data_to_save => { ##use anything
        is => 'rw',
    },
};

foreach my $f ( keys %$FIELDS ) {
    has $f => ( is => $FIELDS->{ $f }->{ is } );
}

sub save_data {
    my ( $self, $data ) = @_; 
    $self->data_to_save( $data );
    print "Data saved...into memory!\n";
}

1;
