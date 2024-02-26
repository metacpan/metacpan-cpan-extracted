#!env perl
use strict;
use diagnostics;
use File::HomeDir;
use File::Spec;
use POSIX qw/EXIT_SUCCESS/;

my ($user, $password) = @ARGV;

my $pause = File::Spec->catfile(File::HomeDir->my_home, '.pause');
print "Initializing $pause\n";
open(my $fd, '>', $pause) || die "Cannot open $pause, $!";
if ($user) {
    print $fd "user $user\n";
}
if ($password) {
    print $fd "password $password\n";
}
close($fd) || warn "Cannot close $pause, $!";

exit(EXIT_SUCCESS);
