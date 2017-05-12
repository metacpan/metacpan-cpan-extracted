package HTML::Robot::Scrapper;
use Moose;
#use Class::Load ':all';
use Data::Dumper;
use Data::Printer;
use Try::Tiny;
use HTML::Robot::Scrapper::Benchmark::Default;
use HTML::Robot::Scrapper::Log::Default;
use HTML::Robot::Scrapper::Parser::Default;
use HTML::Robot::Scrapper::Queue::Default;
use HTML::Robot::Scrapper::UserAgent::Default;
use HTML::Robot::Scrapper::Encoding::Default;

our $VERSION     = '0.11';

=head1 ATTRIBUTES

=cut

=head2 reader

this attribute access your reader class instance

=cut
has reader => (
    is      => 'rw',
#   default => sub {
#       
#   },
);

=head2 writer

this attribute accesses your writer class instance

=cut
has  writer => (
    is      => 'rw',
#   default => sub {
#   },
);

=head2 benchmark

not ready, i want a catalyst type of method tree like debug for each method for each request

=cut
has benchmark => (
    is      => 'rw',
    default => sub {
        HTML::Robot::Scrapper::Benchmark::Default->new();
    },
);
=head2 chache

the cache works, with CHI however its only useful right now for GET requests for specific urls. 
using the cache you will not need to download the page each time, so its good for dev

=cut
has cache => (
    is      => 'rw',
#   default => sub {
#       HTML::Robot::Scrapper::Cache::Default->new();
#   },
);
=head2 log

the log is not ready yet however it will be log4perl

=cut
has log => (
    is      => 'rw',
    default => sub {
        HTML::Robot::Scrapper::Log::Default->new();
    },
);
=head2 parser

The default parser reads content types:

  - text/html with HTML::TreeBuilder::XPath

which is in file: lib/HTML/Robot/Scrapper/Parser/HTML/TreeBuilder/XPath.pm

  - text/xml with XML::XPath  

which is in file: lib/HTML/Robot/Scrapper/Parser/XML/XPath.pm

and the parser is:

  -base: lib/HTML/Robot/Scrapper/Parser/Base.pm

  override with:

  my $robot = HTML::Robot::Scrapper->new (
    ....
    log       => {
        base_class => 'HTML::Robot::Scrapper::Log::Base', #optional, your custom base class
        class => 'Default' #or HTML::Robot::Scrapper::Log::Default
    },
    ...
  )

  -default: lib/HTML/Robot/Scrapper/Parser/Default.pm

=cut
has parser => (
    is      => 'rw',
    default => sub {
        HTML::Robot::Scrapper::Parser::Default->new();
    },
);
=head2 queue

base_class: lib/HTML/Robot/Scrapper/Queue/Base.pm

default class: lib/HTML/Robot/Scrapper/Queue/Default.pm (Simple Instance Array)

you can override the whole thing using a custom base_class, or simply use 

a different class

  my $robot = HTML::Robot::Scrapper->new (
    ....
    queue     => {
        base_class => 'HTML::Robot::Scrapper::Queue::Base',
        class => 'HTML::Robot::Scrapper::Queue::Default'
    },
    ...
  )

=cut
has queue => (
    is      => 'rw',
    default => sub {
        HTML::Robot::Scrapper::Queue::Default->new();
    },
);

=head2 useragent
=cut
has useragent => (
    is      => 'rw',
    default => sub {
        HTML::Robot::Scrapper::UserAgent::Default->new();
    },
);

=head2 encoding
=cut
has encoding => (
    is      => 'rw',
    default => sub {
        HTML::Robot::Scrapper::Encoding::Default->new();
    },
);


has custom_attrs => (
    is      => 'rw',
    default => sub {
      return [qw/benchmark cache log parser queue useragent encoding/];
    }
); 

=head2 new

    my $robot = HTML::Robot::Scrapper->new (
        reader    => HTML::Robot::Scrapper::Reader::TestReader->new,
        writer    => HTML::Robot::Scrapper::Writer::TestWriter->new,
    #   cache     => CHI->new(
    #                   driver => 'BerkeleyDB',
    #                   root_dir => dir( getcwd() , "cache" ),
    #           ),
    #   log       => HTML::Robot::Scrapper::Log::Default->new(),
    #   parser    => HTML::Robot::Scrapper::Parser::Default->new(),
    #   queue     => HTML::Robot::Scrapper::Queue::Default->new(),
    #   useragent => HTML::Robot::Scrapper::UserAgent::Default->new(),
    #   encoding  => HTML::Robot::Scrapper::Encoding::Default->new(),
    );

=cut



=head2 before 'start'

    - give access to this class inside other custom classes

=cut

before 'start' => sub {
    my ( $self ) = @_;
    foreach my $attr ( @{ $self->custom_attrs } ) {
        #give access to this class inside other classes
        $self->$attr->robot( $self ) if defined $self->$attr and $self->$attr->can( "robot" );
    }
    $self->reader->robot( $self );
};

sub start {
    my ( $self ) = @_;
    $self->reader->on_start( $self );
    my $counter = 0;
    while ( my $item = $self->queue->queue_get_item ) {
        $self->benchmark->method_start('finish_in');

        print '--[ '.$counter++.' ]------------------------------------------------------------------------------'."\n";
        print ' url: '. $item->{ url }."\n" if exists $item->{ url };
        my $method = $item->{ method };
        my $res = $self->useragent->visit($item);

        #clean up&set passed_key_values
        $self->reader->passed_key_values( {} );
        $self->reader->passed_key_values( $item->{passed_key_values} )
            if exists $item->{passed_key_values};

        #clean up&set passed_key_values
        $self->reader->headers( {} );
        $self->reader->headers( $res->{headers} )
            if exists $res->{headers};

        #TODO: set the cookies in $self->reader->cookies
        # that way its possible to use and update 1 same cookie

        
        $self->benchmark->method_start( $method );
        try {
          $self->reader->$method( );
        } catch {
          warn "ERROR on reader->$method: $_";
        };
        $self->benchmark->method_finish( $method );

        $self->benchmark->method_finish('finish_in', 'Total: ' );
    }
    $self->reader->on_finish( );
}

=head1 NAME

HTML::Robot::Scrapper - Your robot to parse webpages

=head1 SYNOPSIS

See a working example under the module: WWW::Tabela::Fipe ( search on github ). 

The class

    HTML::Robot::Scrapper::Parser::Default

handles only text/html and text/xml by default

So i need to add an extra option for text/plain and tell it to use 

the same method that already parses text/html, here is an example:

* im using the code from the original as base class for this: 

    HTML::Robot::Scrapper::Parser::Default

Here i will redefine that class and tell my $robot to favor it

    ...
    parser => WWW::Tabela::Fipe::Parser->new,
    ...

See below:

    package  WWW::Tabela::Fipe::Parser;
    use Moo;

    has [qw/engine robot/] => ( is => 'rw' );

    with('HTML::Robot::Scrapper::Parser::HTML::TreeBuilder::XPath'); 
    with('HTML::Robot::Scrapper::Parser::XML::XPath'); 

    sub content_types {
        my ( $self ) = @_;
        return {
            'text/html' => [
                {
                    parse_method => 'parse_xpath',
                    description => q{
                        The method above 'parse_xpath' is inside class:
                        HTML::Robot::Scrapper::Parser::HTML::TreeBuilder::XPath
                    },
                }
            ],
            'text/plain' => [
                {
                    parse_method => 'parse_xpath',
                    description => q{
                        esse site da fipe responde em text/plain e eu preciso parsear esse content type.
                        por isso criei esta classe e passei ela como parametro, sobreescrevendo a classe 
                        HTML::Robot::Scrapper::Parser::Default
                    },
                }
            ],
            'text/xml' => [
                {
                    parse_method => 'parse_xml'
                },
            ],
        };
    }

    1;

    package FIPE;

    use HTML::Robot::Scrapper;
    #use CHI;
    use HTTP::Tiny;
    use HTTP::CookieJar;
    use WWW::Tabela::Fipe;
    use WWW::Tabela::FipeWrite;
    #use WWW::Tabela::Fipe::Parser;
    use HTML::Robot::Scrapper::UserAgent::Default;

    my $robot = HTML::Robot::Scrapper->new(
        reader    => WWW::Tabela::Fipe->new,
        writer    => WWW::Tabela::FipeWrite->new,
    #   cache     => 
    #           CHI->new(
    #                   driver => 'BerkeleyDB',
    #                   root_dir => "/home/catalyst/WWW-Tabela-Fipe/cache/",
    #           ),
        parser    => WWW::Tabela::Fipe::Parser->new,  #custom para tb fipe. pois eles respondem com Content type text/plain
        useragent => HTML::Robot::Scrapper::UserAgent::Default->new(
                     ua => HTTP::Tiny->new( 
                        cookie_jar => HTTP::CookieJar->new,
                        agent      => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:24.0) Gecko/20100101 Firefox/24.0'
                     ),

        )
    );

    $robot->start();

=head1 DESCRIPTION

This cralwer has been created to be extensible. Scalable with redis queue.

The main idea is: i need a queue of urls to be crawled, it can be an array living during 

my instance (not scalable)... or it can be a Redis queue ( scallable ), being acessed by 

many HTML::Robot::Scrapper instances.

Each request inserted into the queue is suposed to be independent. So this thing can scale. I mean,

Supose i need to create an object using stuff from page1, page2 and page3... that will be 3 requests

so, the first request will access page1 and collect data into $colleted_data, then, i will append another

request for page2 with $collected_data from page 1. So the request for page2 will collect some more data 

and merge with $collected_data from page1 generating $collected_data_from_page1_and_page2, and then i will insert

a new request into my queue for page3 that will collect data and merge with $collected_data_from_page1_and_page2

and create the final object: $collected_data_complete. 


Basicly, you need to create a 

    - reader: to read/parse your webpages and 

and a
        
    - writer: to save data you reader collected.

You 'might' need to add other content types also, creating your custom class based on:

    HTML::Robot::Scrapper::Parser::Default

See it and you will understand.. by default it handles: 
    
    - text/html
    - text/xml

=head1 READER ( you create this )

Reader: Its where the parsing logic for a specific site lives.

You customize the reader telling it where the nodes are, etc..

The reader class is where you create your parser.

=head2 WRITER ( you create this )

Writer: Its the class that will save the data the reader collects.

ie: You can create a method "save" that receives an object and simply writes into your DB.

Or you can make it write into DB + elastic search .. etc.. whatever you want


=head1 CONTENT TYPES AND PARSING METHODS ( you might need to extend this )

For example, after making a request call ( HTML::Robot::Scrapper::UserAgent::Default ) 

it will need to parse data.. and will use the response content type to parse that data

by default the class that handles that is: 

    package HTML::Robot::Scrapper::Parser::Default;
    use Moose;

    has [qw/engine robot/] => ( is => 'rw' );

    with('HTML::Robot::Scrapper::Parser::HTML::TreeBuilder::XPath'); #gives parse_xpath
    with('HTML::Robot::Scrapper::Parser::XML::XPath'); #gives parse_xml

    sub content_types {
        my ( $self ) = @_;
        return {
            'text/html' => [
                {
                    parse_method => 'parse_xpath',
                    description => q{
                        The method above 'parse_xpath' is inside class:
                        HTML::Robot::Scrapper::Parser::HTML::TreeBuilder::XPath
                    },
                }
            ],
            'text/xml' => [
                {
                    parse_method => 'parse_xml'
                },
            ],
        };
    }

    1;

WWW::Tabela::FIPE has a custom Parser class and you can see it as an example. 

If you need to download images, you will need to create a custom parser class adding 'image/png' as content type for example.

=head1 QUEUE OF REQUESTS

Another example is the Queue system, it has an api: HTML::Robot::Scrapper::Queue::Base and by default

uses: HTML::Robot::Scrapper::Queue::Array which works fine for 1 local instance. However, lets say i want a REDIS queue, so i could

implement HTML::Robot::Scrapper::Queue::Redis and make the crawler access a remote queue.. this way i can share a queue between many crawlers independently.

Just so you guys know, i have a redis module almost ready, it needs litle refactoring because its from another personal project. It will be released asap when i got time.

So, if that does not fit you, or you want something else to handle those content types, just create a new class and pass it on to the HTML::Robot::Scrapper constructor. ie:

    see the SYNOPSIS

By default it uses HTTP Tiny and useragent related stuff is in: 

    HTML::Robot::Scrapper::UserAgent::Default

=head1 Project Status

The crawling works as expected, and works great. And the api will not change probably. 

Ideas are welcome! You are welcome to contribute.

=head1 TODO

Implement the REDIS Queue to give as option for the Array queue. Array queue runs local/per instance.. and the redis queue can be shared and accessed by multiple machines!

Still need to implement the Log, proper Benchmark with subroutine tree and timing.

Allow parameters to be passed in to UserAgent (HTTP::Tiny on this case)

Better tests and docs.

=head1 Example 1 - Append some urls and extract some data

On this first example, it shows how to make a simple crawler... by simple i mean simple GET requests following urls... and grabbing some data.

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
        $self->append( search => 'http://www.zap.com.br/' ); 
        $self->append( search => 'http://www.uol.com.br/' );
        $self->append( search => 'http://www.google.com/' );
    }

    sub search {
        my ( $self ) = @_;
        my $title = $self->robot->parser->tree->findvalue( '//title' );
        my $h1 = $self->robot->parser->tree->findvalue( '//h1' );
        warn $title;
        warn p $self->robot->useragent->url ;
        push( @{ $self->array_of_data } , 
            { title => $title, url => $self->robot->useragent->url, h1 => $h1 } 
        );
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
    }

    sub on_finish {
        my ( $self ) = @_;
        $self->robot->writer->save_data( $self->array_of_data );
    }

    1;

=head1 Example 2 - Tabela FIPE ( append custom request calls )

See the working version at: https://github.com/hernan604/WWW-Tabela-Fipe

This example show an asp website that has those '__EVENTVALIDATION' and '__VIEWSTATE' which must be sent back again on each request... here is the example of such crawler for such website...

This example also demonstrates how one could easily login into a website and crawl it also.

    package WWW::Tabela::Fipe;
    use Moose;
    with 'HTML::Robot::Scrapper::Reader';
    use Data::Printer;
    use utf8;
    use HTML::Entities;
    use HTTP::Request::Common qw(POST);

    has [ qw/marcas viewstate eventvalidation/ ] => ( is => 'rw' );

    has veiculos => ( is => 'rw' , default => sub { return []; });
    has referer => ( is => 'rw' );

    sub start {
        my ( $self ) = @_;
    }

    has startpage => (
        is => 'rw',
        default => sub {
            return [
              {
                tipo => 'moto',
                url => 'http://www.fipe.org.br/web/indices/veiculos/default.aspx?azxp=1&v=m&p=52'
              },
              {
                tipo => 'carro',
                url => 'http://www.fipe.org.br/web/indices/veiculos/default.aspx?p=51'
              },
              {
                tipo => 'caminhao',
                url => 'http://www.fipe.org.br/web/indices/veiculos/default.aspx?v=c&p=53'
              },
            ]
        },
    );

    sub on_start {
      my ( $self ) = @_;
      foreach my $item ( @{ $self->startpage } ) {
        $self->append( search => $item->{ url }, {
            passed_key_values => {
                tipo => $item->{ tipo },
                referer => $item->{ url },
            }
        } );
      }
    }

    sub _headers {
        my ( $self , $url, $form ) = @_;
        return {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Encoding' => 'gzip, deflate',
          'Accept-Language' => 'en-US,en;q=0.5',
          'Cache-Control' => 'no-cache',
          'Connection' => 'keep-alive',
          'Content-Length' => length( POST('url...', [], Content => $form)->content ),
          'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8',
          'DNT' => '1',
          'Host' => 'www.fipe.org.br',
          'Pragma' => 'no-cache',
          'Referer' => $url,
          'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:20.0) Gecko/20100101 Firefox/20.0',
          'X-MicrosoftAjax' => 'Delta=true',
        };
    }

    sub _form {
        my ( $self, $args ) = @_;
        return [
          ScriptManager1 => $args->{ script_manager },
          __ASYNCPOST => 'true',
          __EVENTARGUMENT => '',
          __EVENTTARGET => $args->{ event_target },
          __EVENTVALIDATION => $args->{ event_validation },
          __LASTFOCUS => '',
          __VIEWSTATE => $args->{ viewstate },
          ddlAnoValor => ( !exists $args->{ano} ) ? 0 : $args->{ ano },
          ddlMarca => ( !exists $args->{marca} ) ? 0 : $args->{ marca },
          ddlModelo => ( !exists $args->{modelo} ) ? 0 : $args->{ modelo },
          ddlTabelaReferencia => 154,
          txtCodFipe => '',
        ];
    }

    sub search {
      my ( $self ) = @_;
      my $marcas = $self->tree->findnodes( '//select[@name="ddlMarca"]/option' );
      my $viewstate = $self->tree->findnodes( '//form[@id="form1"]//input[@id="__VIEWSTATE"]' )->get_node->attr('value');
      my $event_validation = $self->tree->findnodes( '//form[@id="form1"]//input[@id="__EVENTVALIDATION"]' )->get_node->attr('value');
      foreach my $marca ( $marcas->get_nodelist ) {
        my $form = $self->_form( {
            script_manager => 'UdtMarca|ddlMarca',
            event_target => 'ddlMarca',
            event_validation=> $event_validation,
            viewstate => $viewstate,
            marca => $marca->attr( 'value' ),
        } );
        $self->prepend( busca_marca => 'url' , {
          passed_key_values => {
              marca => $marca->as_text,
              marca_id => $marca->attr( 'value' ),
              tipo => $self->robot->reader->passed_key_values->{ tipo },
              referer => $self->robot->reader->passed_key_values->{referer },
          },
          request => [
            'POST',
            $self->robot->reader->passed_key_values->{ referer },
            {
              headers => $self->_headers( $self->robot->reader->passed_key_values->{ referer } , $form ),
              content => POST('url...', [], Content => $form)->content,
            }
          ]
        } );
      }
    }

    sub busca_marca {
      my ( $self ) = @_;
      my ( $captura1, $viewstate ) = $self->robot->useragent->content =~ m/hiddenField\|__EVENTTARGET(.+)__VIEWSTATE\|([^\|]+)\|/g;
      my ( $captura_1, $event_validation ) = $self->robot->useragent->content =~ m/hiddenField\|__EVENTTARGET(.+)__EVENTVALIDATION\|([^\|]+)\|/g;
      my $modelos = $self->tree->findnodes( '//select[@name="ddlModelo"]/option' );
      foreach my $modelo ( $modelos->get_nodelist ) {


        next unless $modelo->as_text !~ m/selecione/ig;
        my $kv={};
        $kv->{ modelo_id } = $modelo->attr( 'value' );
        $kv->{ modelo } = $modelo->as_text;
        $kv->{ marca_id } = $self->robot->reader->passed_key_values->{ marca_id };
        $kv->{ marca } = $self->robot->reader->passed_key_values->{ marca };
        $kv->{ tipo } = $self->robot->reader->passed_key_values->{ tipo };
        $kv->{ referer } = $self->robot->reader->passed_key_values->{ referer };
        my $form = $self->_form( {
            script_manager => 'updModelo|ddlModelo',
            event_target => 'ddlModelo',
            event_validation=> $event_validation,
            viewstate => $viewstate,
            marca => $kv->{ marca_id },
            modelo => $kv->{ modelo_id },
        } );
        $self->prepend( busca_modelo => '', {
          passed_key_values => $kv,
          request => [
            'POST',
            $self->robot->reader->passed_key_values->{ referer },
            {
              headers => $self->_headers( $self->robot->reader->passed_key_values->{ referer } , $form ),
              content => POST( 'url...', [], Content => $form )->content,
            }
          ]
        } );
      }
    }

    sub busca_modelo {
      my ( $self ) = @_;
      my $anos = $self->tree->findnodes( '//select[@name="ddlAnoValor"]/option' );
      foreach my $ano ( $anos->get_nodelist ) {
        my $kv = {};
        $kv->{ ano_id } = $ano->attr( 'value' );
        $kv->{ ano } = $ano->as_text;
        $kv->{ modelo_id } = $self->robot->reader->passed_key_values->{ modelo_id };
        $kv->{ modelo } = $self->robot->reader->passed_key_values->{ modelo };
        $kv->{ marca_id } = $self->robot->reader->passed_key_values->{ marca_id };
        $kv->{ marca } = $self->robot->reader->passed_key_values->{ marca };
        $kv->{ tipo } = $self->robot->reader->passed_key_values->{ tipo };
        $kv->{ referer } = $self->robot->reader->passed_key_values->{ referer };
        next unless $ano->as_text !~ m/selecione/ig;

        my ( $captura1, $viewstate ) = $self->robot->useragent->content =~ m/hiddenField\|__EVENTTARGET(.*)__VIEWSTATE\|([^\|]+)\|/g;
        my ( $captura_1, $event_validation ) = $self->robot->useragent->content =~ m/hiddenField\|__EVENTTARGET(.*)__EVENTVALIDATION\|([^\|]+)\|/g;
        my $form = $self->_form( {
            script_manager => 'updAnoValor|ddlAnoValor',
            event_target => 'ddlAnoValor',
            event_validation=> $event_validation,
            viewstate => $viewstate,
            marca => $kv->{ marca_id },
            modelo => $kv->{ modelo_id },
            ano => $kv->{ ano_id },
        } );

        $self->prepend( busca_ano => '', {
          passed_key_values => $kv,
          request => [
            'POST',
            $self->robot->reader->passed_key_values->{ referer },
            {
              headers => $self->_headers( $self->robot->reader->passed_key_values->{ referer } , $form ),
              content => POST( 'url...', [], Content => $form )->content,
            }
          ]
        } );
      }
    }

    sub busca_ano {
      my ( $self ) = @_;
      my $item = {};
      $item->{ mes_referencia } = $self->tree->findvalue('//span[@id="lblReferencia"]') ;
      $item->{ cod_fipe } = $self->tree->findvalue('//span[@id="lblCodFipe"]');
      $item->{ marca } = $self->tree->findvalue('//span[@id="lblMarca"]');
      $item->{ modelo } = $self->tree->findvalue('//span[@id="lblModelo"]');
      $item->{ ano } = $self->tree->findvalue('//span[@id="lblAnoModelo"]');
      $item->{ preco } = $self->tree->findvalue('//span[@id="lblValor"]');
      $item->{ data } = $self->tree->findvalue('//span[@id="lblData"]');
      $item->{ tipo } = $self->robot->reader->passed_key_values->{ tipo } ;
      warn p $item;

      push( @{$self->veiculos}, $item );
    }

    sub on_link {
        my ( $self, $url ) = @_;
    }

    sub on_finish {
        my ( $self ) = @_;
        warn "Terminou.... exportando dados.........";
        $self->robot->writer->write( $self->veiculos );
    }

=head1 DESCRIPTION

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    perldelux / movimentoperl
    hernan@cpan.org
    http://github.com/hernan604

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

