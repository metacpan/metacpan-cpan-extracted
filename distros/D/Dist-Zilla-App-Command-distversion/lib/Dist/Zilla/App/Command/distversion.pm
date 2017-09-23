package Dist::Zilla::App::Command::distversion;

# ABSTRACT: report the dist version on stdot
 
use strict;
use warnings;
 
our $VERSION = '0.01';
 
use Dist::Zilla::App -command;

sub abstract    { "Prints your dist version on the command line" }
sub description { "Asks dzil what version the dist is on, then prints that" }
sub usage_desc  { "%c" }
sub execute {
    my $self = shift;
    print $self->zilla->version, "\n";
}

1;

=head1 SYNOPSIS

    $ dzil distversion
    0.01
