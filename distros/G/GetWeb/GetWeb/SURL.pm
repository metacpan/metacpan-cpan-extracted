package GetWeb::SURL;

use Carp;

use URI::Escape;
use strict;

sub new
{
    my $type = shift;
    my ($url, $paramBase, $paramOpt) = @_;

    ($url =~ m^:^) or ($url =~ m^\..+\.^)
	or croak "SYNTAX ERROR: not a valid URL or command: $url\n";

    my $self = {
	URL => $url,
	PARAM_BASE => $paramBase,
	PARAM_OPT => $paramOpt,
	PARAM_TEXT => []
	};

    bless($self,$type);
}

sub addParam
{
    my $self = shift;
    my $param = shift;

    my $paramText = $$self{PARAM_TEXT};
    push(@$paramText,$param);
}

sub getURLString
{
    my $self = shift;

    my $url = $$self{URL};
    my $paramBase = $$self{PARAM_BASE};
    my $paParamText = $$self{PARAM_TEXT};

    return $url unless (defined $paramBase or
			@$paParamText);
    $url .= "?";

    my $paramString = "";
    my $optString = "";
    my $param;

    my %hFound;
    foreach $param (@$paParamText)
    {
	my $option = $self -> findKey($param);
	if ($option)
	{
	    $hFound{$option} = 1;
	    $optString .= ("$option=" . uri_escape($param) . '&');
	}
	else
	{
	    $paramString .= ("+" . uri_escape($param));
	}
    }
    $paramString =~ s/^\+//;

    # insert defaults
    my $phpaParamOpt = $$self{PARAM_OPT};

    my $option;
    foreach $option (keys %$phpaParamOpt)
    {
	my $paParamOpt = $$phpaParamOpt{$option};
	my $defaultOpt = $$paParamOpt[0];
	next if $hFound{$option};
	next unless defined $defaultOpt;
	$optString .= ("$option=" . uri_escape($defaultOpt) . "&");
    }
    # $optString =~ s/^\&//;

    $url . $optString . $paramBase . $paramString;
}

sub findKey
{
    my $self = shift;
    my $param = shift;

    my $phpaParamOpt = $$self{PARAM_OPT};

    my $option;
    foreach $option (keys %$phpaParamOpt)
    {
	my $paParamOpt = $$phpaParamOpt{$option};
	if (grep($_ eq $param,@$paParamOpt))
	{
	    return $option;
	}
    }
    undef;
}

1;
