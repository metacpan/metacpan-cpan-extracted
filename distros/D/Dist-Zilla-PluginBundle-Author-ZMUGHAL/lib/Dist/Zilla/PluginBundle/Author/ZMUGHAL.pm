use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::ZMUGHAL;
# ABSTRACT: A plugin bundle for distributions built by ZMUGHAL
$Dist::Zilla::PluginBundle::Author::ZMUGHAL::VERSION = '0.005';
use Moose;

# Dependencies
use Dist::Zilla::Role::PluginBundle::Easy ();
use Dist::Zilla::Role::PluginBundle::Config::Slicer ();
use Dist::Zilla::Role::PluginBundle::PluginRemover ();

with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

sub configure {
	my $self = shift;

	$self->add_bundle('Author::ZMUGHAL::Basic');
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::ZMUGHAL - A plugin bundle for distributions built by ZMUGHAL

=head1 VERSION

version 0.005

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
