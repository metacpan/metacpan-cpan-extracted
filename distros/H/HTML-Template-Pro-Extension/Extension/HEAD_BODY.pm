package HTML::Template::Pro::Extension::HEAD_BODY;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

use HTML::TokeParser;

my %fields_parent 	=
			    (
			    	autoDeleteHeader => 1,
			     );
     
sub init {
    my $self = shift;
    while (my ($key,$val) = each(%fields_parent)) {
        $self->{$key} = $self->{$key} || $val;
    }
}

sub get_filter {
	my $self = shift;
	return _get_filter($self);
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	push @ret, sub {
				my $tmpl 	= shift;
				my $self	= shift;
				if ($self->{autoDeleteHeader}) {
					my $header;
					if ($$tmpl =~s{(^.+?<body(?:[^>'"]*|".*?"|'.*?')+>)}{}msi) {
						$self->{header} = $1;
						&tokenizer_header($self);
					} else {
						# header doesn't exist
						undef $self->{header};
						undef $self->{tokens};
					}
					$$tmpl =~ s{</body>.+}{}msi;
				}
			};
	return @ret;
}

sub autoDeleteHeader { 
	my $s=shift;
	if (@_)  {	
		my $newvalue 	= shift;
		return if ($newvalue == $s->{autoDeleteHeader});
		$s->{autoDeleteHeader}=$newvalue;
	};
	return $s->{autoDeleteHeader};
}

sub tokenizer_header {
	# prende l'header contenuto in $self->{header} e ne estrae i
	# token fondamentali inserendoli in $self->{tokens}
	my $self 		= shift;
	my $header 	= $self->{header};
  $header 		=~m|<head>(.*?)</head>|smi;
	$header			= $1;
	my $p = HTML::TokeParser->new(\$header);
	$self->{tokens} 	= {};
  while (my $token  = $p->get_tag()) {
  	my $tag  = $token->[0];
    my $type = substr($tag,0,1) eq '/' ? 'E' : 'S';
    my $tag_text;
    if ($type eq 'S') {
    	$tag_text = $token->[3];
      my $text = $p->get_text();
      my $struct = [$tag_text,$text,undef];
      push @{$self->{tokens}->{$tag}},$struct;
    } elsif ($type eq 'E') {
      $tag      = substr($tag,1,length($tag)-1);
      $tag_text = $token->[1];
      my $last_idx = scalar @{$self->{tokens}->{$tag}}-1;
      $self->{tokens}->{$tag}->[$last_idx]->[2] = $tag_text;
    }
  }
}


sub header {my $s = shift;return exists($s->{header}) ?  $s->{header} : ''};

sub js_header { return &header_js(shift); }

sub header_js {
        # ritorna il codice javascript presente nell'header
        my $self        = shift;
        my $ret;
				my $js_token = $self->{tokens}->{script};
				foreach (@{$js_token}) {
					$ret .= $_->[0] . $_->[1] . $_->[2];
				}
        return $ret;
}

sub header_css {
	# ritorna i css presenti nell'header
	# compresi i link a css esterni
	my $self        = shift;
	my $ret;
  my $style_token = $self->{tokens}->{style};
  foreach (@{$style_token}) {
  	$ret .= $_->[0] . $_->[1] . $_->[2];
  }
	my $link_token = $self->{tokens}->{link};
  foreach (@{$link_token}) {
		if ($_->[0] =~ /[Rr][Ee][Ll]\s*=\s*"?[Ss][Tt][Yy][Ll][Ee][Ss][Hh][Ee][Ee][Tt]"?/ &&
			$_->[0] =~ /[Tt][Yy][Pp][Ee]\s*=\s*"?[Tt][Te][Xx][Tt]\/[Cc][Ss][Ss]"?/) {
	  	$ret .= $_->[0] . $_->[1] . $_->[2];
		}
  }
  return $ret;
}

sub body_attributes {
	# ritorna gli attributi interni al campo body
	my $self 		= shift;
	my $h					= $self->{header};
	my $re_init	= q|<\s*body(.*?)>|;
	$h=~/$re_init/msxi;
	return $1;
}

sub header_tokens {
	# ritorna un riferimento ad un hash che contiene
	# come chiavi tutti i tag presenti nell'header <HEAD>...</HEAD>
	# ogni elemento dell'hash e' un riferimento ad un array. 
	# Ogni array e' a sua volta un riferimento ad array di tre elementi
	# tag_init - testo contenuto tra il tag e l'eventuale fine tag o successivo tag - eventuale fine tag o undef
	my $self	= shift;
	return $self->{tokens};
}
 
1;
