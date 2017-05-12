package HTTP::LoadGen::ScoreBoard;

use strict;
use IPC::ScoreBoard;
no warnings 'uninitialized';

our $VERSION = '0.04';

use Exporter qw/import/;
our @EXPORT_OK=qw/scoreboard sb slot thread_start thread_done req_start
		  req_done thread_count req_started req_success req_failed
		  header_bytes header_count body_bytes sbinit/;

use constant {
  SC_THREADCOUNT=>0,		# scoreboard items
  SC_REQ_STARTED=>1,
  SC_REQ_SUCCESS=>2,
  SC_REQ_FAILED=>3,
  SC_BODY_BYTES=>4,
  SC_HEADER_BYTES=>5,
  SC_HEADER_COUNT=>6,
  SC_SLOTSIZE=>7,
};

my ($scoreboard, $slotsz, $extra, $myslot);

sub scoreboard () : lvalue {$scoreboard;}
sub slot () : lvalue {$myslot;}

BEGIN {
  if( SB::have_atomics ) {
    *init=sub {
      (my ($name, $nslots), $slotsz, $extra)=@_;
      if( defined $name ) {
	$scoreboard=SB::named $name, 0+$nslots, 0+$slotsz, $extra+SC_SLOTSIZE;
      } else {
	$scoreboard=SB::anon 0+$nslots, 0+$slotsz, $extra+SC_SLOTSIZE;
      }
      return $scoreboard;
    };

    *thread_start=sub () {
      SB::incr_extra $scoreboard, $extra+SC_THREADCOUNT;
    };

    *thread_done=sub () {
      SB::decr_extra $scoreboard, $extra+SC_THREADCOUNT;
    };

    *req_start=sub () {
      SB::incr_extra $scoreboard, $extra+SC_REQ_STARTED;
    };

    *req_done=sub ($$$) {
      my ($success, $hdr, $body)=@_;
      SB::incr_extra $scoreboard,
	  $extra+($success ? SC_REQ_SUCCESS : SC_REQ_FAILED);
      SB::incr_extra $scoreboard, $extra+SC_BODY_BYTES, length $body;
      SB::incr_extra $scoreboard, $extra+SC_HEADER_COUNT, 0+keys %$hdr;
      my $sum=0;
      while( my ($k, $v)=each %$hdr ) {
	$sum+=length $k;
	for my $s (@$v) {
	  $sum+=length $s;
	}
      }
      SB::incr_extra $scoreboard, $extra+SC_HEADER_BYTES, $sum;
    };

    *thread_count=sub () {
      SB::get_extra $scoreboard, $extra+SC_THREADCOUNT;
    };

    *req_started=sub () {
      SB::get_extra $scoreboard, $extra+SC_REQ_STARTED;
    };

    *req_success=sub () {
      SB::get_extra $scoreboard, $extra+SC_REQ_SUCCESS;
    };

    *req_failed=sub () {
      SB::get_extra $scoreboard, $extra+SC_REQ_FAILED;
    };

    *header_bytes=sub () {
      SB::get_extra $scoreboard, $extra+SC_HEADER_BYTES;
    };

    *header_count=sub () {
      SB::get_extra $scoreboard, $extra+SC_HEADER_COUNT;
    };

    *body_bytes=sub () {
      SB::get_extra $scoreboard, $extra+SC_BODY_BYTES;
    };
  } else {			# no atomics
    *init=sub {
      (my ($name, $nslots), $slotsz, $extra)=@_;
      if( defined $name ) {
	$scoreboard=SB::named $name, 0+$nslots, 0+$slotsz+SC_SLOTSIZE, 0+$extra;
      } else {
	$scoreboard=SB::anon 0+$nslots, 0+$slotsz+SC_SLOTSIZE, 0+$extra;
      }
      return $scoreboard;
    };

    *thread_start=sub () {
      SB::incr $scoreboard, $myslot, $slotsz+SC_THREADCOUNT;
    };

    *thread_done=sub () {
      SB::decr $scoreboard, $myslot, $slotsz+SC_THREADCOUNT;
    };

    *req_start=sub () {
      SB::incr $scoreboard, $myslot, $slotsz+SC_REQ_STARTED;
    };

    *req_done=sub ($$$) {
      my ($success, $hdr, $body)=@_;
      SB::incr $scoreboard, $myslot,
	  $slotsz+($success ? SC_REQ_SUCCESS : SC_REQ_FAILED);
      SB::incr $scoreboard, $myslot, $slotsz+SC_BODY_BYTES, length $body;
      SB::incr $scoreboard, $myslot, $slotsz+SC_HEADER_COUNT, 0+keys %$hdr;
      my $sum=0;
      while( my ($k, $v)=each %$hdr ) {
	$sum+=length $k;
	for my $s (@$v) {
	  $sum+=length $s;
	}
      }
      SB::incr $scoreboard, $myslot, $slotsz+SC_HEADER_BYTES, $sum;
    };

    *thread_count=sub () {
      SB::sum $scoreboard, $slotsz+SC_THREADCOUNT;
    };

    *req_started=sub () {
      SB::sum $scoreboard, $slotsz+SC_REQ_STARTED;
    };

    *req_success=sub () {
      SB::sum $scoreboard, $slotsz+SC_REQ_SUCCESS;
    };

    *req_failed=sub () {
      SB::sum $scoreboard, $slotsz+SC_REQ_FAILED;
    };

    *header_bytes=sub () {
      SB::sum $scoreboard, $slotsz+SC_HEADER_BYTES;
    };

    *header_count=sub () {
      SB::sum $scoreboard, $slotsz+SC_HEADER_COUNT;
    };

    *body_bytes=sub () {
      SB::sum $scoreboard, $slotsz+SC_BODY_BYTES;
    };
  }
}

*sbinit=\&init;

1;
__END__

=encoding utf8

=head1 NAME

HTTP::LoadGen::ScoreBoard - a slightly specialized IPC::ScoreBoard

=head1 SYNOPSIS

 use HTTP::LoadGen::ScoreBoard;

 # create it, storing the return value is optional. It is saved in
 # in a global variable internally.
 $sb=HTTP::LoadGen::ScoreBoard::init $name, $nproc, $slotsz, $extra;

 # get/set the internal scoreboard
 $sb=HTTP::LoadGen::ScoreBoard::scoreboard;
 HTTP::LoadGen::ScoreBoard::scoreboard=$sb;

 # get/set the current process' slot number
 $procnr=HTTP::LoadGen::ScoreBoard::slot;
 HTTP::LoadGen::ScoreBoard::slot=$procnr;

 # signal that a new thread has been born
 HTTP::LoadGen::ScoreBoard::thread_start;

 # signal that a thread has finished
 HTTP::LoadGen::ScoreBoard::thread_done;

 # signal that a request has been started
 HTTP::LoadGen::ScoreBoard::req_start;

 # signal that a request has finished
 HTTP::LoadGen::ScoreBoard::req_done $success, \%hdr, $body;

 # get current thread count
 $count=HTTP::LoadGen::ScoreBoard::thread_count;

 # get number of started requests so far
 $count=HTTP::LoadGen::ScoreBoard::req_started;

 # get number of successfully finished requests so far
 $count=HTTP::LoadGen::ScoreBoard::req_success;

 # get number of failed requests so far
 $count=HTTP::LoadGen::ScoreBoard::req_failed;

 # get number of bytes transferred so far as HTTP header fields
 $count=HTTP::LoadGen::ScoreBoard::header_bytes;

 # get number of HTTP header fields transferred so far
 $count=HTTP::LoadGen::ScoreBoard::header_count;

 # get number of bytes transferred so far as HTTP body
 $count=HTTP::LoadGen::ScoreBoard::body_bytes;

=head1 DESCRIPTION

This module is designed to cooperate with L<HTTP::LoadGen>.

=head2 Functions

=head3 $sb=HTTP::LoadGen::ScoreBoard::init $name, $nproc, $slotsz, $extra

creates an L<IPC::ScoreBoard> with C<$nproc> slots. The scoreboard has
room at least for the values maintained by this module. If C<$slotsz>
and C<$extra> are omitted or C<0> a scoreboard of exactly that size is
created. If you want to store more data you can either create a second
scoreboard and waste a bit of memory or extend this one. To do that
pass C<$slotsz> and C<$extra> as you need, see L<IPC::ScoreBoard>.
The fields private to C<HTTP::LoadGen::ScoreBoard> are placed at the
end of each slot including the extra slot. So, custom elements are
addressed as usual. For example

 HTTP::LoadGen::ScoreBoard::init undef, $nproc, 5, 10;

creates a scoreboard with room for C<5> custom values per slot and C<10>
custom values in the extra slot. The custom values are addressed by
element indices from C<0> to C<4> and for the extra slot from C<0> to C<10>.

The fields private to this module are addressed by element indices from C<5>
and C<10> for the extra slot upwards.

C<init> returns the scoreboard object. However, you don't need to
store it because it is stored internally and can be accessed
by the C<scoreboard> function.

The C<$name> parameter may be C<undef> to create an anonymous scoreboard
or contain a file name for a named one.

=head3 $sb=HTTP::LoadGen::ScoreBoard::sbinit

C<sbinit> is an alias for C<init> that is exported on demand while C<init>
is not.

=head3 $sb=HTTP::LoadGen::ScoreBoard::scoreboard

returns the scoreboard recently created by C<init>.

This is a lvalue-function. Hence, it can be assigned:

 HTTP::LoadGen::ScoreBoard::scoreboard=$other_scoreboard;
 undef HTTP::LoadGen::ScoreBoard::scoreboard;

=head3 HTTP::LoadGen::ScoreBoard::slot=$procnr;

This scoreboard maintains one slot per process. Hence, the slot number
may be stored in a global variable. This lvalue-function provides access
to that internal value.

This function must be called to set the process number prior to all other
operations that access a certain slot, e.g. C<thread_start>, C<req_done>,
etc.

=head3 HTTP::LoadGen::ScoreBoard::thread_start;

signals that a new thread has been born.

=head3 HTTP::LoadGen::ScoreBoard::thread_done;

signals that a thread has been done.

=head3 HTTP::LoadGen::ScoreBoard::req_start;

signals that a new request has been started.

=head3 HTTP::LoadGen::ScoreBoard::req_done $success, \%hdr, $body;

signals that a request has been done.

C<$success> is a boolean specifying whether the request was successful.

C<%hdr> is a hash containing all HTTP headers. Since a header can be
multi-valued the values in this hash are expected to be arrays:

 (
  HEADER1=>[VALUE1, VALUE2, ...],
  HEADER2=>[VALUE1, VALUE2, ...],
  ...
 )

C<$body> is the HTTP response body.

=head3 $count=HTTP::LoadGen::ScoreBoard::thread_count;

returns the number of threads currently active over all processes.

=head3 $count=HTTP::LoadGen::ScoreBoard::req_started;

returns the number of requests that have been started by all processes
together.

=head3 $count=HTTP::LoadGen::ScoreBoard::req_success;

returns the number of requests that have been successfully done by all
processes together.

=head3 $count=HTTP::LoadGen::ScoreBoard::req_failed;

returns the number of requests that have failed over all
processes.

Note, C<req_started - req_success - req_failed> is the number of requests
currently in progress.

=head3 $count=HTTP::LoadGen::ScoreBoard::header_bytes;

returns the number of bytes received so far as HTTP header (excluding
line endings and the HTTP status line).

=head3 $count=HTTP::LoadGen::ScoreBoard::header_count;

the number of HTTP header fields received so far. If a certain response
contains a header with the same name multiple times it is counted only
once.

=head3 $count=HTTP::LoadGen::ScoreBoard::body_bytes;

returns the number of bytes received so far as HTTP content.

=head2 EXPORT

exports on demand C<scoreboard>, C<slot>, C<thread_start>, C<thread_done>,
C<req_start>, C<req_done>, C<thread_count>, C<req_started>, C<req_success>,
C<req_failed>, C<header_bytes>, C<header_count>, C<body_bytes> and C<sbinit>

=head1 SEE ALSO

L<HTTP::LoadGen>

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
