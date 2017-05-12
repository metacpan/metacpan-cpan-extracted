package Dist::Zilla::App::Command::debi;
{
  $Dist::Zilla::App::Command::debi::VERSION = '0.04';
}

use strict;
use warnings;

# ABSTRACT: install generated debian package


use Dist::Zilla::App -command;
use autodie qw(:all);

sub abstract { 'install generated debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    system('cd debuild/source && sudo debi');
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::App::Command::debi - install generated debian package

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command runs 'sudo debi' command on sources built with 'dzil debuild'.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
