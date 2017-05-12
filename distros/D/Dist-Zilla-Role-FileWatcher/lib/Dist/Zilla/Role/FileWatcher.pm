use strict;
use warnings;
package Dist::Zilla::Role::FileWatcher; # git description: v0.005-17-ge7b35a0
# ABSTRACT: Receive notification when something changes a file's contents
# KEYWORDS: plugin build file change notify checksum watch monitor immutable lock
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.006';

use Moose::Role;
use Safe::Isa;
use Dist::Zilla::Role::File::ChangeNotification;
use namespace::autoclean;

sub watch_file
{
    my ($self, $file, $on_changed) = @_;

    $file->$_does('Dist::Zilla::Role::File')
        or $self->log_fatal('watch_file was not passed a valid file object');

    Dist::Zilla::Role::File::ChangeNotification->meta->apply($file)
        if not $file->$_does('Dist::Zilla::Role::File::ChangeNotification');

    my $plugin = $self;
    $file->on_changed(sub {
        my $self = shift;
        $plugin->$on_changed($self);
    });

    $file->watch_file;
}

sub lock_file
{
    my ($self, $file, $message) = @_;

    $file->$_does('Dist::Zilla::Role::File')
        or $self->log_fatal('lock_file was not passed a valid file object');

    $message ||= 'someone tried to munge ' . $file->name
        . ' after we read from it. You need to adjust the load order of your plugins!';

    $self->watch_file(
        $file,
        sub {
            my $me = shift;
            $me->log_fatal($message);
        },
    );
}

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        version => __PACKAGE__->VERSION,
    };

    return $config;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FileWatcher - Receive notification when something changes a file's contents

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::MyPlugin;
    use Moose;
    with 'Dist::Zilla::Role::SomeRole', 'Dist::Zilla::Role::FileWatcher';

    sub some_phase
    {
        my $self = shift;

        my (file) = grep { $_->name eq 'some_name' } @{$self->zilla->files};
        # ... do something with this file ...

        $self->lock_file($file, 'KEEP OUT!');

        # or:

        $self->watch_file(
            $file,
            sub {
                my ($plugin, $file) = @_;
                ... do something with the file object ...
            },
        );
    }

=head1 DESCRIPTION

This is a role for L<Dist::Zilla> plugins which gives you a mechanism for
detecting and acting on files changing their content. This is useful if your
plugin performs an action based on a file's content (perhaps copying that
content to another file), and then later in the build process, that source
file's content is later modified.

=head1 METHODS

This role adds the following methods to your plugin class:

=head2 C<watch_file($file, $subref)>

This method takes two arguments: the C<$file> object to watch, and a
subroutine which is invoked when the file's contents change. It is called as a
method on your plugin, and is passed one additional argument: the C<$file>
object that changed.

=head2 C<lock_file($file, $message?)>

This method takes the C<$file> object to watch, and an optional message
string; when the file is modified after it is locked, the build dies.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-FileWatcher>
(or L<bug-Dist-Zilla-Role-FileWatcher@rt.cpan.org|mailto:bug-Dist-Zilla-Role-FileWatcher@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Role::File::ChangeNotification> - in this distribution, the underlying implementation for watching the file

=item *

L<Dist::Zilla::File::OnDisk>

=item *

L<Dist::Zilla::File::InMemory>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Yanick Champoux

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
