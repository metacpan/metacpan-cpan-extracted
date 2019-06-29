use strict;
use warnings;

use Config;
use Module::Build;

my @extra_compiler_flags = qw( -std=c89 -Ihax );

# MSWin32 needs NO_XSLOCKS to make longjmp work. I have no idea what this is
# about, I just stole it from Scope::Escape
#   https://metacpan.org/source/ZEFRAM/Scope-Escape-0.005/Build.PL#L25
if( $^O eq "MSWin32" ) {
   push @extra_compiler_flags, "-DNO_XSLOCKS=1";
}

# Thready perls before 5.22 are known to massively fail. For now lets just
# declare such perls unsupported
#   https://rt.cpan.org/Ticket/Display.html?id=124351
die "OS unsupported - threaded perl earlier than 5.22 (RT124351)"
   if $] < 5.022 and ( $Config{usethreads} || "" ) eq "define";

my $build = Module::Build->new(
   module_name => 'Future::AsyncAwait',
   requires => {
      'Future' => 0,
      'perl' => '5.016', # PL_keyword_plugin, pad_new(), CvDYNFILE, many tests fail on 5.14
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => '0.09',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },

   extra_compiler_flags => \@extra_compiler_flags,
);

if( eval { require Devel::MAT::Dumper::Helper } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

$build->create_build_script;
