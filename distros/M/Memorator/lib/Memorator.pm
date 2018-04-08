package Memorator;
use strict;
use warnings;
{ our $VERSION = '0.006'; }

use Memorator::Util ();
use Module::Runtime qw< use_module >;

use Mojo::Base -base;
use Try::Tiny;

use constant ATTEMPTS       => 2;                  # default value
use constant PROCESS_ALERT  => 'process_alert';
use constant PROCESS_UPDATE => 'process_update';

has alert_callback => sub { die "missing mandatory parameter 'alert_cb'" };
has backend        => undef;
has minion         => sub { die "missing mandatory parameter 'minion'" };
has name           => 'memorator';

sub _cleanup_alerts {
   my ($self, $minion) = @_;
   $minion //= $self->minion;

   my $backend = $self->backend;
   my $log     = $minion->app->log;

   my @stales = try { $backend->stale_mappings }
   catch { $log->error("cleanup error: $_"); };

   for my $stale (@stales) {
      my ($id, $eid, $jid) = @{$stale}{qw< id eid jid >};
      if (! defined $id) {
         $log->error('found stale with undefined id...');
         next;
      }
      try {
         my $log_jid = defined($jid) ? $jid : '*undef*';
         $log->info("removing superseded job '$log_jid'");
         $backend->remove_mapping($id);
         if (my $job = $minion->job($jid)) {
            $job->remove
              if $job->info->{state} =~ m{\A(?: active | inactive )\z}mxs;
         }
      } ## end try
      catch {
         $log->error("cleanup of id<$id>/eid<$eid>/jid<$jid> error: $_");
      };
   } ## end for my $href (@stales)

   return;
} ## end sub _cleanup_alerts

sub _minion2backend {
   my $self = shift;
   my $mb   = $self->minion->backend;
   (my $dbtech = ref $mb) =~ s{.*::}{}mxs;
   my $mdb       = $mb->can(lc($dbtech))->($mb);
   my $classname = __PACKAGE__ . '::Backend::' . ref($mdb);
   return use_module($classname)->new(mojodb => $mdb, name => $self->name);
} ## end sub _minion2backend

sub _local_name {
   my ($self, $suffix) = @_;
   return Memorator::Util::local_name($self->name, $suffix);
}

sub new {
   my $package = shift;
   my $self    = $package->SUPER::new(@_);

   $self->backend($self->_minion2backend) unless $self->backend;
   $self->backend->ensure_table;

   my $minion = $self->minion;
   $minion->add_task($self->_local_name(PROCESS_UPDATE) =>
        sub { $self->_process_update(@_) });
   $minion->add_task($self->_local_name(PROCESS_ALERT) =>
        sub { $self->_process_alert(@_) });

   return $self;
} ## end sub new

sub _process_alert {
   my ($self, $job, $eid) = @_;
   my $backend = $self->backend;

   # find mapping, fail fast if not present/obsoleted/superseded
   my $e2j = $backend->mapping_between($eid, $job->id)
     or return $job->fail;

   # here this job is entitled to send the alert for this eid
   $self->alert_callback->($eid);

   # now passivate the mapping and do a general cleanup
   $backend->deactivate_mapping($e2j->{id});
   $self->_cleanup_alerts($job->minion);

   return;
} ## end sub _process_alert

sub _process_update {
   my ($self, $job, $alert) = @_;
   return $self->set_alert($alert, $job->minion);
}

sub remove_alert {
   my ($self, $id, $minion) = @_;
   $self->backend->remove_mapping(ref($id) ? $id->{id} : $id);
   $self->_cleanup_alerts($minion);
   return;
}

sub set_alert {
   my ($self, $alert, $minion) = @_;
   $minion //= $self->minion;
   my ($eid, $epoch, $attempts) = @{$alert}{qw< id epoch attempts >};
   $attempts //= ATTEMPTS;

   if (defined $epoch) {
      my $now = time;
      my $delay = ($epoch > $now) ? ($epoch - $now) : 0;

      my $task = $self->_local_name(PROCESS_ALERT);
      $minion->app->log->debug("enqueuing $task in ${delay}s");
      my $jid = $minion->enqueue(
         $task => [$eid],
         {delay => $delay, attempts => $attempts}
      );

      # record for future mapping
      $self->backend->add_mapping($eid, $jid);
   }
   else { # remove alert
      $self->backend->remove_mapping($eid);
   }

   # whatever happened, cleanup
   $self->_cleanup_alerts($minion);    # never fails
   return $self;
} ## end sub set_alert

1;
