package HTTP::Tiny::Patch::Plugin;

our $DATE = '2019-04-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use HTTP::Tiny::Plugin ();
use Module::Patch qw();
use base qw(Module::Patch);

our %config;

my $plugins_set;
my $p_new = sub {
    my $ctx = shift;
    my $class = shift;

    if ($config{-set_plugins} && !$plugins_set++) {
        HTTP::Tiny::Plugin->set_plugins(@{ $config{-set_plugins} });
    }

    $class = 'HTTP::Tiny::Plugin' if $class eq 'HTTP::Tiny';
    $ctx->{orig}->($class, @_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -set_plugins => {
                schema  => 'array*',
            },
        },
        patches => [
            {
                action      => 'wrap',
                sub_name    => 'new',
                code        => $p_new,
            },
        ],
    };
}

1;
# ABSTRACT: Change use of HTTP::Tiny to that of HTTP::Tiny::Plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Patch::Plugin - Change use of HTTP::Tiny to that of HTTP::Tiny::Plugin

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Patch::Plugin (from Perl distribution HTTP-Tiny-Patch-Plugin), released on 2019-04-14.

=head1 SYNOPSIS

First, invoke this patch. From Perl:

 use HTTP::Tiny::Patch::Plugin
     # -set_plugins => ['Cache', CustomRetry=>{strategy=>"Exponential", strategy_options=>{initial_delay=>0.5, max_delay=>300}}],
 ;

or:

 use HTTP::Tiny::Patch::Plugin;
 HTTP::Tiny::Plugin->set_plugins('Cache', ...);

From command-line:

 % HTTP_TINY_PLUGINS='["Cache","CustomRetry",{"strategy":"Exponential","strategy_options":{"initial_delay":0.5}}]' \
     perl -MHTTP::Tiny::Patch::Plugin script-that-uses-http-tiny.pl ...

Now every usage of L<HTTP::Tiny>, e.g.:

 my $response = HTTP::Tiny->new->get("http://www.example.com/");

will become:

 my $response = HTTP::Tiny::Plugin->new->get("http://www.example.com/");

=head1 DESCRIPTION

This module replaces every instantiation of L<HTTP::Tiny> to instantiate
L<HTTP::Tiny::Plugin> instead, so you can use HTTP::Tiny::Plugin's plugins. Note
that instantiation of other HTTP::Tiny subclasses, e.g. L<HTTP::Tiny::Cache> is
not replaced with instantiation of HTTP::Tiny::Plugin.

=for Pod::Coverage ^(patch_data)$

=head1 CONFIGURATION

=head2 -set_plugins

Array. Will be passed to L<HTTP::Tiny::Plugin>'s C<set_plugins()>. You can also
set plugins by calling C<set_plugins()> yourself.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Patch-Plugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Patch-Plugin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Patch-Plugin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin>

L<HTTP::Tiny>

L<Module::Patch>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
