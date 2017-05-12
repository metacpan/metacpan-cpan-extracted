package Evo::Attr;
use strict;
use warnings;
use Carp 'croak';
use Evo::Internal::Util;
use feature 'signatures';
no warnings 'experimental::signatures';

my $MCO = \&invoke_handlers;

sub patch_package ($me, $pkg) {
  Evo::Internal::Util::monkey_patch $pkg, MODIFY_CODE_ATTRIBUTES => $MCO;
}

our %HANDLERS;

%HANDLERS = (
  Attr => {
    provider => __PACKAGE__,
    handler  => sub ($provider, $handler, $name) {
      register_attribute($provider, $name, $handler);
    }
  }
);

# $provider is a key, just for error message
sub register_attribute ($provider, $name, $handler) {
  croak "$name was already taken by $HANDLERS{$name}{provider}" if $HANDLERS{$name};
  $HANDLERS{$name} = {provider => $provider, handler => $handler};
}

sub invoke_handlers ($dest, $code, @attrs) {
  my (undef, $subname) = Evo::Internal::Util::code2names($code);
  my @remaining;
  foreach my $attr_raw (@attrs) {
    my ($attr, @args) = parse_attr($attr_raw);

    if (my $slot = $HANDLERS{$attr}) {
      $slot->{handler}->($dest, $code, $subname, @args);
    }
    else { push @remaining, $attr_raw }
  }
  @remaining;
}

sub parse_attr ($attr) {
  $attr =~ /(\w+) ( \( \s* ([\w\,\s]+) \s* \) )?/x;
  return ($1, split /\,\s?/, $3 // '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Attr

=head1 VERSION

version 0.0403

=head2 SYNOPSYS

  package Foo;
  use Evo;

  sub Foo ($dest, $code, $name, @args) : EvoAttr {
    say "$dest-$code-$name: " . join ';', @args;
  }

  package main;
  use Evo;
  sub mysub : Foo          {...}
  sub mysub2 : Foo(a1, a2) {...}

=head2 DESCRIPTION

This module provide a simple way to handle attributes. It doesn't change UNIVERSAL. To work properly, each module should call C<use Evo> at the beginning to install necessary code

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
