package Graph::Template::Context;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Graph::Template::Base);

    use Graph::Template::Base;
}

# This is a helper object. It is not instantiated by the user, nor does it
# represent an XML object. Rather, every container will use this object to
# maintain the context for its children.

my %isAbsolute = map { $_ => 1 } qw(
);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{PARAM_MAP} = [] unless UNIVERSAL::isa($self->{PARAM_MAP}, 'ARRAY');
    $self->{STACK}     = [] unless UNIVERSAL::isa($self->{STACK},     'ARRAY');

    return $self;
}

sub param
{
    my $self = shift;
    my ($param, $depth) = @_;
    $param = uc $param;
    $depth ||= 0;

    my $val = undef;
    my $found = 0;

    for my $map (reverse @{$self->{PARAM_MAP}})
    {
        next unless exists $map->{$param};
        $depth--, next if $depth;

        $found = 1;
        $val = $map->{$param};
        last;
    }

    die "Parameter '$param' not found\n"
        if !$found && $self->{DIE_ON_NO_PARAM};

    return $val;
}

sub resolve
{
    my $self = shift;
    my ($obj, $key, $depth) = @_;
    $key = uc $key;
    $depth ||= 0;

    my $obj_val = $obj->{$key};

    $obj_val = $self->param($1)
        if $obj->{$key} =~ /^\$(\S+)$/o;

#GGG Does this adequately test values to make sure they're legal??
    # A value is defined as:
    #    1) An optional operator (+, -, *, or /)
    #    2) A decimal number

#GGG Convert this to use //x
    my ($op, $val) = $obj_val =~ m!^\s*([\+\*\/\-])?\s*([\d.]*\d)\s*$!oi;

    # Unless it's a relative value, we have what we came for.
    return $obj_val unless $op;

    my $prev_val = $isAbsolute{$key}
        ? $self->{$key}
        : $self->get($obj, $key, $depth + 1);

    return $obj_val unless defined $prev_val;
    return $prev_val unless defined $obj_val;

    # Prevent divide-by-zero issues.
    return $val if $op eq '/' and $val == 0;

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

    return 1;
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

    return 1;
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

sub plotted_graph
{
    my $self = shift;
    
    $self->{PLOTTED_GRAPH} = $_[0]
        if @_;

    $self->{PLOTTED_GRAPH};
}

sub graph
{
    my $self = shift;
    
    $self->{GRAPH} = $_[0]
        if @_;

    $self->{GRAPH};
}

sub format
{
    my $self = shift;
    
    $self->{FORMAT} = $_[0]
        if @_;

    $self->{FORMAT};
}

sub start_data
{
    $_[0]{DATA} = [];
    $_[0]{DATA_AXIS} = 0;
    $_[0]{DATA_POINT} = 0;

    1;
}

sub increment_data
{
    $_[0]{DATA_AXIS} = 0;
    $_[0]{DATA_POINT}++;

    1;
}

sub add_data
{
    my $self = shift;
    my ($value) = @_;

    $value =~ s/\D//g
        if $self->{DATA_AXIS} > 0;

    $self->{DATA}
         ->[$self->{DATA_AXIS}++]
         ->[$self->{DATA_POINT}] = $value;

    return 1;
}

sub plot_data { $_[0]->plotted_graph($_[0]->graph->plot($_[0]->{DATA})) }
#{
#    my $self = shift;
#
#    $self->plotted_graph($self->graph->plot($self->{DATA}));
#}

1;
__END__
