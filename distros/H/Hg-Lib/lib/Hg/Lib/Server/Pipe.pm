package Hg::Lib::Server::Pipe;

use Symbol 'gensym';
#use IPC::Open3 qw[ open3 ];
use IPC::Open2 qw[ open2 ];

use Carp;

use POSIX qw[ :sys_wait_h ];
use Try::Tiny;

use Moo;
use MooX::Types::MooseLike::Base qw[ :all ];

sub forceArray {
    sub { 'ARRAY' eq ref $_[0] ? $_[0] : [ $_[0] ] }
}


with 'MooX::Attributes::Shadow::Role';

shadowable_attrs( qw[ hg args path configs ] );

has _pid => (
    is        => 'rwp',
    predicate => 1,
    clearer   => 1,
    init_arg  => undef
);
has _write => ( is => 'rwp', init_arg => undef );
has _read  => ( is => 'rwp', init_arg => undef );
has _error => ( is => 'rwp', init_arg => undef );
has cmd    => ( is => 'rwp' );

# path to hg executable
has hg => (
    is      => 'ro',
    default => sub { 'hg' },
    coerce  => forceArray,
    isa     => sub {
        is_Str( $_ )
          or die( "'hg' attribute must be string\n" )
          foreach @{ shift() };
    },
);

# arguments to hg
has args => (
    is      => 'ro',
    coerce  => forceArray,
    default => sub { [] },
);

has path => (
    is        => 'ro',
    predicate => 1,
);

has configs => (
    is      => 'ro',
    coerce  => forceArray,
    default => sub { [] },
);

has cmd => (
    is       => 'lazy',
    init_arg => undef,
);


sub _build_cmd {

    my $self = shift;

    my @cmd = (
        @{ $self->hg },
        qw[ --config ui.interactive=True
          serve
          --cmdserver pipe
          ],
    );

    push @cmd, '-R', $self->path if $self->has_path;

    push @cmd, map { ( '--config' => $_ ) } @{ $self->configs };

    push @cmd, @{ $self->args };

    return \@cmd;
}

sub BUILD {

    shift()->open;

}

sub open {

    my $self = shift;

    my ( $write, $read );
    my $error = gensym();

    my $pid;

    try {

        $pid = open2( $read, $write, @{ $self->cmd } );
        #        $pid = open3( $write, $read, $error, @{ $self->cmd } );

	# there's probably not enough time elapsed between starting
	# the child process and checking for its existence, but this
	# doesn't cost much
	_check_on_child( $pid, status => 'alive' );

    }
    catch {

        croak( $_ );

    };


    $self->_set__pid( $pid );
    $self->_set__write( $write );
    $self->_set__read( $read );
    $self->_set__error( $error );

}

sub DEMOLISH {

    shift()->close;

}

sub read {

    my $self = shift;

    # use aliased data in @_ to prevent copying
    return $self->_read->sysread( @_ );
}

# always use aliased $_[0] as buffer to prevent copying
# call as get_chunk( $buf )
sub get_chunk {

    my $self = shift;

    # catch pipe errors from child
    local $SIG{'PIPE'} = sub { croak( "SIGPIPE on read from server\n" ) };

    my $nr = $self->read( $_[0], 5 );
    croak( "error reading chunk header from server: $!\n" )
      unless defined $nr;

    $nr > 0
      or croak( "unexpected end-of-file getting chunk header from server\n" );

    my ( $ch, $len ) = unpack( 'A[1] l>', $_[0] );

    if ( $ch =~ /IL/ ) {

        return $ch, $len;

    }

    else {

        $self->read( $_[0], $len ) == $len
          or croak(
            "unexpected end-of-file reading $len bytes from server channel $ch\n"
          );

        return $ch;
    }

}

sub close {

    my $self = shift;

    # if the command server was created, see if it's
    # still hanging around
    if ( $self->_has_pid ) {

        $self->_write->close;

	_check_on_child( $self->_pid, status => 'exit', wait => 1 );

        $self->_clear_pid;
    }

    return;

}

sub _check_on_child {

    my $pid = shift;
    my %opt = @_;

    my $flags = WUNTRACED | ( $opt{wait} ? 0 : WNOHANG );
    my $status = waitpid( $pid, $flags );

    # if the child exitted, it had better have been a clean death;
    # anything else is not ok.
    if ( $pid == $status ) {

        die( "unexpected exit of child with status ",
            WEXITSTATUS( $? ), "\n" )
          if WIFEXITED( $? ) && WEXITSTATUS( $? ) != 0;

        die( "unexpected exit of child with signal ",
            WTERMSIG( $? ), "\n" )
          if WIFSIGNALED( $? );

    }

    if ( $opt{status} eq 'alive' ) {

	die( "unexpected exit of child\n" )
	    if $pid == $status || -1 == $status;

    }

    elsif ( $opt{status} eq 'exit' ) {

	# is the child still alive
	die( "child still alive\n" )
	     unless $pid == $status  || -1 == $status;

    }

    else {

	die( "internal error: unknown child status requested\n" );

    }

}
1;
