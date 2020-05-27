package JSON::Karabiner::Manipulator::Actions::To_delayed_if_canceled ;
$JSON::Karabiner::Manipulator::Actions::To_delayed_if_canceled::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Actions::To';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $has_delayed_action;
  { no warnings 'once';
    $has_delayed_action = $main::has_delayed_action;
  }
  my $obj;
  if ($main::has_delayed_action) {
    $obj = $main::has_delayed_action;
  } else {
    $obj = $class->SUPER::new('to_delayed_action', $value);
    $obj->{data} = {};
  }
  $obj->{delayed_type} = 'canceled';
  if ($value) {
    $obj->{data} = $value,
  } else {
    $obj->{data}{to_if_canceled} = [];

#    $obj->{data}{to_delayed_action}{to_if_invoked} = [];
  }
  $main::has_delayed_action = $obj;
  return $obj;
}

# ABSTRACT: to_delayed_if_canceled action

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Actions::To_delayed_if_canceled - to_delayed_if_canceled action

=head1 VERSION

version 0.018

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
