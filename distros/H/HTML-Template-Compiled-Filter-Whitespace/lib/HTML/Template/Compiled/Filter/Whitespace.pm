package HTML::Template::Compiled::Filter::Whitespace; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.09';

use parent qw( Exporter::Tiny );

our @EXPORT_OK = qw(
    get_whitespace_filter
    whitespace_filter
);
our $DEBUG;

my $inplace_whitespace_filter = sub {
    my $scalarref = shift;

    return if $DEBUG;
    ${$scalarref} =~ tr{\0}{ };
    my @unclean;
    while (
        ${$scalarref} =~ s{(
            < \s* (pre | code | textarea) [^>]* > # opening pre-, code
                                                  # or textarea tag
            .*?                                   # content
            < \s* / \2 [^>]* >                    # closing tag
            )}{\0}xmsi
    ) {
        push @unclean, $1;
    }
    ${$scalarref} =~ s{
        (?: ^ \s*)              # leading spaces and empty lines
        |
        (?: [^\S\n]* $)
        |
        ([^\S\n]* (?: \n | \z)) # spaces at EOL
        |
        ([^\S\n]{2,})           # spaces between text
    }{ $1 ? "\n" : $2 ? q{ } : q{} }xmsge;
    for my $unclean (@unclean) {
        ${$scalarref} =~ s{\0}{$unclean}xms;
    }

    return;
};

sub get_whitespace_filter {
    return $inplace_whitespace_filter;
}

sub whitespace_filter {
    my $html = shift;

    $inplace_whitespace_filter->(\$html);

    return $html;
}

# $Id$

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Filter::Whitespace - whitespace filter for HTML output

=head1 VERSION

0.09

=head1 SYNOPSIS

To clean a string you can pass a scalar to the function whitespace_filter().

    use HTML::Template::Compiled::Filter::Whitespace qw(whitespace_filter);

    my $clean_html = whitespace_filter($unclean_html);

If you are using HTML::Template::Compiled and want to clean the Template before
parsing you can use the function get_whitespace_filter:

    use HTML::Template::Compiled::Filter::Whitespace qw(get_whitespace_filter);

    my $htc = HTML::Template::Compiled->new(
        tagstyle  => [qw(-classic -comment +asp)],
        filter    => get_whitespace_filter,
        scalarref => \$scalar,
    );

If you are using HTML::Template::Compiled and want to clean the output
do both or only this:

    use HTML::Template::Compiled::Filter::Whitespace qw(whitespace_filter);

    my $clean_html = whitespace_filter( $htc->output );

If you want to disable the filter set the global variable DEBUG to something true.

    $HTML::Template::Compiled::Filter::Whitespace::DEBUG = 1;

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

This package provides functions to clean out whitespaces and empty lines.

HTML tags pre, code and textarea will be unchanged.

=head1 SUBROUTINES/METHODS

=head2 get_whitespace_filter

This function returns the reference to a function to clean out HTML code from
whitespaces and empty lines. Can be used as filter in HTML::Template::Compiled.

=head2 whitespace_filter

This function returns a string clean from multiple whitespaces and empty lines.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Exporter::Tiny|Exporter::Tiny>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<HTML::Template::Compiled|HTML::Template::Compiled>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2016,
Steffen Winkler
C<< <steffenw at cpan.org> >>,
Volker Voit
C<< <volker.voit at googlemail.com> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
