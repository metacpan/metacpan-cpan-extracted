package Lab::Moose::Connection::Debug;
#ABSTRACT: Debug connection
$Lab::Moose::Connection::Debug::VERSION = '3.554';
use Moose;
use 5.010;
use namespace::autoclean;
use Data::Dumper;
use YAML::XS;

use Carp;


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::Debug - Debug connection

=head1 VERSION

version 3.554

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
