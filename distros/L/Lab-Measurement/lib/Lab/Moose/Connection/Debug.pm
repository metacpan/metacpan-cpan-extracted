package Lab::Moose::Connection::Debug;

use Moose;
use 5.010;
use namespace::autoclean;
use Data::Dumper;
use YAML::XS;

use Carp;

our $VERSION = '3.542';

sub Write {
    my $self = shift;
    my %args = @_;
    carp "Write called with args:\n", Dump \%args, "\n";
}

sub Read {
    my $self = shift;
    my %args = @_;
    carp "Read called with args:\n", Dump \%args, "\n";
    say "enter return value:";
    my $retval = <STDIN>;
    chomp $retval;
    return $retval;
}

sub Query {
    my $self = shift;
    my %args = @_;
    carp "Query called with args:\n", Dump \%args, "\n";
    say "enter return value:";
    my $retval = <STDIN>;
    chomp $retval;
    return $retval;
}

sub Clear {
    carp "Clear called";
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();
1;
