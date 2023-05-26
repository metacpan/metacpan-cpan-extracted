package Dist::Zilla::Plugin::OurDate;

use 5.010001;
use strict;
use warnings;

use POSIX ();

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules', ':ExecFiles' ],
    },
);

has date_format => (is => 'rw', default => sub { '%Y-%m-%d' });

use namespace::autoclean;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-07'; # DATE
our $DIST = 'Dist-Zilla-Plugin-OurDate'; # DIST
our $VERSION = '0.040'; # VERSION

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ( $self, $file ) = @_;

    if ( $file->name =~ m/\.pod$/ixms ) {
        $self->log_debug( 'Skipping: "' . $file->name . '" is pod only');
        return;
    }

    # so it doesn't differ from file to file
    state $date = POSIX::strftime($self->date_format, localtime());

    my $content = $file->content;

    my $end_pos = $content =~ /^(__DATA__|__END__)$/m ? $-[0] : undef;

    my $munged_date = 0;
    $content =~ s/
                     ^
                     (\s*)           # capture all whitespace before comment

                     (?:our [ ] \$DATE [ ] = [ ] '[^']+'; [ ] )?  # previously produced output
                     (
                         \#\s*DATE     # capture # DATE
                         \b            # and ensure it ends on a word boundary
                         [             # conditionally
                             [:print:]   # all printable characters after DATE
                             \s          # any whitespace including newlines see GH #5
                         ]*            # as many of the above as there are
                 )
                 $               # until the EOL}xm
                 /

                     !defined($end_pos) || $-[0] < $end_pos ?

                     "${1}our \$DATE = '$date'; $2"

                     :

                     $&

                     /emx and $munged_date++;

    if ( $munged_date ) {
        $self->log_debug([ 'adding $DATE assignment to %s', $file->name ]);
        $file->content($content);
    }
    else {
        $self->log_debug( 'Skipping: "'
                              . $file->name
                              . '" has no "# DATE" comment'
                          );
    }
    return;
}
__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: no line insertion and does Package release date with our

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::OurDate - no line insertion and does Package release date with our

=head1 VERSION

This document describes version 0.040 of Dist::Zilla::Plugin::OurDate (from Perl distribution Dist-Zilla-Plugin-OurDate), released on 2023-03-07.

=head1 SYNOPSIS

In F<dist.ini>:

	[OurDate]
	; optional, default is '%Y-%m-%d'
	date_format=%Y-%m-%d

in your modules:

	# DATE

or

	our $DATE = '2014-04-16'; # DATE

=head1 DESCRIPTION

This module is like L<Dist::Zilla::Plugin::OurVersion> except that it inserts
release date C<$DATE> instead of C<$VERSION>.

Comment/directive below C<__DATA__> or C<__END__> will not be replaced.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-OurDate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-OurDate>.

=head1 SEE ALSO

L<Dist::Zilla>

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

This software is copyright (c) 2023, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-OurDate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
