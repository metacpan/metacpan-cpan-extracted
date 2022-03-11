package Dist::Zilla::Role::RequireFromBuild;

use strict;
use warnings;
use 5.010001;
use Moose::Role;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-19'; # DATE
our $DIST = 'Dist-Zilla-Role-RequireFromBuild'; # DIST
our $VERSION = '0.007'; # VERSION

sub require_from_build {
    my $self = shift;
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my ($name) = @_;

    if ($name =~ /::/) {
        $name =~ s!::!/!g;
        $name .= ".pm";
    }

    if (exists $INC{$name} && !$opts->{reload}) {
        $self->log_debug(["Module %s has been loaded(%%INC entry: %s), skipped require-ing", $name, $INC{$name}]);
        return;
    }

    my @files = grep { $_->name eq "lib/$name" } @{ $self->zilla->files };
    @files    = grep { $_->name eq $name }       @{ $self->zilla->files }
        unless @files;
    die "Can't find $name in lib/ or ./ in build files" unless @files;

    my $file = $files[0];
    my $filename = $file->name;
    eval "# line 1 \"$filename (from dist build)\"\n" . $file->encoded_content; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die if $@;
    $INC{$name} = "(set by ".__PACKAGE__.", from build files)";
}

no Moose::Role;
1;
# ABSTRACT: Role to require() from build files

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::RequireFromBuild - Role to require() from build files

=head1 VERSION

This document describes version 0.007 of Dist::Zilla::Role::RequireFromBuild (from Perl distribution Dist-Zilla-Role-RequireFromBuild), released on 2022-02-19.

=head1 SYNOPSIS

In your plugin's preamble, include the role:

 with 'Dist::Zilla::Role::RequireFromBuild';

Then in your plugin subroutine, e.g. C<munge_files()>:

 $self->require_from_build("Foo/Bar.pm");
 $self->require_from_build("Baz::Quux");

=head1 DESCRIPTION

Since build files are not necessarily on-disk files, but might also be in-memory
files or files with munged content, we cannot use C<require()> directly.
C<require_from_build()> is like Perl's C<require()> except it looks for files
not from C<@INC> but from build files C<< $self->zilla->files >>. It searches
libraries in C<lib/> and C<.>.

C<< $self->require_from_build("Foo/Bar.pm") >> or C<<
$self->require_from_build("Foo::Bar") >> is a convenient shortcut for something
like:

 return if exists $INC{"Foo/Bar.pm"};

 my @files = grep { $_->name eq "lib/Foo/Bar.pm" } @{ $self->zilla->files };
 @files    = grep { $_->name eq "Foo/Bar.pm" }     @{ $self->zilla->files } unless @files;
 die "Can't find Foo/Bar.pm in lib/ or ./ in build files" unless @files;

 eval $files[0]->encoded_content;
 die if $@;

 $INC{"Foo/Bar.pm"} = "(set by Dist::Zilla::Role::RequireFromBuild, loaded from build file)";

=head1 PROVIDED METHODS

=head2 $obj->require_from_build( [ \%opts , ] $file)

Known options:

=over

=item * reload

Bool. Optional, default false. If set to true, will reload the module even if
it's already loaded.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Role-RequireFromBuild>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Role-RequireFromBuild>.

=head1 SEE ALSO

L<Require::Hook::DzilBuild>

L<Pod::Weaver::Role::RequireFromBuild>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-RequireFromBuild>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
