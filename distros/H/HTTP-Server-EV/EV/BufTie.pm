package HTTP::Server::EV::BufTie;
our $VERSION = '0.69';
use Carp;
use strict;
use bytes;
use Guard;

=head1 NAME

HTTP::Server::EV::BufTie - Internal class used by L<HTTP::Server::EV::CGI> for proxifying output to correct L<HTTP::Server::EV::Buffer>. 

=head1 DESCRIPTION

Mainly it`s workaround for bug of localizing *STDOUT(no only it, all global vars also) in L<Coro> threads, when calling HTTP::Server::EV::CGI->attach(local *STDOUT) overwrites STDOUT in all now runing coros.
That happens because local() doesn`t create lexical copy of var, it pushes old value to stack and sets new value to glob var, old value is restored when interpreter leaves the scope. So localizing variable in one coro overwrites it in all other.

=head1 BUGS

One coro thread - one socket. All handles attached in coro thread will refer to one socket that attached to filehandle last. 
It`s possible to support attaching different sockets to different handles in same coro thread by constructing tie object on flow, but it slow and generally needn't, so not implemented.

=cut



our %storage;


sub new {
	unless(tied *{$_[1]}){
		tie *{$_[1]} , __PACKAGE__;
	}
	
	my $coro = $Coro::current;
	$storage{$coro} = $_[2];
	
	Guard::guard {
		delete $storage{$coro};
	}
}


sub TIEHANDLE { # pkgname, handle, buffer obj
	$storage{$Coro::current} = $_[1];
	bless \%storage , $_[0];
}

*TIESCALAR=\&TIEHANDLE;


sub PRINT { shift->{$Coro::current}->PRINT(@_); }

sub PRINTF { shift->{$Coro::current}->PRINTF(@_); }

sub READLINE { croak "HTTP::Server::EV::BufTie doesn't support a READLINE method"; }

sub GETC { croak "HTTP::Server::EV::BufTie doesn't support a GETC method"; }

sub READ { croak "HTTP::Server::EV::BufTie doesn't support a READ method"; }

sub WRITE { shift->{$Coro::current}->WRITE(@_); }



sub DESTROY { 
	
}

*CLOSE = \&DESTROY;

1;