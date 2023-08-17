# ABSTRACT: YAML::PP frontend for LibYAML::FFI
package LibYAML::FFI::YPP;
use strict;
use warnings;

use base qw/ YAML::PP Exporter /;
our @EXPORT_OK = qw/ Load Dump LoadFile DumpFile /;

our $VERSION = 'v0.0.1'; # VERSION

use LibYAML::FFI::YPP::Parser;

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(
        parser => LibYAML::FFI::YPP::Parser->new,
        %args,
    );
    return $self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LibYAML::FFI::YPP - YAML::PP frontend for LibYAML::FFI

=head1 SYNOPSIS

    use LibYAML::FFI::YPP;
    my $yp = LibYAML::FFI::YPP->new;
    my $yaml = "foo: bar";
    my $data = $yp->load_string($yaml);

=head1 DESCRIPTION

Warning: Proof of Conecept.

With this module you can use YAML::PP with the libyaml FFI binding as a
parser backend.
