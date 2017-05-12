package Dist::Zilla::Plugin::NameFromDirectory;
use 5.008_001;
our $VERSION = '0.04';

use Moose;
with 'Dist::Zilla::Role::NameProvider';

use Path::Tiny ();

sub provide_name {
    my $self = shift;

    my $root = $self->zilla->root->absolute;

    # Dist::Zilla v6 has excised Path::Class in favor of Path::Tiny
    # make sure $root is a Path::Tiny object
    $root = Path::Tiny->new("$root");

    # make sure it is a root dir, by checking -e dist.ini
    return unless $root->child('dist.ini')->exists;

    my $name = $root->basename;
    $name =~ s/(?:^(?:perl|p5)-|[\-\.]pm$)//x;
    $self->log("guessing your distribution name is $name");

    return $name;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::NameFromDirectory - Guess distribution name from the current directory

=head1 SYNOPSIS

  [NameFromDirectory]

=head1 DESCRIPTION

Dist::Zilla::Plugin::NameFromDirectory is a Dist::Zilla plugin to
guess distribution name (when it's not set in C<dist.ini>) from the
current working directory.

Prefixes such as C<perl-> and C<p5->, as well as the postfix C<.pm>
and C<-pm> will be automatically trimmed. The following directory
names are all recognized as C<Foo-Bar>.

  Foo-Bar
  p5-Foo-Bar
  perl-Foo-Bar
  Foo-Bar-pm

It is designed to be used with Plugin bundle so that your dist.ini
doesn't need to contain per-project name anymore.

Even when this plugin is used, you can always override the name by
specifying it in C<dist.ini>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Dist::Zilla>

=cut