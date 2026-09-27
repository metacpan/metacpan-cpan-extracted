package Devel::ebug::Backend::Plugin::Output;

use strict;
use warnings;

our $VERSION = '0.67'; # VERSION

my $stdout = "";
my $stderr = "";

# Capture the program's output so the frontend can show it.  Under
# PERL_DEBUG_DONT_RELAY_IO (ebug_server -keepio) STDOUT and STDERR are
# deliberately left going wherever they were going, so that a program
# which prompts can still be used interactively; output then has nothing
# to report.
unless ($ENV{PERL_DEBUG_DONT_RELAY_IO}) {
  close STDOUT;
  open STDOUT, '>', \$stdout or die "Can't open STDOUT: $!";
  close STDERR;
  open STDERR, '>', \$stderr or die "Can't open STDERR: $!";
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

version 0.67

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2026 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
