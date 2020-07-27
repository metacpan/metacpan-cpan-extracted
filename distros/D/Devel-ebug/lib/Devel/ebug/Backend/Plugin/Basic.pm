package Devel::ebug::Backend::Plugin::Basic;

use strict;
use warnings;

our $VERSION = '0.63'; # VERSION

sub register_commands {
  return (basic => { sub => \&basic });
}

sub basic {
  my ($req, $context) = @_;
  return {
    codeline   => $context->{codeline},
    filename   => $context->{filename},
    finished   => $context->{finished},
    line       => $context->{line},
    package    => $context->{package},
    subroutine => subroutine($req, $context),
  };
}

sub subroutine {
  my ($req, $context) = @_;
  foreach my $sub (keys %DB::sub) {
    my ($filename, $start, $end) = $DB::sub{$sub} =~ m/^(.+):(\d+)-(\d+)$/;
    next if $filename ne $context->{filename};
    next unless $context->{line} >= $start && $context->{line} <= $end;
    return $sub;
  }
  return 'main';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend::Plugin::Basic

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
