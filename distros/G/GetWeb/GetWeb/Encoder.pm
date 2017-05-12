package GetWeb::Encoder;

use HTML::Parse;
use HTML::FormatText;

use GetWeb::Filter::HTML2Txt;
use MailBot::Util;

use strict;

my $DEFAULT_RAW = 1000000;

sub d
{
  MailBot::Util::debug(@_);
}

# jfj cap raw length of total request, incl. redirects

sub new
{
    my $type = shift;
    my $allowRawLength = shift;
    defined $allowRawLength or $allowRawLength = $DEFAULT_RAW;

#    my $baseURL = shift;
    
    my $self = {
	PREFER_SOURCE => 0,
#	BASE_URL => $baseURL,
	ALLOW_RAW_LENGTH => $allowRawLength,
	TEXT => ''
	};
    bless($self,$type);
}

# jfj clean up encoding code

sub beginFormat
{
    my $self = shift;
    # &d("initing format");

    undef $$self{FILTER_LIST};
}

sub addEncoded
{
    my $self = shift;
    my $string = shift;

    my $message = $$self{MESSAGE};
    if (defined $message)
    {
	$message -> append($string);
    }
    # else
    {
	$$self{TEXT} .= $string;
    }
}

sub getTextRef
{
    my $self = shift;
    \$$self{TEXT};
}

sub getContentType
{
    shift -> {CONTENT_TYPE};
}

sub preferSource
{
    shift -> {PREFER_SOURCE} = 1;
}

sub setMessage
{
    my $self = shift;
    my $message = shift;

    $$self{MESSAGE} = $message;
}

sub encode
{
    my $self = shift;
    my $inString = shift;
    my $inType = shift;
    my $url = shift;
    
    my $paFilter = $self -> createFilterList($inType);
    
    my $filter;
    foreach $filter (@$paFilter)
    {
 	$inString = $filter -> append($inString);
 	$inString .= $filter -> done($url);
    }
    
    $self -> addEncoded($inString);
}

sub done
{
    my $self = shift;
    my $baseURL = shift;

    my $paFilter = $$self{FILTER_LIST};
#     if (! defined $paFilter)
#     {
# 	$self -> append("document contains no data");
# 	$paFilter = $$self{FILTER_LIST};
#     }
    
    my $filter;
    my $data = "";
    foreach $filter (@$paFilter)
    {
	$data = $filter -> append($data);
	$data .= $filter -> done($baseURL);
    }

    my $message = $$self{MESSAGE};
    if (defined $message)
    {
	my $fileName = $baseURL;
	$fileName =~ s|^.*/||;
	$message -> setFileName($fileName);
    }
    $self -> addEncoded($data);
}

sub base
{
    my $self = shift;
    $$self{BASE_URL} = shift;
}

sub createFilterList
{
    my $self = shift;
    my $contentType = shift;

    my $paFilter = [];

    if ($contentType eq "text/html")
    {
	if (! $$self{PREFER_SOURCE})
	{
	    push(@$paFilter,new GetWeb::Filter::HTML2Txt());
	    $contentType = "text/plain";
	}
    }

    my $message = $$self{MESSAGE};
    # jfj check content type against "allowed types"

    if (defined $message)
    {
	$message -> setContentType($contentType);
    }

    $$self{CONTENT_TYPE} = $contentType;

    $paFilter;
}

1;
