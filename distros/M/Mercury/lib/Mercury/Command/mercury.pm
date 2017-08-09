package Mercury::Command::mercury;
our $VERSION = '0.014';
# ABSTRACT: Mercury command for Mojolicious

use Mojo::Base 'Mojolicious::Commands';

has description => 'Mercury message broker';
has hint        => <<EOF;

See 'APPLICATION mercury help COMMAND' for more information on a specific
command.
EOF

has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { ['Mercury::Command::mercury'] };

sub help { shift->run(@_) }

1;

__END__

=pod

=head1 NAME

Mercury::Command::mercury - Mercury command for Mojolicious

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  Usage: APPLICATION mercury COMMAND [OPTIONS]

=head1 DESCRIPTION

L<Mercury::Command::mercury> lists available L<Mercury> commands.

=head1 SEE ALSO

=over 4

=item *

L<mercury>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
