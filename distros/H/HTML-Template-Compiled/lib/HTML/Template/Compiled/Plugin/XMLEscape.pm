package HTML::Template::Compiled::Plugin::XMLEscape;
use strict;
use warnings;
use Carp qw(croak carp);
use HTML::Template::Compiled;
HTML::Template::Compiled->register(__PACKAGE__);
our $VERSION = '1.003'; # VERSION

sub register {
    my ($class) = @_;
    my %plugs = (
        escape => {
            # <tmpl_var foo escape=XML>
            XML => \&escape_xml,
            XML_ATTR => 'HTML::Template::Compiled::Plugin::XMLEscape::escape_xml_attr',
        },
    );
    return \%plugs;
}

sub escape_xml {
    defined( my $escaped = $_[0] ) or return;
    $escaped =~ s/&/&#x26;/g;
    $escaped =~ s/</&#x3C;/g;
    $escaped =~ s/>/&#x3E;/g;
    $escaped =~ s/"/&#x22;/g;
    $escaped =~ s/'/&#x27;/g;
    return $escaped;
}

sub escape_xml_attr {
    defined( my $escaped = $_[0] ) or return;
    $escaped =~ s/&/&#x26;/g;
    $escaped =~ s/</&#x3C;/g;
    $escaped =~ s/>/&#x3E;/g;
    $escaped =~ s/"/&#x22;/g;
    $escaped =~ s/'/&#x27;/g;
    return $escaped;
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::XMLEscape - XML-Escaping for HTC

=head1 SYNOPSIS

    use HTML::Template::Compiled::Plugin::XMLEscape;

    my $htc = HTML::Template::Compiled->new(
        plugin => [qw(HTML::Template::Compiled::Plugin::XMLEscape)],
        ...
    );

=head1 METHODS

=over 4

=item register

gets called by HTC

=item escape_xml

escapes data for XML CDATA.

=item escape_xml_attr

escapes data for XML attributes

=back

=head1 EXAMPLE

    use HTML::Template::Compiled::Plugin::XMLEscape;
    my $htc = HTML::Template::Compiled->new(
        plugin => [qw(HTML::Template::Compiled::Plugin::XMLEscape)],
        tagstyle => [qw(-classic -comment -asp +tt)],
        scalarref => \'<foo attr="[%= attribute %]">[%= cdata escape=XML %]</foo>',
        default_escape => 'XML_ATTR',
    );
    $htc->param(
        attr => 'foo & bar',
        cdata => 'text < with > tags',
    );
    print $htc->output;

Output:

    <foo attr="foo &amp; bar">text &lt; with &gt; tags</foo>

=cut

