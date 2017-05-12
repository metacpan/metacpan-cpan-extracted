package Meta::Builder::Base;
use strict;
use warnings;

use Meta::Builder::Util;
use Carp qw/croak carp/;

sub new {
    my $class = shift;
    my ( $package, %metrics ) = @_;
    my $meta = $class->meta_meta;
    my $self = bless( [ $package ], $class );

    for my $metric ( keys %{ $meta->{metrics} }) {
        my $idx = $meta->{metrics}->{$metric};
        $self->[$idx] = $metrics{$metric}
                     || $meta->{generators}->[$idx]->();
    }

    inject(
        $package,
        ($meta->{accessor} || croak "$class does not have an accessor set."),
        sub { $self }
    );

    $self->init( %metrics ) if $self->can( 'init' );

    return $self;
}

sub meta_meta {
    my $class = shift;
    return $class->_meta_meta
        if $class->can( '_meta_meta' );

    my $meta = { index => 1 };
    inject( $class, "_meta_meta", sub { $meta });
    return $meta;
}

sub package { shift->[0] }

sub set_accessor {
    my $class = shift;
    ($class->meta_meta->{accessor}) = @_;
}

sub add_hash_metric {
    my $class = shift;
    my ( $metric, %actions ) = @_;
    $class->add_metric(
        $metric,
        \&gen_hash,
        add   => \&default_hash_add,
        get   => \&default_hash_get,
        has   => \&default_hash_has,
        clear => \&default_hash_clear,
        pull  => \&default_hash_pull,
        merge => \&default_hash_merge,
        %actions,
    );
}

sub add_lists_metric {
    my $class = shift;
    my ( $metric, %actions ) = @_;
    $class->add_metric(
        $metric,
        \&gen_hash,
        push  => \&default_list_push,
        get   => \&default_list_get,
        has   => \&default_list_has,
        clear => \&default_list_clear,
        pull  => \&default_list_pull,
        merge => \&default_list_merge,
        %actions,
    );
}

sub add_metric {
    my $class = shift;
    my ( $metric, $generator, %actions ) = @_;
    my $meta = $class->meta_meta;
    my $index = $meta->{index}++;

    croak "Already tracking metric '$metric'"
        if $meta->{metrics}->{$metric};

    $meta->{metrics}->{$metric} = $index;
    $meta->{generators}->[$index] = $generator;
    $meta->{indexes}->{$index} = $metric;

    inject( $class, $metric, sub { shift->[$index] });
    $class->add_action( $metric, %actions );
}

sub add_action {
    my $class = shift;
    my ( $metric, %actions ) = @_;
    $class->_add_action( $metric, $_, $actions{ $_ })
        for keys %actions;
}

sub _add_action {
    my $class = shift;
    my ( $metric, $action, $code ) = @_;
    croak "You must specify a metric, an action name, and a coderef"
        unless $metric && $action && $code;

    my $meta = $class->meta_meta;
    my $name = $class->action_method_name( $metric, $action );

    inject( $class, $name, sub {
        my $self = shift;
        my $args = \@_;
        $_->( $self, $self->$metric, $metric, $action, @$args )
            for @{ $meta->{before}->{$name} || [] };
        my @out = $code->( $self, $self->$metric, $metric, $action, @$args );
        $_->( $self, $self->$metric, $metric, $action, @$args )
            for @{ $meta->{after}->{$name} || [] };
        return @out ? (@out > 1 ? @out : $out[0]) : ();
    });
}

sub action_method_name {
    my $class = shift;
    my ( $metric, $action ) = @_;
    return "$metric\_$action";
}

sub hook_before {
    my $class = shift;
    my ( $metric, $action, $code ) = @_;
    my $name = $class->action_method_name( $metric, $action );
    push @{ $class->meta_meta->{before}->{$name} } => $code;
}

sub hook_after {
    my $class = shift;
    my ( $metric, $action, $code ) = @_;
    my $name = $class->action_method_name( $metric, $action );
    push @{ $class->meta_meta->{after}->{$name} } => $code;
}

sub gen_hash { {} }

sub default_hash_add {
    my $self = shift;
    my ( $data, $metric, $action, $item, @value ) = @_;
    my $name = $self->action_method_name( $metric, $action );
    croak "$name() called without anything to add"
        unless $item;

    croak "$name('$item') called without a value to add"
        unless @value;

    croak "'$item' already added for metric $metric"
        if $data->{$item};

    ($data->{$item}) = @value;
}

sub default_hash_get {
    my $self = shift;
    my ( $data, $metric, $action, $item ) = @_;
    my $name = $self->action_method_name( $metric, $action );
    croak "$name() called without anything to get"
        unless $item;

    # Prevent autovivication
    return exists $data->{$item}
        ? $data->{$item}
        : undef;
}

sub default_hash_has {
    my $self = shift;
    my ( $data, $metric, $action, $item ) = @_;
    my $name = $self->action_method_name( $metric, $action );
    croak "$name() called without anything to find"
        unless $item;
    return exists $data->{$item} ? 1 : 0;
}

sub default_hash_clear {
    my $self = shift;
    my ( $data, $metric, $action, $item ) = @_;
    my $name = $self->action_method_name( $metric, $action );
    croak "$name() called without anything to clear"
        unless $item;
    delete $data->{$item};
    return 1;
}

sub default_hash_pull {
    my $self = shift;
    my ( $data, $metric, $action, $item ) = @_;
    my $name = $self->action_method_name( $metric, $action );
    croak "$name() called without anything to pull"
        unless $item;
    return delete $data->{$item};
}

sub default_hash_merge {
    my $self = shift;
    my ( $data, $metric, $action, $merge ) = @_;
    for my $key ( keys %$merge ) {
        croak "$key is defined for $metric in both meta-objects"
            if $data->{$key};
        $data->{$key} = $merge->{$key};
    }
}

sub default_list_push {
    my $self = shift;
    my ( $data, $metric, $action, $item, @values ) = @_;
    my $name = $self->action_method_name( $metric, $action );
    croak "$name() called without an item to which data should be pushed"
        unless $item;

    croak "$name('$item') called without values to push"
        unless @values;

    push @{$data->{$item}} => @values;
}

sub default_list_get {
    my $data = default_hash_get(@_);
    return $data ? @$data : ();
}

sub default_list_has {
    default_hash_has( @_ );
}

sub default_list_clear {
    default_hash_clear( @_ );
}

sub default_list_pull {
    my @out = default_list_get( @_ );
    default_list_clear( @_ );
    return @out;
}

sub default_list_merge {
    my $self = shift;
    my ( $data, $metric, $action, $merge ) = @_;
    for my $key ( keys %$merge ) {
        push @{ $data->{$key} } => @{ $merge->{$key} };
    }
}

sub merge {
    my $self = shift;
    my ( $merge ) = @_;
    for my $metric ( keys %{ $self->meta_meta->{ metrics }}) {
        my $mergesub = $self->action_method_name( $metric, 'merge' );
        unless( $self->can( $mergesub )) {
            carp "Cannot merge metric '$metric', define a 'merge' action for it.";
            next;
        }
        $self->$mergesub( $merge->$metric );
    }
}

1;

__END__

=head1 NAME

Meta::Builder::Base - Base class for Meta::Builder Meta Objects.

=head1 DESCRIPTION

Base class for all L<Meta::Builder> Meta objects. This is where the methods
used to define new metrics and actions live. This class allows for the creation
of dynamic meta objects.

=head1 SYNOPSIS

My/Meta.pm:

    package My::Meta;
    use strict;
    use warnings;

    use base 'Meta::Builder::Base';

    # Name the accessor that will be defined in the class that uses the meta object
    # It is used to retrieve the classes meta object.
    __PACKAGE__->set_accessor( "mymeta" );

    # Add a metric with two actions
    __PACKAGE__->add_metric(
        mymetric => sub { [] },
        pop => sub {
            my $self = shift;
            my ( $data ) = @_;
            pop @$data;
        },
        push => sub {
            my $self = shift;
            my ( $data, $metric, $action, @args ) = @_;
            push @$data => @args;
        }
    );

    # Add an additional action to the metric
    __PACKAGE__->add_action( 'mymetric', get_ref => sub { shift });

    # Add some predefined metric types + actions
    __PACKAGE__->add_hash_metric( 'my_hashmetric' );
    __PACKAGE__->add_lists_metric( 'my_listsmetric' );

My.pm:

    package My;
    use strict;
    use warnings;

    use My::Meta;

    My::Meta->new( __PACKAGE__ );

    # My::Meta defines mymeta() as the accessor we use to get our meta object.
    # this is the ONLY way to get the meta object for this class.

    mymeta()->mymetric_push( "some data" );
    mymeta()->my_hashmetric_add( key => 'value' );
    mymeta()->my_listsmetric_push( list => qw/valueA valueB/ );

    # It works fine as an object/class method as well.
    __PACKAGE__->mymeta->do_thing(...);

    ...;

=head1 PACKAGE METRIC

Whenever you create a new instance of a meta-object you must provide the name
of the package to which the meta-object belongs. The 'package' metric will be
set to this package name, and can be retirved via the 'package' method:
C<$meta->package()>.

=head1 HASH METRICS

Hash metrics are metrics that hold key/value pairs. A hash metric is defined
using either the C<hash_metric()> function, or the C<$meta->add_hash_metric()>
method. The following actions are automatically defined for hash metrics:

=over 4

=item $meta->add_METRIC( $key, $value )

Add a key/value pair to the metric. Will throw an exception if the metric
already has a value for the specified key.

=item $value = $meta->get_METRIC( $key )

Get the value for a specified key.

=item $bool = $meta->has_METRIC( $key )

Check that the metric has the specified key defined.

=item $meta->clear_METRIC( $key )

Clear the specified key/value pair in the metric. (returns nothing)

=item $value = $meta->pull_METRIC( $key )

Get the value for the specified key, then clear the pair form the metric.

=back

=head1 LISTS METRICS

=over 4

=item $meta->push_METRIC( $key, @values )

Push values into the specified list for the given metric.

=item @values = $meta->get_METRIC( $key )

Get the values for a specified key.

=item $bool = $meta->has_METRIC( $key )

Check that the metric has the specified list.

=item $meta->clear_METRIC( $key )

Clear the specified list in the metric. (returns nothing)

=item @values = $meta->pull_METRIC( $key )

Get the values for the specified list in the metric, then clear the list.

=back

=head1 CLASS METHODS

=over 4

=item $meta = $class->new( $package, %metrics )

Create a new instance of the meta-class, and apply it to $package.

=item $metadata = $class->meta_meta()

Get the meta data for the meta-class itself. (The meta-class is build using
meta-data)

=item $new_hashref = $class->gen_hash()

Generate a new empty hashref.

=item $name = $class->action_method_name( $metric, $action )

Generate the name of the method for the given metric and action. Override this
if you do not like the METRIC_ACTION() method names.

=back

=head1 OBJECT METHODS

=over 4

=item $package = $meta->package()

Get the name of the package to which this meta-class applies.

=item $meta->set_accessor( $name )

Set the accessor that is used to retrieve the meta-object from the class to
which it applies.

=item $meta->add_hash_metric( $metric, %actions )

Add a hash metric (see L</"HASH METRICS">).

%actions should contain C<action =<gt> sub {...}> pairs for constructing
actions (See add_action()).

=item $meta->add_lists_metric( $metric, %actions )

Add a lists metric (see L</"LISTS METRICS">)

%actions should contain C<action =<gt> sub {...}> pairs for constructing
actions (See add_action()).

=item $meta->add_metric( $metric, \&generator, %actions )

Add a custom metric. The second argument should be a sub that generates a
default value for the metric.

%actions should contain C<action =<gt> sub {...}> pairs for constructing
actions (See add_action()).

=item $meta->add_action( $metric, $action => sub { ... } )

Add an action for the specified metric. See L</"ACTION AND HOOK METHODS"> for
details on how to write an action coderef.

=item $meta->hook_before( $metric, $action, sub { ... })

Add a hook for the specified metric. See L</"ACTION AND HOOK METHODS"> for
details on how to write a hook coderef.

=item $meta->hook_after( $metric, $action, sub { ... })

Add a hook for the specified metric. See L</"ACTION AND HOOK METHODS"> for
details on how to write a hook coderef.

=back

=head1 ACTION AND HOOK METHODS

    sub {
        my $self = shift;
        my ( $data, $metric, $action, @args ) = @_;
        ...;
    }

Action and hook methods are called when someone calls
C<$meta-<gt>metric_action(...)>. First all before hooks will be called, the the
action itself, and finally the after hooks will be called. All methods in the
chain get the exact same unaltered arguments. Only the main action sub can
return anything.

Arguments are:

=over 4

=item 0: $self

These are methods, so the first argument is the meta object itself.

=item 1: $data

This is the data structure stored for the metric. This is the same as calling
$meta->metric()

=item 2: $metric

Name of the metric

=item 3: $action

Name of the action

=item 4+: @args

Arguments that metric_action() was called with.

=back

=head1 DEFAULT ACTION METHODS

There are the default action methods used by hashmetrics and listsmetrics.

=over 4

=item $meta->default_hash_add( $data, $metric, $action, $item, $value )

=item $value = $meta->default_hash_get( $data, $metric, $action, $item )

=item $bool = $meta->default_hash_has( $data, $metric, $action, $item )

=item $meta->default_hash_clear( $data, $metric, $action, $item )

=item $value = $meta->default_hash_pull( $data, $metric, $action, $item )

=item $meta->default_list_push( $data, $metric, $action, $item, @values )

=item @values = $meta->default_list_get( $data, $metric, $action, $item )

=item $bool = $meta->default_list_has( $data, $metric, $action, $item )

=item $meta->default_list_clear( $data, $metric, $action, $item )

=item @values = $meta->default_list_pull( $data, $metric, $action, $item )

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Meta-Builder is free software; Standard perl licence.

Meta-Builder is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
