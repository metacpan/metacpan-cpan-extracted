package Lingua::FR::Ladl::Exceptions;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.3');

use Exception::Class (
                      'X::NoTableData' => {
                                           fields => [ 'table' ],
                                          },
                      'X::NoGraphData' => {
                                           fields => [ 'graph' ],
                                          },
                     );

sub X::NoTableData::full_message {
  my ($self) = @_;

  my $msg = $self->message();
  
  return $msg.'Need table data for "'.$self->table()->get_name().q(").qq(, maybe you should call the load method first?\n);
};

sub X::NoGraphData::full_message {
  my ($self) = @_;

  my $msg = $self->message();
  
  return $msg.'Graph not initialized: "'.$self->graph()->get_name().q(").qq(, maybe you should call the load method first?\n);
};



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::FR::Ladl::Exceptions - Exceptions for the Lingua::FR::Ladl modules

=head1 SYNOPSIS

   use Lingua::FR::Ladl::Exceptions;

=head1 DESCRIPTION

Bundles common exceptions for the Lingua::FR::Ladl modules.

=head1 INTERFACE

=over

=item X::NoTableData::full_message

thrown when the table data has not yet been initialised.

=back

=head1 DEPENDENCIES

L<Exception::Class>

=head1 AUTHOR

Ingrid Falk  C<< <ingrid dot falk at loria dot fr> >>

=head1 SEE ALSO

L<Lingua::FR::Ladl>

L<Lingua::FR::Ladl::Table>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ingrid Falk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

