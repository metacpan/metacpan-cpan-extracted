package Games::SolarConflict::Roles::Controller;
{
  $Games::SolarConflict::Roles::Controller::VERSION = '0.000001';
}

# ABSTRACT: Controller role

use strict;
use warnings;
use Mouse::Role;

has game => (
    is       => 'rw',
    isa      => 'Games::SolarConflict',
    required => 1,
);

no Mouse::Role;

1;



=pod

=head1 NAME

Games::SolarConflict::Roles::Controller - Controller role

=head1 VERSION

version 0.000001

=head1 SEE ALSO

=over 4

=item * L<Games::SolarConflict>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


