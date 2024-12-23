package Dist::Zilla::Plugin::Author::Plicease::PkgVersionBlock 2.79 {

  use Moose;
  extends 'Dist::Zilla::Plugin::PkgVersion::Block';
  use experimental qw( signatures );


  sub munge_files ($self)
  {
    my $old = $self->zilla->version;
    my $new = $old;
    $new =~ s/_//g;
    $self->zilla->version($new);
    if($new ne $old)
    {
      $self->log("Using $new instead of $old in Perl source for version");
    }

    local $@ = '';
    eval { $self->SUPER::munge_files };
    my $error = $@;

    $self->zilla->version($old);

    die $error if $error;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::PkgVersionBlock

=head1 VERSION

version 2.79

=head1 SYNOPSIS

 [Author::Plicease::PkgVersionBlock]

=head1 DESCRIPTION

This is a subclass of L<Dist::Zilla::Plugin::PkgVersion::Block> that allows underscores
in versions.  You probably shouldn't use this.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::Plicease>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
