package Email::MIME::Kit::KitReader::SWAK 1.093065;
# ABSTRACT: the swiss army knife of EMK kit readers

use Moose;
with 'Email::MIME::Kit::Role::KitReader';

#pod =head1 DESCRIPTION
#pod
#pod This replaces and extends the standard (Dir) kit reader for Email::MIME::Kit,
#pod letting your kit refer to resources in locations other than the kit itself.
#pod
#pod In your manifest (assuming it's YAML, for readability):
#pod
#pod   ---
#pod   kit_reader: SWAK
#pod   attachments:
#pod   - type: text/html
#pod     path: template.html
#pod
#pod   - type: text/plain
#pod     path: /dist/Your-App/config.conf
#pod
#pod   - type: text/plain
#pod     path: /fs/etc/motd
#pod
#pod This will find the first file in the kit (the absolute path prefix F</kit>
#pod could also be used), the second file in the L<File::ShareDir|File::ShareDir>
#pod shared dist space for the Your-App, and the third file on the root filesystem.
#pod
#pod SWAK may be given a C<fs_root> option to start the contents of F</fs> somewhere
#pod other than root.
#pod
#pod =cut

use Path::Resolver::Resolver::Mux::Prefix;
use Path::Resolver::Resolver::FileSystem;
use Path::Resolver::Resolver::AnyDist;

has resolver => (
  reader   => 'resolver',
  writer   => '_set_resolver',
  does     => 'Path::Resolver::Role::Resolver',
  init_arg => undef,
  lazy     => 1,
  default  => sub {
    my ($self) = @_;
    my $prs = sub { 'Path::Resolver::Resolver::' . $_[0] };

    my $old_kr = $self->kit->kit_reader;
    confess(__PACKAGE__ . ' must (for now) replace an existing KitReader::Dir')
      unless $old_kr and $old_kr->isa('Email::MIME::Kit::KitReader::Dir');
    
    my $kit_resolver = $prs->('FileSystem')->new({
      root => $self->kit->source,
    });

    Path::Resolver::Resolver::Mux::Prefix->new({
      prefixes => {
        fs   => $prs->('FileSystem')->new({ root => $self->fs_root }),
        dist => $prs->('AnyDist')->new,
        kit  => $kit_resolver,
        q{}  => $kit_resolver,
      },
    });
  },
);

has fs_root => (
  is  => 'ro',
  isa => 'Str',
  default => '/',
);

sub get_kit_entry {
  my ($self, $path) = @_;

  my $content = $self->resolver->entity_at($path)->content_ref;
  return $content if $content;

  confess "no content for $path";
}

sub BUILD {
  my ($self) = @_;
  $self->resolver;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::KitReader::SWAK - the swiss army knife of EMK kit readers

=head1 VERSION

version 1.093065

=head1 DESCRIPTION

This replaces and extends the standard (Dir) kit reader for Email::MIME::Kit,
letting your kit refer to resources in locations other than the kit itself.

In your manifest (assuming it's YAML, for readability):

  ---
  kit_reader: SWAK
  attachments:
  - type: text/html
    path: template.html

  - type: text/plain
    path: /dist/Your-App/config.conf

  - type: text/plain
    path: /fs/etc/motd

This will find the first file in the kit (the absolute path prefix F</kit>
could also be used), the second file in the L<File::ShareDir|File::ShareDir>
shared dist space for the Your-App, and the third file on the root filesystem.

SWAK may be given a C<fs_root> option to start the contents of F</fs> somewhere
other than root.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
