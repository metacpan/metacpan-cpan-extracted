use strict;
use warnings;

package M3;

use Exporter::VA qw/import VERSION/,  # but not AUTOLOAD (part of the testing)
 -def => {
 foo => [v1.0, \\&old_foo, v1.5, \\&middle_foo, v2.0, \\&new_foo],
 ':tag' => ['foo'],
 '.plain' => [qw/:tag bar/],
 '.default_VERSION' => v1.3,
 ':blarg' => [v1.0, ':_old_blarg', v2.0, ':_new_blarg'],
 '&_bar' => \\&bar,
 ':_old_blarg' => [qw/foo bar/],
 ':_new_blarg' => [qw/bar/],
 'get_export_def' => sub { my $export_def= shift; return sub { return $export_def; } },
 } ;

our $VERSION= v2.4.1;

sub old_foo
 {
 return "Called " . __PACKAGE__ . "::old_foo (@_).";
 }

sub new_foo
 {
 return "Called " . __PACKAGE__ . "::new_foo (@_).";
 }

sub middle_foo
 {
 return "Called " . __PACKAGE__ . "::middle_foo (@_).";
 }

sub bar
 {
 return "Called " . __PACKAGE__ . "::bar (@_).";
 }

print "module M3 loaded\n"  unless $main::quiet;
1;


