
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
       ? [ @{$self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]]}, $name ]
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
    return '' unless ref $values eq 'ARRAY' and @$values == 3
              and exists ($self->{'shaped'}{'name'}[$values->[0]])
              and exists ($self->{'shaped'}{'name'}[$values->[0]][$values->[1]])
              and exists ($self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]]);
    return                $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]];
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
    # keep names in insert possible
    @names = map { @{$self->names_from_values( $self->values_from_name($_))} } @names;
    @names = uniq( @names );
    return (\@names, sqrt($sqr_min));
}

sub names_in_range {
    my ($self, $values, $range) = @_;
    my @names;
    my $sqr_max = $range ** 2;
    my $all_values = $self->{'shaped'}{'values'};
    for my $index_name (keys %$all_values){
        my $index_values = $all_values->{ $index_name };
        my $temp_sqr_sum = ($index_values->[0] - $values->[0]) ** 2;
        next if $temp_sqr_sum > $sqr_max;
        $temp_sqr_sum += ($index_values->[1] - $values->[1]) ** 2;
        next if $temp_sqr_sum > $sqr_max;
        $temp_sqr_sum += ($index_values->[2] - $values->[2]) ** 2;
        next if $temp_sqr_sum > $sqr_max;
        push @names, [$index_name, $temp_sqr_sum];
    }
    return '' unless @names;
    @names = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @names;
    # keep names in insert possible
    @names = map { @{$self->names_from_values( $self->values_from_name($_))} } @names;
    return [ uniq( @names ) ];
}

#### util ##############################################################
sub _clean_name {
    my $name = shift;
    $name =~ tr/_ '.\/-//d;
    lc $name;
}

1;
