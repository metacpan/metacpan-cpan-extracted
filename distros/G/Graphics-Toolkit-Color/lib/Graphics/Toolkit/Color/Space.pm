use v5.12;
use warnings;

# common code of Graphics::Toolkit::Color::Space::Instance::*

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Shape;

sub new {
    my $pkg = shift;
    my %args = @_;
    my $basis = Graphics::Toolkit::Color::Space::Basis->new( $args{'axis'}, $args{'short'} );
    return unless ref $basis;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, $args{'range'}, $args{'type'} );
    return unless ref $shape;

    # which formats the constructor will accept, that can be deconverted into list
    my %deformats = ( hash => sub { $basis->list_from_hash(@_)   if $basis->is_hash(@_) },
               named_array => sub { @{$_[0]}[1 .. $#{$_[0]}]     if $basis->is_named_array(@_) },
                    string => sub { $basis->list_from_string(@_) if $basis->is_string(@_) },
                css_string => sub { $basis->list_from_css(@_)    if $basis->is_css_string(@_) },
    );
    # which formats we can output
    my %formats = (list => sub { @_ },                                 # 1,2,3
                   hash => sub { $basis->key_hash_from_list(@_) },     # { red => 1, green => 2, blue => 3 }
              char_hash => sub { $basis->shortcut_hash_from_list(@_) },# { r =>1, g => 2, b => 3 }
                  array => sub { $basis->named_array_from_list(@_) },  # ['rgb',1,2,3]
                 string => sub { $basis->named_string_from_list(@_) }, #   rgb: 1, 2, 3
             css_string => sub { $basis->css_string_from_list(@_) },   #   rgb(1,2,3)
    );

    bless { basis => $basis, shape => $shape, format => \%formats, deformat => \%deformats, convert => {} };
}
sub basis            { $_[0]{'basis'}}
sub name             { $_[0]->basis->name }
sub dimensions       { $_[0]->basis->count }
sub is_array         { $_[0]->basis->is_array( $_[1] ) }
sub is_partial_hash  { $_[0]->basis->is_partial_hash( $_[1] ) }
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }

########################################################################

sub delta      { shift->{'shape'}->delta( @_ ) }    # @values -- @vector, @vector --> |@vector # on normalize values
sub check      { shift->{'shape'}->check( @_ ) }    # @values -- @range           -->  ?       # pos if carp
sub clamp      { shift->{'shape'}->clamp( @_ ) }    # @values -- @range           --> |@vector
sub normalize  { shift->{'shape'}->normalize(@_)}   # @values -- @range           --> |@vector
sub denormalize{ shift->{'shape'}->denormalize(@_)} # @values -- @range           --> |@vector
sub denormalize_range{ shift->{'shape'}->denormalize_range(@_)} # @values -- @range           --> |@vector

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
    my ($self, $space_name, $to_code, $from_code, $mode) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code, mode => $mode };
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
