package Hessian::Deserializer;

use Moose::Role;
use YAML;
##use Smart::Comments;

with qw/
  Hessian::Deserializer::Numeric
  Hessian::Deserializer::String
  Hessian::Deserializer::Date
  Hessian::Deserializer::Binary
  /;

has 'input_handle' => (    #{{{
    is      => 'rw',
    isa     => 'GlobRef',
    clearer => 'clear_input_handle',
    lazy    => 1,
    default => sub {#{{{
        my $self = shift;
        my $input_handle;
        my $input_string = $self->input_string();
        if ($input_string) {
            open $input_handle, "<", \$input_string
              or InputOutput::X->throw(
                error => "Unable to read from string input." );
            return $input_handle;
        }
    }
);

after 'input_string' => sub {    #{{{
    my $self = shift;

    # Get rid of the input file handle if user has given us a new string to
    # process. input handle should then re-initialize itself the next time it
    # is called.
    $self->clear_input_handle();
};

before qw/deserialize_data deserialize_message/ => sub {    #{{{
    my ( $self, $input ) = @_;
    my $input_string = $input->{input_string};
    $self->input_string($input_string) if $input_string;
};

sub deserialize_data {    #{{{
    my ( $self, $args ) = @_;
    my $result = $self->read_hessian_chunk($args);
    return $result;
}

sub deserialize_message {    #{{{
    my ( $self, $args ) = @_;
    my $result;
    eval {
        $result =
           $self->read_message_chunk();
    };
    if ( my $e = $@ ) {
        print "Got exception ".$e."\n";
        return if Exception::Class->caught('EndOfInput::X');
        $e->rethrow()
          if $e->isa('Hessian::Exception')
              or $e->isa('MessageIncomplete::X');
    }
    return $result;
}

sub next_token {    #{{{
    my $self = shift;
    return $self->deserialize_message();
}

sub process_message {    #{{{
    my $self = shift;
    my $tokens;
    while ( my $token = $self->deserialize_message()) { #next_token() ) {
        if ( ( ref $token ) eq 'HASH' ) {
            my @token_keys = keys %{$token};
            @{$tokens}{@token_keys} = @{$token}{@token_keys};
        }
        else {
            $tokens = $token;
        }
    }
    return $tokens;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer - Add deserialization capabilities to processor.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


=head2    deserialize_data

Deserialize a single chunk from the file handle. Note that this only processes
the composite and basic datastructures and cannot handle I<call>, I<packet> or
I<envelope> level chunks.

=head2    deserialize_message

Similar to C<deserialize_data> except that it also processes I<envelope> level
chunks of the message.

=head2 next_token

Iterate to the next chunk in the input handle.


=head2 process_message

Process a complete Hessian message by reading chunk by chunk until reaching
the end of the input filehandle. The deserialized message is currently
returned in an array reference, although this is likely to change in future
iterations.  The contents of this array reference depend on the data that is
parsed from the Hessian message.

