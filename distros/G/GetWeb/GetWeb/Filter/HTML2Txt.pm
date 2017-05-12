package GetWeb::Filter::HTML2Txt;

use GetWeb::Filter;
use HTML::Parse;
require GetWeb::FormatAnnotated;

@ISA = qw( GetWeb::Filter );
use strict;

sub DESTROY
{
    my $self = shift;
    return unless defined $self;

    # avoids a memory leak by deleting object with circular reference

    my $parse = $$self{PARSE};
    $parse -> delete if defined $parse;
}

sub new
{
    my $type = shift;
    # my $base = shift;

    my $parse = parse_html("");
    my $self = { PARSE => $parse,
		 TOTAL => "",
	         # BASE_URL => $base
	     };

    bless($self,$type);
}

sub append
{
    my $self = shift;
    my $data = shift;

    # print STDERR "data is $data";
    $$self{TOTAL} .= $data;
        
    # j dynamically remove from head of element to save memory
    $$self{PARSE} = parse_html($data,$$self{PARSE});

    return '';
}

sub done
{
    my $self = shift;
    my $baseURL = shift;

    my $formatter;
    $formatter = new GetWeb::FormatAnnotated($baseURL);

    my $parse = $self -> {PARSE};
    #print STDERR $parse -> dump;
    join('',$formatter -> format($parse));
}
