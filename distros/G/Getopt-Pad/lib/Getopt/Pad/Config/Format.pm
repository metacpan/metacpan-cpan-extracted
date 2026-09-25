package Getopt::Pad::Config::Format;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Object::Pad;
use Getopt::Pad::Registry;

our $VERSION = '0.03';

my @builtins = map { "Getopt::Pad::Config::Format::$_" } qw(Yaml Json);
my $registry;

sub registry() {
	return $registry //= Getopt::Pad::Registry->new(kind => 'config format')->register(@builtins);
}

sub registerFormat($class) {
	return registry()->register($class);
}

class Getopt::Pad::Config::Format :abstract {
	method parse;
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config::Format - config format base class and registry

=head1 DESCRIPTION

Abstract base class for config file formats and home of the format Registry. Subclass it, provide a NAMES constant and a parse($text) method returning a hashref, then call Getopt::Pad::Config::Format::registerFormat with your class. A format never touches files: Config I/O reads and writes them as UTF-8 and passes the decoded text in, so parse() receives and dump() returns Perl character strings, never octets. parse() should die on parse problems; the message is reported as a config error naming the file. An optional dump($data) method (hashref in, serialized text out) enables --create-default-config for the format. The full contract with a worked TOML example is documented under "EXTENDING" in L<Getopt::Pad>.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
