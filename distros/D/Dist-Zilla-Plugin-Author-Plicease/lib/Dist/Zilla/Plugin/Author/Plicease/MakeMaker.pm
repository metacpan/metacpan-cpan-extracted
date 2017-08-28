package Dist::Zilla::Plugin::Author::Plicease::MakeMaker 2.22 {

  use 5.014;
  use Moose;
  use namespace::autoclean;

  # ABSTRACT: munge the AUTHOR section


  extends 'Dist::Zilla::Plugin::MakeMaker';

  around write_makefile_args => sub {
    my $orig = shift;
    my $self = shift;
  
    my $h = $self->$orig(@_);  

    # to prevent any non .pm/.pod files from being installed in lib
    # because shit like this is stuff we ought to have to customize.
    my %PM = map {; "lib/$_" => "\$(INST_LIB)/$_" } map { s/^lib\///; $_ } grep /^lib\/.*\.p(od|m)$/, map { $_->name } @{ $self->zilla->files };
    $h->{PM} = \%PM;

    $h;
  };

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::MakeMaker - munge the AUTHOR section

=head1 VERSION

version 2.22

=head1 SYNOPSIS

 [Author::Plicease::MakeMaker]

=head1 DESCRIPTION

My personal customization of the L<Dist::Zilla::Plugin::MakeMaker>.  You are unlikely to
need or want to use this.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::Plicease>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
