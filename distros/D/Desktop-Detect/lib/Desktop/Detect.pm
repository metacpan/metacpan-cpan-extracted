package Desktop::Detect;

our $DATE = '2016-10-07'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(detect_desktop); # detect_desktop_cached

#my $dd_cache;
#sub detect_desktop_cached {
#    if (!$dd_cache) {
#        $dd_cache = detect_desktop(@_);
#    }
#    $dd_cache;
#}

sub _det_env {
    my ($info, $desktop, $env, $re_or_str) = @_;
    my $cond = ref($re_or_str) eq 'Regexp' ?
        ($ENV{$env}//'') =~ $re_or_str : ($ENV{$env}//'') eq $re_or_str;
    if ($cond) {
        push @{$info->{_debug_info}}, "detect: $desktop via $env env";
        $info->{desktop} = $desktop;
        return 1;
    }
    0;
}

sub detect_desktop {
    my @dbg;
    my $info = {_debug_info=>\@dbg};

  DETECT:
    {
        # xfce
        last DETECT if _det_env($info, 'xfce', 'XDG_MENU_PREFIX', 'xfce-');
        last DETECT if _det_env($info, 'xfce', 'DESKTOP_SESSION', 'xfce');

        # kde-plasma
        last DETECT if _det_env($info, 'kde-plasma', 'XDG_DESKTOP_SESSION', 'kde-plasma');
        last DETECT if _det_env($info, 'kde-plasma', 'DESKTOP_SESSION', 'kde-plasma');
        last DETECT if _det_env($info, 'plasma', 'XDG_DESKTOP_SESSION', 'plasma');
        last DETECT if _det_env($info, 'plasma', 'DESKTOP_SESSION', 'plasma');

        # cinnamon
        last DETECT if _det_env($info, 'cinnamon', 'DESKTOP_SESSION', 'cinnamon');

        # gnome
        last DETECT if _det_env($info, 'gnome', 'DESKTOP_SESSION', 'gnome');
        last DETECT if _det_env($info, 'gnome-classic', 'DESKTOP_SESSION', 'gnome-classic');
        last DETECT if _det_env($info, 'gnome-fallback', 'DESKTOP_SESSION', 'gnome-fallback');

        # lxde
        last DETECT if _det_env($info, 'lxde', 'XDG_MENU_PREFIX', 'lxde-');
        last DETECT if _det_env($info, 'lxde', 'DESKTOP_SESSION', 'LXDE');

        # openbox
        last DETECT if _det_env($info, 'openbox', 'DESKTOP_SESSION', 'openbox');

        push @dbg, "detect: nothing detected";
        $info->{desktop} = '';
    } # DETECT

    $info;
}

1;
# ABSTRACT: Detect desktop environment currently running

__END__

=pod

=encoding UTF-8

=head1 NAME

Desktop::Detect - Detect desktop environment currently running

=head1 VERSION

This document describes version 0.06 of Desktop::Detect (from Perl distribution Desktop-Detect), released on 2016-10-07.

=head1 SYNOPSIS

 use Desktop::Detect qw(detect_desktop);
 my $res = detect_desktop();
 say "We are running under XFCE" if $res->{desktop} eq 'xfce';

=head1 DESCRIPTION

This module uses several heuristics to find out what desktop environment
is currently running, along with extra information.

=head1 FUNCTIONS

=head2 detect_desktop() => HASHREF

Return a hashref containing information about running desktop environment and
extra information.

Detection is done from the cheapest methods, e.g. looking at environment
variables. Several environment variables are checked, e.g. C<DESKTOP_SESSION>,
C<XDG_DESKTOP_SESSION>, etc.

Result:

=over

=item * desktop => STR

Possible values: C<xfce>, C<kde-plasma>, C<gnome>, C<gnome-classic>,
C<cinnamon>, C<lxde>, C<openbox>, or empty string (if can't detect any desktop
environment running).

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Desktop-Detect>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Desktop-Detect>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Desktop-Detect>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
