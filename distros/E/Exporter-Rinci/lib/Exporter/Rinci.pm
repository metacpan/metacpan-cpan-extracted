package Exporter::Rinci;

our $DATE = '2019-08-15'; # DATE
our $VERSION = '0.030'; # VERSION

use Exporter ();

sub import {
    my $package = shift;
    my $exporter = caller();

    my $export      = \@{"$exporter\::EXPORT"};
    my $export_ok   = \@{"$exporter\::EXPORT_OK"};
    my $export_tags = \%{"$exporter\::EXPORT_TAGS"};

    if (@_ && $_[0] eq 'import') {
        shift @_;
        *{"$exporter\::import"} = sub {
            my $importer = caller;
            {
                last if @$export || @$export_ok || keys(%$export_tags);
                my $metas = \%{"$exporter\::SPEC"};
                for my $k (keys %$metas) {
                    # for now we limit ourselves to subs
                    next unless $k =~ /\A\w+\z/;
                    my @tags = @{ $metas->{$k}{tags} || [] };
                    next if grep {$_ eq 'export:never'} @tags;
                    if (grep {$_ eq 'export:default'} @tags) {
                        push @$export, $k;
                    } else {
                        push @$export_ok, $k;
                    }
                    for my $tag (@tags) {
                        s/\Aexport://;
                        push @{ $export_tags->{$tag} }, $k;
                    }
                }
            }
            goto \&Exporter::import;
        };
    }
}

1;
# ABSTRACT: A simple wrapper for Exporter for modules with Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Exporter::Rinci - A simple wrapper for Exporter for modules with Rinci metadata

=head1 VERSION

This document describes version 0.030 of Exporter::Rinci (from Perl distribution Exporter-Rinci), released on 2019-08-15.

=head1 SYNOPSIS

 package YourModule;

 # most of the time, you only need to do this
 use Exporter::Rinci qw(import);

 our %SPEC;

 # f1 will not be exported by default, but user can import them explicitly using
 # 'use YourModule qw(f1)'
 $SPEC{f1} = { v=>1.1 };
 sub f1 { ... }

 # f2 will be exported by default because it has the export:default tag
 $SPEC{f2} = { v=>1.1, tags=>[qw/a export:default/] };
 sub f2 { ... }

 # f3 will never be exported, and user cannot import them via 'use YourModule
 # qw(f1)' nor via 'use YourModule qw(:a)'
 $SPEC{f3} = { v=>1.1, tags=>[qw/a export:never/] };
 sub f3 { ... }

=head1 DESCRIPTION

Exporter::Rinci is a simple wrapper for L<Exporter>. Before handing out control
to Exporter's import(), it will look at the exporting module's C<@EXPORT>,
C<@EXPORT_OK>, and C<%EXPORT_TAGS> and if they are empty will fill them out with
data from L<Rinci> metadata (C<%SPEC>). The rules are similar to
L<Perinci::Exporter>: all functions will be put in C<@EXPORT_OK>, except
functions with C<export:never> tag will not be exported and functions with
C<export:default> tag will be put in C<@EXPORT>. C<%EXPORT_TAGS> will also be
filled from functions' tags.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Exporter-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Exporter-Rinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Exporter-Rinci>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

If you want something more full-featured, there's L<Perinci::Exporter>. If
Exporter::Rinci is like Exporter.pm + Rinci, then Perinci::Exporter is like
L<Sub::Exporter> + Rinci. It features subroutine renaming, wrapping (adding
retries, timeouts, etc).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
