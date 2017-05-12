package HTML::Robot::Scrapper::Reader::TestReader;
use Moose;
with 'HTML::Robot::Scrapper::Reader';
use Data::Printer;
use Digest::SHA qw(sha1_hex);

## The commented stuff is useful as example

has startpage => (
    is => 'rw',
    default => sub { return 'http://www.bbc.co.uk/'} ,
);

has array_of_data => ( is => 'rw', default => sub { return []; } );

has counter => ( is => 'rw', default => sub { return 0; } );

sub on_start {
    my ( $self ) = @_;
    $self->append( search => $self->startpage );
    $self->append( search => 'http://www.zap.com.br/' ); #iso-8859-1
    $self->append( search => 'http://www.uol.com.br/' );
    $self->append( search => 'http://www.google.com/' );
}

sub search {
    my ( $self ) = @_;
    my $title = $self->robot->parser->tree->findvalue( '//title' );
    my $h1 = $self->robot->parser->tree->findvalue( '//h1' );
    warn $title;
    warn p $self->robot->useragent->url ;
#   warn p $self->robot->parser->tree;
    warn p $self->robot;
#   warn $self->url;
#   $self->robot->writer->url( $self->url );
#   $self->robot->writer->title( $title );
#   $self->writer->html( sha1_hex($self->html_content) );
#   my $news = $self->tree->findnodes( '//div[@class="detalhes"]/h1/a' );
#   foreach my $item ( $news->get_nodelist ) {
#        my $url = $item->attr( 'href' );
#        $self->prepend( detail => $url ); #  append url on end of list
#   }
    push( @{ $self->array_of_data } , { title => $title, url => $self->robot->useragent->url, h1 => $h1 } );
}

sub on_link {
    my ( $self, $url ) = @_;
    return if $self->counter( $self->counter + 1 ) > 3;
    if ( $url =~ m{^http://www.bbc.co.uk}ig ) {
        $self->prepend( search => $url ); #  append url on end of list
    }
}


sub detail {
    my ( $self ) = @_;
#   warn $self->tree->findvalue( '//h1' );
#   $self->data->author( $self->tree->findvalue( '//div[@class="bb-md-noticia-autor"]' ) );
#   $self->data->webpage( $self->url );
#   $self->data->content( $content );
#   $self->data->title( $self->tree->findvalue( '//title' ) );
#   $self->data->meta_keywords( $self->tree->findvalue( '//meta[@name="keywords"]/@content' ) );
#   $self->data->meta_description( $self->tree->findvalue( '//meta[@name="description"]/@content' ) );
#   $self->data->save;
}

sub on_finish {
    my ( $self ) = @_;
    $self->robot->writer->save_data( $self->array_of_data );
}

1;
