package Dist::Zilla::App::Command::update;

use strict;
use warnings;
our $VERSION = '0.06';

use Dist::Zilla::App -command;

sub abstract { "update generated files by building and then removing the build" }

sub opt_spec {
  [ 'trial'  => 'build a trial release' ],
}

sub execute {
    my ($self, $opt) = @_;
    my $zilla;
    {
        local $ENV{TRIAL} = $opt->trial ? 1 : 0;
        $zilla = $self->zilla;
    }
    $self->log("update: building into tmpdir");
    my ($built_in) = $self->zilla->ensure_built_in_tmpdir;
    $self->log("update: removing $built_in");
    my $rmtree = $built_in->can("remove_tree")  # ≥ 6.000 is Path::Tiny
              || $built_in->can("rmtree");      # < 6.000 is Path::Class::Dir
    $rmtree->($built_in);
}

1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::App::Command::update - A Dist::Zilla (and hence Dist::Milla)
command to update generated files

=head1 SYNOPSIS

    $ dzil update [--trial]
    $ milla update    # my use case

=head1 DESCRIPTION

This command is approximated by

    $ dzil build --no-tgz [--trial]
    $ rm -rf Your-Package-x.yz/

but it builds inside a temporary directory.  If you've ever used C<dzil build
&& dzil clean> to update generated files, now you can use C<dzil update>.
That's all!

=head1 OPTIONS

=head2 --trial

Build a trial release, as if C<dzil build> was called with --trial.

=head1 AUTHOR

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Thomas Sibley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<dzil>

L<Dist::Zilla>

L<milla>

L<Dist::Milla>

=cut
