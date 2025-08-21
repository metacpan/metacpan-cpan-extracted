
# name space for color names, translate values > names & back, find closest name

package Graphics::Toolkit::Color::Name::Scheme;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Hub;
use Graphics::Toolkit::Color::Space::Util qw/round_int uniq/;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space_name();

#### constructor #######################################################
sub new {
    my $pkg = shift;
    bless { shaped => {name => [], values => {}}, normal => {} }
}
sub add_color {
    my ($self, $name, $values) = @_;
    return 0 if not defined $name or ref $values ne 'ARRAY' or @$values != 3  or $self->is_name_taken($name);
    $name = _clean_name( $name );
    $self->{'shaped'}{'values'}{$name} = $values;
    $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]] =
        (exists $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]])
       ? [@{$self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]]}, $name]
       : [$name];
    1;
}

#### exact getter ######################################################
sub all_names { keys %{$_[0]->{'shaped'}{'values'}} }
sub is_name_taken {
    my ($self, $name) = @_;
    (exists $self->{'shaped'}{'values'}{_clean_name($name)}) ? 1 : 0;
}
sub values_from_name {
    my ($self, $name) = @_;
    return unless defined $name;
    $name = _clean_name($name);
    return $self->{'shaped'}{'values'}{$name} if exists $self->{'shaped'}{'values'}{$name};
}
sub names_from_values {
    my ($self, $values) = @_;
    return '' unless ref $values eq 'ARRAY' and @$values == 3;
    return '' unless exists $self->{'shaped'}{'name'}[$values->[0]];
    return '' unless exists $self->{'shaped'}{'name'}[$values->[0]][$values->[1]];
    return '' unless exists $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]];
    return                  $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]];
}

#### nearness methods ##################################################
sub closest_names_from_values {
    my ($self, $values) = @_;
    return '' unless ref $values eq 'ARRAY' and @$values == 3;
    my $names = names_from_values( $values );
    return ($names, 0) if ref $names;
    my @names;
    my $sqr_min  = 1 + 255**3;
    my $all_values = $self->{'shaped'}{'values'};
    for my $index_name (keys %$all_values){
        my $index_values = $all_values->{ $index_name };
        my $temp_sqr_sum = ($index_values->[0] - $values->[0]) ** 2;
        next if $temp_sqr_sum > $sqr_min;
        $temp_sqr_sum += ($index_values->[1] - $values->[1]) ** 2;
        next if $temp_sqr_sum > $sqr_min;
        $temp_sqr_sum += ($index_values->[2] - $values->[2]) ** 2;
        next if $temp_sqr_sum > $sqr_min;
        @names = ($sqr_min == $temp_sqr_sum) ? (@names, $index_name) : $index_name;
        $sqr_min = $temp_sqr_sum;
    }
    return '' unless @names;
    # restore as much order as possible
    @names = map { @{$self->names_from_values( $self->values_from_name($_))} } @names;
    @names = uniq( @names );
    return (\@names, sqrt($sqr_min));
}

sub names_in_range {
    my ($self, $values, $range, $space_name) = @_;
}

#### util ##############################################################
sub _clean_name {
    my $name = shift;
    $name =~ tr/_'//d;
    lc $name;
}

1;
#    my $names = $scheme->names_in_range( $values, $distance ); #       -> ARRAY of names
__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Name::Scheme - a name space for color names

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Name::Scheme;
    my $scheme = Graphics::Toolkit::Color::Name::Scheme->new();
    $scheme->add_color( $_->{'name'}, $_->{'rgb_values'} ) for @colors;
    say for $scheme->all_names();
    my $values = $scheme->values_from_name( 'blue' );          # tuple = 3 element ARRAY
    my $names = $scheme->names_from_values( $values );         # tuple -> ARRAY of names
    my ($names, $distance) = $scheme->closest_name( $values ); # tuple -> \@names, $distance


=head1 DESCRIPTION

This module is mainly for internal usage to model name spaces for HTML,
SVG, Pantone ... colors. You may Use it to create your own set color names
or to give color name constante slightly different values.


=head1 ROUTINES


=head2 new

Needs no arguments.


=head2 sub add_color

takes two positional arguments, a color name a n ARRAY with three
RGB values in range of 0 .. 255.


=head2 all_names

List of all names held by the scheme.


=head2 is_name_taken

Pseudo boolean tells you if given name is already held.


=head2 values_from_name

Returns the value tuple associated with the name.


=head2 names_from_values

Returns ARRAY ref with all names associated with these RGB values or an
empty string if none.


=head2 closest_names

Returns ARRAY ref with all names associated with RGB values from this
scheme that are the closest. Second return value is the distance between
these closest names and the given value tuple (irst and only parameter).


=head1 SEE ALSO

L<Color::Library>

L<Graphics::ColorNamesLite::All>

=head1 COPYRIGHT & LICENSE

Copyright 2025 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
