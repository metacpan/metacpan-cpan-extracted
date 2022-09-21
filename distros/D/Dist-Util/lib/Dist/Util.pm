package Dist::Util;

use strict;
use warnings;

use Config;
use Exporter 'import';
use File::Spec;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-21'; # DATE
our $DIST = 'Dist-Util'; # DIST
our $VERSION = '0.071'; # VERSION

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_dist_modules
                       list_dists
                       packlist_for
               );

sub packlist_for {
    my $mod = shift;

    unless ($mod =~ s/\.pm\z//) {
        $mod =~ s!::!/!g;
    }

    for (@INC) {
        next if ref($_);
        my $f = "$_/$Config{archname}/auto/$mod/.packlist";
        return $f if -f $f;
    }
    undef;
}

sub list_dists {
    require File::Find;

    my %args = @_;

    my %dists;
    for my $inc (@INC) {
        next if ref($inc);
        my $prefix = "$inc/$Config{archname}/auto";
        next unless -d $prefix;

        File::Find::find(
            sub {
                return unless $_ eq '.packlist';
                my $dist = substr($File::Find::dir, length($prefix)+1);
                # XXX use platform-neutral path separator
                $dist =~ s!/!-!g;
                $dists{$dist} = {dist=>$dist, packlist => "$File::Find::dir/$_"};
            },
            $prefix,
        );
    }
    if ($args{detail}) {
        return values %dists;
    } else {
        return (sort keys %dists);
    }
}

sub list_dist_modules {
    my $mod = shift;

    # convenience: convert Foo-Bar to Foo::Bar
    $mod =~ s/-/::/g;

    my $packlist = packlist_for($mod);
    return () unless $packlist;

    # path structure for .packlist: <libprefix> + <arch> + "auto" +
    # /Module/Name/ + "/.packlist". we want to get <libprefix>
    my $libprefix;
    {
        my ($vol, $dirs, $name) = File::Spec->splitpath(
            File::Spec->rel2abs($packlist));
        my @dirs = File::Spec->splitdir($dirs);
        for (0..@dirs-2) {
            if ($dirs[$_] eq $Config{archname} && $dirs[$_+1] eq 'auto') {
                $libprefix = File::Spec->catpath(
                    $vol, File::Spec->catdir(@dirs[0..$_-1]));
                last;
            }
        }
        die "Can't find libprefix for packlist $packlist" unless $libprefix;
    }

    open my($fh), "<", $packlist or return ();
    my @mods;
    while (my $l = <$fh>) {
        chomp $l;
        next unless $l =~ /\.pm\z/;
        $l =~ s/\A\Q$libprefix\E// or next;
        my @dirs = File::Spec->splitdir($l);
        shift @dirs; # ""
        shift @dirs if $dirs[0] eq $Config{archname};
        $dirs[-1] =~ s/\.pm\z//;
        push @mods, join("::", @dirs);
    }

    @mods;
}

1;
# ABSTRACT: Dist-related utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Util - Dist-related utilities

=head1 VERSION

This document describes version 0.071 of Dist::Util (from Perl distribution Dist-Util), released on 2022-08-21.

=head1 SYNOPSIS

 use Dist::Util qw(
     list_dist_modules
     list_dists
     packlist_for
 );

 say packlist_for("Text::ANSITable"); # sample output: /home/steven/perl5/perlbrew/perls/perl-5.18.2/lib/site_perl/5.18.2/x86_64-linux/auto/Text/ANSITable/.packlist
 my @mods = list_dist_modules("Text::ANSITable"); # -> ("Text::ANSITable", "Text::ANSITable::BorderStyle::Default", "Text::ANSITable::ColorTheme::Default")

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 packlist_for($mod) => STR

Find C<.packlist> file for installed module C<$mod> (which can be in the form of
C<Package::SubPkg> or C<Package/SubPkg.pm>). Return undef if none is found.

Depending on the content of C<@INC>, the returned path may be absolute or
relative.

Caveat: many Linux distributions strip C<.packlist> files.

=head2 list_dists

Usage:

 list_dists(%opts) => LIST

Find all C<.packlist> files in C<@INC> and then pick the dist names from the
paths, because C<.packlist> files are put in:

 $INC/$Config{archname}/auto/Foo/Bar/.packlist

Caveat: many Linux distributions strip C<.packlist> files.

TODO: Instead of via L<.packlist>, also try querying the OS package manager.

Known options:

=over

=item * detail

Bool. If set to true, instead of a list of distribution names, the function will
return a list of hashrefs containing detailed information e.g.:

 (
   {dist=>"Foo-Bar", packlist=>"/home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/x86_64-linux/auto/Foo/Bar/.packlist"},
   ...
 )

=back

=head2 list_dist_modules($mod) => LIST

Given installed module name C<$mod> (which must be the name of the main module
of its distribution), list all the modules in the distribution. This is done by
first finding the C<.packlist> file, then look at all the C<.pm> files listed in
the packlist.

Will return empty list if fails to get the packlist.

Caveat: many Linux distributions strip C<.packlist> files.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Util>.

=head1 SEE ALSO

L<Dist::Util::Current>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
