
# common code of Graphics::Toolkit::Color::Space::Instance::* packages

package Graphics::Toolkit::Color::Space;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Basis;         # 1 attr class
use Graphics::Toolkit::Color::Space::Shape;         # 2 ..
use Graphics::Toolkit::Color::Space::Format;        # 3 ..
use Graphics::Toolkit::Color::Space::Util qw/:all/; # forward all its symbols
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/min max uniq round_int round_decimals mod_real spow mult_matrix_vector_3 is_nr/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

########################################################################
sub new {
    my $pkg = shift;
    return if @_ % 2;
    my %args = @_;
    my $basis = Graphics::Toolkit::Color::Space::Basis->new( $args{'axis'}, $args{'short'}, $args{'name'}, $args{'alias_name'}, 
                                                             $args{'family'}, $args{'role'}, );
    return $basis unless ref $basis;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, $args{'type'}, $args{'range'}, $args{'precision'}, $args{'constraint'} );
    return $shape unless ref $shape;
    my $format = Graphics::Toolkit::Color::Space::Format->new( $basis, $args{'value_form'}, $args{'prefix'}, $args{'suffix'} );
    return $format unless ref $format;
    my $self = bless { basis => $basis, shape => $shape, format => $format, convert => {} };
    if (ref $args{'format'} eq 'HASH'){
        for my $format_name (keys %{$args{'format'}}){
            my $formatter = $args{'format'}{$format_name};
            next unless ref $formatter eq 'ARRAY' and  @$formatter > 0;
            $format->add_formatter($format_name, $formatter->[0])
                if exists $formatter->[0] and ref $formatter->[0] eq 'CODE';
            $format->add_deformatter($format_name, $formatter->[1])
                if exists $formatter->[1] and ref $formatter->[1] eq 'CODE';
        }
    }
    if (ref $args{'convert'} eq 'HASH'){
        for my $converter_target_space_name (keys %{$args{'convert'}}){
            my $converter_data = $args{'convert'}{ $converter_target_space_name };
            next unless ref $converter_data eq 'ARRAY' and @$converter_data > 1
                    and ref $converter_data->[0] eq 'CODE' and ref $converter_data->[1] eq 'CODE';
            $self->add_converter( $converter_target_space_name, @$converter_data );
        }
    }
    if (ref $args{'values'} eq 'HASH') {
        my $numifier = $args{'values'};
        $format->set_value_numifier( $numifier->{'read'}, $numifier->{'write'} )
            if ref $numifier->{'read'} eq 'CODE' and ref $numifier->{'write'} eq 'CODE';
    }
    return $self;
}

########################################################################
sub basis              { $_[0]{'basis'} }
sub name               { shift->basis->space_name(@_) }       #       -- ?alias ?given     --> ~
sub family             { shift->basis->family(@_) }           #                            --> ~
sub is_name            { shift->basis->is_name(@_) }          # ~name                      --> ?
sub normalize_name     { shift->basis->normalize_name(@_) }   # ~name                      --> ~
sub axis_count         { shift->basis->axis_count }           #                            --> +
sub is_axis_name       { shift->basis->is_axis_name(@_) }     # ~axis_name                 --> ?
sub is_axis_role       { shift->basis->is_axis_role(@_) }     # ~role_name                 --> ?
sub pos_from_axis_name { shift->basis->pos_from_axis_name(@_) }# ~axis_name                --> +|
sub pos_from_axis_role { shift->basis->pos_from_axis_role(@_) }# ~axis_name                --> +|
sub is_value_tuple     { shift->basis->is_value_tuple(@_) }   # @+tuple                    --> ?
sub is_number_tuple    { shift->basis->is_number_tuple(@_) }  # @+tuple                    --> ?
sub is_partial_hash    { shift->basis->is_partial_hash(@_) }  # %+partial_hash             --> ?
sub tuple_from_partial_hash { shift->basis->tuple_from_partial_hash(@_) } # %+partial_hash --> @+tuple

########################################################################
sub shape              { $_[0]{'shape'} }
sub is_euclidean       { shift->shape->is_euclidean() }       #                                     --> ?
sub is_cylindrical     { shift->shape->is_cylindrical }       #                                     --> ?
sub is_equal           { shift->shape->is_equal( @_ ) }       # @+tuple_a, @+tuple_b -- @+precision --> ?
sub is_in_linear_bounds{ shift->shape->is_in_linear_bounds(@_)}#@+tuple -- @+range                  --> ?
sub is_in_bounds       { shift->shape->is_in_bounds(@_)}      # @+tuple -- @+range                  --> ?
sub round              { shift->shape->round( @_ ) }          # @+tuple -- @+precision              --> @+tuple   
sub clamp              { shift->shape->clamp( @_ ) }          # @+tuple -- @+range                  --> @+tuple   
sub rotate             { shift->shape->rotate( @_ ) }         # @+tuple -- @+range                  --> @+tuple   
sub check_value_shape  { shift->shape->check_value_shape( @_)}# @+tuple -- @+range, @+precision     --> @+tuple|!~   # errmsg
sub normalize          { shift->shape->normalize(@_)}         # @+tuple -- @+range                  --> @+tuple|!~
sub denormalize        { shift->shape->denormalize(@_)}       # @+tuple -- @+range                  --> @+tuple|!~
sub denormalize_delta  { shift->shape->denormalize_delta(@_)} # @+tuple -- @+range                  --> @+tuple|!~
sub delta              { shift->shape->delta( @_ ) }          # @+tuple_a, @+tuple_b                --> @+tuple|     # on normalized values
sub has_constraints    { shift->shape->has_constraints(@_)}   #                                     --> ?
sub add_constraint     { shift->shape->add_constraint(@_)}    # ~name, ~error, &checker, &remedy    --> %constraint

########################################################################
sub form               { $_[0]{'format'} }
sub format             { shift->form->format(@_) }            # @+values, ~format_name -- @~suffix --> $*color
sub deformat           { shift->form->deformat(@_) }          # $*color                -- @~suffix --> @+values, ~format_name

#### conversion ########################################################
sub conversion_tree_parent { (keys %{  $_[0]{'convert'} })[0] }
sub can_convert          { (defined $_[1] and exists $_[0]{'convert'}{ $_[0]->normalize_name($_[1]) }) ? 1 : 0 }
sub add_converter {
    my ($self, $space_name, $to_code, $from_code, $normal) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    return 0 if defined $normal and ref $normal ne 'HASH';
    $normal = { from => 1, to => 1, } unless ref $normal; # flags: default is full normalisation
    $normal->{'from'} = {} if not exists $normal->{'from'} or (exists $normal->{'from'} and not $normal->{'from'});
    $normal->{'from'} = {in => 1, out => 1} if not ref $normal->{'from'};
    $normal->{'from'}{'in'} = 0 unless exists $normal->{'from'}{'in'};
    $normal->{'from'}{'out'} = 0 unless exists $normal->{'from'}{'out'};
    $normal->{'to'} = {} if not exists $normal->{'to'} or (exists $normal->{'to'} and not $normal->{'to'});
    $normal->{'to'} = {in => 1, out => 1} if not ref $normal->{'to'};
    $normal->{'to'}{'in'} = 0 unless exists $normal->{'to'}{'in'};
    $normal->{'to'}{'out'} = 0 unless exists $normal->{'to'}{'out'};
    $self->{'convert'}{ $self->normalize_name( $space_name )  } = { from => $from_code, to => $to_code, normal => $normal };
}

sub convert_to { # convert value tuple from this space into another
    my ($self, $space_name, $tuple) = @_;
    $space_name = $self->normalize_name( $space_name );
    return unless $self->is_value_tuple( $tuple ) and defined $space_name and $self->can_convert( $space_name );
    return $self->{'convert'}{ $space_name }{'to'}->( $tuple );
}
sub convert_from { # convert value tuple from another space into this
    my ($self, $space_name, $tuple) = @_;
    $space_name = $self->normalize_name( $space_name );
    return unless ref $tuple eq 'ARRAY' and defined $space_name and $self->can_convert( $space_name );
    return $self->{'convert'}{ $space_name }{'from'}->( $tuple );
}
sub converter_normal_states {
    my ($self, $direction, $space_name) = @_;
    $space_name = $self->normalize_name( $space_name );
    return unless $self->can_convert( $space_name )
              and defined $direction and ($direction eq 'from' or $direction eq 'to');
    return @{$self->{'convert'}{ $space_name }{'normal'}{$direction}}{'in', 'out'};
}

1;
