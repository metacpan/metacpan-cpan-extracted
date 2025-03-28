package Devel::ebug::Backend::Plugin::Eval;

use strict;
use warnings;

our $VERSION = '0.64'; # VERSION

sub register_commands {
  return (
    eval => { sub => \&DB::eval, record => 1 },
    yaml => { sub => \&DB::yaml },
  );
}


package DB;


# there appears to be something semi-magical about the DB
# namespace that makes this eval only work when it's in it
sub eval {
  my($req, $context) = @_;
  my $eval = $req->{eval};
  local $SIG{__WARN__} = sub {};

  my $v = eval "package $context->{package}; $eval";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
  if ($@) {
    return { eval => $@, exception => 1 };
  } else {
    return { eval => $v, exception => 0 };
  }
}

sub yaml {
  my($req, $context) = @_;
  my $eval = $req->{yaml};
  local $SIG{__WARN__} = sub {};

  my $v = eval "package $context->{package}; use YAML; Dump($eval)";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
  if ($@) {
    return { yaml => $@ };
  } else {
    return { yaml => $v };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend::Plugin::Eval

=head1 VERSION

version 0.64

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2021 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
