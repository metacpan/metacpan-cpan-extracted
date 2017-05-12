package Dist::Zilla::Plugin::OurDist;

our $DATE = '2015-07-04'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010;
use strict;
use warnings;

use Moose;
with (
	'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	},
);

has date_format => (is => 'rw', default => sub { '%Y-%m-%d' });

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    my $content = $file->content;

    my $dist = $self->zilla->name;

    my $end_pos = $content =~ /^(__DATA__|__END__)$/m ? $-[0] : undef;

    my $munged_dist = 0;
    $content =~ s/
                     ^
                     (\s*)           # capture all whitespace before comment

                     (?:our [ ] \$DIST [ ] = [ ] '[^']+'; [ ] )?  # previously produced output
                     (
                         \#\s*DIST     # capture # DIST
                         \b            # and ensure it ends on a word boundary
                         [             # conditionally
                             [:print:]   # all printable characters after DIST
                             \s          # any whitespace including newlines see GH #5
                         ]*              # as many of the above as there are
                     )
                     $                 # until the EOL}xm
                 /

                     !defined($end_pos) || $-[0] < $end_pos ?

                     "${1}our \$DIST = '$dist'; $2"

                     :

                     $&


                     /emx and $munged_dist++;

    if ($munged_dist) {
        $self->log_debug(['adding $DIST assignment to %s', $file->name]);
        $file->content($content);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add a $DIST to your packages (no line insertion)

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::OurDist - Add a $DIST to your packages (no line insertion)

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::OurDist (from Perl distribution Dist-Zilla-Plugin-OurDist), released on 2015-07-04.

=head1 SYNOPSIS

in F<dist.ini>:

 [OurDist]

in your modules/scripts:

 our $DIST = 'Dist-Zilla-Plugin-OurDist'; # DIST

or

 our $DIST = 'Some-Dist'; # DIST

=head1 DESCRIPTION

This module is like L<Dist::Zilla::Plugin::PkgDist> except that it looks for
comments C<# DIST> and put the C<$DIST> assignment there instead of adding
another line. The principle is the same as in L<Dist::Zilla::Plugin::OurVersion>
(instead of L<Dist::Zilla::Plugin::PkgVersion>).

Comment/directive below C<__DATA__> or C<__END__> will not be replaced.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-OurDist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-OurDist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OurDist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
