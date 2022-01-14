package Dist::Zilla::Plugin::Data::Sah;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-04'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Data-Sah'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Package::Stash;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

sub munge_files {
    no strict 'refs';

    my $self = shift;

    for my $file (@{ $self->found_files }) {
        unless ($file->isa("Dist::Zilla::File::OnDisk")) {
            $self->log_debug(["skipping %s: not an ondisk file, currently generated file is assumed to be OK", $file->name]);
            return;
        }
        my $file_name = $file->name;
        my $file_content = $file->content;
        if ($file_name =~ m!^lib/((.+)\.pm)$!) {
            my $package_pm = $1;
            my $package = $2; $package =~ s!/!::!g;

            if ($package =~ /^Data::Sah::Type::(.+)/) {
                my $type = $1;
                {
                    local @INC = ("lib", @INC);
                    require $package_pm;
                }

                my @clauses;
                for (Package::Stash->new($package)->list_all_symbols("CODE")) {
                    next unless /^clausemeta_(.+)/;
                    push @clauses, $1;
                }
                $self->log_debug(["type %s has these clauses: %s", $type, \@clauses]);

                for my $clause (@clauses) {
                    my $meth = "clausemeta_$clause";
                    my $clausemeta = $package->$meth;

                    # check that schema is already normalized
                    {
                        my $sch = $clausemeta->{schema} or last;
                        $self->log_debug(["checking schema of clause '%s' (type %s) ...", $clause, $type]);
                        require Data::Dump;
                        require Data::Sah::Normalize;
                        require Text::Diff;
                        my $nsch = Data::Sah::Normalize::normalize_schema($sch);
                        my $sch_dmp  = Data::Dump::dump($sch);
                        my $nsch_dmp = Data::Dump::dump($nsch);
                        last if $sch_dmp eq $nsch_dmp;
                        my $diff = Text::Diff::diff(\$sch_dmp, \$nsch_dmp);
                        $self->log_fatal("Schema for clause '$clause' (type $type) is not normalized, below is the dump diff (- is current, + is normalized): " . $diff);
                    }
                } # for clause
            } # Data::Sah::Type::*
        } # lib/
    } # for $file
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin for building Data-Sah and Data-Sah-* distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Data::Sah - Plugin for building Data-Sah and Data-Sah-* distributions

=head1 VERSION

This document describes version 0.005 of Dist::Zilla::Plugin::Data::Sah (from Perl distribution Dist-Zilla-Plugin-Data-Sah), released on 2021-07-04.

=head1 SYNOPSIS

In F<dist.ini>:

 [Data::Sah]

=head1 DESCRIPTION

This plugin is to be used when building C<Data-Sah> distribution (see
L<Data::Sah>) and C<Data-Sah-*> distribution like C<Data-Sah-Compiler-*>
distributions. Currently it does the following:

=over

=item * For C<lib/Data/Sah/Type/*.pm>, check that schema specified in each clause's C<schema> is normalized

=item * TODO: For C<lib/Data/Sah/Type/*.pm>, check that schema specified in each clause attribute's C<schema> is normalized

=back

Note that for C<Data-Sah-Coerce-*> distributions there are
L<Dist::Zilla::Plugin::Data::Sah::Coerce>. For C<Data-Sah-Filter-*>
distributions there are L<Dist::Zilla::Plugin::Data::Sah::Filter>.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
