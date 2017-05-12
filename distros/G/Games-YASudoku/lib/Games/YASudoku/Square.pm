package Games::YASudoku::Square;

# Andrew Wyllie <wyllie@dilex.net>
# July 2005

=head1 MODULE

Games::YASudoku::Square

=head1 DESCRIPTION

this object will be used to represent a single square
on the sudoku board.

=head1 METHODS

=over

=cut


=item B<new( $id )>

create a new square on the board at location $id

=cut

sub new {
    my $proto = shift;
    my $class = ref ( $proto ) || $proto;

    # this is the element_id
    my $id = shift;

    my $self  = {
	id    => $id,
        value => undef,
	valid => {}
    };

    bless $self, $class;
}


=item B<id>

get the id of the element

=cut

sub id {
    my $self = shift;
    return $self->{'id'};
}


=item B<value>

get or set the value for this square

=cut

sub value {
    my $self = shift;
    my $value = shift;

    $self->{'value'} = $value if $value;

    return $self->{'value'};
}


=item B<valid>

get the  values in the valid array.

=cut

sub valid {
    my $self = shift;
    @valid = sort( keys %{$self->{'valid'}} );
    return \@valid;
}


=item B<valid_add>

add a number to the valid array

=cut

sub valid_add {
    my $self = shift;
    my $number = shift;
    
    $self->{'valid'}{ $number } = $number;
    return $number;
}


=item B<valid_del>

remove a number from the valid array

=cut

sub valid_del {
    my $self = shift;
    my $number = shift;

    delete $self->{'valid'}{ $number } if $self->{'valid'}{ $number };
}

1;


=head1 AUTHOR

Andrew Wyllie <wyllie@dilex.net>

=head1 BUGS

Please send any bugs to the author

=head1 COPYRIGHT

The Games::YASudoku moudule is free software and can be redistributed
and/or modified under the same terms as Perl itself.

