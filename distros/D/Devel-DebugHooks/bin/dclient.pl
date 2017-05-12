#!/usr/bin/env perl

use warnings;
use strict;


our $session_stream;


my ( $host, $port ) =  @ARGV[ 1, 2 ];
$host //=  '127.0.0.1';
$port //=  9000;

my $loop;
my $timer;
my $tty;

my $verbose =  0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
use IO::Async::Loop;
$loop = IO::Async::Loop->new;

use IO::Async::Timer::Periodic;
$timer = IO::Async::Timer::Periodic->new(
    first_interval =>  0,
    interval       =>  2,

    on_tick        =>  sub {
        # warn ">>@_<<<< Retrying";
        my $self =  shift;

        unless( $session_stream  &&  $session_stream->loop ) {
            create_dbg_session( $loop, $host, $port );
        } else {
            # warn "Stopping the timer";
            $self->stop;
        }
    },
);



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
use IO::Async::Stream;
$tty =  IO::Async::Stream->new(
    read_handle  =>  \*STDIN,
    write_handle =>  \*STDOUT,
    on_read      =>  \&tty_read,
);


sub tty_read {
    my ( $self, $buffref, $eof ) = @_;

    if( $$buffref =~ s/-v\n// ) {
        $verbose =  $verbose ? 0 : 1 ;
        return 1;
    }
    if( $$buffref =~ s/-vv\n// ) {
        $verbose =  2;
        return 1;
    }

    if( $session_stream  &&  $session_stream->loop ) {
        $session_stream->write( $$buffref );
    }
    else {
        $tty->write( "No debug session is active\n" );
    }

    $$buffref =  '';

    if( $eof ) {
        warn "STDIN EOF";
    }


    return 0;
}

$loop->add( $tty );



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub handle_write_eof {
    warn "Write EOF: >>@_<<";
}


sub handle_write_error {
    warn "Write error: >>@_<<";
}


sub handle_closed {
    warn "Closed >>@_<<$session_stream<<";

    # Q: It is so restrictive... I think, it sould be enough just warn about
    # that timer is already running, because that is not so critical
    $timer->start   unless $timer->is_running;
}


# Why this is called after 'handle_closed'?
sub handle_read_eof {
    warn "Read EOF: >>@_<<";
}


sub handle_read_error {
    warn "Read error: >>@_<<";
}


sub handle_read {
    my( $self, $buffref, $eof ) =  @_;

    on_data( $buffref );
    $$buffref =  '';

    if( $eof ) {
        warn "GOT EOF at $self";
        $self->close_when_empty();
    }


    return 0;
};


sub on_data {
    my( $data ) =  @_;

    $tty->write( "New data(DC)\n" )   if $verbose;
    $data =  $$data;
    $data =  ' -'x20 ."\n" .$data ." -"x20 ."\n"   if $verbose > 1;
    $tty->write( $data );
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub on_dbg_session {
    ( $session_stream ) =  @_;


    $session_stream->configure(
        close_on_read_eof =>  0
        ,autoflush        =>  1

        ,on_write_eof     =>  \&handle_write_eof
        ,on_write_error   =>  \&handle_write_error
        ,on_closed        =>  \&handle_closed

        ,on_read_eof      =>  \&handle_read_eof
        ,on_read_error    =>  \&handle_read_error
        ,on_read          =>  \&handle_read
    );


    $loop->add( $session_stream );

    $session_stream->write( "l .\n" );
    warn "DBG session activated";
}


# Подключение по протоколу TCP к хосту на порт
sub create_dbg_session {
    my( $loop, $host, $port ) =  @_;


    $loop->connect(
        host     =>  $host,
        service  =>  $port,
        socktype =>  'stream',

        on_resolve_error => sub { die "Cannot resolve - >>@_<<\n"; },
        on_connect_error => sub { 0  &&  warn "Cannot connect\n"; },

        # Успешное подключение
        on_stream =>  \&on_dbg_session
    );
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
$timer->start;
$loop->add( $timer );
$loop->run;


__END__


# Devel::Caller - like 'caller'
# PadWalker <- debug statements
# Package::Stash - shows package variables
# View op tree: B::Concise
# B::Deparse - deparse CODEREF
#     $deparse = B::Deparse->new("-p", "-sC");
#     print $deparse->coderef2text( \&DB::process );
# B::DeparseTree
# Devel::Size - занятое пространство под переменную
# http://search.cpan.org/~abigail/perl-5.23.5/pod/perldebguts.pod#Using_$ENV{PERL_DEBUG_MSTATS}
# http://www.foo.be/docs/tpj/issues/vol3_2/tpj0302-0011.html
# Devel::Peek - shows info about variables as it exists at internals
# # Module::Reloader
# use Smart::Comments - clever thins at comments
# Devel::Cover - качество покрытия программы тестами

Devel::Spy
Devel::Refactor
Devel::PL_origargv
Devel::Peek
Devel::LeakTrace
Devel::DollarAt
Devel::Cycle
Devel::CoverReport
Devel::Cover

Tie::Watch
