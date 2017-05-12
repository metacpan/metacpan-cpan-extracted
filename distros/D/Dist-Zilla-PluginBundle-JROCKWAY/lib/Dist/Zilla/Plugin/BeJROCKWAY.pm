package Dist::Zilla::Plugin::BeJROCKWAY;
BEGIN {
  $Dist::Zilla::Plugin::BeJROCKWAY::VERSION = '1.102911';
}
# ABSTRACT: Sets the author/license/copyright year to be me/Perl 5/now
use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Plugin';
use DateTime;

sub BUILD {
    my $self = shift;
    $self->zilla->_global_stashes->{'%Rights'} = bless({
        copyright_holder => 'Jonathan Rockway',
        license_class    => 'Perl_5',
        copyright_year   => DateTime->now->year,
    }, 'Dist::Zilla::Stash::Rights' );

    $self->zilla->_global_stashes->{'%User'} = bless({
        email => 'jrockway@cpan.org',
        name  => 'Jonathan Rockway',
    }, 'Dist::Zilla::Stash::User');
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::BeJROCKWAY - Sets the author/license/copyright year to be me/Perl 5/now

=head1 VERSION

version 1.102911

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

