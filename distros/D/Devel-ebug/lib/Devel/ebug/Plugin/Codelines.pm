package Devel::ebug::Plugin::Codelines;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(codelines);

our $VERSION = '0.63'; # VERSION

# return some lines of code
sub codelines {
  my($self) = shift;
  my($filename, @lines);
  if (!defined($_[0]) || $_[0] =~ /^\d+$/) {
    $filename = $self->filename;
  } else {
    $filename = shift;
  }
  @lines = map { $_ -1 } @_;
  my $response = $self->talk({
    command  => "codelines",
    filename => $filename,
    lines    => \@lines,
  });
  return @{$response->{codelines}};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Plugin::Codelines

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
