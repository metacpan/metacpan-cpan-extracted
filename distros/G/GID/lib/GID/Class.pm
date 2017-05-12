package GID::Class;
BEGIN {
  $GID::Class::AUTHORITY = 'cpan:GETTY';
}
{
  $GID::Class::VERSION = '0.004';
}
# ABSTRACT: Making your classes with GID


use strictures 1;
use Import::Into;
use Scalar::Util qw( blessed );
use namespace::clean ();

use GID ();
use MooX ();

use MooX::Override ();
use MooX::Augment ();

sub import {
	my $class = shift;
	my $target = scalar caller;
	my @args = @_;

	GID->import::into($target,@args);

	MooX->import::into($target,qw(
		ClassStash
		HasEnv
		Options
		Types::MooseLike
		late
	),
		Override => [qw( -class )],
		Augment => [qw( -class )],
	);

	namespace::clean->import::into($target);

	$target->can('extends')->('GID::Object');
}

1;

__END__

=pod

=head1 NAME

GID::Class - Making your classes with GID

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  package MyApp::Class;
  use GID::Class;

  has last_index => ( is => 'rw' );

  sub test_last_index {
    return last_index { $_ eq 1 } ( 1,1,1,1 );
  }

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
