package Hoppy::User;
use strict;
use warnings;
use base qw(Hoppy::Base);

__PACKAGE__->mk_accessors($_) for qw( user_id session_id);

1;
__END__

=head1 NAME

Hoppy::User - User class, that simply stores user's information. 

=head1 SYNOPSIS

  use Hoppy::User; 

  my $user = Hoppy::User->new( user_id => $user_id, session_id => $session_id );

  $user->user_id;
  $user->session_id;

=head1 DESCRIPTION

User class, that simply stores user's information.
(user_id and session_id)

=head1 METHODS

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut