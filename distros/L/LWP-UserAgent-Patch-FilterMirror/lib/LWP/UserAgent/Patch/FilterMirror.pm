package LWP::UserAgent::Patch::FilterMirror;

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our $DATE = '2015-07-27'; # DATE
our $VERSION = '0.05'; # VERSION

our %config;

my $p_mirror = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my ($self, $url, $file) = @_;
    die __PACKAGE__ . ": please specify filter code" unless $config{-filter};
    return unless $config{-filter}->($url, $file);
    return $orig->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -filter => {
                schema => 'code*',
            },
        },
        patches => [
            {
                action => 'wrap',
                mod_version => qr/^6\.[01].+/,
                sub_name => 'mirror',
                code => $p_mirror,
            },
        ],
    };
}

1;
# ABSTRACT: Add filtering for mirror()

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Patch::FilterMirror - Add filtering for mirror()

=head1 VERSION

This document describes version 0.05 of LWP::UserAgent::Patch::FilterMirror (from Perl distribution LWP-UserAgent-Patch-FilterMirror), released on 2015-07-27.

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::FilterMirror -filter => sub { ... };
 # use LWP::UserAgent's mirror() as usual
 # ...

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Patch-FilterMirror>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-LWP-UserAgent-Patch-FilterMirror>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Patch-FilterMirror>

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
