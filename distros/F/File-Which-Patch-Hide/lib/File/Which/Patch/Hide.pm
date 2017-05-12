package File::Which::Patch::Hide;

our $DATE = '2016-07-01'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our %config;

my $w_which = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my @prog = split /\s*[;,]\s*/, $config{-prog};

    my $wa = wantarray;
    my @res;
    if ($wa) {
        @res = $orig->(@_);
    } else {
        my $res = $orig->(@_);
        push @res, $res if defined $res;
    }

    my @filtered_res;
    for my $path (@res) {
        my ($vol, $dir, $file) = File::Spec->splitpath($path);
        next if grep { m![/\\]! ? $path eq $_ : $file eq $_ } @prog;
        push @filtered_res, $path;
    }

    if ($wa) {
        return @filtered_res;
    } else {
        if (@filtered_res) {
            return $filtered_res[0];
        } else {
            return undef;
        }
    }
};

sub patch_data {
    return {
        v => 3,
        config => {
            -prog => {
                summary => 'A string containing semicolon-separated list '.
                    'of program names to hide',
                schema => 'str*',
            },
        },
        patches => [
            {
                action => 'wrap',
                sub_name => 'which',
                code => $w_which,
            },
        ],
    };
}

1;
# ABSTRACT: Hide some programs from File::Which

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Which::Patch::Hide - Hide some programs from File::Which

=head1 VERSION

This document describes version 0.003 of File::Which::Patch::Hide (from Perl distribution File-Which-Patch-Hide), released on 2016-07-01.

=head1 SYNOPSIS

 % PERL5OPT=-MFile::Which::Patch::Hide=-prog,'foo;bar' app.pl

In the above example C<app.pl> will think that C<foo> and C<bar> are not in
C<PATH> even though they actually are.

 % PERL5OPT=-MFile::Which::Patch::Hide=-prog,'/usr/bin/foo' app.pl

The above example hides just C</usr/bin/foo> but C<foo> might be available in
another directory in PATH.

=head1 DESCRIPTION

This module can be used to simulate the absence of certain programs. This module
works by patching (wrapping) L<File::Which>'s C<which()> routine to remove the
result if the programs that want to be hidden are listed in the result. So only
programs that use C<which()> will be fooled.

An example of how I use this module: L<Nodejs::Util> has a routine
C<get_nodejs_path()> which uses C<File::Which::which()> to check for the
existence of node.js binary. The C<get_nodejs_path()> routine is used in some of
my test scripts to optionally run tests when node.js is available. So to
simulate a condition where node.js is not available:

 % PERL5OPT=-MFile::Which::Patch::Hide=-prog,'node;nodejs' prove ...

=head1 PATCH CONTENTS

=over

=item * wrap C<which>

=back

=head1 PATCH CONFIGURATION

=over

=item * -prog => str

A string containing semicolon-separated list of program names to hide.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Which-Patch-Hide>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Which-Patch-Hide>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Which-Patch-Hide>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Patch>

L<File::Which>

To simulate tha absence of some perl modules, you can try: L<lib::filter>,
L<lib::disallow>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
