package Method::Cached::KeyRule::Base;

use strict;
use warnings;
use base qw/Exporter/;

sub export_rule {
    my $class = shift;
    no strict 'refs';
    no warnings 'redefine';
    for my $rule (@_) {
        my $name = $class . '::' . $rule;
        my $code = \&{$name};
        *{$name} = sub { return $code };
        push @{$class . '::EXPORT'},    $rule;
        push @{$class . '::EXPORT_OK'}, $rule;
    }
}

1;

__END__

=head1 NAME

Method::Cached::KeyRule::Base - Base class to make key generation rule

=head1 SYNOPSIS

  package Foo::SomeRule;
  
  use base qw/Method::Cached::KeyRule::Base/;
  
  __PACKAGE__->export_rule(qw/SOME_RULE/);
  
  sub SOME_RULE {
      my ($method_name, $args) = @_;
      ...
  }

=head1 AUTHOR

Satoshi Ohkubo E<lt>s.ohkubo@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
