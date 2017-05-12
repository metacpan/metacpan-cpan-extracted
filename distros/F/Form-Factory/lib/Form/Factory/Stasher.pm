package Form::Factory::Stasher;
$Form::Factory::Stasher::VERSION = '0.022';
use Moose::Role;

requires qw( stash unstash );

# ABSTRACT: An object responsible for remembering things


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Stasher - An object responsible for remembering things

=head1 VERSION

version 0.022

=head1 DESCRIPTION

A stasher remembers things.

=head1 ROLE METHODS

=head2 stash

  $stasher->stash($key, $hashref);

Given a C<$key> to store it under and a C<$hashref> to store. Remember the given information for recall with L</unstash>.

=head2 unstash

  my $hashref = $stasher->unstash($key);

Given a C<$key>, recall a previously stored C<$hashref>.

=head1 SEE ALSO

L<Form::Factory::Stasher::Memory>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
