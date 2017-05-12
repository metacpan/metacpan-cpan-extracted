package Message::Stack::Types;
BEGIN {
  $Message::Stack::Types::VERSION = '0.22';
}
use MooseX::Types -declare => [ qw( MessageStackMessage ) ];

class_type MessageStackMessage, { class => 'Message::Stack::Message' };

1;

__END__
=pod

=head1 NAME

Message::Stack::Types

=head1 VERSION

version 0.22

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

