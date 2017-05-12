package Digital::Role;
BEGIN {
  $Digital::Role::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Base role for Digital driver (positive integer input)
$Digital::Role::VERSION = '0.002';
use Moo::Role;
use Carp qw( croak );

sub input {
  my ( $class, $input, %args ) = @_;
  return $class->new( in => $input, %args );
}

has in => (
  is => 'ro',
  isa => sub {
    croak "Digital input must be positive integer!"
      unless $_[0] =~ /^\d+$/ and $_[0] >= 0;
  },
  required => 1,
);

1;

__END__

=pod

=head1 NAME

Digital::Role - Base role for Digital driver (positive integer input)

=head1 VERSION

version 0.002

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/p5-digital
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/p5-digital/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
