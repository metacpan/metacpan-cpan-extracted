use strict;
use warnings;
package Exception::Reporter::Dumper::YAML 0.015;
# ABSTRACT: a dumper to turn any scalar value into a plaintext YAML record

use parent 'Exception::Reporter::Dumper';

use Try::Tiny;
use YAML::XS ();

sub _ident_from {
  my ($self, $str, $x) = @_;

  $str =~ s/\A\n+//;
  ($str) = split /\n/, $str;

  unless (defined $str and length $str and $str =~ /\S/) {
    $str = sprintf "<<unknown%s>>", $x ? ' ($x)' : '';
  }

  return $str;
}

sub dump {
  my ($self, $value, $arg) = @_;
  my $basename = $arg->{basename} || 'dump';

  my ($dump, $error) = try {
    (YAML::XS::Dump($value), undef);
  } catch {
    (undef, $_);
  };

  if (defined $dump) {
    my $ident = ref $value     ? (try { "$value" } catch { "<unknown>" })
              : defined $value ? "$value" # quotes in case of glob, vstr, etc.
              :                  "(undef)";

    $ident = $self->_ident_from($ident);

    return {
      filename => "$basename.yaml",
      mimetype => 'text/plain',
      body     => $dump,
      ident    => $ident,
    };
  } else {
    my $string = try { "$value" } catch { "value could not stringify: $_" };
    my $ident  = $self->_ident_from($string);

    return {
      filename => "$basename.txt",
      mimetype => 'text/plain',
      body     => <<EOB,
__DATA__
$string
__YAML_ERROR__
$error
EOB
      ident    => $ident,
    };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Dumper::YAML - a dumper to turn any scalar value into a plaintext YAML record

=head1 VERSION

version 0.015

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
