#!/usr/bin/env perl
use strict;
use warnings;
use EntityModel::Log qw(:all);
EntityModel::Log->instance->min_level(0);

logDebug("Debug message");
logInfo("Info message [%s] and a number [%d]", 'with a string', 17);
logWarning("Warning message");
logError("An error message");

logInfo("Stack trace - note that it must have at least one parameter (%s): %S", 'like this');
logInfo("No stack trace without parameters despite %S");
logInfo(sub { 'Message from a sub with a stack trace: %S, note that other text can follow' });

my $log = EntityModel::Log->instance;
$log->debug("OO-style debug");
$log->info("OO-style info");
$log->warning("OO-style warning");
$log->error("OO-style error");
$log->info(sub { "OO-style stack trace: %S" });

my $code;
$code = sub { $log->info(sub { sub { 'nested subs in ->info with stack trace %S' } }); $code };
sub chain { calls(method(of($code))) }
sub of { $_[0]->() }
sub method { $_[0]->() }
sub calls { $_[0]->() }
chain();
