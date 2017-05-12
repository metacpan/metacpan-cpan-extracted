package Dist::Zilla::App::Command::debc;
{
  $Dist::Zilla::App::Command::debc::VERSION = '0.04';
}

use strict;
use warnings;

# ABSTRACT: run debc on generated debian package


use Dist::Zilla::App -command;
use autodie qw(:all);

sub abstract { 'run debc on generated debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    system('cd debuild/source && debc');
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::App::Command::debc - run debc on generated debian package

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command runs 'debc' command on sources built with 'dzil debuild'.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
