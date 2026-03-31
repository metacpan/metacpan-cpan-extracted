
# common code of Graphics::Toolkit::Color::Space::Instance::* packages

package Graphics::Toolkit::Color::Space;
use v5.12;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Shape;
use Graphics::Toolkit::Color::Space::Format;
use Graphics::Toolkit::Color::Space::Util qw/:all/;
our @EXPORT_OK = qw/round_int round_decimals mod_real min max uniq mult_matrix_vector_3 is_nr/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

########################################################################
sub new {
    my $pkg = shift;
    return if @_ % 2;
    my %args = @_;
    my $basis = Graphics::Toolkit::Color::Space::Basis->new( $args{'axis'}, $args{'short'}, $args{'name'}, $args{'alias'});
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
        for my $converter_target (keys %{$args{'convert'}}){
            my $converter = $args{'convert'}{ $converter_target };
            next unless ref $converter eq 'ARRAY' and @$converter > 1
                    and ref $converter->[0] eq 'CODE' and ref $converter->[1] eq 'CODE';
            $self->add_converter( $converter_target, @$converter );
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
sub name               { shift->basis->space_name }           #            --> ~
sub alias              { shift->basis->alias_name }           #            --> ~
sub is_name            { shift->basis->is_name(@_) }          #      ~name --> ?
sub axis_count         { shift->basis->axis_count }           #            --> +
sub is_axis_name       { shift->basis->is_axis_name(@_) }     # ~axis_name --> ?
sub is_value_tuple     { shift->basis->is_value_tuple(@_) }   # @+values   --> ?
sub is_number_tuple    { shift->basis->is_number_tuple(@_) }  # @+values   --> ?
sub is_partial_hash    { shift->basis->is_partial_hash(@_) }  # %+values   --> ?
sub pos_from_axis_name { shift->basis->pos_from_axis_name(@_) } # ~name    --> +|
sub tuple_from_partial_hash { shift->basis->tuple_from_partial_hash(@_) }  # %+values --> ?

########################################################################
sub shape              { $_[0]{'shape'} }
sub is_euclidean       { shift->shape->is_euclidean() }       #                                    --> ?
sub is_cylindrical     { shift->shape->is_cylindrical }       #                                    --> ?
sub is_equal           { shift->shape->is_equal( @_ ) }       # @+val_a, @+val_b -- @+precision    --> ?
sub is_in_linear_bounds{ shift->shape->is_in_linear_bounds(@_)}#@+values -- @+range                --> ?
sub is_in_bounds       { shift->shape->is_in_bounds(@_)}      # @+values -- @+range                --> ?
sub round              { shift->shape->round( @_ ) }          # @+values -- @+precision            --> @+rvals       # result values
sub clamp              { shift->shape->clamp( @_ ) }          # @+values -- @+range                --> @+rvals       # result values
sub check_value_shape  { shift->shape->check_value_shape( @_)}# @+values -- @+range, @+precision   --> @+values|!~   # errmsg
sub normalize          { shift->shape->normalize(@_)}         # @+values -- @+range                --> @+rvals|!~
sub denormalize        { shift->shape->denormalize(@_)}       # @+values -- @+range                --> @+rvals|!~
sub denormalize_delta  { shift->shape->denormalize_delta(@_)} # @+values -- @+range                --> @+rvals|!~
sub delta              { shift->shape->delta( @_ ) }          # @+val_a, @+val_b                   --> @+rvals|      # on normalized values
sub add_constraint     { shift->shape->add_constraint(@_)}    # ~name, ~error, &checker, &remedy   --> %constraint

########################################################################
sub form               { $_[0]{'format'} }
sub format             { shift->form->format(@_) }            # @+values, ~format_name -- @~suffix --> $*color
sub deformat           { shift->form->deformat(@_) }          # $*color                -- @~suffix --> @+values, ~format_name

#### conversion ########################################################
sub converter_names      { keys %{  $_[0]{'convert'} } }
sub alias_converter_name {
    my ($self, $space_name, $name_alias) = @_;
    $self->{'convert'}{ uc $name_alias } = $self->{'convert'}{ uc $space_name };
}
sub can_convert          { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }
sub add_converter {
    my ($self, $space_name, $to_code, $from_code, $normal) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    return 0 if defined $normal and ref $normal ne 'HASH';
    $normal = { from => 1, to => 1, } unless ref $normal; # default is full normalisation
    $normal->{'from'} = {} if not exists $normal->{'from'} or (exists $normal->{'from'} and not $normal->{'from'});
    $normal->{'from'} = {in => 1, out => 1} if not ref $normal->{'from'};
    $normal->{'from'}{'in'} = 0 unless exists $normal->{'from'}{'in'};
    $normal->{'from'}{'out'} = 0 unless exists $normal->{'from'}{'out'};
    $normal->{'to'} = {} if not exists $normal->{'to'} or (exists $normal->{'to'} and not $normal->{'to'});
    $normal->{'to'} = {in => 1, out => 1} if not ref $normal->{'to'};
    $normal->{'to'}{'in'} = 0 unless exists $normal->{'to'}{'in'};
    $normal->{'to'}{'out'} = 0 unless exists $normal->{'to'}{'out'};
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code, normal => $normal };
}

sub convert_to { # convert value tuple from this space into another
    my ($self, $space_name, $values) = @_;
    return unless $self->is_value_tuple( $values ) and defined $space_name and $self->can_convert( $space_name );
    return $self->{'convert'}{ uc $space_name }{'to'}->( $values );
}
sub convert_from { # convert value tuple from another space into this
    my ($self, $space_name, $values) = @_;
    return unless ref $values eq 'ARRAY' and defined $space_name and $self->can_convert( $space_name );
    return $self->{'convert'}{ uc $space_name }{'from'}->( $values );
}

sub converter_normal_states {
    my ($self, $direction, $space_name) = @_;
    return unless $self->can_convert( $space_name )
              and defined $direction and ($direction eq 'from' or $direction eq 'to');
    return @{$self->{'convert'}{ uc $space_name }{'normal'}{$direction}}{'in', 'out'};
}


1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space - base class of all color spaces


=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Space qw/:all/;

    Graphics::Toolkit::Color::Space->new (
              name => 'demo',               # space name, defaults to concatenated short axis names
             alias => 'alias',              # second, user set space name, often a shortcut
              axis => [qw/red green blue/], # long axis names, required !
             short => [qw/Re Gr Bl/],       # short names, defaults to first char of long
              type => [qw/linear circular angular/], # axis type
             range => [1, [-2, 2], [-3, 3]],         # axis value range
         precision => [-1, 0, 1],                    # axis value precision of value output
            suffix => ['', '', '%'],                 # axis value suffix of value in in and output
        value_form => ['\d{3}','\d{1,3}','\d{1,3}'], # special axis value shape
            values => {read => \&read_vals, write => \&write_vals }, # translate values to numbers and back
           convert => {RGB => [\&to_rgb, \&from_rgb, {..flags..}]},  # converter CODE, required !
            format => {'hex_string'=> [\&hex_from_tuple,\&tuple_from_hex]}, # custom IO format
        constraint => {cone => {checker => '$_[0][1] + $_[0][2] <= 1',
	                           error    => 'The sum of whiteness and blackness can not exceed 100%.',
		                       remedy   => 'my $s = $_[0][1] + $_[0][2];[$_[0][0], $_[0][1]/$s, $_[0][2]/$s]', }},
    );


=head1 DESCRIPTION

This is the low level API of this distribution. Its purpose is to define
color space representing objects that hold all specific informations about
the names, shapes and sizes of the axis and all algorithms for conversion
and formating. As a result all spaces can be managed by one central Hub
and accessed via onother unified API.

The mentioned (low level) API is formed by the constructor arguments,
as demonstrated in the SYNOPSIS. They build together a little DSL for
defining color spaces. This keeks the space classes short and sweet and
helps also contributers to program own color spaces with little effort.

Please name them L<Graphics::Toolkit::Color::Space::Instance::MyName>
and send them in as a merge request or feature request. Or if you want to
keep it for yourself load them ad runtime via L<Graphics::Toolkit::Color::Space::Hub::add_space>.

The other mentioned API is provided by the other methods of this class.
They are not documented here, because they are for internal use only.


=head1 METHODS

=head2 new

The constructor takes thirteen named arguments, which will be explained
in this chapter in logical order. Of those only C<axis> is required. 
But without also providing C<convert> the space becomes useless.

The values of these arguments have to be in most cases an ARRAY references,
which have one element for each axis of this space. Sometimes are also
strings acceptable, either because its about a property of the space or 
its a property that is the same for all axis or dimensions.

The argument B<axis> defines the long names of all axis, which will set
also the number and ordering of the space dimensions! Each axis will also
have a short name, which is per default the first letter of the long name.
If you prefer other shortcuts, define them via the B<short> argument.
Please note that a short axis name can be only one letter long or it
will trimmed to the first letter.

The concatenation of the upper-cased short axis names will be the name
of the space. In case that doesn't suit your wishes, set the B<name> argument.
(Example: axis => [qw/red green blue/] ... becomes ... 
         short => [qw/r g b/] ... becomes ... name => 'RGB' ).
Some spaces have a second, longer name which you can set via the argument
B<alias>, that defaults to an empty string that will be ignored.

If no argument under the name B<type> is provided, then all dimensions (axis)
will be I<linear> (Euclidean). But you might want to change that for some
axis to be I<circular> or I<angular> (same thing). This will influenc how
the methods I<clamp> ans I<delta> work. For instance cylindrical spaces
like C<HSL> or C<Lab> have one I<circular> and two I<linear> axis.
A third option for the I<type> argument is I<no>, which indicates,
that you can not treat the values of this dimension as numbers 
and they will be ignored for the most part.

Under the argument B<range> you can set the numeric limits,
values can have in that dimension. If none are provided, I<normal> ranges
(0 .. 1) are assumed. You can make it explicit by stating range => 'normal'.
range => 'percent' sets all axis to a range of 0 .. 100. The same can be
achieved by : range => 100. The one number is the upper bound and the lower
is zero by default. A range -100 .. 100 you get from: range => [-100, 100].
If every axis needs an individual range you can combine these statements
inside an ARRAY ref like: [20, 'normal', [2,5]].

The argument B<precision> defines how many decimals a value of that dimension
has to have. Zero makes the values practically an integer and negative values
express the demand for the maximally available precision. The default precision
is -1.

The argument B<suffix> is only interesting if color values has to have a suffix
like I<'%'> in '63%'. Its defaults to the empty string. It is imortant to
declare it so it can be removed before calculations and added to putputs.

B<value_form> is for very special cases when axis values are not simply
numerical. You can pass you own regular expressions and even provide custom
code that can transform your values into numbers and back. Please see the 
I<NCol> space as an example. If even that is not possible and GTC has
simply to ignore the values of one axis, you can still set the axis I<type> to I<'no'>.

Most important is the B<convert> argument. Here you pass the converter 
code to one of the already accepted color spaces. The argument expects
an HASH ref with one! key, which is the name of the color space you
want to convert to and from. This key gets as value an ARRAY ref with
two or three values. The first two are CODE references to routines
that do the converstion. First the one that converts to that other space.
That the routine that converts from it. These routines should expect
and return the color values as a tuple (ARRAY ref with numbers).
The optional third element in ARRAY which is the value to the key which
is the other color space is a HASH with converter flags. This will
help to optimize for precision and will be documented later when implemented.

If you want to invent a special format for your color space - with
B<format> you can! This option was introduced, so that the RGB space
can have it's special I<hex_string> and I<array> formats. Same rules
apply as for C<convert>.

Finally there is the B<constraint> argument. It is used for the rare cases,
when you space has a custom shape. It expects a HASH ref with as many
keys as necessary. The keys are there only for documentation and separation
purposes. But to each key belongs a HASH which holds another three keys.
I<checker> contains a string with perl code and formulates a condition
that must be kept for a point to be inside your space. Again the values
are given as a tuple (ARRAY) as the first argument to that code ($_[0]).
The second key, I<remedy> contains similar Perl code that can handle the 
case if a color is outside that constraint (if the condition is not met).
The thir key, I<error> is just a fitting error message so the use can
know, what the condition is about, that was not met.


=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2023-26 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
