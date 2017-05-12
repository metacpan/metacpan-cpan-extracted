package I22r::Translate::Filter::Literal;
use Carp;
use Moose;
with 'I22r::Translate::Filter';

our $VERSION = '0.96';

our $DOUBLE_BRACES_WRAP_LITERAL = 1;
our $DOUBLE_BRACES_WRAP_PARAMETER_LITERAL = 1;
our $HTML_ENTITIES_ARE_LITERAL = 1;

sub apply {
    my ($self, $req, $key) = @_;

    local $_ = $req->text->{$key};
    my $keymap = $self->{map}{$key} //= { __keys__ => [] };

    if ($DOUBLE_BRACES_WRAP_PARAMETER_LITERAL) {
	s[   (   \{\{  _\d+  \}\}  )   ]
	 [   $self->_literal_transform( $keymap, $1 )  ]gexs;
    }

    if ($HTML_ENTITIES_ARE_LITERAL) {
	s[ (&[#]?\w+;) ][
	    $self->_literal_transform( $keymap, $1 )
	 ]gexs;
    }

    if ($DOUBLE_BRACES_WRAP_LITERAL) {
	s[   \{\{   ([^_].*?)   \}\}    ]
         [
	     $self->_literal_transform( $keymap, $1, ['{{','}}'] ) 
	 ]gexs;
    }

    s{  (\[lit(?:eral)?\])    (.*?)    (\[/lit(?:eral)?\])     }
     [    $self->_literal_transform( $keymap, $2, [$1,$3] )
         ]gexs;

    s{ (<\s*span(?:[^>]*) lang=["']..['"](?:[^>]*)>)
                (.*?)
           (<\s*/\s*span\s*>) }
     [  $self->_literal_transform( $keymap, $2, [$1,$3] ) ]gexs;

    $req->text->{$key} = $_;
    return;
}

sub unapply {
    my ($self, $req, $key) = @_;

    ### remove next line when bare filter tests are fixed. See ...::Filter::HTML
    $req->text->{$key} = $self->_unapply( $req, $key, $req->text->{$key}, 1 );
    if ($req->results->{$key}) {
	$req->results->{$key}{text} =
	    $self->_unapply( $req, $key, $req->results->{$key}->text, 0 );;
    }
}

sub _unapply {
    my ($self, $req, $key, $topic, $apply_m2) = @_;
    local $_ = $topic;

    my $keymap = $self->{map}{$key};

    foreach my $enc (reverse @{$keymap->{__keys__}}) {
	my $mapping = $keymap->{$enc};
	next if !defined $mapping;

	my $element = $mapping->[1];
	if ($apply_m2 && $mapping->[2]) {
	    $element = $mapping->[2][0] . $element . $mapping->[2][1];
	}
	if ($enc ne lc $enc) {
	    # sometimes external translator will change case of the
	    # literal placeholder, e.g.  _XZX_ => _xzx_
	    my $lc_enc = lc $enc;
	    s/(?<!#|_)$lc_enc(?!#|_)/$enc/i;
	}
	s/(?<!#|_)$enc(?!#|_)/$element/ or
	    s/(?<!#)$enc(?!#)/$element/ or
	    $self->_untransform2($_,$enc,$element) or
	    do {
		carp "Could not find place to restore ",
		    "literal text $element with encoding ",
		    "$enc in translated text result $_\n";
	};
    }
    return $_;
}

sub _literal_transform {
    my ($self, $map,$element,$unmapping) = @_;
    my $mapping = [ 'literal', $element, $unmapping // ['', ''] ];
#    my $subst = '###';
#    while (defined $map->{$subst}) {
#	$subst .= '#';
#    }

    my $subst = "_XZX_";
    while (defined $map->{$subst}) {
	$subst =~ s/^_/_XZ/;
    }

    $map->{$subst} = $mapping;
    push @{$map->{__keys__}}, $subst;
    return $subst;
}

sub _untransform2 {
    my ($string, $encoding, $replacement) = @_;
    return 0;
}

1;

__END__

=head1 NAME

I22r::Translate::Filter::Literal - protect text in input to I22r::Translate

=head1 SYNOPSIS

    I22r::Translate->config(
       ...,
       filter => [ 'Literal' ]
    );

    $t = I22r::Translate->translate_string(
       src => ..., dest => ..., text => 'string with Proper Nouns',
       filter => [ 'Literal' ] )

=head1 DESCRIPTION

A preprocessing and postprocessing filter that recognizes words or
phrases with particular markup, and prevents that text from
being altered in a translation engine.

Sometimes, content that you wish to translate may contain words
or phrases that you I<don't> want to translate.

    My friend Paul Fisher lives in Key West.

    The French word for cat is "chat".

If you wished to translate these sentences into, say, Spanish, 
you would probably B<not> want some of those words to be translated,
including all the proper nouns and the "foreign" word which also
happens to have the same spelling as an English word. That is, you
would much prefer a translation output like

    Mi amigo Paul Fisher vive en Key West.

    La palabra francesca para gato es "chat".

rathen than

    Mi amigo Pablo Pescador vive en Clave Oeste.

    La palabra francesca para gato es "charlar".

The C<I22r::Translate::Filter::Literal> filter will recognize
certain markup in translation input and interpret it as an
instruction to hide certain words from the translation engine.
The untranslated words will then be (hopefully) restored to 
the correct place in the translated output.

=head1 MARKUP

The C<I22r::Translate::Filter::Literal> filter recognizes
any of the following ways to protect parts of the input
from being seen by the translators:

=head2 double braces

Parts of the input enclosed in a set of double braces will
be protected from the translator.

    The French word for cat is {{"chat"}}.

=head2 lit and literal pseudo tags

Text enclosed in C<[lit]...[/lit]> or C<[literal]...[/literal]>
tokens will be protected from the translator.

    My friend Mr. [lit]Wong[/lit] lives in [literal]Los Angeles[/literal].

=head2 span tag with lang attribute

Text inside a C<< <span> >> tag with an attribute called C<< lang >>
will be protected from the translator. This is somewhat of a convention
for identifying the source language of some text in an HTML document,
and it wouldn't be sensible for a translator to render text inside those
tags in another language.

    The French word for "hat" is <span lang="fr">"chapeau"</span>.

Note that if your input uses this construction and you also intend to
pass translation input through the L<I22r::Translate::Filter::HTML>
filter, you should include this filter first, or the
C<< <span>...</span> >> tags will not be visible to this filter.
That is, you should specify

    filter => [ 'Literal', 'HTML' ]

rather than

    filter => [ 'HTML', 'Literal' ]


These markup specifications are kind of arbitrary. More may be
added and some may be removed in future releases of this module.
Send me a note (C<< mob at cpan.org >>) if you have an opinion
one way or the other about what is a good way to specify
protected text.

=head1 SEE ALSO

L<I22r::Translate::Filter>, L<I22r::Translate::Filter::HTML>,
L<I22r::Translate>.

=cut
