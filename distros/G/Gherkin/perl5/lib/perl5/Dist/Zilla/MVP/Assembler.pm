package Dist::Zilla::MVP::Assembler 6.017;
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles' => { -version => '2.200010' };

use namespace::autoclean;

use Dist::Zilla::Util;

#pod =head1 DESCRIPTION
#pod
#pod B<Take this next bit seriously!>  If you don't understand how L<Config::MVP>
#pod works, reading about how the Dist::Zilla-specific Assembler works is not going
#pod to be useful.
#pod
#pod Dist::Zilla::MVP::Assembler extends L<Config::MVP::Assembler> and composes
#pod L<Config::MVP::Assembler::WithBundles>.  For potential plugin bundles (things
#pod composing L<Dist::Zilla::Role::PluginBundle>)
#pod
#pod The Assembler has chrome, so it can log and will (eventually) be able to get
#pod input from the user.
#pod
#pod The Assembler's C<expand_package> method delegates to Dist::Zilla::Util's
#pod L<expand_config_package_name|Dist::Zilla::Util/expand_config_package_name>
#pod method.
#pod
#pod The Assembler will throw an exception if it is instructed to add a value for
#pod C<plugin_name> or C<zilla>.
#pod
#pod =cut

has chrome => (
  is   => 'rw',
  does => 'Dist::Zilla::Role::Chrome',
  required => 1,
);

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli::Proxy', # could be duck typed, I guess
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->chrome->logger->proxy({ proxy_prefix => '[DZ] ' })
  },
);

sub expand_package {
  return scalar Dist::Zilla::Util->expand_config_package_name($_[1]);
}

sub package_bundle_method {
  my ($self, $pkg) = @_;
  return unless $pkg->isa('Moose::Object')
         and    $pkg->does('Dist::Zilla::Role::PluginBundle');
  return 'bundle_config';
}

before add_value => sub {
  my ($self, $name) = @_;

  return unless $name =~ /\A(?:plugin_name|zilla)\z/;

  my $section_name = $self->current_section->name;
  $self->log_fatal(
    "$section_name arguments attempted to provide reserved argument $name"
  );
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MVP::Assembler - Dist::Zilla-specific subclass of Config::MVP::Assembler

=head1 VERSION

version 6.017

=head1 DESCRIPTION

B<Take this next bit seriously!>  If you don't understand how L<Config::MVP>
works, reading about how the Dist::Zilla-specific Assembler works is not going
to be useful.

Dist::Zilla::MVP::Assembler extends L<Config::MVP::Assembler> and composes
L<Config::MVP::Assembler::WithBundles>.  For potential plugin bundles (things
composing L<Dist::Zilla::Role::PluginBundle>)

The Assembler has chrome, so it can log and will (eventually) be able to get
input from the user.

The Assembler's C<expand_package> method delegates to Dist::Zilla::Util's
L<expand_config_package_name|Dist::Zilla::Util/expand_config_package_name>
method.

The Assembler will throw an exception if it is instructed to add a value for
C<plugin_name> or C<zilla>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
