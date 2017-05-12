package HTML::WidgetValidator::Widget::AlexaTrafficGraph;
use base qw(HTML::WidgetValidator::Widget);
use warnings;
use strict;
use Carp;

__PACKAGE__->name('Alexa Traffic Graph');
__PACKAGE__->url('http://www.alexa.com/site/site_stats/signup');
__PACKAGE__->models([
    [
        {
            type =>'start',
            name =>'script',
            attr => { type => 'text/javascript',
                      src  => 'http://widgets.alexa.com/traffic/javascript/graph.js' },
        },
        { type => 'end', name=>'script' }
    ],
    [
        {
            type => 'start',
            name => 'script',
            attr => { type => 'text/javascript', }
        },
        { type => 'text', text => qr{\s*/\*\s*<!\[CDATA\[\*/\s*//\s+USER-EDITABLE\s+VARIABLES\s+//\s+enter\s+up\s+to\s+3\s+domains,\s+separated\s+by\s+a\s+space\s*var\s+sites\s*=\s*\[\s*'[\w\.\-\/:\s]+'*\];\s*var\s+opts\s*=\s*\{\s*width:\s*\d+,\s*//\s+width\s+in\s+pixels\s+\(max\s+400\)\s*height:\s*\d+,\s*//\s*height\s+in\s+pixels\s+\(max\s+300\)\s*type:\s*'[rnp]',\s*//\s+"r"\s+Reach,\s+"n"\s+Rank,\s+"p"\s+Page\s+Views\s*range:\s*'(?:7d|1m|3m|6m|1y|3y|5y|max)',\s+//\s+"7d",\s+"1m",\s"3m",\s+"6m",\s+"1y",\s+"3y",\s+"5y",\s+"max"\s*bgcolor:\s+'[0-9A-Fa-f]{6}'\s+//\s+hex\s+value without\s+"#"\s+char\s+\(usually\s+"e6f3fc"\)\s*\};\s*//\s+END\s+USER\-EDITABLE\s+VARIABLES\s*AGraphManager\.add\(\s*new\s+AGraph\(sites,\s*opts\)\s*\);\s*//\]\]>},  },
        { type => 'end',  name =>'script', },
    ],
]);

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget::AlexaTrafficeGraph


=head1 SYNOPSIS

    my $validateor = HTML::WidgetValidator->new(widgets => [ 'AlexaTrafficeGraph' ]);
    my $result  = $validateor->validate($html);


=head1 DESCRIPTION

Validate Alexa Traffic Graph code.


=head1 SEE ALSO

L<HTML::WidgetValidator>,
L<http://www.alexa.com/site/site_stats/signup>


=head1 AUTHOR

higepon  C<< <higepon@hatena.ne.jp> >>


=head1 LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
