use strict;
use warnings;

package M1;

use Exporter::VA qw/import VERSION/;
use vars qw/ $ztesch /;
our $VERSION= v1.0;

our %EXPORT= (
   '&foo' => '&foo',  #easiest case
   bar => 'internal_bar',
   baz => '', # empty string means same name.
   quux => \\&quux,  # hard link
   bazola => \&figure_it_out,  # callback
   '$ztesch' => '',  # var, not function
   );  # does not lose blessing

sub foo
 {
 return "Called " . __PACKAGE__ . "::foo (@_).";
 }

sub internal_bar
 {
 return "Called " .  __PACKAGE__ . "::internal_bar (@_).";
 }

sub baz
 {
 return "Called " .  __PACKAGE__ . "::baz (@_)."; 
 }

sub quux
 {
 return "Called " .  __PACKAGE__ . "::quux (@_)."; 
 }

sub figure_it_out
 {
 my ($blessed_export_def, $caller, $version, $symbol, $param_list_tail)= @_;
 my $package= __PACKAGE__;
 return sub {
    return "Called dynamically-generated ${package}::$symbol asked for by $caller, with parameters (@_).";
    }
 }

print "module M1 loaded\n"  unless $main::quiet;
1;
