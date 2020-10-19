use v5.10;
use strict;
use warnings;

use Module::Build;

# This version of Future contains an important bugfix around weak references
# in sequence Futures. Unfortunately, a lot of existing CPAN code is known to
# rely on this behaviour, and will break if this module is upgraded.
#
# Abort if any of the following modules are installed at versions less than
# the first known-working version. They must be updated before Future can be
# installed.
my %FIXED = (
   'IO::Async' => '0.62',
   'IO::Async::SSL' => '0.14',
   'Net::Async::CassandraCQL' => '0.11',
   'Net::Async::FTP' => '0.08',
   'Net::Async::HTTP' => '0.34',
   'Net::Async::WebSocket' => '0.08',
);

my $printed;
foreach my $module ( sort keys %FIXED ) {
   my $needsver = $FIXED{$module};
   ( my $modfile = "$module.pm" ) =~ s{::}{/}g;

   next unless eval { require $modfile };
   next if ( my $instver = $module->VERSION ) >= $needsver;

   print STDERR "Installing this version of Future will fix a bug that the following installed\n".
                "modules rely on. You must upgrade these modules to a later version after\n".
                "Future is installed, or they will not work correctly.\n\n" unless $printed;

   print STDERR "  * $module (installed $instver; need at least $needsver)\n";
   $printed++;
}
print STDERR "\n" if $printed;

if( $printed and -t STDIN ) {
   # Attended update; might as well ask the user to confirm and exit if not
   my $reply = Module::Build->prompt(
      "Are you still sure you wish to go ahead with this upgrade?\n" .
         "[enter 'yes' to continue]: ",
      "no"
   );

   die "Aborting install due to broken dependent modules\n" unless $reply =~ m/^y/i;
}

my $build = Module::Build->new(
   module_name => 'Future',
   configure_requires => {
      'Module::Build' => "0.4004", # test_requires
   },
   requires => {
      'Carp' => '1.25', # new message format with trailing period
      'Test::Builder::Module' => 0,
      'Time::HiRes' => 0,

      'perl' => '5.010', # //
   },
   test_requires => {
      'Test::Identity' => 0,
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   meta_merge => {
      # It's unlikely at the time of writing that any CPAN client actually
      # pays attention to this field, but it's nice to declare it on CPAN
      # anyway so people will know I want to use it; maybe one day clients
      # will follow it...
      x_breaks => { do {
         map { $_ => "< $FIXED{$_}" } keys %FIXED
      }},
   },
   auto_configure_requires => 0, # Don't add M::B
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

$build->create_build_script;
