package Dist::Zilla::Plugin::DBIO::SetMeta;
# ABSTRACT: Set author, copyright_holder, and license on the Dist::Zilla object
use Moose;
with 'Dist::Zilla::Role::Plugin', 'Dist::Zilla::Role::BeforeBuild';

has author => (is => 'ro', isa => 'Str', required => 1);
has holder => (is => 'ro', isa => 'Str', required => 1);

sub before_build {
  my ($self) = @_;
  my $zilla = $self->zilla;

  my %attr = map { $_->name => $_ } $zilla->meta->get_all_attributes;

  $attr{authors}->set_value($zilla, [$self->author]);
  $attr{_copyright_holder}->set_value($zilla, $self->holder);
  $attr{_license_class}->set_value($zilla, 'Perl_5');
}

__PACKAGE__->meta->make_immutable;
no Moose;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::SetMeta - Set author, copyright_holder, and license on the Dist::Zilla object

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
