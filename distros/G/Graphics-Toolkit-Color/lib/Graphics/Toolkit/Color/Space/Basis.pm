
# count and names of color space axis (short and long), space name = usr | prefix + axis initials

package Graphics::Toolkit::Color::Space::Basis;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Util qw/is_nr/;

sub new {
    my ($pkg, $axis_long_names, $axis_short_names, $space_name, $alias_name) = @_;
    return 'first argument (axis names) has to be an ARRAY reference' unless ref $axis_long_names eq 'ARRAY';
    return 'amount of shortcut names have to match that of full names'
        if defined $axis_short_names and (ref $axis_short_names ne 'ARRAY' or @$axis_long_names != @$axis_short_names);

    my @axis_long_name = map {lc} @$axis_long_names;
    my @axis_short_name = map { color_key_shortcut($_) } (defined $axis_short_names) ? @$axis_short_names : @axis_long_name;
    return 'need some axis names to create a color space' unless @axis_long_name > 0;
    return 'need same amount of axis short names and long names' unless @axis_long_name == @axis_short_name;

    my @iterator         = 0 .. $#axis_long_name;
    my %long_name_order  = map { $axis_long_name[$_] => $_ }  @iterator;
    my %short_name_order = map { $axis_short_name[$_] => $_ } @iterator;
    my $axis_initials    = uc join( '', @axis_short_name );
    $space_name //= $axis_initials;
    $alias_name //= '';

    bless { space_name => uc $space_name, alias_name => uc $alias_name,
            axis_long_name => \@axis_long_name, axis_short_name => \@axis_short_name,
            long_name_order => \%long_name_order, short_name_order => \%short_name_order,
            axis_iterator => \@iterator }
}
sub color_key_shortcut { lc substr($_[0], 0, 1) if defined $_[0] }

#### getter ############################################################
sub space_name       {   $_[0]{'space_name'}  }      # color space name
sub alias_name       {   $_[0]{'alias_name'}  }      # alternative space name

sub long_axis_names  { @{$_[0]{'axis_long_name'}}  } # axis full names
sub short_axis_names { @{$_[0]{'axis_short_name'}} } # axis short names
sub axis_iterator    { @{$_[0]{'axis_iterator'}} }   # counting all axis 0 .. -1
sub axis_count   { int @{$_[0]{'axis_iterator'}} }   # amount of axis

sub pos_from_long_axis_name  {  defined $_[1] ? $_[0]->{'long_name_order'}{ lc $_[1] } : undef }  # ~long_name  --> +pos
sub pos_from_short_axis_name {  defined $_[1] ? $_[0]->{'short_name_order'}{ lc $_[1] } : undef } # ~short_name --> +pos

#### predicates ########################################################
sub is_name          {
    return 0 if not defined $_[1];
    return 1 if uc $_[1] eq $_[0]{'space_name'};
    return 1 if $_[0]{'alias_name'} and uc $_[1] eq $_[0]{'alias_name'};
    return 0;
}
sub is_long_axis_name   { (defined $_[1] and exists $_[0]->{'long_name_order'}{ lc $_[1] }) ? 1 : 0 } # ~long_name  --> ?
sub is_short_axis_name  { (defined $_[1] and exists $_[0]->{'short_name_order'}{ lc $_[1] }) ? 1 : 0 }# ~short_name --> ?
sub is_axis_name        { $_[0]->is_long_axis_name($_[1]) or $_[0]->is_short_axis_name($_[1]) }       # ~name       --> ?
sub is_hash {         # with all axis names as keys
    my ($self, $value_hash) = @_;
    $self->is_partial_hash( $value_hash ) and (keys %$value_hash == $self->axis_count);
}
sub is_partial_hash { # with some axis names as keys
    my ($self, $value_hash) = @_;
    return 0 unless ref $value_hash eq 'HASH';
    my $key_count = keys %$value_hash;
    my @axis_visited;
    return 0 unless $key_count and $key_count <= $self->axis_count;
    for my $axis_name (keys %$value_hash) {
        return 0 unless $self->is_axis_name( $axis_name );
        my $axis_pos = $self->pos_from_long_axis_name( $axis_name );
        $axis_pos = $self->pos_from_short_axis_name( $axis_name ) unless defined $axis_pos;
        $axis_visited[ $axis_pos ]++;
        return 0 if $axis_visited[ $axis_pos ] > 1;
    }
    return 1;
}
sub is_value_tuple { (ref $_[1] eq 'ARRAY' and @{$_[1]} == $_[0]->axis_count) ? 1 : 0 }
sub is_number_tuple {
    my ($self, $tuple) = @_;
    return 0 unless $self->is_value_tuple( $tuple );
    map { return 0 unless is_nr( $tuple->[$_] ) } $self->axis_iterator;
    return 1;
}

#### converter #########################################################
sub short_axis_name_from_long {
    my ($self, $name) = @_;
    return unless $self->is_long_axis_name( $name );
    ($self->short_axis_names)[ $self->pos_from_long_axis_name( $name ) ];
}
sub long_axis_name_from_short {
    my ($self, $name) = @_;
    return unless $self->is_short_axis_name( $name );
    ($self->long_axis_names)[ $self->pos_from_short_axis_name( $name ) ];
}

sub long_name_hash_from_tuple {
    my ($self, $values) = @_;
    return unless $self->is_value_tuple( $values );
    return { map { $self->{'axis_long_name'}[$_] => $values->[$_]} $self->axis_iterator };
}
sub short_name_hash_from_tuple {
    my ($self, $values) = @_;
    return unless $self->is_value_tuple( $values );
    return { map {$self->{'axis_short_name'}[$_] => $values->[$_]} $self->axis_iterator };
}

sub tuple_from_hash {
    my ($self, $value_hash) = @_;
    return unless $self->is_hash( $value_hash );
    my @values = (0) x $self->axis_count;
    for my $key (keys %$value_hash) {
        if    ($self->is_long_axis_name( $key ))  { $values[ $self->pos_from_long_axis_name($key) ] = $value_hash->{ $key } }
        elsif ($self->is_short_axis_name( $key )) { $values[ $self->pos_from_short_axis_name($key) ] = $value_hash->{ $key } }
        else                                      { return "value of $key is missing" }
    }
    return \@values;
}
sub tuple_from_partial_hash {
    my ($self, $value_hash) = @_;
    return unless $self->is_partial_hash( $value_hash );
    my $values = [];
    for my $key (keys %$value_hash) {
        if    ( $self->is_long_axis_name( $key ) ) { $values->[$self->pos_from_long_axis_name($key) ] = $value_hash->{ $key } }
        elsif ( $self->is_short_axis_name( $key )) { $values->[$self->pos_from_short_axis_name($key)] = $value_hash->{ $key } }
        else                                       { return "value of $key is missing" }
    }
    return $values;
}
sub select_tuple_value_from_axis_name {
    my ($self, $name, $values) = @_;
    $name = lc $name;
    return unless $self->is_value_tuple( $values );
    return $values->[ $self->{'long_name_order'}{$name} ] if exists $self->{'long_name_order'}{$name};
    return $values->[ $self->{'short_name_order'}{$name} ] if exists $self->{'short_name_order'}{$name};
    undef;
}

1;
