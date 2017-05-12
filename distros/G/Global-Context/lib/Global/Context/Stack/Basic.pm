package Global::Context::Stack::Basic;
{
  $Global::Context::Stack::Basic::VERSION = '0.003';
}
use Moose;
with 'Global::Context::Stack';
# ABSTRACT: trivial class implementing Global::Context::Stack


use namespace::autoclean;
1;

__END__

=pod

=head1 NAME

Global::Context::Stack::Basic - trivial class implementing Global::Context::Stack

=head1 VERSION

version 0.003

=head1 SEE ALSO

L<Global::Context::Stack>

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
