package Devel::REPL::Plugin::ReadLineHistory::WithoutExpansion;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Moose::Role;

with 'Devel::REPL::Plugin::ReadLineHistory';

before 'run_once' => sub {
    my $self = shift;
    $self->term->Attribs->{do_expand} = 0;
};

1;
__END__

=encoding utf-8

=head1 NAME

Devel::REPL::Plugin::ReadLineHistory::WithoutExpansion - ReadLineHistory plugin, without expansion

=head1 DESCRIPTION

The standard readline history plugin makes it impossible to disable history
expansion (via C<!>) from a profile or rc file.  This plugins solves that.

=head1 AUTHOR

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Thomas Sibley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
