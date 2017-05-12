#$Id: Lex.pm 106 2007-06-25 10:35:07Z zag $

package HTML::WebDAO::Lex;
use XML::LibXML;
use Data::Dumper;
use HTML::WebDAO::Lexer::Lobject;
use HTML::WebDAO::Lexer::Lbase;
use HTML::WebDAO::Lexer::Lregclass;
use HTML::WebDAO::Lexer::Lobjectref;
use HTML::WebDAO::Lexer::Ltext;
use HTML::WebDAO::Lexer::Linclude;
use HTML::WebDAO::Lexer::Lmethod;
use HTML::WebDAO::Base;
use base qw( HTML::WebDAO::Base );
__PACKAGE__->attributes qw/ tree auto / ;
use strict;

sub _init() {
    my $self = shift;
    return $self->Init(@_);
}

sub Init {
    my $self = shift;
    my %par  = @_;
    $self->auto( [] );
    $self->tree( $self->buld_tree( $par{content} ) ) if $par{content};
    return 1;
}

sub buld_tree {
    my $self     = shift;
    my $raw_html = shift;

    #Mac and DOS line endings
    $raw_html =~ s/\r\n?/\n/g;
    my $mass;
    $mass = [ split( /(<WD>.*?<\/WD>)/is, $raw_html ) ];
    my @res;
    foreach my $text (@$mass) {
        my @ref;
        unless ( $text =~ /^<wd/i ) {
            push @ref,
              HTML::WebDAO::Lexer::Lobject->new(
                class   => "_rawhtml_element",
                id      => "none",
                childs  => [ HTML::WebDAO::Lexer::Ltext->new( value => \$text ) ],
                context => $self
              )  unless $text =~/^\s*$/;
        }
        else {
            my $parser = new XML::LibXML;
            my $dom    = $parser->parse_string($text);
            push @ref, $self->get_obj_tree( $dom->documentElement->childNodes );

        }
        next unless @ref;
        push @res, @ref;
    }
    return \@res;
}

sub get_obj_tree {
    my $self = shift;
    my %map  = (
        object    => 'HTML::WebDAO::Lexer::Lobject',
        regclass  => 'HTML::WebDAO::Lexer::Lregclass',
        objectref => 'HTML::WebDAO::Lexer::Lobjectref',
        text      => 'HTML::WebDAO::Lexer::Ltext',
        include   => 'HTML::WebDAO::Lexer::Linclude',
        default   => 'HTML::WebDAO::Lexer::Lbase',
        method    => 'HTML::WebDAO::Lexer::Lmethod'
    );
    my @result;
    foreach my $node (@_) {
        my $node_name = $node->nodeName;
        my %attr      = map { $_->nodeName => $_->value } grep { defined $_ } $node->attributes;
        my $map_key   = $node->nodeName || 'text';
        $map_key = $map_key =~ /text$/ ? "text" : $map_key; 
        $attr{name} = $map_key unless exists $attr{name};
        if ( $map_key eq 'text' ) { $attr{value} = $node->nodeValue }
        my $lclass = $map{$map_key} || $map{default};
        my @vals = ();
        if ( my @childs = $node->childNodes ) {
            @vals = grep { defined $_ } $self->get_obj_tree(@childs);
        }
        my $lobject = $lclass->new( %attr, childs => \@vals, context => $self ) || next;
        if ( my @res = grep { ref($_) } ( $lobject->get_self ) ) {
            push @result, @res;
        }
    }
    return @result;

}
sub _destroy {
    my $self = shift;
    $self->auto( [] );
}
1;
