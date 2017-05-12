package HTML::Extract::CPANModules;

our $DATE = '2016-03-07'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_modules_from_html);

our %SPEC;

$SPEC{extract_cpan_modules_from_html} = {
    v => 1.1,
    summary => 'Extract CPAN module names from an HTML document',
    args => {
        html => {
            schema => 'str*',
            req => 1,
            tags => ['category:input'],
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
        from_text => {
            schema => 'bool',
            default => 0,
            description => <<'_',

If set to true, will try to extract things that look like a Perl module name
from text in HTML, e.g.: `Foo::Bar`, `Baz::Qux::2048` (basically, anything that
looks like a package name). This means that single words (package without a
double colon and a subpackage) won't be picked up.

_
        },
        from_links => {
            schema => 'bool',
            default => 1,
            description => <<'_',

If set to true (the default), will try to extract module names from URLs. Some
URLs are recognized, e.g.:

    https://metacpan.org/pod/Foo::Bar
    https://search.cpan.org/~user/Foo-Bar-1.23/lib/Foo/Bar.pm

and so on. Currently, the CPAN module `CPAN::Module::FromURL` is used to
recognize the URLs.

_
        },
    },
    result_naked => 1,
    result => {
        schema => ['array*', of=>'str*'],
    },
};
sub extract_cpan_modules_from_html {
    require DOM::Tiny;

    my %args = @_;

    my %mods;

    my $dom = DOM::Tiny->new($args{html});

    if ($args{from_links} // 1) {
        require CPAN::Module::FromURL;
        for my $link ($dom->find('a[href]')->each) {
            #say $link;
            my $url = $link->attr->{href};
            my $m = CPAN::Module::FromURL::extract_cpan_module_from_url($url);
            next unless $m;
            $mods{$m}++;
        }
    }

    if ($args{from_text}) {
        for my $el ($dom->find('*')->each) {
            my $text = $el->text;
            while ($text =~ /\b([A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_0-9]+)+)\b/g) {
                $mods{$1}++;
            }
        }
    }

    [sort keys %mods];
}

1;
# ABSTRACT: Extract CPAN module names from an HTML document

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Extract::CPANModules - Extract CPAN module names from an HTML document

=head1 VERSION

This document describes version 0.04 of HTML::Extract::CPANModules (from Perl distribution HTML-Extract-CPANModules), released on 2016-03-07.

=head1 FUNCTIONS


=head2 extract_cpan_modules_from_html(%args) -> array[str]

Extract CPAN module names from an HTML document.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<from_links> => I<bool> (default: 1)

If set to true (the default), will try to extract module names from URLs. Some
URLs are recognized, e.g.:

 https://metacpan.org/pod/Foo::Bar
 https://search.cpan.org/~user/Foo-Bar-1.23/lib/Foo/Bar.pm

and so on. Currently, the CPAN module C<CPAN::Module::FromURL> is used to
recognize the URLs.

=item * B<from_text> => I<bool> (default: 0)

If set to true, will try to extract things that look like a Perl module name
from text in HTML, e.g.: C<Foo::Bar>, C<Baz::Qux::2048> (basically, anything that
looks like a package name). This means that single words (package without a
double colon and a subpackage) won't be picked up.

=item * B<html>* => I<str>

=back

Return value:  (array[str])

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTML-Extract-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTML-Extract-CPANModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Extract-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Module::FromURL>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
