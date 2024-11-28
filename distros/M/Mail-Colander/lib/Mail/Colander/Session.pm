package Mail::Colander::Session;
use v5.24;
use Moo;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use Ouch qw< :trytiny_var >;
use Mail::Colander::Message;

sub coerce_msg ($input) { Mail::Colander::Message->new(entity => $input) }

use namespace::clean;

has peer_ip       => (is => 'ro', default => undef);
has peer_port     => (is => 'ro', default => undef);
has peer_ip_port  => (is => 'lazy');
has peer_identity => (is => 'rw', clearer => 1, predicate => 1);
has reverse_path  => (is => 'rw', clearer => 1, predicate => 1);
has forward_path  => (is => 'rw', clearer => 1, predicate => 1);
has mail_min_size => (is => 'rw', clearer => 1, predicate => 1);
has mail_data     => (is => 'rw', clearer => 1, predicate => 1);
has last_op       => (is => 'rw', default => 'RST');

# the star
has message => (
   is => 'lazy',
   clearer => 1,
   coerce => \&coerce_msg,
   handles => [qw<
      from
      recipients to cc bcc
      subject
      bare_addresses
      header_first
      header_all
   >],
);

sub _build_peer_ip_port ($self) {
   my $ip = $self->peer_ip // '*undefined*';
   my $port = $self->peer_port // 0;
   return "$ip:$port";
}

sub mail_size ($self) {
   ouch 400, 'no mail available' unless $self->has_mail_data;
   return length(${$self->mail_data});
}

sub _return ($self, $offset = 1) {
   my (undef, undef, undef, $sub) = caller($offset);
   $self->last_op($sub =~ s{\A .* ::}{}rmxs);
   return $self;
}

sub reset ($self) {
   $self->reset_transaction;
   $self->clear_peer_identity;
   return $self->_return(2);
}

sub _start_session ($self, $peer_identity) {
   $self->reset->peer_identity($peer_identity);
   return $self->_return(2);
}

sub reset_transaction ($self) {
   $self->clear_forward_path;
   $self->clear_reverse_path;
   $self->clear_mail_min_size;
   $self->clear_mail_data;
   $self->clear_message;
   return $self->_return(2);
}

sub HELO ($self, $srv, $peer)        { $self->_start_session($peer) }
sub EHLO ($self, $srv, $peer, $exts) { $self->_start_session($peer) }
sub RST  ($self, $srv)               { $self->reset_transaction     }
sub QUIT ($self, $srv)               { $self->reset                 }

sub MAIL ($self, $srv, $reverse_path) {
   ouch 400, 'out of sync MAIL command'
      if (! $self->has_peer_identity) # no HELO received so far
      || ($self->has_reverse_path && (! $self->has_mail_data));
   $self->reverse_path($reverse_path =~ s{\A < | > \z}{}rgmxs);
   return $self->_return;
}

sub RCPT ($self, $srv, $forward_path) {
   ouch 400, 'out of sync RCPT command'
      if (! $self->has_reverse_path) || ($self->has_mail_min_size);
   my $fps = $self->has_forward_path ? $self->forward_path : [];
   push($fps->@*, ($forward_path =~ s{\A < | > \z}{}rgmxs));
   $self->forward_path($fps) unless $self->has_forward_path;
   return $self->_return;
}

sub DATA ($self, $srv, $mail_data) {
   ouch 400, 'out of sync DATA, rejected initialization'
      unless $self->has_mail_min_size;
   $self->mail_data($mail_data);
   return $self->_return;
}

sub DATA_INIT ($self, $srv) {
   ouch 400, 'out of sync DATA command, already receving?'
      if $self->has_mail_min_size;
   ouch 400, 'out of sync DATA command'
      if (! $self->has_reverse_path) || ($self->has_mail_data);
   ouch 400, 'no forward-path, DATA makes no sense'
      unless $self->has_forward_path;
   $self->mail_min_size(0);
   return $self->_return;
}

sub DATA_PART ($self, $srv, $chunk_ref) {
   ouch 400, 'out of sync DATA-PART, rejected initialization'
      unless $self->has_mail_min_size;
   $self->mail_min_size($self->mail_min_size + length($$chunk_ref));
   return $self->_return;
}

sub _build_message ($self) { return $self->mail_data }

1;
