package Dist::Zilla::PluginBundle::RBUELS;
BEGIN {
  $Dist::Zilla::PluginBundle::RBUELS::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Dist::Zilla::PluginBundle::RBUELS::VERSION = '0.1';
}
# ABSTRACT: Build your distributions like RBUELS does
use Moose;

use namespace::autoclean;

extends qw(Dist::Zilla::PluginBundle::FLORA);

has '+authority' => ( default => "cpan:RBUELS" );

has '+github_user' => ( default => "rbuels" );

after 'configure' => sub {
    shift->add_plugins(qw(
        NextRelease
      ));
};

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::RBUELS - Build your distributions like RBUELS does

=head1 AUTHOR

Robert Buels <rbuels@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

