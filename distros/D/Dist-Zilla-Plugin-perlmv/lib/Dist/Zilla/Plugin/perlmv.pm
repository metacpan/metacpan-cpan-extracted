package Dist::Zilla::Plugin::perlmv;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-04'; # DATE
our $DIST = 'Dist-Zilla-Plugin-perlmv'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::BeforeBuild';
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [':InstallModules'],
};
use File::Spec::Functions qw(catfile);
use namespace::autoclean;

# either provide filename or filename+filecontent
sub _get_abstract_from_scriptlet_summary {
    my ($self, $filename, $filecontent) = @_;

    local @INC = @INC;
    unshift @INC, 'lib';

    unless (defined $filecontent) {
        $filecontent = do {
            open my($fh), "<", $filename or die "Can't open $filename: $!";
            local $/;
            ~~<$fh>;
        };
    }

    unless ($filecontent =~ m{^#[ \t]*ABSTRACT:[ \t]*([^\n]*)[ \t]*$}m) {
        $self->log_debug(["Skipping %s: no # ABSTRACT", $filename]);
        return undef;
    }

    my $abstract = $1;
    if ($abstract =~ /\S/) {
        $self->log_debug(["Skipping %s: Abstract already filled (%s)", $filename, $abstract]);
        return $abstract;
    }

    my $pkg;
    if (!defined($filecontent)) {
        (my $mod_p = $filename) =~ s!^lib/!!;
        require $mod_p;

        # find out the package of the file
        ($pkg = $mod_p) =~ s/\.pm\z//; $pkg =~ s!/!::!g;
    } else {
        eval $filecontent;
        die if $@;
        if ($filecontent =~ /\bpackage\s+(\w+(?:::\w+)*)/s) {
            $pkg = $1;
        } else {
            die "Can't extract package name from file content";
        }
    }

    no strict 'refs';
    my $scriptlet = ${"$pkg\::SCRIPTLET"};

    return $scriptlet->{summary} if $scriptlet->{summary};
}

# dzil also wants to get abstract for main module to put in dist's
# META.{yml,json}
sub before_build {
   my $self  = shift;
   my $name  = $self->zilla->name;
   my $class = $name; $class =~ s{ [\-] }{::}gmx;
   my $filename = $self->zilla->_main_module_override ||
       catfile( 'lib', split m{ [\-] }mx, "${name}.pm" );

   $filename or die 'No main module specified';
   -f $filename or die "Path ${filename} does not exist or not a file";
   my $abstract = $self->_get_abstract_from_scriptlet_summary($filename);
   return unless $abstract;

   $self->zilla->abstract($abstract);
   return;
}

sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;

    unless ($file->isa("Dist::Zilla::File::OnDisk")) {
        $self->log_debug(["skipping %s: not an ondisk file, currently generated file is assumed to be OK", $file->name]);
        return;
    }

    $self->log_debug(["Processing %s ...", $file->name]);

    my $pkg = do {
        my $pkg = $file->name;
        $pkg =~ s!^lib/!!;
        $pkg =~ s!\.pm$!!;
        $pkg =~ s!/!::!g;
        $pkg;
    };

    if ($pkg =~ /\AApp::perlmv::scriptlet::/) {

        my $abstract = $self->_get_abstract_from_scriptlet_summary($file->name, $file->content);

        my $scriptlet;
        {
            no strict 'refs';
            $scriptlet = ${"$pkg\::SCRIPTLET"};
        }

      CHECK_SCRIPTLET: {
            $self->log_fatal("Scriptlet does not have 'code' property")
                unless $scriptlet->{code};
        } # CHECK_SCRIPTLET

      SET_ABSTRACT:
        {
            last unless $abstract;
            $content =~ s{^#\s*ABSTRACT:.*}{# ABSTRACT: $abstract}m
                or die "Can't insert abstract for " . $file->name;
            $self->log(["inserting abstract for %s (%s)", $file->name, $abstract]);
            $file->content($content);
        } # SET_ABSTRACT

    } else {
    }

}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building App::perlmv and App::perlmv::scriptlet::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::perlmv - Plugin to use when building App::perlmv and App::perlmv::scriptlet::* distribution

=head1 VERSION

This document describes version 0.002 of Dist::Zilla::Plugin::perlmv (from Perl distribution Dist-Zilla-Plugin-perlmv), released on 2020-08-04.

=head1 SYNOPSIS

In F<dist.ini>:

 [perlmv]

=head1 DESCRIPTION

This plugin is to be used when building L<App::perlmv> and
C<App::perlmv::scriptlet::*> distributions. It currently does the following for
each F<lib/App/perlmv/scriptlet/*.pm> file:

=over

=item * Set abstract from scriptlet's summary

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-perlmv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::perlmv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
