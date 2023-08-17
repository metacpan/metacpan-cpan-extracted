package Log::Any::Adapter::Log4perlTiny;
use strict;
use warnings;
{ our $VERSION = '0.001' }

use Log::Log4perl::Tiny     qw< :dead_if_first LEVELID_FOR >;
use Log::Any::Adapter::Util ();
use parent 'Log::Any::Adapter::Base';

{

   my $logger = Log::Log4perl::Tiny->get_logger;

   # map stuff, rest goes to fatal
   my %level_for = (
      notice  => 'info',
      warning => 'warn',
      (map { $_ => $_ } qw< trace debug info warn error fatal >),
   );

   my %id_for =
     map { $_ => LEVELID_FOR(uc($level_for{$_})) } keys(%level_for);

   sub structured {
      my ($self, $level, $category, @args) = @_;
      local $Log::Log4perl::Tiny::caller_depth =
         $Log::Log4perl::Tiny::caller_depth + 2;
      $logger->log($id_for{$level} || $id_for{fatal}, @args);
   }

   for my $method (Log::Any::Adapter::Util::detection_methods()) {
      my $level     = $level_for{substr($method, 3)} || 'fatal';
      my $delegated = $logger->can("is_$level");
      no strict 'refs';
      *{$method} = sub { $logger->$delegated }
   } ## end for my $method (Log::Any::Adapter::Util::detection_methods...)
}

1;
