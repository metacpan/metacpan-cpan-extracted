package MetaStore::Component;

=head1 NAME

MetaStore::Component - Abstract class for component

=head1 SYNOPSIS


=head1 DESCRIPTION

Abstract class for component

=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use Template;
use WebDAO;
use base qw/ WebDAO/;
our $VERSION = '0.01';

sub parse_template {
    my $self = shift;
    my ( $template, $predefined ) = @_;
    $predefined->{self} = $self unless exists $predefined->{self};
    return $self->_root_->parse_template(@_);
}
1;
__END__

=head1 SEE ALSO

MetaStore, WebDAO, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

