package Dist::Zilla::Plugin::Deb::VersionFromChangelog;
{
  $Dist::Zilla::Plugin::Deb::VersionFromChangelog::VERSION = '0.04';
}

use Moose;
use autodie;
with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
    my ($self) = @_;
    my $zilla = $self->zilla;
    my $changelog_file = $zilla->root.'/debian/changelog';
    unless (-e $changelog_file) {
        confess("$changelog_file not found");
    }

    open(my $fh, '<', $changelog_file);
    my $first_line = <$fh>;
    chomp $first_line;
    my ($version) = $first_line =~ m{^\S+\s+\((\S+)\)} or die "Invalid first line '$first_line'";
    # TODO - remove trailing '-$build' from debian version?
    $zilla->version($version);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Deb::VersionFromChangelog

=head1 VERSION

version 0.04

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
