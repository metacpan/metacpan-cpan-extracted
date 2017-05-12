#!perl -T

use Test::More tests => 1;
# use Test::More "no_plan";

use HTML::DTD;

SKIP: {
    skip "Install XML::LibXML to run validation tests", 1
        unless eval "require XML::LibXML";

    my $html_dtd = HTML::DTD->new();
    ok( my $raw_dtd = $html_dtd->get_dtd("xhtml1-transitional.dtd"),
        'get_dtd("html-4-0-1-strict.dtd")' );

    my $dtd = XML::LibXML::Dtd->parse_string($raw_dtd);
}


__END__
    my $dtd = XML::LibXML::Dtd->new(
                                   "SOME // Public / ID / 1.0",
                                   "test.dtd"
                                             );

    $self->dtd( XML::LibXML::Dtd->parse_string($self->{ $self->config->{dtd} }) );
            unless ( eval { $xhtml->validate($self->dtd); 1; } )
