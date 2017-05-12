package Excel::Template::Context;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Base);

    use Excel::Template::Base;
}

use Excel::Template::Format;

# This is a helper object. It is not instantiated by the user, nor does it
# represent an XML node. Rather, every container will use this object to
# maintain the context for its children.

my %isAbsolute = map { $_ => ~~1 } qw(
    ROW
    COL
);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{ACTIVE_WORKSHEET} = undef;
    $self->{FORMAT_OBJECT}    = Excel::Template::Format->new;
    $self->{ACTIVE_FORMAT}    = $self->{FORMAT_OBJECT}->blank_format($self);
    $self->{WORKSHEET_NAMES}  = undef;

    $self->{__MARKS} = {};

    # Removed NAME_MAP until I figure out what the heck it's for
    for (qw( STACK PARAM_MAP ))
    {
        next if defined $self->{$_} && ref $self->{$_} eq 'ARRAY';
        $self->{$_} = [];
    }

    $self->{$_} = 0 for keys %isAbsolute;

    return $self;
}

sub use_unicode { $_[0]->{UNICODE} && 1 }

sub _find_param_in_map
{
    my $self = shift;
    my ($map, $param, $depth) = @_;
    $param = uc $param;
    $depth ||= 0;

    my ($val, $found);
    for my $map (reverse @{$self->{$map}})
    {
        next unless exists $map->{$param};
        $depth--, next if $depth;

        $found = ~~1;
        $val = $map->{$param};
        last;
    }

    die "Parameter '$param' not found\n"
        if !$found && $self->{DIE_ON_NO_PARAM};

    return $val;
}

sub param
{
    my $self = shift;
    $self->_find_param_in_map(
        'PARAM_MAP',
        @_,
    );
}

#sub named_param
#{
#    my $self = shift;
#    $self->_find_param_in_map(
#        'NAME_MAP',
#        @_,
#    );
#}

sub resolve
{
    my $self = shift;
    my ($obj, $key, $depth) = @_;
    $key = uc $key;
    $depth ||= 0;

    my $obj_val = $obj->{$key};

    $obj_val = $self->param($1)
        if $obj_val =~ /^\$(\S+)$/o;

#GGG Remove this once NAME_MAP is working
#    $obj_val = $self->named_param($1)
#        if $obj_val =~ /^\\(\S+)$/o;

#GGG Does this adequately test values to make sure they're legal??
    # A value is defined as:
    #    1) An optional operator (+, -, *, or /)
    #    2) A decimal number

#GGG Convert this to use //x
    my ($op, $val) = $obj_val =~ m/^\s*([\+\*\/\-])?\s*([\d.]*\d)\s*$/oi;

    # Unless it's a relative value, we have what we came for.
    return $obj_val unless $op;

    my $prev_val = $isAbsolute{$key}
        ? $self->{$key}
        : $self->get($obj, $key, $depth + 1);

    return $obj_val unless defined $prev_val;
    return $prev_val unless defined $obj_val;

    # Prevent divide-by-zero issues.
    return $prev_val if $op eq '/' and $val == 0;

    my $new_val;
    for ($op)
    {
        /^\+$/ && do { $new_val = ($prev_val + $val); last; };
        /^\-$/ && do { $new_val = ($prev_val - $val); last; };
        /^\*$/ && do { $new_val = ($prev_val * $val); last; };
        /^\/$/ && do { $new_val = ($prev_val / $val); last; };

        die "Unknown operator '$op' in arithmetic resolve\n";
    }

    return $new_val if defined $new_val;
    return;
}

sub enter_scope
{
    my $self = shift;
    my ($obj) = @_;

    push @{$self->{STACK}}, $obj;

    for my $key (keys %isAbsolute)
    {
        next unless exists $obj->{$key};
        $self->{$key} = $self->resolve($obj, $key);
    }

    return ~~1;
}

sub exit_scope
{
    my $self = shift;
    my ($obj, $no_delta) = @_;

    unless ($no_delta)
    {
        my $deltas = $obj->deltas($self);
        $self->{$_} += $deltas->{$_} for keys %$deltas;
    }

    pop @{$self->{STACK}};

    return ~~1;
}

sub get
{
    my $self = shift;
    my ($dummy, $key, $depth) = @_;
    $depth ||= 0;
    $key = uc $key;

    return unless @{$self->{STACK}};

    my $obj = $self->{STACK}[-1];

    return $self->{$key} if $isAbsolute{$key};

    my $val = undef;
    my $this_depth = $depth;
    foreach my $e (reverse @{$self->{STACK}})
    {
        next unless exists $e->{$key};
        next if $this_depth-- > 0;

        $val = $self->resolve($e, $key, $depth);
        last;
    }

    $val = $self->{$key} unless defined $val;
    return $val unless defined $val;

    return $self->param($1, $depth) if $val =~ /^\$(\S+)$/o;

    return $val;
}

sub active_format
{
    my $self = shift;
    
    $self->{ACTIVE_FORMAT} = $_[0]
        if @_;

    $self->{ACTIVE_FORMAT};
}

sub new_worksheet
{
    my $self = shift;
    my ($worksheet) = @_;

    $self->{ROW} = $self->{COL} = 0;
    $self->{REFERENCES} = {};

    my $name = $self->get( $worksheet, 'NAME' );

    if ( defined $name && length $name )
    {
        if ( exists $self->{WORKSHEET_NAMES}{$name} )
        {
            $name = '';
        }
        else
        {
            $self->{WORKSHEET_NAMES}{$name} = undef;
        }
    }
    else
    {
        $name = '';
    }

    return $self->active_worksheet(
        $self->{XLS}->add_worksheet( $name ),
    );
}

sub mark
{
    my $self = shift;

    if ( @_ > 1 )
    {
        my %args = @_;

        @{$self->{__MARKS}}{keys %args} = values %args;
    }

    return $self->{__MARKS}{$_[0]}
}

sub active_worksheet
{
    my $self = shift;
    
    $self->{ACTIVE_WORKSHEET} = $_[0]
        if @_;

    $self->{ACTIVE_WORKSHEET};
}

sub add_reference
{
    my $self = shift;
    my ($ref, $row, $col) = @_;

    $self->{REFERENCES}{$ref} ||= [];

    push @{$self->{REFERENCES}{$ref}}, [ $row, $col ];

    return ~~1;
}

sub get_all_references
{
    my $self = shift;
    my $ref = uc shift;

    $self->{REFERENCES}{$ref} ||= [];

    return @{ $self->{REFERENCES}{$ref} };
}

sub get_last_reference
{
    my $self = shift;
    my $ref = uc shift;

    $self->{REFERENCES}{$ref} ||= [];

    return @{ $self->{REFERENCES}{$ref}[-1] };
}

sub format_object { $_[0]{FORMAT_OBJECT} }

1;
__END__

=head1 NAME

Excel::Template::Context - Excel::Template::Context

=head1 PURPOSE

This is a helper node that provides the global context for the nodes do their processing within. It provides attribute scoping, parameter resolution, and other very nice things.

Documentation is provided for if you wish to subclass another node.

=head1 NODE NAME

None

=head1 INHERITANCE

None

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 AFFECTS

Everything

=head1 DEPENDENCIES

None

=head1 METHODS

=head2 active_format

=head2 active_worksheet

=head2 add_reference

=head2 format_object

=head2 get

=head2 get_all_references

=head2 get_last_reference

=head2 mark

=head2 new_worksheet

=head2 param

=head2 use_unicode

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

=cut
