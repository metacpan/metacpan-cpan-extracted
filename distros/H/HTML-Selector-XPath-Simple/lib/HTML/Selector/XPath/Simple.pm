package HTML::Selector::XPath::Simple;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use HTML::Selector::XPath;
use HTML::TreeBuilder::XPath;

sub new {
    my $class = shift;
    bless {
	tree => HTML::TreeBuilder::XPath->new->parse( shift )->eof,
    }, $class;
}

sub select {
    my $self = shift;
    my $xpath = HTML::Selector::XPath->new( shift )->to_xpath;
    my @results = map { @{ $_->content } }
	               $self->{tree}->findnodes($xpath);
    return wantarray ? @results : $results[0];
}

1; # Magic true value required at end of module
__END__

=head1 NAME

HTML::Selector::XPath::Simple - Simple CSS Selector to XPath compiler


=head1 SYNOPSIS

    use HTML::Selector::XPath::Simple;

    my $xml =<<'END_XML';
    <div class="vcard">
      <span class="fn">Foo Bar</span>
      <span class="tel">
        <span class="type">home</span>
        <span class="value">+81-12-3456-7890</span>
      </span>
      <span class="tel">
        <span class="type">work</span>
        <span class="value">+81-98-7654-3210</span>
      </span>
    </div>
    END_XML

    my $selector = HTML::Selector::XPath::Simple->new($xml);

    print $selector->select('.vcard .fn'); # Foo Bar

    my @tel = $selector->select('.vcard .tel .value');
    print $tel[0]; # +81-12-3456-7890
    print $tel[1]; # +81-98-7654-3210


=head1 DESCRIPTION

B<HTML::Selector::XPath::Simple> is a simple utility to access XML/HTML
elements by using CSS selector.


=head1 METHODS

=head2 HTML::Selector::XPath::Simple->new($xml)

Creates a new parser object.
It is passed a XML/HTML document I<$xml>, which can be string or code
reference (see L<HTML::Parser>::parse).


=head2 select($expr)

Returns a XML/HTML elements indicated by I<$expr>.


=head1 SEE ALSO

L<HTML::Selector::XPath>


=head1 AUTHOR

Takeru INOUE  C<< <takeru.inoue _ gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
