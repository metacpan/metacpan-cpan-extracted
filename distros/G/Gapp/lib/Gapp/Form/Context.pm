package Gapp::Form::Context;
{
  $Gapp::Form::Context::VERSION = '0.60';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use Gapp::Form::Context::Node;

has 'accessor' => (
    is => 'rw',
    isa => 'CodeRef|Undef',
    default => undef,
);

has 'reader_prefix' => (
    is => 'rw',
    isa => 'Str|Undef',
    default => undef,
);

has 'writer_prefix' => (
    is => 'rw',
    isa => 'Str|Undef',
    default => undef,
);

has 'nodes' => (
    is => 'rw',
    isa => 'HashRef',
    traits => [qw( Hash )],
    default => sub { { } },
    handles => {
        get_node => 'get',
        set_node => 'set',
    }
);


# returns a list of default values to use when creating a new node
sub _defaults {
    my $self = shift;
    my @defaults;
    push @defaults, reader_prefix => $self->reader_prefix, if defined $self->reader_prefix;
    push @defaults, writer_prefix => $self->writer_prefix, if defined $self->writer_prefix;
    push @defaults, accessor => $self->accessor, if defined $self->accessor;
    return @defaults;
}

# create a new node
sub add {
    my ( $self, $name, $content, @args ) = @_;

    my $node = Gapp::Form::Context::Node->new( content => $content, $self->_defaults, @args );
    $self->set_node( $name, $node );
    return $node;
}

# create a new node
sub add_node {
    my ( $self, $name, $content, @args ) = @_;

    use Carp qw(carp);
    carp 'add_node deprecrated. Use add instead.';
    
    $self->add( $name, $content, @args );
}

# used to lookup the value of an attribute
sub lookup {
    my ( $self, $path ) = @_;
    $self->meta->throw_error( 'you must supply a path' ) if ! $path;
    
    my ( $name, $attr ) = split /\./, $path;
    my $node = $self->get_node( $name );
    
    $self->meta->throw_error( qq[could not find node "$name" in context] ) if ! $node;
    $node->lookup( $attr );
}

# used to set the value of an attribute
sub modify {
    my ( $self, $path, $value ) = @_;
    $self->meta->throw_error( 'you must supply a path' ) if ! $path;
    $self->meta->throw_error( 'you must supply a value' ) if @_ <= 2;
    
    my ( $name, $attr ) = split /\./, $path;
    
    my $node = $self->get_node( $name );
    return if ! $node;
    $node->modify( $attr, $value );
    # $self->_value_changed( $path, $value ) if ! $self->in_update( $path );
}

sub update {
    my ( $self, $stash ) = @_;
    
    
    for my $path ( $stash->elements ) {
        next if $path eq '';
        
        my $value = $stash->fetch( $path );
        
        # $self->set_in_update( $path, 1 );
        $self->modify( $path, $value );
        # $self->set_in_update( $path, 0 );
    }
}

sub update_from_stash {
    my $self = shift;
    use Carp qw( cluck );
    
    cluck '$cx->update_from_stash( $stash ) deprecated, use $cx->update( $stash )';
    $self->update( @_ );
}



1;



__END__

=pod

=head1 NAME

Gapp::Form::Context - Form context object

=head1 SYNOPSIS

  # use an object

  $o = Foo::Character->new( fname => 'Mickey', lname => 'Mouse' );

  $cx = Gapp::Form::Context->new(

    reader_prefix => 'get_',

    writer_prefix => 'set_'

  );

  $cx->add( 'character', $o );

  $cx->lookup( 'character.fname' ); # returns 'Mickey'

  # use a hash-ref

  $data = { foo => 'bar' };
  
  $cx->add( data => $data,

      accessor => sub {

        my ( $data, $attr, $value ) = @_;

        @_ == 2 ? $data{$attr} : $data{$attr} = $value;

      }

  );
  
  $cx->lookup( 'data.foo' ); # returns 'Bar'

=head1 DESCRIPTION

The context is used to sync data between objects/data structures and forms. 

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Form::Context>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<accessor>

=over 4

=item is rw

=item isa CodeRef|Undef

=item default Undef

=back

If C<accessor> is defined, it will be used as the default accessor for nodes in the context.
The accessor is used to update and retrieve data from the data sctructure. If no accessor is
set, reader and writer methods will be used.

=item B<reader_prefix>

=over 4

=item is rw

=item isa Str|Undef

=item default Undef

=back

If C<reader_prefix> is defined, it will be used as the default C<reader_prefix> for nodes in
the context. When doing a C<lookup>, the C<reader_prefix> is appended to beginning of the
attribute name to form the reader method. This method will then be called on the data structure
to retrieve the value. If an C<accessor> has been defined, that will be used instead.

=item B<writer_prefix>

=over 4

=item is rw

=item isa Str|Undef

=item default Undef

=back

If C<writer_prefix> is defined, it will be used as the default C<writer_prefix> for nodes in
the context. When doing a C<modify>, the C<writer_prefix> is appended to beginning of the
attribute name to form the writer method. This method will then be called on the data structure
to store the value. If an C<accessor> has been defined, that will be used instead.

=back

=head1 PROVIDED METHODS

=over 4

=item B<add $node_name, $data_structure|CodeRef, @opts>

Add a node to the context. All nodes must have name. The C<$data_structure> is the
C<Object> or other data to work on. If any options are specified, they will over-ride
those set by the context. The avaialble options are C<accessor>, C<reader_prefix>,
C<writer_prefix>.

=item B<lookup $path>

Retrieves a value from the context. C<$path> is a string in the format of "node_name.attribute".

=item B<get_node $node_name>

Retrieves a L<Gapp::Form::Context::Node> from the context with the given C<$node_name>.

=item B<modify $path, $new_value>

Sets a value in the context. C<$path> is a string in the format of "nodename.attribute".

=item B<set_node $node_name, $node>

Add L<Gapp::Form::Context::Node> to the context with the given C<$name>.

=item B<update $stash>

Updates the values in the context based on values in the C<$stash>. C<$stash> is a
L<Gapp::Form::Stash> object.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


