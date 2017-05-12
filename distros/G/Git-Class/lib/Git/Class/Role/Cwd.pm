package Git::Class::Role::Cwd;

use Moo::Role;
use Path::Tiny ();

has '_cwd' => (
  is       => 'ro',
#  isa      => 'Str|Undef',
  init_arg => 'cwd',
  default  => sub { Path::Tiny->cwd },
);

1;

__END__

=head1 NAME

Git::Class::Role::Cwd

=head1 DESCRIPTION

Used internally.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
