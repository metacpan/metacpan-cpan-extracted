package EPL2::Command;
# ABSTRACT: EPL2::Command (Base Class for EPL2 Commands)
$EPL2::Command::VERSION = '0.001';
use 5.010;
use Moose;
use namespace::autoclean;

#Methods
sub string { die 'Must Implement ->string Method'; }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command - EPL2::Command (Base Class for EPL2 Commands)

=head1 VERSION

version 0.001

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for setting label width.

=head1 SEE ALSO

L<EPL2>

L<EPL2::Types>

=head1 AUTHOR

Ted Katseres <tedkat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
