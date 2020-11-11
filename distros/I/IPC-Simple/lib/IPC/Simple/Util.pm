package IPC::Simple::Util;
$IPC::Simple::Util::VERSION = '0.03';
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(
  debug
);

sub debug {
  if ($ENV{IPC_SIMPLE_DEBUG}) {
    my $msg = sprintf shift, @_;
    my ($pkg, $file, $line) = caller;
    my $ts = time;
    warn "<$pkg:$line | $ts> $msg\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Simple::Util

=head1 VERSION

version 0.03

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
