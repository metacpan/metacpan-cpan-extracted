package Dist::Zilla::Plugin::Extras;

our $DATE = '2015-06-14'; # DATE
our $VERSION = '0.03'; # VERSION

use Moose;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

has params => (
    is => 'ro',
    default => sub { {} },
);

sub BUILDARGS {
    my ($class, @arg) = @_;
    my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};

    return {
        zilla => $zilla,
        plugin_name => $name,
        params => \%copy,
    };
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Put extra parameters in dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Extras - Put extra parameters in dist.ini

=head1 VERSION

This document describes version 0.03 of Dist::Zilla::Plugin::Extras (from Perl distribution Dist-Zilla-Plugin-Extras), released on 2015-06-14.

=head1 SYNOPSIS

In your F<dist.ini>:

  [Extras]
  foo = 1
  bar = 2

  [Extras / Baz]
  qux = 1
  quux = 2

=head1 DESCRIPTION

This plugin lets you specify extra parameters in your F<dist.ini> under the
C<[Extras]> section. Other than that it does nothing. It basically serves as
"bags" to put parameters in.

One use-case of this is to put template variables in your F<dist.ini>, e.g.:

 [Extras]
 name1 = value1
 name2 = value2

The parameters are available for other plugins through C<$zilla> (Dist::Zilla
object), e.g.:

 my $extras_plugin = grep { $_->plugin_name eq 'Extras' } $zilla->plugins;
 my $name1 = $extras_plugin->params->{name1}; # -> "value1"

Another use-case of this is to put stuffs to be processed by other software
aside from L<Dist::Zilla> (e.g. see L<App::LintPrereqs>).

=head1 ATTRIBUTES

=head2 params => hash

=head1 SEE ALSO

L<Dist::Zilla>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Extras>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Extras>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Extras>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
