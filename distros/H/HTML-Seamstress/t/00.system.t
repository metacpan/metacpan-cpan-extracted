# Welcome to a -*- perl -*- test script
use strict;
use Test::More qw(no_plan);

sub req_ver {
  my $string = shift;
  my $eval = "#Using $string version v\$${string}::VERSION\n";
  my $eval2 = sprintf 'warn "%s"', $eval;
  require_ok($string);
  eval  $eval2 ;
}

my @module = 
  qw(
     HTML::Seamstress Pod::Usage HTML::Tree HTML::TreeBuilder 
     HTML::Element HTML::Element::Library 
     HTML::Parser HTML::Entities HTML::Tagset 
     HTML::PrettyPrinter
    ) ;

req_ver($_) for @module;

warn "# Running under perl version $] for $^O",
  (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";
warn "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
  if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();
warn "# MacPerl verison $MacPerl::Version\n"
  if defined $MacPerl::Version;
warn sprintf
  "# Current time local: %s\n# Current time GMT:   %s\n",
  scalar(localtime($^T)), scalar(gmtime($^T));
  
ok 1;

