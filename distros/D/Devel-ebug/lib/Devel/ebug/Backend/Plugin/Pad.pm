package Devel::ebug::Backend::Plugin::Pad;

use strict;
use warnings;
use PadWalker;

our $VERSION = '0.63'; # VERSION

sub register_commands {
  return ( pad => { sub => \&DB::pad } )
}

package DB;


use Scalar::Util qw(blessed reftype);
sub pad {
  my($req, $context) = @_;
  my $pad;
  my $h = eval { PadWalker::peek_my(2) };
  foreach my $k (sort keys %$h) {
    if ($k =~ /^@/) {
      my @v = eval "package $context->{package}; ($k)";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
      $pad->{$k} = \@v;
    } else {
      my $v = eval "package $context->{package}; $k";    ## no critic (BuiltinFunctions::ProhibitStringyEval)
      $pad->{$k} = $v;

      # workaround for blessed globs
      $pad->{$k} = "".$v if blessed $v and reftype $v eq "GLOB";
    }
  }
  return { pad => $pad };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend::Plugin::Pad

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
