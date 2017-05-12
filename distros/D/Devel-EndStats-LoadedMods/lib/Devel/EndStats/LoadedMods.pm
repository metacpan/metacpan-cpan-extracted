package Devel::EndStats::LoadedMods;

our $DATE = '2014-10-10'; # DATE
our $VERSION = '0.03'; # VERSION

END {
    print "# BEGIN stats from Devel::EndStats::LoadedMods\n";
    print "perl ($^V)\n";
    for my $file (sort keys %INC) {
        next if $file =~ m!^/!;
        my $pkg = $file; $pkg =~ s!/!::!g; $pkg =~ s/\.pm$//;
        my $ver = ${"$pkg\::VERSION"};
        $ver = 'undef' unless defined $ver;
        print "$pkg ($ver)\n";
    }
    print "# END stats\n";
}

1;
# ABSTRACT: Display loaded modules and their versions at the end of program run

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::EndStats::LoadedMods - Display loaded modules and their versions at the end of program run

=head1 VERSION

This document describes version 0.03 of Devel::EndStats::LoadedMods (from Perl distribution Devel-EndStats-LoadedMods), released on 2014-10-10.

=head1 SYNOPSIS

 # from the command line
 % perl -MDevel::EndStats::LoadedMods script.pl

 ##### sample output #####
 <normal script output, if any...>

 # BEGIN stats from Devel::EndStats::LoadedMods
 perl (5.18.2)
 Data::Dump (1.22)
 Devel::EndStats::LoadedMods (0.02)
 Exporter (5.70)
 feature (1.32)
 overload (1.22)
 overloading (0.02)
 strict (1.07)
 subs (1.01)
 vars (1.03)
 warnings (1.18)
 warnings::register (1.02)
 # END stats

=head1 DESCRIPTION

This module installs an END block to dump a list of loaded modules with their
versions. It simply lists the content of C<%INC> keys, with versions taken from
corresponding C<$VERSION> package variables. The output is easily diff-able.

I first wrote this to debug why my script doesn't work when run under cron
(using system perl) but works when run under my shell (using perlbrew's perl).

=head1 SEE ALSO

There are probably already existing modules on CPAN when I wrote this module,
but I couldn't find them.

Related modules to print information at the end of program run:
L<Devel::EndStats>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-EndStats-LoadedMods>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-EndStats-LoadedMods>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-EndStats-LoadedMods>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
