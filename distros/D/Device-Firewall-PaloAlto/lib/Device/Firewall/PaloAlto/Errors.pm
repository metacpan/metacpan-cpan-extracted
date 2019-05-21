package Device::Firewall::PaloAlto::Errors;
$Device::Firewall::PaloAlto::Errors::VERSION = '0.1.6';
use strict;
use warnings;
use 5.010;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ERROR);

use Class::Error;
use Carp;

# VERSION
# PODNAME
# ABSTRACT: Parent class for errors.



sub ERROR {
    my ($errstring, $errno) = @_;

    $errno //= 0;
    
    # Are we in a one liner? If so, we croak out straight away
    croak $errstring if (caller())[1] eq '-e';

    return Class::Error->new($errstring, $errno);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Errors - Parent class for errors.

=head1 VERSION

version 0.1.6

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a parent class containing functions relating to errors.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
