package Dist::Zilla::Plugin::ConfigureSelf;
$Dist::Zilla::Plugin::ConfigureSelf::VERSION = '0.007';
use Moose;

with qw/Dist::Zilla::Role::ConfigureSelf/;

1;


# ABSTRACT: Build a Build.PL that uses the current module to build itself

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ConfigureSelf - Build a Build.PL that uses the current module to build itself

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This plugin copies any runtime requirements to configure requirements. This can be useful for bootstrapping install tools, it should not be necessary for almost anything else.

It takes a single option, C<sanatize_for>, that takes a perl version. If set any prerequisites provided by that version of perl will be filtered out of the configure requirements.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
