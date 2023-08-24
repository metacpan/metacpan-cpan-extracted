use v5.12;
use warnings;

# base logic of every color space

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::SpaceBasis;

sub new {
    my $pkg = shift;
    my $basis = Graphics::Toolkit::Color::SpaceBasis->new( @_ );
    return unless ref $basis;

    # which formats the constructor will accept, that can be deconverted into list
    my %deformats = ( hash => sub { $basis->list_from_hash(@_) if $basis->is_hash(@_) },
               named_array => sub { @{$_[0]}[1 .. $#{$_[0]}]   if $basis->is_named_array(@_) },
    );
    # which formats we can output
    my %formats = (list => sub {@_}, hash => sub { $basis->key_hash_from_list(@_) },
                                char_hash => sub { $basis->shortcut_hash_from_list(@_) },
    );

    bless { basis => $basis, format => \%formats, deformat => \%deformats, convert => {},
            trim => sub { map {$_ < 0 ? 0 : $_} map {$_ > 1 ? 1 : $_} @_ },
            delta => sub { my ($vector1, $vector2) = @_;
                           map {$vector2->[$_] - $vector1->[$_] } $basis->iterator },
    };
}

sub basis            { $_[0]{'basis'}}
sub name             { uc $_[0]->basis->name }
sub dimensions       { $_[0]->basis->count }
sub iterator         { $_[0]->basis->iterator }
sub is_array         { $_[0]->basis->is_array( $_[1] ) }
sub is_partial_hash  { $_[0]->basis->is_partial_hash( $_[1] ) }
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }

sub change_trim_routine {
    my ($self, $code) = @_;
    $self->{'trim'} = $code if ref $code eq 'CODE';
}
sub trim {
    my ($self, @vector) = @_;
    push @vector, 0 while @vector < $self->dimensions;
    pop  @vector    while @vector > $self->dimensions;
    return $self->{'trim'}->( @vector );
}

########################################################################

sub change_delta_routine {
    my ($self, $code) = @_;
    $self->{'delta'} = $code if ref $code eq 'CODE';
}
sub delta {
    my ($self, $vector1, $vector2) = @_;
    return unless $self->basis->is_array( $vector1 ) and $self->basis->is_array( $vector2 );
    $self->{'delta'}->( $vector1, $vector2 );
}

########################################################################

sub add_formatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or ref $code ne 'CODE';
    return 0 if $self->has_format( $format );
    $self->{'format'}{ $format } = $code;
}
sub format {
    my ($self, $values, $format) = @_;
    return unless $self->basis->is_array( $values );
    $self->{'format'}{ lc $format }->(@$values) if $self->has_format( $format );
}

sub add_deformatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or exists $self->{'deformat'}{$format} or ref $code ne 'CODE';
    $self->{'deformat'}{ lc $format } = $code;
}
sub deformat {
    my ($self, $values) = @_;
    return undef unless defined $values;
    for my $deformatter (values %{$self->{'deformat'}}){
        my @values = $deformatter->($values);
        return @values if @values == $self->dimensions;
    }
    return undef;
}

########################################################################

sub add_converter {
    my ($self, $space_name, $to_code, $from_code) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code };
}
sub convert {
    my ($self, $values, $space_name) = @_;
    return unless $self->{'basis'}->is_array( $values ) and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'to'}->(@$values) if $self->can_convert( $space_name );
}

sub deconvert {
    my ($self, $values, $space_name) = @_;
    return unless ref $values eq 'ARRAY' and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'from'}->(@$values) if $self->can_convert( $space_name );
}



1;
