# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 13; # last test to print

use Log::Log4perl::Tiny qw< :easy get_logger >;
Log::Log4perl::easy_init($INFO);

my $logger = get_logger();

# sink log messages into this array
my @messages; 
$logger->fh(sub { push @messages, $_[0] });

# sink warnings into this array
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

# simple message, check that LOGWARN does not exit
@messages = @warnings = ();
LOGWARN('whatever');
ok(1, 'LOGWARN did not exit');
is(scalar(@warnings), 1, 'one element in warnings');
is(scalar(@messages), 1, 'one element in messages');

sub some_warning {
   my @warn = @_ ? @_ : 'whatever';
   my $line = __LINE__; warn @warn; WARN(@warn); LOGWARN(@warn);
   return $line;
}

$logger->format('%m');
@messages = @warnings = ();
some_warning();
is(scalar(@warnings), 2, 'two elements in warnings');
is(scalar(@messages), 2, 'two elements in messages');
is($warnings[0], $warnings[1],
   "warn and LOGWARN are consistent in 'at <file> line <line number>'.");
is($messages[0], $messages[1],
   "WARN and LOGWARN are consistent as to what they log.");


$logger->format('%C %F %L %M %p');
@messages = @warnings = ();
my $line = some_warning('whateeeeevah');
is(scalar(@warnings), 2, 'two elements in warnings');
is(scalar(@messages), 2, 'two elements in messages');
is($warnings[0], $warnings[1],
   "warn and LOGWARN are consistent in 'at <file> line <line number>'.");
is($messages[0], $messages[1],
   "WARN and LOGWARN are consistent as to what they log.");
my $needle = "whateeeeevah at $0 line $line";
like($warnings[1], qr/\Q$needle\E/, "LOGWARN warns right file and line");
my $package = __PACKAGE__;
is($messages[1], "$package $0 $line ${package}::some_warning WARN",
   'LOGWARN emits right log line with file, package, line and calling sub');
