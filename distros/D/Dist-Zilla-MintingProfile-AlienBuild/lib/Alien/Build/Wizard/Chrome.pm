use strict;
use warnings;
use 5.022;

package Alien::Build::Wizard::Chrome 0.05 {

  use Moose;
  use experimental qw( signatures postderef );
  use Term::Clui ();
  use namespace::autoclean;

  # ABSTRACT: Wizard chrome

  sub ask ($self, $prompt, $default=undef) {
    $self->say($prompt);
    Term::Clui::ask("> ", $default);
  }

  sub choose ($self, $prompt, $options, $default=undef) {
    no warnings 'redefine';
    local *Term::Clui::get_default = sub {
      return undef unless defined $default && ref $default eq 'ARRAY';
      wantarray ? $default->@* : $default->[0];      ## no critic (Community::Wantarray)
    };
    Term::Clui::choose($prompt, $options->@*);
  }

  sub say ($self, $string) {
    CORE::say($string);
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Wizard::Chrome - Wizard chrome

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 % perldoc Dist::Zilla::MintingProfile::AlienBuild

=head1 DESCRIPTION

This class is private.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::MintingProfile::AlienBuild>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
