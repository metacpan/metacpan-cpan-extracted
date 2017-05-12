use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::Runtime - Default functions that can be invoked from JavaScript

=cut

package EJS::Template::Runtime;
use base 'EJS::Template::Base';

use URI::Escape;

our @EJS_FUNCTIONS = qw(
    concat
    escapeHTML
    escapeXML
    escapeURI
    escapeQuote
);

our %ESCAPES = qw(
    raw   concat
    html  escapeHTML
    xml   escapeXML
    uri   escapeURI
    quote escapeQuote
);

=head1 Methods

=head2 make_map

=cut

sub make_map {
    my ($self) = @_;
    my $class = ref $self || $self;
    my $map = {};
    
    for my $name (@EJS_FUNCTIONS) {
        $map->{$name} = \&{$class.'::'.$name};
    }
    
    return $map;
}

=head2 concat

=cut

sub concat {
    return join('', @_);
}

=head2 escapeHTML

=cut

my $html_map = {
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&#39;',
    '&' => '&amp;',
};

sub escapeHTML {
    return join('', map {
        s/([<>&"'])/$html_map->{$1}/g;
        $_;
    } @_);
}

=head2 escapeXML

=cut

my $xml_map = {
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&apos;',
    '&' => '&amp;',
};

sub escapeXML {
    return join('', map {
        s/([<>&"'])/$xml_map->{$1}/g;
        $_;
    } @_);
}

=head2 escapeURI

=cut

sub escapeURI {
    return join('', map {uri_escape($_)} @_);
}

=head2 escapeQuote

=cut

sub escapeQuote {
    return join('', map {
        s/(["'])/\\$1/g;
        $_;
    } @_);
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
