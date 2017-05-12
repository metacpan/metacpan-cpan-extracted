package Locale::Maketext::Extract::Plugin::XSL;

use warnings;
use strict;

use base qw(Locale::Maketext::Extract::Plugin::Base);
use Carp qw(croak);
use Regexp::Common;
use XML::LibXML;
use XML::LibXML::XPathContext;

=head1 NAME

Locale::Maketext::Extract::Plugin::XSL - XSL file parser

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

    my $ext = Locale::Maketext::Extract->new(
                plugins => {'Locale::Maketext::Extract::Plugin::XSL' => '*'} );
    $ext->extract_file('test.xsl');
    $ext->compile();

    or perhaps more convenient:

    xgettext.pl -P Locale::Maketext::Extract::Plugin::XSL <files>


=head1 DESCRIPTION

Extracts strings to localise from XSL stylesheet files.

Using Perl, custom localisation functions may be registered using
L<XML::LibXSLT/register_function>->register_function().

=head1 KNOWN FILE TYPES

=over 4

=item .xsl

=item .xslt

=back

=head1 VALID FORMATS

This plugin will check for localisation functions in all attribute values of the XSL document.
Valid localisation function names are:

=over 4

=item loc

=item locfrag

=item l

=item lfrag

=back

Note that only the local-name for the function will be checked for. Namespace prefixes
will be ignored. I.e. <xsl:value-of select="i18n:loc('Hello World')"/> and
<xsl:value-of select="sth:loc('Hello World')"/> will be treated the same.

=head1 FUNCTIONS

=head2 file_types

File types this plugin should handle

=cut
sub file_types {
    return qw( xsl xslt );
}


=head2 extract

Extraction function. Parses XSL document and adds localisation entries

=cut
sub extract {
    my ($self,$filecontent) = @_;

    my $parser = XML::LibXML->new();
    $parser->load_ext_dtd(0);

    my $doc;
    eval {
        $doc = $parser->parse_string( $filecontent );
    };
    if ( $@ ) {
        croak( "Could not parse input string: $@\n" );
    }

    my $xc = XML::LibXML::XPathContext->new($doc);
    $xc->registerNs('xsl', 'http://www.w3.org/1999/XSL/Transform');
    my @nodes = $xc->findnodes('//@*[contains(.,":loc(") or contains(.,":l(") or contains(.,":locfrag(") or contains(.,":lfrag(")]');
    foreach my $node (@nodes) {
        $self->_parse_expression( $node->value() );
    }

    return;
}

=head2 _parse_expression

Extract loc functions from XPATH expressions

=cut
sub _parse_expression {
    my ($self, $value) = @_;

    while (
            $value =~ /$RE{balanced}{-begin => ':loc|:locfrag|:l|:lfrag'}{-keep}/gx
           ) {
        my $str = substr($1,1,length($1)-2); # remove wrapping parens

        # $Re{balanced} will match the outermost parens only, -begin does not work
        # as (I) expected, so...
        # If the expression includes more than one loc function, recurse
        if (
            $str =~ /\:l(?:oc)?(?:frag)?\(/x
           ) {
            $self->_parse_expression( $str );
        }
        else {
            my @data;
            while ($str =~ /$RE{quoted}{-keep}/gx ) {
                push @data, substr($1,1,length($1)-2); # remove wrapping quotes
            }
            $self->add_entry(shift @data,  undef, join(',', @data));
        }
    }

    return 1;
}

=head1 SEE ALSO

=over 4

=item L<xgettext.pl>

for extracting translatable strings from common template
systems and perl source files.

=item L<Locale::Maketext::Lexicon>

=item L<Locale::Maketext::Plugin::Base>

=item L<Locale::Maketext::Plugin::FormFu>

=item L<Locale::Maketext::Plugin::Perl>

=item L<Locale::Maketext::Plugin::TT2>

=item L<Locale::Maketext::Plugin::YAML>

=item L<Locale::Maketext::Plugin::Mason>

=item L<Locale::Maketext::Plugin::TextTemplate>

=item L<Locale::Maketext::Plugin::Generic>

=item L<XML::LibXSLT>

=back


=head1 AUTHOR

Michael Kroell, C<< <pepl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-locale-maketext-extract-plugin-xsl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Maketext-Extract-Plugin-XSL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Maketext::Extract::Plugin::XSL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Maketext-Extract-Plugin-XSL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Locale-Maketext-Extract-Plugin-XSL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-Maketext-Extract-Plugin-XSL>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-Maketext-Extract-Plugin-XSL>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT

Copyright 2008-2011 Michael Kroell, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Locale::Maketext::Extract::Plugin::XSL
