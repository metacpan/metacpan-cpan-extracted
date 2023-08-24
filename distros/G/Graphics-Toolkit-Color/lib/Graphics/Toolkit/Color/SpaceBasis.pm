use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::SpaceBasis;

sub new {
    my $pkg = shift;
    my @keys = map {lc} @_;
    return unless @keys > 0;
    my @iterator = 0 .. $#keys;
    my %key_order = map { $keys[$_] => $_ } @iterator;
    my @shortcuts = map { _color_key_shortcut($_) } @keys;
    my %shortcut_order = map { $shortcuts[$_] => $_ } @iterator;
    bless { keys => [@keys], shortcuts => [@shortcuts],
            key_order => \%key_order, shortcut_order => \%shortcut_order,
            name => join('', @shortcuts), count => int @keys, iterator => \@iterator }
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
        my $shortcut = _color_key_shortcut( $value_key );
        return undef unless exists $self->{'shortcut_order'}{ $shortcut };
        $values[ $self->{'shortcut_order'}{ $shortcut } ] = $value_hash->{ $value_key };
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
        else                              { return }
    }
    return $result;
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

sub _color_key_shortcut { lc substr($_[0], 0, 1) if defined $_[0] }

1;
