#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Templates/File.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Templates.
#
#   perl-Dist-Zilla-Plugin-Templates is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Templates is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Templates. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for test_synopsis BEGIN { die "SKIP: Not Perl code.\n" };
#pod
#pod =head1 SYNOPSIS
#pod
#pod In a template:
#pod
#pod     {{ include( 'as-is.txt' ); }}
#pod     {{ include( 'verbatim.txt' )->indent; }}
#pod     {{ include( 'template.txt' )->fill_in; }}
#pod     {{ include( 'readme.pod' )->pod2text; }}
#pod     {{ include( 'assa.txt' )->chomp->trim->indent; }}
#pod     …
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a helper module for C<Dist::Zilla::Templates>. It provides few frequently used operations
#pod on include files.
#pod
#pod Usually objects are created by "include" function (see
#pod L<Dist::Zilla::Plugin::Templates/"include">).
#pod
#pod The object evaluated in string context returns the file content, so
#pod
#pod     $file->content
#pod
#pod and
#pod
#pod     "$file"
#pod
#pod produces the same result.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role::FileFinderUser>
#pod = L<Dist::Zilla::Role::TextTemplater>
#pod = L<Text::Template>
#pod = L<Pod::Text>
#pod = L<Dist::Zilla::Plugin::Templates::Manual>
#pod
#pod =cut

package Dist::Zilla::Plugin::Templates::File;

use Moose;
use namespace::autoclean 0.16;
    # ^ `namespace::autoclean` pre-0.16 wipes out overloads,
    #   see <https://rt.cpan.org/Ticket/Display.html?id=50938>.
use version 0.77;

# ABSTRACT: Frequently used operations on include files
our $VERSION = 'v0.6.4'; # VERSION

extends 'Dist::Zilla::File::InMemory';

use overload '""' => sub {
    my ( $self ) = @_;
    return $self->content;
};

use Pod::Text qw{};     # `Pod::Text` exports `pod2text` by default. Let us avoid it.
use Carp qw{ croak };

# --------------------------------------------------------------------------------------------------

#pod =attr _plugin
#pod
#pod Reference to the plugin created this object.
#pod
#pod C<Object>, read-only.
#pod
#pod =cut

has _plugin => (
    isa         => 'Object',
    is          => 'ro',
    weak_ref    => 1,
);

# --------------------------------------------------------------------------------------------------

#pod =method chomp
#pod
#pod     $file->chomp();
#pod     $file->chomp( $count );
#pod
#pod Chomps the file content C<$count> times. If C<$count> is not specified, the method chomps all the
#pod trailing newlines (more exactly: all the trailing input record separators; see core function
#pod C<chomp> for details).
#pod
#pod Note: The methods chomps newlines from the end of file, I<not> from each line.
#pod
#pod The method returns C<$self> for chaining.
#pod
#pod =cut

sub chomp {                             ## no critic ( ProhibitBuiltinHomonyms )
    my ( $self, $count ) = @_;
    my $content = $self->content;
    if ( not defined( $count ) ) {
        $count = -1;
    };
    while ( $count and CORE::chomp( $content ) ) {
        -- $count;
    };
    $self->content( $content );
    return $self;
};

# --------------------------------------------------------------------------------------------------

#pod =method fill_in
#pod
#pod     $file->fill_in();
#pod     $file->fill_in( \%variables, \%extra_args );
#pod
#pod Calls plugin's C<fill_in_file> method (which is defined in C<TextTemplater> role), passing C<$self>
#pod as the first argument. Returns C<$self>.
#pod
#pod Primary purpose of the method is including a file which is template itself:
#pod
#pod     {{ include( 'doc/chapter1.pod' )->fill_in; }}
#pod
#pod Without C<fill_in>, F<doc/chapter1.pod> is included as-is, Perl code fragments, if any, are not
#pod evaluated.
#pod
#pod See L<Dist::Zilla::Role::TextTemplater/"fill_in_file">.
#pod
#pod =cut

# TODO: Pass arguments recursively?

sub fill_in {
    my ( $self, @args ) = @_;
    $self->_plugin->fill_in_file( $self, @args );
    return $self;
};

# --------------------------------------------------------------------------------------------------

#pod =method indent
#pod
#pod     $file->indent();
#pod     $file->indent( $size );
#pod
#pod Indents file content by inserting specified number of spaces to the beginning of every non-empty
#pod line. By default, file is indented with 4 spaces. The method returns C<$self> for chaining.
#pod
#pod Primary purpose of the method is including a file into POD as verbatim paragraph(s):
#pod
#pod     =head2 example.pl
#pod
#pod     {{ include( 'ex/example.pl' )->indent; }}
#pod
#pod     =cut
#pod
#pod =cut

sub indent {
    my ( $self, $size ) = @_;
    my $indent  = ' ' x ( defined( $size ) ? $size : 4 );
    my $content = $self->content;
    $content =~ s{^(?!$)}{$indent}gmx;
    $self->content( $content );
    return $self;
};

# --------------------------------------------------------------------------------------------------

#pod =method munge
#pod
#pod     $file->munge( \&func );
#pod     $file->munge( sub { …modify $_ here… } );
#pod
#pod Calls the specified function. File content is passed to the function in C<$_> variable. Return
#pod value of the function is ignored. Value of C<$_> variable becomes new file content. The method
#pod returns C<$self> for chaining.
#pod
#pod =cut

sub munge {
    my ( $self, $sub ) = @_;
    local $_ = $self->content;
    $sub->();
    $self->content( $_ );
    return $self;
};

# --------------------------------------------------------------------------------------------------

#pod =method pod2text
#pod
#pod     $file->pod2text( %options );
#pod
#pod Converts POD to plain text. It is a simple wrapper over C<Pod::Text>. See documentation on
#pod C<Pod::Text::new> for description of available options. The method returns C<$self> for chaining.
#pod
#pod Example:
#pod
#pod     {{ include( 'readme.pod' )->pod2text( width => 80, quotes => 'none', loose => 1 ); }}
#pod
#pod See L<Pod::Text/"DESCRIPTION">.
#pod
#pod =cut

sub pod2text {
    my ( $self, %opts ) = @_;
    my $name = $self->name;
    my $parser = Pod::Text->new( %opts );
    my ( $text, $errata );
    $parser->output_string( \$text );
    if ( $parser->can( 'errata_seen' ) ) {
        $parser->complain_stderr( 0 );
        $parser->parse_string_document( $self->content );
        $errata = $parser->errata_seen;
    } else {
        # Now do a dirty hack. `Pod::Simple` parser prior to 3.32 either print messages to `STDERR`
        # or creates a section at the end of the document. There is no simple way to get error
        # messages. Let us redefine its `_complain_warn` function to catch error messages.
        $parser->complain_stderr( 1 );
        no warnings 'redefine';                         ## no critic ( ProhibitNoWarnings )
        local *Pod::Simple::_complain_warn = sub {      ## no critic ( ProtectPrivateVars )
            my ( undef, $line, $msg ) = @_;
            push( @{ $errata->{ $line } }, $msg );
        };
        # Ok, now parse POD and reports errors, if any:
        $parser->parse_string_document( $self->content );
    };
    ## no critic ( RequireCarping )
    if ( $parser->any_errata_seen ) {
        for my $line ( sort( keys( %$errata ) ) ) {
            warn "$_ at $name line $line.\n" for @{ $errata->{ $line } };
        };
        #   TODO: Use `log_errors_in_file` to repot POD errors?
        die "POD errata found at $name.\n";
    };
    if ( not $parser->content_seen ) {
        die "No POD content found at $name.\n";
    };
    ## critic ( RequireCarping )
    $self->content( $text );
    return $self;
};

# --------------------------------------------------------------------------------------------------

#pod =method trim
#pod
#pod     $file->trim();
#pod
#pod Trims trailing whitespaces from every line. The method returns C<$self> for chaining.
#pod
#pod =cut

sub trim {
    my ( $self ) = @_;
    my $content = $self->content;
    $content =~ s{(?:(?!\n)\s)+$}{}gmx;
    $self->content( $content );
    return $self;
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Templates::File - Frequently used operations on include files

=head1 VERSION

Version v0.6.4, released on 2016-12-28 20:24 UTC.

=for test_synopsis BEGIN { die "SKIP: Not Perl code.\n" };

=head1 SYNOPSIS

In a template:

    {{ include( 'as-is.txt' ); }}
    {{ include( 'verbatim.txt' )->indent; }}
    {{ include( 'template.txt' )->fill_in; }}
    {{ include( 'readme.pod' )->pod2text; }}
    {{ include( 'assa.txt' )->chomp->trim->indent; }}
    …

=head1 DESCRIPTION

This is a helper module for C<Dist::Zilla::Templates>. It provides few frequently used operations
on include files.

Usually objects are created by "include" function (see
L<Dist::Zilla::Plugin::Templates/"include">).

The object evaluated in string context returns the file content, so

    $file->content

and

    "$file"

produces the same result.

=head1 OBJECT ATTRIBUTES

=head2 _plugin

Reference to the plugin created this object.

C<Object>, read-only.

=head1 OBJECT METHODS

=head2 chomp

    $file->chomp();
    $file->chomp( $count );

Chomps the file content C<$count> times. If C<$count> is not specified, the method chomps all the
trailing newlines (more exactly: all the trailing input record separators; see core function
C<chomp> for details).

Note: The methods chomps newlines from the end of file, I<not> from each line.

The method returns C<$self> for chaining.

=head2 fill_in

    $file->fill_in();
    $file->fill_in( \%variables, \%extra_args );

Calls plugin's C<fill_in_file> method (which is defined in C<TextTemplater> role), passing C<$self>
as the first argument. Returns C<$self>.

Primary purpose of the method is including a file which is template itself:

    {{ include( 'doc/chapter1.pod' )->fill_in; }}

Without C<fill_in>, F<doc/chapter1.pod> is included as-is, Perl code fragments, if any, are not
evaluated.

See L<Dist::Zilla::Role::TextTemplater/"fill_in_file">.

=head2 indent

    $file->indent();
    $file->indent( $size );

Indents file content by inserting specified number of spaces to the beginning of every non-empty
line. By default, file is indented with 4 spaces. The method returns C<$self> for chaining.

Primary purpose of the method is including a file into POD as verbatim paragraph(s):

    =head2 example.pl

    {{ include( 'ex/example.pl' )->indent; }}

    =cut

=head2 munge

    $file->munge( \&func );
    $file->munge( sub { …modify $_ here… } );

Calls the specified function. File content is passed to the function in C<$_> variable. Return
value of the function is ignored. Value of C<$_> variable becomes new file content. The method
returns C<$self> for chaining.

=head2 pod2text

    $file->pod2text( %options );

Converts POD to plain text. It is a simple wrapper over C<Pod::Text>. See documentation on
C<Pod::Text::new> for description of available options. The method returns C<$self> for chaining.

Example:

    {{ include( 'readme.pod' )->pod2text( width => 80, quotes => 'none', loose => 1 ); }}

See L<Pod::Text/"DESCRIPTION">.

=head2 trim

    $file->trim();

Trims trailing whitespaces from every line. The method returns C<$self> for chaining.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::FileFinderUser>

=item L<Dist::Zilla::Role::TextTemplater>

=item L<Text::Template>

=item L<Pod::Text>

=item L<Dist::Zilla::Plugin::Templates::Manual>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
