package GID::File;
BEGIN {
  $GID::File::AUTHORITY = 'cpan:GETTY';
}
{
  $GID::File::VERSION = '0.004';
}
# ABSTRACT: A file representation in GID

use strictures 1;
use base 'Path::Class::File';

sub rm { shift->remove(@_) }

1;

__END__

=pod

=head1 NAME

GID::File - A file representation in GID

=head1 VERSION

version 0.004

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
