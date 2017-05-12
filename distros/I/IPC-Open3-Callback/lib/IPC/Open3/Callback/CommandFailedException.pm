use strict;
use warnings;

package IPC::Open3::Callback::CommandFailedException;
$IPC::Open3::Callback::CommandFailedException::VERSION = '1.19';
# ABSTRACT: An exception thrown when run_or_die encounters a failed command
# PODNAME: IPC::Open3::Callback::CommandFailedException

use overload q{""} => 'to_string', fallback => 1;
use parent qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(command exit_status out err));

sub new {
    my ( $class, @args ) = @_;
    return bless( {}, $class )->_init(@args);
}

sub _init {
    my ( $self, $command, $exit_status, $out, $err ) = @_;

    $self->{command}     = $command;
    $self->{exit_status} = $exit_status;
    if ( defined($out) ) {
        $out =~ s/^\s+//;
        $out =~ s/\s+$//;
        $self->{out} = $out;
    }
    if ( defined($err) ) {
        $err =~ s/^\s+//;
        $err =~ s/\s+$//;
        $self->{err} = $err;
    }

    return $self;
}

sub to_string {
    my ($self) = @_;
    if ( !$self->{message} ) {
        my @message = ( 'FAILED (', $self->{exit_status}, '): ', @{ $self->{command} } );
        if ( $self->{out} ) {
            push( @message, "\n***** out *****\n", $self->{out}, "\n***** end out *****" );
        }
        if ( $self->{err} ) {
            push( @message, "\n***** err *****\n", $self->{err}, "\n***** end err *****" );
        }
        $self->{message} = join( '', @message );
    }
    return $self->{message};
}

1;

__END__

=pod

=head1 NAME

IPC::Open3::Callback::CommandFailedException - An exception thrown when run_or_die encounters a failed command

=head1 VERSION

version 1.19

=head1 SYNOPSIS

  use IPC::Open3::Callback::CommandRunner;
  
  my $runner = IPC::Open3::Callback::CommandRunner->new();
  eval {
      $runner->run_or_die( 'echo Hello World' );
  };
  if ( $@ && ref( $@ ) eq 'IPC::Open3::Callback::CommandFailedException' ) {
      # gather info
      my $command = $@->get_command(); # an arrayref
      my $exit_status = $@->get_exit_status();
      my $out = $@->get_out();
      my $err = $@->get_err();
      
      # or just print 
      print( "$@\n" ); # includes all info
  }

=head1 DESCRIPTION

This provides a container for information obtained when a command fails.  The
C<command> and C<exit_status> will always be available, but C<out> and C<err>
will only be present if you supply the command option C<out_buffer =E<gt> 1> and
C<err_buffer =E<gt> 1> respectively.

=head1 ATTRIBUTES

=head2 get_command()

Returns a reference to the array supplied as the C<command> to command runner.

=head2 get_exit_status()

Returns the exit status from the attempt to run the command.

=head2 get_out()

Returns the text written to C<STDOUT> by the command.  Only present if 
C<out_buffer> was requested as a command runner option. 

=head2 get_err()

Returns the text written to C<STDERR> by the command.  Only present if 
C<err_buffer> was requested as a command runner option. 

=head1 METHODS

=head2 to_string()

Returns a string representation of all of the attributes.  The C<qw{""}>
operator is overridden to call this method.

=head1 AUTHORS

=over 4

=item *

Lucas Theisen <lucastheisen@pastdev.com>

=item *

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::Open3::Callback|IPC::Open3::Callback>

=item *

L<IPC::Open3::Callback|IPC::Open3::Callback>

=item *

L<IPC::Open3::Callback::CommandRunner|IPC::Open3::Callback::CommandRunner>

=item *

L<https://github.com/lucastheisen/ipc-open3-callback|https://github.com/lucastheisen/ipc-open3-callback>

=back

=cut
