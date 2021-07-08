package Desktop::Open;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-02'; # DATE
our $DIST = 'Desktop-Open'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(open_desktop);

sub open_desktop {
    my $path_or_url = shift;

    my $res;
  OPEN: {
        if ($^O eq 'MSWin32') {
            system "start", $path_or_url;
            $res = $?;
            last if $res == 0;
        } else {
            require File::Which;
            if (File::Which::which("xdg-open")) {
                system "xdg-open", $path_or_url;
                $res = $?;
                last if $res == 0;
            }
        }

        require Browser::Open;
        $res = Browser::Open::open_browser($path_or_url);
    }
    $res;
}

1;
# ABSTRACT: Open a file or URL in the user's preferred application

__END__

=pod

=encoding UTF-8

=head1 NAME

Desktop::Open - Open a file or URL in the user's preferred application

=head1 VERSION

This document describes version 0.001 of Desktop::Open (from Perl distribution Desktop-Open), released on 2021-07-02.

=head1 SYNOPSIS

 use Desktop::Open qw(open_desktop);
 my $ok = open_desktop($path_or_url);
 # !defined($ok);       no recognized command found
 # $ok == 0;            command found and executed
 # $ok != 0;            command found, error while executing

=head1 DESCRIPTION

This module tries to open specified file or URL in the user's preferred
application. Here's how it does it.

1. If on Windows, use "start". If on other OS, use "xdg-open" if available.

2. If #1 fails, resort to using L<Browser::Open>'s C<open_browser>. Return its
return value.

TODO: On OSX, use "openit". Any taker?

=head1 FUNCTIONS

=head2 open_desktop

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Desktop-Open>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Desktop-Open>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Desktop-Open>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Browser::Open>, on which our module is modelled upon.

L<Open::This> also tries to do "The Right Thing" when opening files, but it's
heavily towards text editor and git/GitHub.

L<App::Open> and its CLI L<openit> also attempt to open file using appropriate
file. It requires setting up a configuration file to run.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
