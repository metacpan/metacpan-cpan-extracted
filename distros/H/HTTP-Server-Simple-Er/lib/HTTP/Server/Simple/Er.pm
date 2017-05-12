package HTTP::Server::Simple::Er;
$VERSION = v0.0.4;

use warnings;
use strict;
use Carp;

use HTTP::Headers ();
use HTTP::Date ();
use HTTP::Status ();

use URI::Escape ();

=head1 NAME

HTTP::Server::Simple::Er - lightweight server and interface

=head1 SYNOPSIS

  use HTTP::Server::Simple::Er;
  HTTP::Server::Simple::Er->new(port => 8089,
    req_handler => sub {
      my $self = shift;
      my $path = $self->path;
      ...
      $self->output(404, "can't find it");
    }
  )->run;

=head1 ABOUT

This is mostly an API experiment.  You might be perfectly happy with
HTTP::Server::Simple, but I find that I often want to use it only in
tests and that the interface is a little clunky for that, so I'm
gathering some of the handiness that has been sitting on my hard drive
and starting to get it on CPAN.

=cut

my @PROPS = qw(method protocol query_string
  request_uri path localname localport peername peeraddr);
use Class::Accessor::Classy;
with 'new';
ri 'listener_cb';
rw @PROPS;
ri 'port';
ri 'req_handler';
ro 'headers';
ri 'child_pid';
no  Class::Accessor::Classy;

# ick, make our accessors overwrite those
use base; base->import('HTTP::Server::Simple');

=head2 new

  my $server = HTTP::Server::Simple::Er->new(%props);

=cut

sub new {
  my $class = shift;
  croak('odd number of elements in argument list') if(@_ % 2);
  my $self = {@_};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=begin internals

=head2 run

  $server->run;

=cut

sub run {
  my $self = shift;
  $self->set_port(8080) unless($self->port);
  $self->SUPER::run(@_);
} # end subroutine run definition
########################################################################

=head2 setup_listener

Used by child_server() to callback once we're setup.

  $server->setup_listener;

=cut

sub setup_listener {
  my $self = shift;
  $self->SUPER::setup_listener;
  if(my $cb = $self->listener_cb) {
    $cb->();
  }
} # end subroutine setup_listener definition
########################################################################

=head2 setup

  $self->setup(%blah);

=cut

sub setup {
  my $self = shift;
  while(my ($item, $value) = splice(@_, 0, 2)) {
    my $setter = 'set_' . $item;
    $self->$setter($value);
  }
} # end subroutine setup definition
########################################################################

=head2 headers

  $self->headers($ref);

=cut

sub headers {
  my $self = shift;
  my ($ref) = @_;
  $ref or return($self->{headers});
  my %headers = @$ref;
  my $h = $self->{headers} = HTTP::Headers->new;
  while(my ($k, $v) = each(%headers)) {
    $h->header($k, $v);
  }
} # end subroutine headers definition
########################################################################

=end internals

=head2 child_server

Starts the server as a child process.

  my $url = $server->child_server;

=cut

sub child_server {
  my $self = shift;

  my $parent = $$;
  my $win_event;
  my $child;
  my $cb;
  my $kill_child;
  if($^O eq 'MSWin32') {
    require Win32::Event;
    $win_event = Win32::Event->new();
    $kill_child = sub { kill 9, $child; sleep 1 while kill 0, $child; };
    $cb = sub {$win_event->pulse};
  }
  else {
    $kill_child = sub { kill INT => $child; };
    $cb = sub {kill USR1 => $parent};
  }
  $self->set_listener_cb($cb);

  my $child_loaded = 0;
  local %SIG;
  if(not $^O eq 'MSWin32') {
    $SIG{USR1} = sub { $child_loaded = 1; };
  }

  local *print_banner = sub {}; # silence this thing

  $self->set_port(8080) unless($self->port);
  $child = $self->background;
  $child =~ /^-?\d+$/ or
    croak("background() didn't return a valid pid");
  $self->set_child_pid($child);

  # hooks to handle our zombies:
  $SIG{INT} = sub { # TODO should really be stacked handlers?
    warn "interrupt";
    $kill_child->();
    # rethrow:  INT *shouldn't* run END blocks => exit/die is wrong
    $SIG{INT} = 'DEFAULT'; kill INT => $$;
  };
  eval(q(END {&$kill_child}));

  if($win_event) {
    $win_event->wait;
  }
  else {
    local $SIG{CHLD} = sub { croak "child died"; };
    1 while(not $child_loaded);
  }
  return("http://localhost:" . $self->port);
} # end subroutine child_server definition
########################################################################

=head2 handler

You may override this, or simply set C<req_handler> before calling run.

  $server->handler;

=cut

sub handler {
  my $self = shift;
  my $h = $self->req_handler or
    croak("req_handler not defined or overridden");
  $h->($self);
} # end subroutine handler definition
########################################################################

=head2 output

Takes status code from $params{status} or a leading number.  Otherwise,
sets it to 200.

  $self->output(\%params, @strings);

  $self->output(501, \%params, @strings);

  $self->output(501, @strings);

  $self->output(@strings);

The code may also be an 'RC_*' string which corresponds to a constant
from HTTP::Status.

  $self->output(RC_NOT_FOUND => @error_html);

=cut

sub output {
  my $self = shift;
  my @args = @_;

  # allow leading code and/or leading params ref
  my $code = ($args[0] =~ m/^RC_|^\d\d\d$/) ? shift(@args) : undef;
  my %p;
  if((ref($args[0])||'') eq 'HASH') {
    %p = %{shift(@args)};
    ($code and $p{status}) and die "cannot have status twice"
  }
  # let subclasses pass a trailing hashref
  if(((ref($args[-1]))||'') eq 'HASH') {
    my $also = pop(@args);
    my @k = keys(%$also);
    @p{@k} = @$also{@k};
  }
  $code = $p{status} ||= $code ||= 200;
  if($code =~ m/^RC_/) {
    my $sub = HTTP::Status->can($code) or
      croak("$code is not a valid RC_* constant in HTTP::Status");
    $p{status} = $code = $sub->();
  }

  # "servers MUST include a Date header"
  $p{Date} ||= HTTP::Date::time2str(time);

  my $h = HTTP::Headers->new(%p);
  $h->content_type('text/html') unless($h->content_type);

  my $data = join("\r\n", @args);
  $h->content_length(length($data));

  my $message = HTTP::Status::status_message($code);
  print join("\r\n",
    "HTTP/1.1 $code $message",
    $h->as_string, '');
  print $data;
} # end subroutine output definition
########################################################################

=head2 params

Return a hash of parameters parsed from $self->query_string;

  my %params = $server->params;

=cut

sub params {
  my $self = shift;

  my $s = $self->query_string;
  # XXX check for correctness
  return map({URI::Escape::uri_unescape($_)}
    map({split(/=/, $_, 2)} split(/&/, $s)));
} # params #############################################################

=head2 form_data

Retrieve POSTed form data.  If an element is mentioned twice, its value
automatically becomes an arrayref.

  my %form = $server->form_data;

=cut

sub form_data {
  my $self = shift;

  my $h = $self->headers;
  my $s;
  my $fh = $self->stdio_handle;
  read($fh, $s, $h->{'content-length'});

  # XXX check for correctness
  my %d;
  foreach my $pair (split(/&/, $s)) {
    my ($k,$v) = map({$_ = URI::Escape::uri_unescape($_); s/\+/ /g; $_}
      split(/=/, $pair, 2));
    if($d{$k}) {
      $d{$k} = [$d{$k}] unless(ref $d{$k});
      push(@{$d{$k}}, $v);
    }
    else {
      $d{$k} = $v;
    }
  }
  return(%d);
} # form_data ##########################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
