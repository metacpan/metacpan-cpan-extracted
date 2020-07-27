package Devel::ebug::Plugin::Pad;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(pad pad_human);

our $VERSION = '0.63'; # VERSION

# find the pad
sub pad {
  my($self) = @_;
  my $response = $self->talk({ command => "pad" });
  return $response->{pad};
}

# human-readable pad
sub pad_human {
  my($self) = @_;
  my $pad = $self->pad;
  foreach my $var (keys %$pad) {
    if ($var =~ /^@/) {
      my @values = @{$pad->{$var}};
      my $value = $self->stack_trace_human_args(@values);
      $pad->{$var} = $value;
    } elsif ($var =~ /^%/) {
      $pad->{$var} = '(...)';
    } else {
      my $value = $pad->{$var};
      $value = $self->stack_trace_human_args($value);
      $value =~ s/^\(//;
      $value =~ s/\)$//;
      $pad->{$var} = $value;
    }
  }
  return $pad;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Plugin::Pad

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
