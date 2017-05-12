package HTML::Template::Compiled::Plugin::VBEscape;

use strict;
use warnings;

our $VERSION = '0.03';

use HTML::Template::Compiled;

HTML::Template::Compiled->register(__PACKAGE__);

sub register {
    my $class = shift;

    my %plugs = (
        escape => {
            # <tmpl_var foo ESCAPE=VB>
            VB      => \&escape_vb,
            VB_ATTR => __PACKAGE__ . '::escape_vb',
        },
    );

    return \%plugs;
}

sub escape_vb {
    my $escaped = shift;

    defined $escaped or return;
    $escaped =~ s{"}{""}xmsg;

    return $escaped;
}

# $Id$

1;

__END__

=head1 NAME

HTML::Template::Compiled::Plugin::VBEscape - VB-Script-Escaping for HTC

=head1 VERSION

0.03

=head1 SYNOPSIS

    use HTML::Template::Compiled::Plugin::VBEscape;

    my $htc = HTML::Template::Compiled->new(
        plugin    => [qw(HTML::Template::Compiled::Plugin::VBEscape)],
        tagstyle  => [qw(-classic -comment +asp)],
        scalarref => \<<'EOVB');
    );
    <script language="VBScript"><!--
        string1 = "<%= attribute ESCAPE=VB%>"
        string2 = "<%= cdata ESCAPE=VB%>"
    '--></script>
    EOVB
    $htc->param(
        attribute => 'foo "bar"',
        cdata     => 'text "with" double quotes',
    );
    print $htc->output();

Output:

    <script language="VBScript"><!--
        string1 = "foo ""bar"""
        string2 = "text ""with"" double quotes"
    '--></script>

=head1 DESCRIPTION

VB-Script-Escaping for HTML::Template::Compiled

=head1 EXAMPLE

Inside of this Distribution is a directory named example. Run this *.pl files.

=head1 SUBROUTINES/METHODS

=over 4

=item register

gets called by HTC

=item escape_vb

Escapes data for VB CDATA or for VB attributes.

=back

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<HTML::Template::Compiled>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<HTML::Template::Compiled>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2009,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut