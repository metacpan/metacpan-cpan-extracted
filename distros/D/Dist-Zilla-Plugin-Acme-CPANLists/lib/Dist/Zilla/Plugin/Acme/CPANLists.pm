package Dist::Zilla::Plugin::Acme::CPANLists;

our $DATE = '2017-07-28'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

use File::Spec::Functions qw(catfile);

# either provide filename or filename+filecontent
sub _get_abstract_from_author_or_module_list {
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
    my $author_lists = \@{"$pkg\::Author_Lists"};
    my $module_lists = \@{"$pkg\::Module_Lists"};

    # find the first module or author list
    my $abstract_from_list;
    {
        for (@$module_lists, @$author_lists) {
            if ($_->{summary}) {
                return $_->{summary};
                last;
            }
        }
    }
    undef;
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
   open my $fh, '<', $filename or die "File ${filename} cannot open: $!";

   my $abstract = $self->_get_abstract_from_author_or_module_list($filename);
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

    my $abstract = $self->_get_abstract_from_author_or_module_list($file->name, $file->content);

  ADD_X_MENTIONS_PREREQS:
    {
        my $pkg = do {
            my $pkg = $file->name;
            $pkg =~ s!^lib/!!;
            $pkg =~ s!\.pm$!!;
            $pkg =~ s!/!::!g;
            $pkg;
        };
        no strict 'refs';
        #my $author_lists = \@{"$pkg\::Author_Lists"};
        my $module_lists = \@{"$pkg\::Module_Lists"};
        my @mods;
        for my $module_list (@$module_lists) {
            for my $entry (@{ $module_list->{entries} }) {
                push @mods, $entry->{module};
                for (@{ $entry->{alternate_modules} || [] }) {
                    push @mods, $_;
                }
            }
        }
        for my $mod (@mods) {
            $self->zilla->register_prereqs(
                {phase=>'x_mentions', type=>'x_mentions'}, $mod, 0);
        }
    }

  SET_ABSTRACT:
    {
        last unless $abstract;
        $content =~ s{^#\s*ABSTRACT:.*}{# ABSTRACT: $abstract}m
            or die "Can't insert abstract for " . $file->name;
        $self->log(["inserting abstract for %s (%s)", $file->name, $abstract]);
        $file->content($content);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Acme::CPANLists::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Acme::CPANLists - Plugin to use when building Acme::CPANLists::* distribution

=head1 VERSION

This document describes version 0.03 of Dist::Zilla::Plugin::Acme::CPANLists (from Perl distribution Dist-Zilla-Plugin-Acme-CPANLists), released on 2017-07-28.

=head1 SYNOPSIS

In F<dist.ini>:

 [Acme::CPANLists]

=head1 DESCRIPTION

This plugin is to be used when building C<Acme::CPANLists::*> distribution. It
currently does the following:

=over

=item * Fill the Abstract from the first module/author list's summary

=item * Add prereq to the mentioned modules (phase=x_mentions, relationship=x_mentions)

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Acme-CPANLists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Acme-CPANLists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Acme-CPANLists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists>

L<Pod::Weaver::Plugin::Acme::CPANLists>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
