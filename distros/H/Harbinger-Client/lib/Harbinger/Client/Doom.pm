package Harbinger::Client::Doom;
$Harbinger::Client::Doom::VERSION = '0.001002';
use List::Util 'first';
use Module::Runtime 'use_module';
use Sereal::Encoder 'encode_sereal';
use Try::Tiny;
use Time::HiRes;
use Moo;
use warnings NONFATAL => 'all';

sub _measure_memory {
   my $pid = shift;

   my $ret = try {
      if ($^O eq 'MSWin32') {
         use_module('Win32::Process::Memory')
            ->new({ pid  => $pid })
            ->get_memtotal
      } else {
         (
            first { $_->pid == $pid } @{
               use_module('Proc::ProcessTable')
               ->new
               ->table
            }
         )->rss
      }
   } catch { 0 };

   int($ret / 1024)
}

use namespace::clean;

has pid => (
   is => 'rw',
   default => sub { $$ },
);

has [qw(
   server ident
   count port milliseconds_elapsed db_query_count memory_growth_in_kb
   _start_time _start_kb query_logger
)] => ( is => 'rw' );

sub bode_ill { $_[0]->count($_[0]->count||0 + 1) }

sub start {
   my ($self, @args) = @_;

   shift->new({
      _start_time => [ Time::HiRes::gettimeofday ],
      _start_kb => _measure_memory($$),
      query_logger => use_module('DBIx::Class::QueryLog')->new,
      @args,
   })
}

sub finish {
   my ($self, %args) = @_;

   $self->milliseconds_elapsed(
      int(Time::HiRes::tv_interval($self->_start_time) * 1000)
   );
   $self->db_query_count($self->query_logger->count);
   $self->memory_growth_in_kb(_measure_memory($self->pid) - $self->_start_kb);
   $self->$_($args{$_}) for keys %args;

   return $self
}

my %mapping = (
   port                 => 'port',
   milliseconds_elapsed => 'ms',
   db_query_count       => 'qc',
   memory_growth_in_kb  => 'mg',
   count                => 'c',
);
sub _as_sereal {
   my $self = shift;

   for my $thing (qw(server ident pid)) {
      unless ($self->$thing) {
         warn "$thing can't be blank" if $ENV{HARBINGER_WARNINGS};
         return
      }
   }

   return encode_sereal({
      server => $self->server,
      ident  => $self->ident,
      pid    => $self->pid,

      map {
         my $m = $mapping{$_};
         defined $self->$_ ? ( $m => 0 + $self->$_ ) : ()
      } keys %mapping
   })
}

1;
