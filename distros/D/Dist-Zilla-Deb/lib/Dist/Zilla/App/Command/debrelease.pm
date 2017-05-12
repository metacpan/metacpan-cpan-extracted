package Dist::Zilla::App::Command::debrelease;
{
  $Dist::Zilla::App::Command::debrelease::VERSION = '0.04';
}

use strict;
use warnings;

# ABSTRACT: build and release debian package


use Dist::Zilla::App -command;
require Dist::Zilla::App::Command::debuild;
use autodie qw(:all);

sub abstract { 'build and release debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    $self->app->execute_command($self->app->prepare_command('debuild'));
    system('cd debuild/source && debrelease');
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::App::Command::debrelease - build and release debian package

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command runs 'debrelease' command on sources built with 'dzil debuild'.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
