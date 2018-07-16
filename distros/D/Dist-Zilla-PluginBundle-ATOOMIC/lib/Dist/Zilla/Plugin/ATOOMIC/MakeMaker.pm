package Dist::Zilla::Plugin::ATOOMIC::MakeMaker;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.00';

use File::Which qw( which );

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

has has_xs => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has wall_min_perl_version => (
    is      => 'ro',
    isa     => 'Str',
    default => '5.008008',
);

with 'Dist::Zilla::Plugin::ATOOMIC::Role::CoreCounter';

# Dist::Zilla provides no way to pass a `-j` option when running dzil release
# but I really would like faster releases.
sub default_jobs {
    return shift->_core_count;
}

override _build_WriteMakefile_dump => sub {
    my $self = shift;

    my $dump = super();
    return $dump unless $self->has_xs;

    $dump .= sprintf( <<'EOF', $self->wall_min_perl_version );
my $gcc_warnings = $ENV{AUTHOR_TESTING} && $] >= %s ? q{ -Wall -Werror} : q{};
$WriteMakefileArgs{DEFINE}
    = ( $WriteMakefileArgs{DEFINE} || q{} ) . $gcc_warnings;

EOF

    return $dump;
};

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Subclasses MakeMaker::Awesome to always run tests in parallel and add -W flags for XS code

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ATOOMIC::MakeMaker - Subclasses MakeMaker::Awesome to always run tests in parallel and add -W flags for XS code

=head1 VERSION

version 1.00

=for Pod::Coverage .*

=head1 SUPPORT

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-ATOOMIC can be found at L<https://github.com/atoomic/Dist-Zilla-PluginBundle-ATOOMIC>.

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Nicolas R.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
