use strict;
use warnings;

package Log::Contextual::Router::LogDispatchouli;
BEGIN {
  $Log::Contextual::Router::LogDispatchouli::AUTHORITY = 'cpan:KENTNL';
}
{
  $Log::Contextual::Router::LogDispatchouli::VERSION = '0.001000';
}

# ABSTRACT: Proxy Log::Dispatchouli without getting wrong carp levels

use Moo;

extends 'Log::Contextual::Router';


around handle_log_request => sub {
  my ( $orig, $self, %message_info ) = @_;
  require Carp;
  ## no critic (ProhibitPackageVars)
  $message_info{caller_level}++;
  local $Carp::CarpLevel = $message_info{caller_level};
  return $self->$orig(%message_info);
};

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Contextual::Router::LogDispatchouli - Proxy Log::Dispatchouli without getting wrong carp levels

=head1 VERSION

version 0.001000

=head1 METHODS

=head2 C<handle_log_request>

This is simply a wrapper around L<< C<Log::Contextual::Router::handle_log_request>|Log::Contextual::Router/handle_log_request >> that locally sets C<$Carp::CarpLevel> to the value needed so L<< C<Log::Dispatchouli>|Log::Dispatchouli >> reports errors from the right place.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
