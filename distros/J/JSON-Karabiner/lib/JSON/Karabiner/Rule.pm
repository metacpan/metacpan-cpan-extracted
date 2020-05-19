package JSON::Karabiner::Rule ;
$JSON::Karabiner::Rule::VERSION = '0.017';
use strict;
use warnings;
require JSON::Karabiner::Manipulator ;
use Carp;

sub new {
  my $class = shift;
  my $desc = shift;
  croak 'JSON::Karabiner constructor requires a desc.' if !$desc;
  my $self = {
    description => $desc,
    manipulators => []
  };
  bless $self, $class;
  return $self;
}

sub _disable_validity_tests {
  my $s = shift;
  my $enable = shift;

  my $op = $enable ? 0 : 1;
  foreach my $manip (@{$s->{manipulators}}) {
    $manip->{_disable_validity_tests} = $op;
  }
}

sub _enable_validity_tests {
  my $s = shift;
  $s->_disable_validity_tests(1);
}

sub add_manipulator {
  my $s = shift;

  my $manip  = JSON::Karabiner::Manipulator->new_manipulator();
  push @{$s->{manipulators}}, $manip;
  return $manip;
}

sub TO_JSON { return { %{ shift() } }; }


# ABSTRACT: turns baubles into trinkets

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Rule - turns baubles into trinkets

=head1 DESCRIPTION

Please see the L<JSON::Karabiner> for more thorough documentation of these module.
Methods are listed below for reference purposes only.

=head3 add_manipulator()

=head1 VERSION

version 0.017

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
