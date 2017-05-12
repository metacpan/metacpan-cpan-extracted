package Gapp::Form::Context::Node;
{
  $Gapp::Form::Context::Node::VERSION = '0.60';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use MooseX::Types::Moose qw( CodeRef );

has 'content' => (
    is => 'rw',
    isa => 'Maybe[Any]',
    default => undef,
);

has 'accessor' => (
    is => 'rw',
    isa => 'CodeRef|Undef',
    default => undef,
);

has 'reader_prefix' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'writer_prefix' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);


sub lookup {
    my ( $self, $attr ) = @_;
    $self->meta->throw( 'you did not supply an attribute to lookup' ) if ! defined $attr;
    
    my $content = $self->content;
    $content = $content->() if is_CodeRef( $content );
    
    if ( $self->accessor ) {
        return $self->accessor->( $content, $attr );
    }
    else {
        my $method = $self->reader_prefix . $attr;
        return $content->$method;
    }
}

sub modify {
    my ( $self, $attr, $value ) = @_;
    $self->meta->throw_error( 'you did not supply an attribute to lookup' ) if ! defined $attr;
    $self->meta->throw_error( 'you must supply a value' ) if @_ <= 2;
    
    my $content = $self->content;
    $content = $content->() if is_CodeRef( $content );
    
    if ( $self->accessor ) {
        return $self->accessor->( $content, $attr, $value );
    }
    else {
        my $method = $self->writer_prefix . $attr;
        return $content->$method( $value );
    }
}

1;


__END__

=pod

=head1 NAME

Gapp::Form::Context::Node - Context node object

=head1 SYNOPSIS

  $o = Foo::Character->new( fname => 'Mickey', lname => 'Mouse' );

  $cx = Gapp::Form::Context->new;

  $node = $cx->add( 'character', $o );

  $node->lookup( 'fname' ); # returns 'Mickey'

  $node->modify( 'fname', 'Minnie' );


=head1 DESCRIPTION

A context node contains a reference to a data structure and rules for accessing
and modifying that data. The context is used to sync data between objects/data
structures and forms. 

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Form::Context::Node>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<accessor>

=over 4

=item is rw

=item isa CodeRef|Undef

=item default Undef

=back

The accessor is used to update and retrieve data from the data sctructure. If no accessor is
set, reader and writer methods will be used.

=item B<content>

=over 4

=item is rw

=item isa Any|Undef

=item default Undef

=back

The data structure to operate on. If set to a <CodeRef>, the C<CodeRef> will be executed
at lookup/modification time and the return value will be used as the data structure.

=item B<reader_prefix>

=over 4

=item is rw

=item isa Str|Undef

=item default Undef

=back

When doing a C<lookup>, the C<reader_prefix> is appended to beginning of the attribute name to
form the reader method. This method will then be called on the data structure to retrieve the
value. If an C<accessor> has been defined, that will be used instead.

=item B<writer_prefix>

=over 4

=item is rw

=item isa Str|Undef

=item default Undef

=back

When doing a C<modify>, the C<writer_prefix> is appended to beginning of the attribute name to
form the writer method. This method will then be called on the data structure to store the
value. If an C<accessor> has been defined, that will be used instead.

=back

=head1 PROVIDED METHODS

=over 4

=item B<lookup $attribute>

Retrieves a value from the context. C<$path> is a string in the format of "node_name.attribute".

=item B<modify $attribute, $path>

Sets a value in the context. C<$path> is a string in the format of "nodename.attribute".

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


