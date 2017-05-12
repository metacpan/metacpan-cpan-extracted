package Git::Repository::Plugin::Hooks;
use parent qw(Git::Repository::Plugin);

use 5.008005;
use strict;
use warnings;

use Carp qw();
use File::Copy qw();

our $VERSION = "0.04";

sub _keywords { qw(
    install_hook
    hook_path
) }

sub install_hook {
    my ($repo, $source, $target) = @_;

    my $dest = $repo->hook_path($target);
    my $copy_rv = File::Copy::copy($source, $dest);
    unless ($copy_rv) {
        Carp::croak "install_hook failed: $!";
    }

    my $chmod_rv = chmod 0755, $dest;
    unless ($chmod_rv) {
        Carp::croak "install_hook failed: $!";
    }
}

sub hook_path {
    my ($repo, $target) = @_;
    return File::Spec->join($repo->git_dir, 'hooks', $target);
}

1;
__END__

=encoding utf-8

=head1 NAME

Git::Repository::Plugin::Hooks - Work with hooks in a Git::Repository

=head1 SYNOPSIS

    use Git::Repository 'Hooks';

    my $r = Git::Repository->new();
    $r->install_hook('my-hook-file', 'pre-receive');

=head1 DESCRIPTION

Git::Repository::Plugin::Hooks adds the C<install_hook> and C<hook_path>
methods to a Git::Repository.

=head1 METHODS

=head2 install_hook($source, $target)

Install a C<$target>, e.g. 'pre-receive', hook into the repository.

=head2 hook_path($target)

Returns the path to a hook of the type specified by C<$target>.  See C<man
githooks> for examples, e.g. C<pre-commit>.

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter E<lt>nnutter@cpan.orgE<gt>

=cut

