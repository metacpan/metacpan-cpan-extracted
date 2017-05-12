package I22r::Translate::Filter::HTML;
use Carp;
use Moose;
with 'I22r::Translate::Filter';

our $VERSION = '0.96';

sub apply {
    my ($self, $req, $key) = @_;
    local $_;
    my $otext = $_ = $req->text->{$key};
    my $keymap = $self->{map}{$key} //= {};

    my $html_transform_count = 0;
    while ( s{
              <  (\w+)  (\b[^>]*)?  >   # OPEN TAG
                  (?!.*?<\1\b)          # TAG INTERIOR does not contain OPEN TAG
                  (.*?)                 # TAG INTERIOR
              </  \1  >                 # CLOSE TAG
         }[ 
	   $self->_html_transform( $otext, $_, $keymap, $1, $2, $3 );
	 ]gexs) {

	if (++$html_transform_count > 500) {
	    Carp::cluck "I22r::Translate::Filter::HTML: ",
		    "endless html_transform loop for data\n---\n$_\n---\n\n";
	    last;
	}
    }

    # XXX - protect singleton <tag/> <tag attr="value"/> tags?

    # protect any remaining HTML tags at the end
    1 while s{<.*?>(?:&nbsp;?|\s)*$}(
	$keymap->{__end__} //= [];
	unshift @{$keymap->{__end__}}, ${^MATCH};
	'' )psex;

    # protect any remaining HTML tags at the beginning
    1 while s{^(?:&nbsp;?|\s)*<.*?>}(
	$keymap->{__begin__} //= [];
	push @{$keymap->{__begin__}}, ${^MATCH};
	'' )psex;

    $req->text->{$key} = $_;
}

sub unapply {
    my ($self, $req, $key) = @_;

    ### - unnecessary to restore $req->text->{$key}, it is always
    ###   done in Request::unapply_filters . When the bare filter
    ###   tests are fixed so they aren't testing this anymore,
    ###   this line can be removed.
    $req->text->{$key} =
	$self->_unapply( $req, $key, $req->text->{$key} );
    if (defined $req->results->{$key}) {
	$req->results->{$key}{text} =
	    $self->_unapply( $req, $key, $req->results->{$key}->text );
    }
}

sub _unapply {
    my ($self, $req, $key, $topic) = @_;
    local $_ = $topic;
    my $keymap = $self->{map}{$key};
    return $_ unless $keymap->{__keys__};
    foreach my $enc (reverse @{$keymap->{__keys__}}) {
	my $mapping = $keymap->{$enc};
	next if !defined $mapping;

	my ($open, $close) = ($mapping->[1], $mapping->[3]);
	my $unmap = 0;
	if ($enc eq q/""/) {
	    $unmap = s/"(.*?)"/$open$1$close/;
	} elsif ($enc eq q/''/) {
	    $unmap = s/'(.*?)'/$open$1$close/;
	} elsif ($enc eq q/()/) {
	    $unmap = s/\((.*?)\)/$open$1$close/;
	} elsif ($enc eq q/[]/) {
	    $unmap = s/\[(.*?)\]/$open$1$close/;
	} elsif ($enc eq q/{}/) {
	    $unmap = s/\{(.*?)\}/$open$1$close/;
	} elsif ($enc =~ /[\x{9FD0}-\x{9FFF}]/) {
	    my ($c1,$c2) = split //, $enc;
#	    $unmap = s/$c1(.*?)$c2/$open$1$close/;
	    $unmap = s/ ?$c1 ?(.*?) ?$c2 ?/$open$1$close/;
	}
	if (!$unmap) {
	    carp "Could not find place to restore html tags ",
		"'$open' and '$close' with encoding $enc ",
		"in translated text result $_\n";
	}
    }
    if ($keymap->{__begin__}) {
	$_ = join('', @{$keymap->{__begin__}}) . $_;
    }
    if ($keymap->{__end__}) {
	$_ .= join('', @{$keymap->{__end__}});
    }
    return $_;
}

sub _html_transform {
    my ($self, $source1,$source2,$map,$tag,$attr,$element) = @_;
    my $interior = $element;
    $element = '' if $element eq "\x{00}\x{00}";
    my $source = $source1 . $source2;

    if ($interior =~ /<$tag/) {
	carp "Detected nested <$tag></$tag> tags!\n";
	return "<$tag$attr>$element</$tag>";
    }

    if (defined($map->{$element}) && $map->{$element}[0] eq 'literal') {
	$interior = $map->{$element}[1];
    }
    my $mapping = [ 'html', "<$tag$attr>", 
		    $interior eq "\x{00}\x{00}"
		    ? ('','') : ($interior,"</$tag>") ];

    if (!defined $map->{q/()/} && $source !~ /[()]/) {
	$map->{q/()/} = $mapping;
	push @{$map->{__keys__}}, q/()/;
	return qq/($element)/;
    }
    if (!defined $map->{q/[]/} && $source !~ /\[|\]/) {
	$map->{q/[]/} = $mapping;
	push @{$map->{__keys__}}, q/[]/;
	return qq/[$element]/;
    }
    if (!defined $map->{q/{}/} && $source !~ /\{|\}/) {
	$map->{q/{}/} = $mapping;
	push @{$map->{__keys__}}, q/{}/;
	return qq/{$element}/;
    }
    if (!defined $map->{q/""/} && $source !~ /\"/) {
	$map->{q/""/} = $mapping;
	push @{$map->{__keys__}}, q/""/;
	return qq/"$element"/;
    }
    if (!defined $map->{q/''/} && $source !~ /\'/) {
	$map->{q/''/} = $mapping;
	push @{$map->{__keys__}}, q/''/;
	return qq/'$element'/;
    }

    # other good ranges:
    #    0x0860 - 0x08FF
    #    0xA6A0 - 0xA6FF
    #    0xAAE0 - 0xABBF
    #    0xD800 - 0xDFFF? (reserved for UTF-16 surrogate pairs)
    #    0xE000 - 0xF8FF? ("private use area")
    #    0x104B0 - 0x107FF
    #    0x10E80 - 0x10FFF
    for (my $q = 0x9FD0; $q <= 0x9FFF; $q += 2) {
	my $c1 = chr($q);
	my $c2 = chr($q+1);
	if (!defined $map->{"$c1$c2"}) {
	    $map->{"$c1$c2"} = $mapping;
	    push @{$map->{__keys__}}, "$c1$c2";
	    return " $c1 " . $element . " $c2 ";
	}
    }

    carp "cannot transform html expression <$tag$attr> $element </$tag> ",
    	"in source text $source1!\n";
    return "<$tag$attr>$element</$tag>";
}

1;
__END__

=head1 NAME

I22r::Translate::Filter::HTML - protect HTML tags in input to I22r::Translate

=head1 SYNOPSIS

    I22r::Translate->config(
       ...,
       filter => [ 'HTML' ]
    );

    $t = I22r::Translate->translate_string(
       src => ..., dest => ..., text => 'string that might have HTML markup',
       filter => [ 'HTML' ] )

=head1 DESCRIPTION

A preprocessing and postprocessing filter that protects
HTML tags from being altered in a translation engine.

Sometimes, content that you wish to translate may have
HTML tags or other markup. Consider this English text:

    <strong>Roses</strong> are <a href="http://red.com/" style="">red</a>.

If you wished to translate this text into, say, Spanish, you would
probably B<not> want to translate the words inside the HTML tags,
even though some of those words are recognizably English. That is,
you would hope the translator would output something like

    <strong>Rosas</strong> son <a href="http://red.com/" style="">rojas</a>.

rather than (in the worst case)

    <fuerte>Rosas</fuerte> son <un href="http://rojo.com/" estilo="">rojas</a>.

which would surely not be rendered correctly in a web browser.

This C<I22r::Translate::Filter::HTML> module is a
L<filter|I22r::Translate::Filter> that can hide HTML tags from
a translation backend, but restore the HTML in the appropriate
place in the translation output.

=head1 SEE ALSO

L<I22r::Translate::Filter>, L<I22r::Translate::Filter::Literal>,
L<I22r::Translate>.

=cut
