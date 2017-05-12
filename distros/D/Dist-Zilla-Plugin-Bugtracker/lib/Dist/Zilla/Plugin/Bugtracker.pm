use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Bugtracker;
BEGIN {
  $Dist::Zilla::Plugin::Bugtracker::VERSION = '1.111080';
}

# ABSTRACT: Automatically sets the bugtracker URL and mailto
use Moose;
with 'Dist::Zilla::Role::MetaProvider';
has web => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
);
has mailto => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_mailto',
);

sub interpolate {
    local $_ = $_[1];
    my $value = $_[2];
    s/(?<!%)%s/$value/g;
    s/(?<!%)%l/lc $value/eg;
    s/(?<!%)%U/uc $value/eg;
    s/%%/%/g;
    $_;
}

sub metadata {
    my $self = shift;
    my $web = $self->interpolate($self->web, $self->zilla->name);
    if (!$self->has_mailto && index($web, 'http://rt.cpan.org/') == 0) {
        $self->mailto('bug-%l at rt.cpan.org');
    }
    my $result = {};
    $result->{resources}{bugtracker}{web} = $web;
    $result->{resources}{bugtracker}{mailto} =
      $self->interpolate($self->mailto, $self->zilla->name)
      if $self->has_mailto && length $self->mailto;
    $result;
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=for stopwords mailto

=for test_synopsis 1;
__END__

=head1 NAME

Dist::Zilla::Plugin::Bugtracker - Automatically sets the bugtracker URL and mailto

=head1 VERSION

version 1.111080

=head1 SYNOPSIS

In C<dist.ini>:

    [Bugtracker]

=head1 DESCRIPTION

This plugin sets the distribution's bugtracker URL and possibly the email
address as metadata. You can set the C<web> and the C<mailto> values
independently in the plugin configuration.

=head1 METHODS

=head2 web

This is the bugtracker URL. It defaults to the CPAN RT URL, so it equivalent to:

    [Bugtracker]
    web = http://rt.cpan.org/Public/Dist/Display.html?Name=%s

See C<interpolate()> for more information.

=head2 mailto

This is the optional email address to which bug reports can be sent. If the
CPAN RT bugtracker is used, the email address defaults to C<bug-%l at
rt.cpan.org> - see C<interpolate()> for what this means.

If a different bugtracker URL is used, the email address is only included in
the metadata if it is explicitly given.

In the following examples, assume that the distribution is called C<Foo-Bar>.

Example 1:

    [Bugtracker]

will produce the defaults:

    web:    http://rt.cpan.org/Public/Dist/Display.html?Name=Foo-Bar
    mailto: bug-foo-bar at rt.cpan.org

Example 2:

To suppress the C<mailto> from example 1, use:

    [Bugtracker]
    mailto =

Example 3:

    [Bugtracker]
    web = http://github.com/me/%s/issues

will only produce a C<web> entry, but not a C<mailto> entry:

    web: http://github.com/me/Foo-Bar/issues

Example 4:

    [Bugtracker]
    mailto = me@example.org

will produce:

    web:    http://rt.cpan.org/Public/Dist/Display.html?Name=Foo-Bar
    mailto: me@example.org

Example 5:

    [Bugtracker]
    web = http://github.com/me/%s/issues
    mailto = bug-%U@example.org

will only produce a C<web> entry, but not a C<mailto> entry:

    web:    http://github.com/me/Foo-Bar/issues
    mailto: bug-FOO-BAR@example.org

See
L<CPAN::Meta::Spec|http://search.cpan.org/dist/CPAN-Meta/lib/CPAN/Meta/Spec.pm#resources>
for more information.

=head2 interpolate

Both the C<web> and C<mailto> strings are interpolated as follows:

    %s  The distribution name as is (e.g., 'Foo-Bar')
    %l  The distribution name in lowercase (e.g., 'foo-bar')
    %U  The distribution name in uppercase (e.g., 'FOO-BAR')
    %%  A literal '%' sign

=head2 metadata

Sets the bugtracker URL and possibly email address in the distribution's metadata.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Bugtracker>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Bugtracker/>.

The development version lives at L<http://github.com/hanekomu/Dist-Zilla-Plugin-Bugtracker>
and may be cloned from L<git://github.com/hanekomu/Dist-Zilla-Plugin-Bugtracker.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

