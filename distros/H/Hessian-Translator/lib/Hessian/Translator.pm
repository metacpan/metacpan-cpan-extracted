package Hessian::Translator;

## no critic
our $VERSION = '1.06';
$VERSION = eval $VERSION;
## use critic
#
use Moose;

use Module::Load;
use YAML;
use List::MoreUtils qw/any/;
use Config;
#use Smart::Comments;

use Hessian::Exception;

has 'is_big_endian'     => ( is => 'rw', isa => 'Bool', default => 0 );
has 'original_position' => ( is => 'rw', isa => 'Int',  default => 0 );
has 'class_definitions' => ( is => 'rw', default => sub { [] } );
has 'type_list' => (    #{{{
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] }
);
has 'reference_list' => ( is => 'rw', default => sub { [] } );
has 'input_string' => (    #{{{
    is  => 'rw',
    isa => 'Str',
);
has 'version'     => ( is => 'ro', isa => 'Int' );
has 'binary_mode' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'chunked'     => ( is => 'ro', isa => 'Bool', default => 0 );
has 'serializer' => (
    is  => 'rw',
    isa => 'Bool',
);
has 'in_interior' => ( is => 'rw', isa => 'Bool', default => 0 );

before 'input_string' => sub {    #{{{
    my $self = shift;
    if (  not $self->does('Hessian::Deserializer') ) {
        load 'Hessian::Deserializer';
        Hessian::Deserializer->meta()->apply($self);
    }
    $self->version();
};

sub append_input_buffer {    #{{{
    my ( $self, $hessian_string ) = @_;
    if ( $self->{input_string} ) {
        my $fh_pos = tell $self->input_handle();
        my $input_string = substr $self->{input_string}, $fh_pos;

        my $entire_string = $input_string . $hessian_string;
        $self->input_string($entire_string);
    }
    else {
        $self->input_string($hessian_string);
    }
}

before 'serializer' => sub {    #{{{
    my $self = shift;
    if ( !$self->does('Hessian::Serializer') ) {
        load 'Hessian::Serializer';
        Hessian::Serializer->meta()->apply($self);
    }
    $self->version();
};

after 'version' => sub {    #{{{
    my ($self) = @_;
    my $version = $self->{version};
  PROCESSVERSION: {
        last PROCESSVERSION unless $version;
        Parameter::X->throw( error => "Version should be either 1 or 2." )
          if $version !~ /^(?:1|2)$/;
        last PROCESSVERSION
          if $self->does('Hessian::Translator::V1')
              or $self->does('Hessian::Translator::V2');
        last PROCESSVERSION
          if not(    $self->does('Hessian::Serializer')
                  or $self->does('Hessian::Deserializer') );
        my $version_role = 'Hessian::Translator::V' . $version;
        load $version_role;
        $version_role->meta()->apply($self);
    }    #PROCESSVERSION
};

sub read_from_inputhandle {    #{{{
    my ( $self, $read_length ) = @_;
    ### Reading from input handle: $read_length;

    my $input_handle = $self->input_handle();
    binmode( $input_handle, 'bytes' );
    my $original_pos            = $self->original_position();
    my $current_position        = ( tell $input_handle ) - 1;
    my $sub_string              = $self->{input_string};
    my $remaining_string_buffer = substr $self->{input_string},
      $current_position;

    my $remaining_length = length $remaining_string_buffer;
    ### remaining: $remaining_length
    my $result;
    if ( $read_length > $remaining_length ) {

        # Set filehandle back to the original position
        my $message =
            "Input buffer does not contain"
          . " a complete message.\n$remaining_string_buffer\n"
          . "Current position $current_position\n"
          . "read length: $read_length\nremaining: $remaining_length\n"
          . "string: "
          . $self->{input_string} . ".\n";

        #          print $message;

        #        seek $input_handle, $original_pos, 0;
        # Throw an exception that will be caught by the caller
        MessageIncomplete::X->throw( error => $message );
    }
    else {
        read $self->input_handle(), $result, $read_length;
    }
    return $result;

}

sub set_current_position {    #{{{
    my ( $self, $offset ) = @_;
    my $input_handle     = $self->input_handle();
    my $current_position = ( tell $input_handle ) + $offset;
    $self->original_position($current_position);
}

sub BUILD {    #{{{
    my ( $self, $params ) = @_;
    load 'Hessian::Translator::Composite';
    Hessian::Translator::Composite->meta()->apply($self);
    if ( any { defined $params->{$_} } qw/input_string input_handle/ ) {
        load 'Hessian::Deserializer';
        Hessian::Deserializer->meta()->apply($self);

    }

    if ( any { defined $params->{$_} } qw/service/ ) {
        load 'Hessian::Serializer';
        Hessian::Serializer->meta()->apply($self);
    }
    $self->version();
    my $byteorder = $Config{byteorder};
    $self->is_big_endian(1) if $byteorder =~ /4321/;

}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator - Base class for Hessian serialization/deserialization.

=head1 SYNOPSIS

    my $translator = Hessian::Translator->new( version => 1 );

    my $hessian_string = "S\x00\x05hello";
    $translator->input_string($hessian_string);
    my $output = $translator->deserialize_message();


    # Apply serialization methods to the object.
    Hessian::Serializer->meta()->apply($translator);

=head1 DESCRIPTION

B<Hessian::Translator> and associated subclasses and roles provides
serialization/deserialization of data and Perl datastructures into Hessian
protocol.

On its own, this class really only provides some of the more basic functions
required for Hessian processing such as the I<type list> for datatypes, the
I<reference list> for maps, objects and arrays; and the I<object class
definition list>.  Integration of the respective serialization and
deserialization behaviours only takes place when needed. Depending on how
the translator is initialized and which methods are called on the object, it
is possibly to specialize the object for either Hessian 1.0 or Hessian 2.0
processing and to selectively include methods for serialization and or
deserialization.



=head1 INTERFACE


=head2 BUILD

Not to be called directly.  Pod::Coverage complains if I don't have it in here
though.


=head2 new


=over 2

=item
version

Allowed values are B<1> or B<2> and correspond to the respective Hessian
protocol version.


=back


=head2 input_string

=over 2

=item
string

The Hessian encoded string to be decoded.  This may represent an entire
message or a simple scalar or datastructure. Note that the first application
of this method causes the L<Hessian::Deserializer> role to be applied to this
class.


=back


=head2 version

Retrieves the current version for which this client was initialized. See
L</"new">.

=head2 append_input_buffer

Appends the string parameter to the filehandle.


=head2 class_definitions

Provides access to the internal class definition list.


=head2 type_list

Provides access to the internal type list.

=head2 reference_list

Provides access to the internal list of references.


=head2 serializer

Causes the L<Hessian::Serializer|Hessian::Serializer> methods to be applied to
the current object.

=head2 read_from_inputhandle

Reads a specified number of bytes from an input stream.

=head2 set_current_position

Set/reset the current position in an input stream.


=head1 DEPENDENCIES



=over 2


=item
L<Moose|Moose>



=back
