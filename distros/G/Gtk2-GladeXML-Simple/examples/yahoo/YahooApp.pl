package YahooApp;

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Html2;
use Gtk2::GladeXML::Simple;
use WWW::Search;

use base qw( Gtk2::GladeXML::Simple );

my $header =<<HEADER;
<html>
<meta HTTP-EQUIV="content-type" CONTENT="text/html; charset=UTF-8">
<header><title>Yahoo Gtk2 App</title>
<style type="text/css">
.title {font-family: Georgia; color: blue; font-size: 13px}
.description {padding-left: 3px; font-family: Georgia; font-size:10px}
.url {padding-left: 3px; font-family: Georgia; font-size:10px; color: green}
</style>
</head>
<body>
<h2 style="font-family: Georgia, Arial; font-weight: bold">
Found:
</h2>
HEADER

my $footer =<<FOOTER;
</body>
</html>
FOOTER

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( 'yahoo.glade' );
    $self->{_yahoo} = WWW::Search->new( 'Yahoo' );
    return $self;
}

sub do_search {
    my $self = shift;
    $self->{_yahoo}->native_query( shift );
    my $buf = $header;
    for( 1..10 ) {
	my $rv = $self->{_yahoo}->next_result || last;
	$buf .= qq{<p><div class="title">} . $rv->title;
	$buf .= qq{</div><br /><div class="description">} . $rv->description;
	$buf .= qq{</div><br /><div class="url">} . $rv->url . q{</div></p><br />};
    }
    $buf .= $footer;
    $self->{buf} = $buf;
}

sub on_Clear_clicked {
    my $self = shift;
    my $html = $self->{custom1};
    $html->{document}->clear;
    my $statusbar = $self->{statusbar1};
    $statusbar->pop( $statusbar->get_context_id( "Yahoo" ) );
}

sub on_Search_clicked {
    my $self = shift;
    my $text_entry = $self->{entry1};
    my $text = $text_entry->get_text;
    return unless $text ne '';
    my $statusbar = $self->{statusbar1};
    $statusbar->push( $statusbar->get_context_id( "Yahoo" ), "Searching for: $text" );
    $self->do_search( $text );
    my $html = $self->{custom1};
    $html->{document}->clear;
    $html->{document}->open_stream( "text/html" );
    $html->{document}->write_stream( $self->{buf} );
    $html->{document}->close_stream;
}

sub create_htmlview {
    my $self = shift;
    my $view = Gtk2::Html2::View->new;
    my $document = Gtk2::Html2::Document->new;
    $view->set_document( $document );
    $view->{document} = $document;
    $view->show_all;
    return $view;
}

sub gtk_main_quit { Gtk2->main_quit }

1;

package main;

YahooApp->new->run;

1;
