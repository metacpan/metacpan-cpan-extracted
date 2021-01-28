package Dist::Zilla::Plugin::CheckChangeLog;
$Dist::Zilla::Plugin::CheckChangeLog::VERSION = '0.05';
# ABSTRACT: Dist::Zilla with Changes check

use 5.004;
use Moose;

with 'Dist::Zilla::Role::AfterBuild';

has filename => (
    is  => 'ro',
    isa => 'Str'
);

sub after_build {
    my ($self, $args) = @_;

    my $root     = $args->{build_root};
    my $filename = $self->{filename};
    my @change_files;

    if ($filename) {
        chomp($filename);
        die "[CheckChangeLog] $! $filename\n" unless -e $filename;
        push @change_files, Dist::Zilla::File::OnDisk->new({name => $filename});
    } else {
        # Search for Changes or ChangeLog on build root
        my @files = $self->_find_change_files($root);
        die "[CheckChangeLog] No changelog file found.\n" unless scalar @files;
        push @change_files, @files;
    }

    for my $file (@change_files) {
        if ($self->has_version($file->content, $self->zilla->version)) {
            $self->log("[CheckChangeLog] OK with " . $file->name);
            return;
        }
    }

    my $msg = "[CheckChangeLog] No Change Log in ";
    $msg .= join(', ', map { $_->name } @change_files) . "\n";
    $self->log($msg);
    $msg = "[CheckChangeLog] Update your Changes file with an entry for ";
    $msg .= $self->zilla->version . "\n";
    die $msg;
}

sub has_version {
    my ($self, $content, $version) = @_;

    for my $line (split(/\n/, $content)) {

        # no blank lines
        next unless $line =~ /\S/;

        # skip things that look like bullets
        next if $line =~ /^\s+/;
        next if $line =~ /^\*/;
        next if $line =~ /^\-/;

        # seen it?
        return 1 if $line =~ /\Q$version\E/;
    }
    return 0;
}

sub _find_change_files {
    my ($self, $root) = @_;
    my $files          = $self->zilla->files;
    my $change_file_re = qr/Change(?:s|Log)?/i;
    my $filter         = sub { -e "$root/$_->{name}" && $_->{name} =~ $change_file_re };
    grep { $filter->($_) } @{$files};
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckChangeLog - Dist::Zilla with Changes check

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # dist.ini
    [CheckChangeLog]

    # or
    [CheckChangeLog]
    filename = Changes.pod

=head1 DESCRIPTION

 This plugin will examine your changes file after a build to make sure it has an entry for your distributions current version prior to a release.

=head1 File name conventions

 With no arguments CheckChangeLog will only look in files named Changes and ChangeLog (case insensitive) within the root directory of your dist. Note you can always pass a filename argument if you have an unconvential name and place for your changelog.

=head1 METHODS

=head2 after_build

=head2 has_version($content_str, $version_str)

=head1 AUTHORS

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
