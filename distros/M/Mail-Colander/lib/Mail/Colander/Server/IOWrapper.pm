package Mail::Colander::Server::IOWrapper;
use v5.24;
use Moo;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use English qw< -no_match_vars >;
use Ouch qw< :trytiny_var >;
use namespace::clean;

has inr  => (is => 'rw', default => sub { my $v = ''; return \$v });
has outr => (is => 'rw', default => sub { my $v = ''; return \$v });
has ofh  => (is => 'lazy');
has size => (is => 'rw', default => 0);
has stream => (is => 'ro', required => 1);

sub _build_ofh ($self) {
   open my $ofh, '>:raw', $self->outr or ouch 500, "open(): $OS_ERROR";
   bless($ofh, 'IO::Handle'); # dirty trick
   return $ofh;
}

sub read_input ($self, $bytes) {
   my $inr = $self->inr;
   $$inr .= $bytes;

   # FIXME we have to think harder on limiting the line lenght AND the
   # input message size (to prevent flooding/excessively big messages)
   $self->size($self->size + length($bytes));

   my $idx = rindex($$inr, "\x{0A}"); # like Net::Server::Mail::process()
   return '' if $idx < 0;
   return substr($$inr, 0, $idx + 1, '');
}

sub write_output ($self) {
   my $outr = $self->outr;
   if (length($$outr)) {
      $self->stream->write($$outr);
      $$outr = '';
      seek($self->ofh, 0, 0);
   }
   return $self;
}

sub reset ($self) {
   ${$self->inr} = '';
   ${$self->outr} = '';
   seek($self->ofh, 0, 0);
   $self->size(0);
   return $self;
}

sub reset_size ($self) {
   $self->size(0);
   return $self;
}

1;
