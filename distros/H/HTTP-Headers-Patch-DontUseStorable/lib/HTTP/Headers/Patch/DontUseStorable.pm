## no critic: Subroutines::ProhibitSubroutinePrototypes
package HTTP::Headers::Patch::DontUseStorable;

use 5.010001;
use strict;
no warnings;

use Module::Patch ();
use base qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-26'; # DATE
our $DIST = 'HTTP-Headers-Patch-DontUseStorable'; # DIST
our $VERSION = '0.062'; # VERSION

our %config;

sub _clone($) {
    my $self = shift;
    my $clone = HTTP::Headers->new;
    $self->scan(sub { $clone->push_header(@_);} );
    $clone;
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'replace',
                mod_version => qr/^6\./,
                sub_name => 'clone',
                code => \&_clone,
            },
        ],
    };
}

1;
# ABSTRACT: (DEPRECATED) Do not use Storable

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::Patch::DontUseStorable - (DEPRECATED) Do not use Storable

=head1 VERSION

This document describes version 0.062 of HTTP::Headers::Patch::DontUseStorable (from Perl distribution HTTP-Headers-Patch-DontUseStorable), released on 2021-08-26.

=head1 SYNOPSIS

 use HTTP::Headers::Patch::DontUseStorable;

=head1 DESCRIPTION

B<UPDATE 2020-02-03:> As of Storable 3.08, freeze/thaw/dclone support Regexp
objects. I'm deprecating this module.

L<HTTP::Headers> (6.11 as of this writing) tries to load L<Storable> (2.56 as of
this writing) and use its dclone() method. Since Storable still does not support
serializing Regexp objects, HTTP::Headers/L<HTTP::Message> croaks when fed data
with Regexp objects.

This patch avoids using Storable and clone using the alternative method.

=for Pod::Coverage ^(patch_data)$

=head1 FAQ

=head2 Is this a bug with HTTP::Headers? Why don't you submit a bug to HTTP-Message?

I tend not to think this is a bug with HTTP::Headers; after all, Storable's
dclone() is a pretty standard way to clone data in Perl. This patch is more of a
workaround for current Storable's deficiencies.

=head2 Shouldn't you add STORABLE_{freeze,thaw} methods to Regexp instead?

This no longer works with newer Perls (5.12 and later).

=head2 Why would an HTTP::Headers object contain a Regexp object in the first place? Shouldn't it only contain strings (and arrays/hashes of strings)?

True. This might be a bug with the client code (e.g. in my module which uses
this patch, L<Finance::Bank::ID::Mandiri>). I haven't investigated further
though and this is the stop-gap solution.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Headers-Patch-DontUseStorable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Headers-Patch-DontUseStorable>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto (on PC)

Steven Haryanto (on PC) <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2017, 2015, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Headers-Patch-DontUseStorable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
