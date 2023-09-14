use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::Space::Basis;

sub new {
    my ($pkg, $axis_names, $name_shortcuts, $prefix) = @_;
    return unless ref $axis_names eq 'ARRAY';
    return if defined $name_shortcuts and (ref $name_shortcuts ne 'ARRAY' or @$axis_names != @$name_shortcuts);
    my @keys      = map {lc} @$axis_names;
    my @shortcuts = map { _color_key_shortcut($_) } (defined $name_shortcuts) ? @$name_shortcuts : @keys;
    return unless @keys > 0;

    my @iterator = 0 .. $#keys;
    my %key_order      = map { $keys[$_] => $_ } @iterator;
    my %shortcut_order = map { $shortcuts[$_] => $_ } @iterator;
    bless { keys => [@keys], shortcuts => [@shortcuts],
            key_order => \%key_order, shortcut_order => \%shortcut_order,
            name => uc (join('', @shortcuts)), count => int @keys, iterator => \@iterator }
}

sub keys     { @{$_[0]{'keys'}} }
sub shortcuts{ @{$_[0]{'shortcuts'}} }
sub iterator { @{$_[0]{'iterator'}} }
sub count    {   $_[0]{'count'} }
sub name     {   $_[0]{'name'} }

sub key_pos      {  defined $_[1] ? $_[0]->{'key_order'}{ lc $_[1] } : undef}
sub shortcut_pos {  defined $_[1] ? $_[0]->{'shortcut_order'}{ lc $_[1] } : undef }
sub is_key       { (defined $_[1] and exists $_[0]->{'key_order'}{ lc $_[1] }) ? 1 : 0 }
sub is_shortcut  { (defined $_[1] and exists $_[0]->{'shortcut_order'}{ lc $_[1] }) ? 1 : 0 }
sub is_key_or_shortcut { $_[0]->is_key($_[1]) or $_[0]->is_shortcut($_[1]) }
sub is_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    $string = lc $string;
    my $name = lc $self->name;
    return 0 unless index($string, $name.':') == 0;
    my $nr = '\s*-?\d+(?:\.\d+)?\s*';
    my $nrs = join(',', ('\s*-?\d+(?:\.\d+)?\s*') x $self->count);
    ($string =~ /^$name:$nrs$/) ? 1 : 0;
}
sub is_css_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    $string = lc $string;
    my $name = lc $self->name;
    return 0 unless index($string, $name.'(') == 0;
    my $nr = '\s*-?\d+(?:\.\d+)?\s*';
    my $nrs = join(',', ('\s*-?\d+(?:\.\d+)?\s*') x $self->count);
    ($string =~ /^$name\($nrs\)$/) ? 1 : 0;
}
sub is_array {
    my ($self, $value_array) = @_;
    (ref $value_array eq 'ARRAY' and @$value_array == $self->{'count'}) ? 1 : 0;
}
sub is_named_array {
    my ($self, $value_array) = @_;
    (ref $value_array eq 'ARRAY' and @$value_array == ($self->{'count'}+1)
                                 and uc $value_array->[0] eq uc $self->name) ? 1 : 0;
}
sub is_hash {
    my ($self, $value_hash) = @_;
    return 0 unless ref $value_hash eq 'HASH' and CORE::keys %$value_hash == $self->{'count'};
    for (CORE::keys %$value_hash) {
        return 0 unless $self->is_key_or_shortcut($_);
    }
    return 1;
}
sub is_partial_hash {
    my ($self, $value_hash) = @_;
    return 0 unless ref $value_hash eq 'HASH';
    my $key_count = CORE::keys %$value_hash;
    return 0 unless $key_count and $key_count <= $self->{'count'};
    for (CORE::keys %$value_hash) {
        return 0 unless $self->is_key_or_shortcut($_);
    }
    return 1;
}

########################################################################

sub key_shortcut {
    my ($self, $key) = @_;
    return unless $self->is_key( $key );
    ($self->shortcuts)[ $self->{'key_order'}{ lc $key } ];
}

sub list_value_from_key {
    my ($self, $key, @values) = @_;
    $key = lc $key;
    return unless @values == $self->{'count'};
    return unless exists $self->{'key_order'}{ $key };
    return $values[ $self->{'key_order'}{ $key } ];
}

sub list_value_from_shortcut {
    my ($self, $shortcut, @values) = @_;
    $shortcut = lc $shortcut;
    return unless @values == $self->{'count'};
    return unless exists $self->{'shortcut_order'}{ $shortcut };
    return $values[ $self->{'shortcut_order'}{ $shortcut } ];
}

sub list_from_hash {
    my ($self, $value_hash) = @_;
    return undef unless ref $value_hash eq 'HASH' and CORE::keys %$value_hash == $self->{'count'};
    my @values = (0) x $self->{'count'};
    for my $value_key (CORE::keys %$value_hash) {
        if    ($self->is_key( $value_key ))      { $values[ $self->{'key_order'}{ lc $value_key } ] = $value_hash->{ $value_key } }
        elsif ($self->is_shortcut( $value_key )) { $values[ $self->{'shortcut_order'}{ lc $value_key } ] = $value_hash->{ $value_key } }
        else                                     { return }
    }
    return @values;
}

sub deformat_partial_hash {
    my ($self, $value_hash) = @_;
    return unless ref $value_hash eq 'HASH';
    my @keys_got = CORE::keys %$value_hash;
    return unless @keys_got and @keys_got <= $self->{'count'};
    my $result = {};
    for my $key (@keys_got) {
        if    ($self->is_key( $key ))     { $result->{ int $self->key_pos( $key ) } = $value_hash->{ $key } }
        elsif ($self->is_shortcut( $key )){ $result->{ int $self->shortcut_pos( $key ) } = $value_hash->{ $key } }
        else                              { return undef }
    }
    return $result;
}

sub list_from_string {
    my ($self, $string) = @_;
    my @parts = split(/:/, $string);
    return map {$_ + 0} split(/,/, $parts[1]);
}

sub list_from_css {
    my ($self, $string) = @_;
    1 until chop($string) eq ')';
    my @parts = split(/\(/, $string);
    return map {$_ + 0} split(/,/, $parts[1]);
}

sub key_hash_from_list {
    my ($self, @values) = @_;
    return unless @values == $self->{'count'};
    return { map { $self->{'keys'}[$_] => $values[$_]} @{$self->{'iterator'}} };
}

sub shortcut_hash_from_list {
    my ($self, @values) = @_;
    return unless @values == $self->{'count'};
    return { map {$self->{'shortcuts'}[$_] => $values[$_]} @{$self->{'iterator'}} };
}

sub named_array_from_list {
    my ($self, @values) = @_;
    return [lc $self->name, @values] if @values == $self->{'count'};
}

sub named_string_from_list {
    my ($self, @values) = @_;
    return unless @values == $self->{'count'};
    lc( $self->name).': '.join(', ', @values);
}

sub css_string_from_list {
    my ($self, @values) = @_;
    return unless @values == $self->{'count'};
    lc( $self->name).'('.join(',', @values).')';
}

sub _color_key_shortcut { lc substr($_[0], 0, 1) if defined $_[0] }

1;
