package Devel::ebug::Backend::Plugin::Output;

use strict;
use warnings;

our $VERSION = '0.63'; # VERSION

my $stdout = "";
my $stderr = "";

if ($ENV{PERL_DEBUG_DONT_RELAY_IO}) {
  # TODO: can we change these to non-bareword file handles
  open NULL, '>', '/dev/null';  ## no critic
  open NULL, '>', \$stdout;     ## no critic
  open NULL, '>', \$stderr;     ## no critic
}
else {
  close STDOUT;
  open STDOUT, '>', \$stdout or die "Can't open STDOUT: $!";
  close STDERR;
  open STDERR, '>', \$stderr or die "Can't open STDOUT: $!";
}

sub register_commands {
  return (output => { sub => \&output });
}

sub output {
  my($req, $context) = @_;
  return {
    stdout => $stdout,
    stderr => $stderr,
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend::Plugin::Output

=head1 VERSION

version 0.63

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
