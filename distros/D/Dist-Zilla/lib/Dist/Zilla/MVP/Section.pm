package Dist::Zilla::MVP::Section 6.020;
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use Moose;
extends 'Config::MVP::Section';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

use Config::MVP::Section 2.200009; # not-installed error with section_name

around add_value => sub {
  my ($orig, $self, $name, $value) = @_;

  if ($name =~ s/\A://) {
    if ($name eq 'version') {
      Dist::Zilla::Util->_assert_loaded_class_version_ok(
        $self->package,
        $value,
      );
    }

    return;
  }

  $self->$orig($name, $value);
};

after finalize => sub {
  my ($self) = @_;

  my ($name, $plugin_class, $arg) = (
    $self->name,
    $self->package,
    $self->payload,
  );

  my %payload = %{ $self->payload };

  $plugin_class->register_component($name, \%payload, $self);

  return;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MVP::Section - a standard section in Dist::Zilla's configuration sequence

=head1 VERSION

version 6.020

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
