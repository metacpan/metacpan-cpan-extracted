package Language::Farnsworth::Functions::GoogleTranslate;

use strict;
use warnings;

use Data::Dumper;

use Language::Farnsworth::Value; #i should encapsulate things so this isn't needed, or make a better interface

use REST::Google::Translate;
use HTML::Entities;

use Encode;

our $VERSION = "0.9.1";

#note that this is fairly C<en> centric!

my $defaultcode = "en";

	my %langs = (
		
ja=>"Japanese",              
en=>"English",               
vi=>"Vietnamese",            
af=>"Afrikaans",             
sq=>"Albanian",              
ar=>"Arabic",                
be=>"Belarusian",            
bg=>"Bulgarian",             
ca=>"Catalan",               
"zh-CN"=>"Chinese",
"zh-TW"=>"Chinese_Traditional",
hr=>"Croatian",              
cs=>"Czech",                 
da=>"Danish",                
nl=>"Dutch",                 
en=>"English",               
et=>"Estonian",              
tl=>"Filipino",              
fi=>"Finnish",               
fr=>"French",                
gl=>"Galician",              
de=>"German",                
el=>"Greek",
ht=>"HaitianCreole",
iw=>"Hebrew",
hi=>"Hindi",
hu=>"Hungarian",
is=>"Icelandic",
id=>"Indonesian",
ga=>"Irish",
it=>"Italian",
ja=>"Japanese",
ko=>"Korean",
lv=>"Latvian",
lt=>"Lithuanian",
mk=>"Macedonian",
ms=>"Malay",
mt=>"Maltese",
no=>"Norwegian",
fa=>"Persian",
pl=>"Polish",
pt=>"Portuguese",
ro=>"Romanian",
ru=>"Russian",
sr=>"Serbian",
sk=>"Slovak",
sl=>"Slovenian",
es=>"Spanish",
sw=>"Swahili",
sv=>"Swedish",
th=>"Thai",
tr=>"Turkish",
uk=>"Ukrainian",
vi=>"Vietnamese",
cy=>"Welsh",
yi=>"Yiddish",

);
	
sub init
{
	my $env = shift;

    REST::Google::Translate->http_referer('http://farnsworth.sexypenguins.com/'); #for now, i need a real website for this!

	my $string = new Language::Farnsworth::Value::String("");

	#generate lang to lang
	for my $x (keys %langs)
	{
		for my $y (keys %langs)
		{
			if ($x ne $y)
			{
				#no need to generate names for DutchToDutch!
				my $name = $langs{$x}."To".$langs{$y};

				#closures in perl will give me this! closures FTW!
				$env->{funcs}->addfunc($name, [["in", undef, $string, 0]], sub {translate($x,$y,@_)},$env);
			}
		}
	}

	#now generate ToLang Lang, and FromLang
	for my $x (keys %langs)
	{
		my $name = $langs{$x};

		#closures in perl will give me this! closures FTW!
		if ($x ne $defaultcode)
		{
			$env->{funcs}->addfunc($name, [["in", undef, $string, 0]], sub {translate("",$x,@_)},$env);
			$env->{funcs}->addfunc("Is".$name, [["in", undef, $string, 0]], sub {islang($x, @_)},$env);
			$env->{funcs}->addfunc("To".$name, [["in", undef, $string, 0]], sub {translate("",$x,@_)},$env);
			$env->{funcs}->addfunc("From".$name, [["in", undef, $string, 0]], sub {translate($x, $defaultcode,@_)},$env);
		}
		else
		{
			$env->{funcs}->addfunc("Is".$name, [["in", undef, $string, 0]], sub {islang($x, @_)},$env);
			$env->{funcs}->addfunc($name, [["in", undef, $string, 0]], sub {translate("",$defaultcode,@_)},$env);
			$env->{funcs}->addfunc("To".$name, [["in", undef, $string, 0]], sub {translate("",$defaultcode,@_)},$env);
		}
	}

	$env->{funcs}->addfunc("DetectLanguage", [["in", undef, $string, 0]], \&detectlang,$env);
}

sub callgoogle
{
  my ($langa, $langb) = (shift(), shift()); #get the two targets
  my $totranslate= shift;

  print "CALLING GOOGLE! $langa, $langb, \"$totranslate\"\n";
	
  my $res = REST::Google::Translate->new(
              q => $totranslate,
                langpair => "$langa|$langb",
       );

	   #print Dumper($res);

  die "response status failure when translating [$langa -> $langb], ".$res->responseStatus, " details follow, ".$res->responseDetails if $res->responseStatus != 200;

  return $res; #if its undef, its undef! i should really make some kind of error checking here
}

sub translate
{
  my ($langa, $langb) = (shift(), shift()); #get the two targets
  my ($args, $eval, $branches)= @_;

  if ($langa eq "")
  {
    if ($args->getarrayref()->[0]->getlang() ne "") #if it is set to something other than "1"
    {
      $langa = $args->getarrayref()->[0]->getlang();
    }
  }

  my $response = callgoogle($langa, $langb, $args->getarrayref()->[0]->getstring());
  my $translated = $response->responseData->translatedText;

  #print "TRANSLATED: $langa|$langb '$translated'\n";

  $translated = new Language::Farnsworth::Value::String(decode_entities($translated), $langb);

  return $translated;
}

sub detectlang
{
  my ($args, $eval, $branches)= @_;

  if ($args->getarrayref()->[0]->getlang() ne "") #if it is set to something other than "1"
  {
    my $lang = $args->getarrayref()->[0]->getlang();
    my $txt = $langs{$lang};
    return new Language::Farnsworth::Value::String($txt, "en"); #NOT INTERNATIONALIZED NAMES!
  }

  my $response = callgoogle("", "en", $args->getarrayref()->[0]->getstring());
  my $translated = $response->{responseData}{detectedSourceLanguage};

  #print "DETECTED: '$translated'\n";

  $translated = $langs{$translated} || $translated; #either its got a name, or we return the code

  $translated = new Language::Farnsworth::Value::String($translated, "en");

  return $translated;
}

sub islang
{
  my ($lang) = shift();
  my ($args, $eval, $branches)= @_;

  my $text = $args->getarrayref()->[0]->getstring();

  return new Language::Farnsworth::Value::String($text, $lang);
}

1;
