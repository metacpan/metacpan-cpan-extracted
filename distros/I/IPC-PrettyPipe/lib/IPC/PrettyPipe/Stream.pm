# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of IPC::PrettyPipe
#
# IPC::PrettyPipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IPC::PrettyPipe::Stream;

use Carp;

use Moo;

use Types::Standard qw[ Bool Str ];

use IPC::PrettyPipe::Stream::Utils qw[ parse_spec ];

use String::ShellQuote 'shell_quote';
use IO::ReStoreFH;
use POSIX ();
use Fcntl qw[ O_RDONLY O_WRONLY O_CREAT O_TRUNC O_APPEND ];

with 'IPC::PrettyPipe::Queue::Element';

my %fh_map = (
    0 => *STDIN,
    1 => *STDOUT,
    2 => *STDERR
);

my %op_map = (

    '<'  => O_RDONLY,
    '>'  => O_WRONLY | O_CREAT | O_TRUNC,
    '>>' => O_WRONLY | O_CREAT | O_APPEND

);

has N => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);
has M => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);
has Op => (
    is       => 'rwp',
    init_arg => undef,
);

has spec => (
    is       => 'rwp',
    isa      => Str,
    required => 1,
);

has file => (
    is        => 'rw',
    isa       => Str,
    predicate => 1,
);

has _type => (
    is       => 'rwp',
    isa      => Str,
    init_arg => undef,
);

has requires_file => (
    is       => 'rwp',
    init_arg => undef,
);

has strict => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 } );

sub BUILDARGS {

    my $class = shift;

    if ( @_ == 1 ) {

        return $_[0] if 'HASH' eq ref( $_[0] );

        return { spec => $_[0][0], file => $_[0][1] }
          if 'ARRAY' eq ref( $_[0] ) && @{ $_[0] } == 2;

        return { spec => $_[0] };

    }

    return {@_};

}

sub BUILD {

    my $self = shift;

    ## no critic (ProhibitAccessOfPrivateData)

    my $opc = parse_spec( $self->spec );

    croak( __PACKAGE__, ': ', "cannot parse stream specification: ", $self->spec )
      unless defined $opc->{type};

    $self->_set_requires_file( $opc->{param} );
    $self->_set__type( $opc->{type} );

    $self->${ \"_set_$_" }( $opc->{$_} )
      for grep { exists $opc->{$_} } qw[ N M Op ];


    if ( $self->strict ) {

        croak( __PACKAGE__, ': ', "stream specification ",
            $self->spec, "requires a file\n" )
          if $self->requires_file && !$self->has_file;

        croak( __PACKAGE__, ': ', "stream specification ",
            $self->spec, "should not have a file\n" )
          if !$self->requires_file && $self->has_file;

    }

    return;
}

sub quoted_file {  shell_quote( $_[0]->file )  }

sub _redirect {

    my ( $self, $N ) = @_;

    my $file = $self->file;

    my $sub;

    if ( defined $N ) {

        my $op = $self->Op;

        $sub = sub {
            open( $N, $op, $file ) or die( "unable to open ", $file, ": $!\n" );
        };
    }

    else {

        $N = $self->N;
        my $op = $op_map{ $self->Op }
          // croak( "error: unrecognized operator: ", $self->Op, "\n" );

        $sub = sub {
            my $nfd = POSIX::open( $file, $op, oct(644) )
              or croak( 'error opening', $file, ": $!\n" );
            POSIX::dup2( $nfd, $N )
              or croak( "error in dup2( $nfd, $N ): $!\n" );
            POSIX::close( $nfd );
        };

    }

    return $sub, $N;
}

sub _dup {

    my ( $self, $N, $M ) = @_;

    $M //= $self->M;

    my $sub;

    # if $N is a known filehandle, we're in luck
    if ( defined $N ) {

        $sub = sub {
            open( $N, '>&', $M )
              or die( "error in open($N >& $M): $!\n" );
        };

    }

    else {

        $N = $self->N;
        $M = $self->M;

        $sub = sub {
            POSIX::dup2( $N, $M )
              or die( "error in dup2( $N, $M ): $!\n" );
        };

    }

    return $sub, $N;
}

sub _redirect_stdout_stderr {

	my $self = shift;

	( undef, my $sub_redir ) = $self->_redirect( *STDOUT );
	( undef, my $sub_dup   ) = $self->_dup( *STDERR, *STDOUT );
	return sub { $sub_redir->(), $sub_dup->() },  *STDOUT, *STDERR;

}

sub _close {

    my ( $self, $N ) = @_;

    my $sub;

    if ( defined $N ) {

        $sub = sub { close( $N ) or die( "error in closing $N: $!\n" ); };

    }

    else {

        $N = $self->N;

        $sub = sub {
            POSIX::close( $N )
              or die( "error in closing $N: $!\n" );
        };

    }

    return $sub, $N;

}

sub apply {

	my $self = shift;

	my ( $N, $M ) =  do {

		no warnings 'uninitialized';

		map { $fh_map{$_} } $self->N, $self->M;

	};

	my $mth = '_' . $self->_type;
	return $self->$mth( $N, $M );
}



1;


__END__

=head1 NAME

B<IPC::PrettyPipe::Stream> - An I/O stream for an B<IPC::PrettyPipe> pipline or command

=head1 SYNOPSIS

  use IPC::PrettyPipe::Stream;

  # standard constructor
  $stream = IPC::PrettyPipe::Stream->new( spec => $spec, %attr );
  $stream = IPC::PrettyPipe::Stream->new( spec => $spec, file => $file, %attr );

  # concise constructors
  $stream = IPC::PrettyPipe::Stream->new( $spec );
  $stream = IPC::PrettyPipe::Stream->new( [ $spec, $file ] );

=head1 DESCRIPTION

B<IPC::PrettyPipe::Stream> objects represent I/O streams attached to
either B<L<IPC::PrettyPipe>> or B<L<IPC::PrettyPipe::Cmd>> objects.

=head1 METHODS

=over 8

=item B<new>

  # named parameters; may provide additional attributes
  $stream = IPC::PrettyPipe::Stream->new( spec => $spec, file => $file, %attr );
  $stream = IPC::PrettyPipe::Stream->new( \%attr );

  # concise interface
  $stream = IPC::PrettyPipe::Stream->new( $spec );
  $stream = IPC::PrettyPipe::Stream->new( [ $spec, $file ] );


The available attributes are:

=over

=item C<spec>

A stream specification. See L<IPC::PrettyPipe::Stream::Utils> for more
information.

=item C<file>

The optional file attached to the stream. A file is
not needed if the specification is for a redirection or a close.

=item C<strict>

If true, die if the stream specification requires a file but one is
not provided, or it does not require a file and one is provided.

=back

=item B<spec>

  $spec = $stream->spec;

Retrieve the specification passed in to the constructor.

=item B<file>

  $file = $stream->file;

Return the file passed in to the constructor (if one was).

=item B<quoted_file>

  $file = $stream->quoted_file;

Return the file passed in to the constructor (if one was),
appropriately quoted for passing as a single word to a Bourne
compatible shell.


=item B<has_file>

  $bool = $stream->has_file;

Returns true if a file was passed to the constructor.

=item B<requires_file>

  $bool = $stream->requires_file;

Returns true if the stream specification requires a file.

=item B<Op>

=item B<N>

=item B<M>

  $Op = $stream->Op;
  $N  = $stream->N;
  $M  = $stream->M;

Retrieve the components of the specification.

=item B<has_N>

=item B<has_M>

  $bool = $stream->has_N;
  $bool = $stream->has_M;

Return true if the stream specification contained the associated
component.


=item B<apply>

  ( $sub, @fh ) = $stream->apply;

Returns a subroutine which will implement the stream operations and
and a list of filehandles or descriptors which would be affected.
This routine is used by backend wrappers in conjunction with
B<L<IO::ReStoreFH>> to handle pipe level stream operations (rather
than command stream operations, which are done by the actual backend
modules).

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>
