package JSON::Karabiner::Manipulator::Actions::To_if_held_down ;
$JSON::Karabiner::Manipulator::Actions::To_if_held_down::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Actions::To';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data} = $value || [],
  return $obj;
}

# ABSTRACT: to_if_held_down action

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Actions::To_if_held_down - to_if_held_down action

=head1 VERSION

version 0.018

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
