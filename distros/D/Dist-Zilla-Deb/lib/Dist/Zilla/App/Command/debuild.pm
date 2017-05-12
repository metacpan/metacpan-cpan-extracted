package Dist::Zilla::App::Command::debuild;
{
  $Dist::Zilla::App::Command::debuild::VERSION = '0.04';
}

use strict;
use warnings;

# ABSTRACT: build debian package


use Dist::Zilla::App -command;
use autodie qw(:all);

sub abstract { 'build debian package' }

sub opt_spec {
    # these options are propagated to debuild mostly for the tests
    # note than they should be specified as --us and will be transformed to -us because of getopt parsing differences
    ['us'   => "do not sign the source package"],
    ['uc'   => "do not sign the .changes file"],
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    die 'no args expected' if @$args;
}

sub execute {
    my ($self, $opt, $args) = @_;

    system('rm -rf debuild');
    mkdir('debuild');
    $self->zilla->build_in('debuild/source');
    my @debuild_args;
    push @debuild_args, '-us' if $opt->{us};
    push @debuild_args, '-uc' if $opt->{uc};
    system("cd debuild/source && debuild @debuild_args");
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::App::Command::debuild - build debian package

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command builds sources using dzil and runs debuild on them.

Sources are kept in 'debuild/source'.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
