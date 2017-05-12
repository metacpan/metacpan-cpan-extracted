package Dist::Zilla::Plugin::MakeMaker::IncShareDir;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker';
with 'Dist::Zilla::Role::ModuleIncluder', 'Dist::Zilla::Role::FileGatherer';

sub gather_files {
    my $self = shift;
    $self->include_modules([ 'File::ShareDir::Install' ], version->new('5.008001'));
}

after register_prereqs => sub {
    my $self = shift;
    $self->zilla->prereqs->requirements_for('configure', 'requires')->clear_requirement('File::ShareDir::Install');
};

override share_dir_code => sub {
    my $self = shift;

    my $code = super;
    $code->{preamble} = "use lib 'inc';\n$code->{preamble}";
    $code;
};

1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::IncShareDir - MakeMaker subclass that bundles File::ShareDir::Install in inc/

=head1 SYNOPSIS

  use Dist::Zilla::Plugin::MakeMaker::IncShareDir;

=head1 DESCRIPTION

Dist::Zilla::Plugin::MakeMaker::IncShareDir is a plugin to emit C<Makefile.PL> but
bundles L<File::ShareDir::Install> in C<inc>.

You probaly don't need to use this plugin. This plugin is made
specifically for L<App::cpanminus> where the build files can't have
external dependencies due to bootstrapping reasons.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::MakeMaker> L<Dist::Zilla::Role::ModuleIncluder>

=cut
