package HTML::Feature::Engine::TagStructure;
use strict;
use warnings;
use Statistics::Lite qw(statshash);
use HTML::TreeBuilder::LibXML;
use HTML::Feature::Result;
use base qw(HTML::Feature::Base);

sub run {
    my $self     = shift;
    my $html_ref = shift;
    my $url      = shift;
    my $result   = shift;
    my $c        = $self->context;
    $self->_tag_cleaning($html_ref);
    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($$html_ref);
    $tree->eof;
    my $data;

    if ( !$result->title ) {
        if ( my $title = $tree->findvalue('//title') ) {
            $result->title($title);
        }
    }
    if ( !$result->desc ) {
        if ( my $desc =
            $tree->look_down( _tag => 'meta', name => 'description' ) )
        {
            my $string = $desc->attr('content');
            $string =~ s{<br>}{}xms;
            $result->desc($string);
        }
    }
    my $i = 0;
    my @ratio;
    my @depth;
    my @order;
    for my $node (
        $tree->look_down( sub { 1 if $_->tag =~ /body|center|td|div/i } ) )
    {
        my $html_length = bytes::length( $node->as_HTML );
        my $text        = $node->as_text;
        my $text_length = bytes::length($text);
        my $text_ration = $text_length / ( $html_length + 0.001 );

        next
          if (  $c->{max_bytes}
            and $c->{max_bytes} =~ /^[\d]+$/
            && $text_length > $c->{max_bytes} );
        next
          if (  $c->{min_bytes}
            and $c->{min_bytes} =~ /^[\d]+$/
            and $text_length < $c->{min_bytes} );

        my $a_count       = 0;
        my $a_length      = 0;
        my $option_count  = 0;
        my $option_length = 0;
        my %node_hash     = (
            text                => '',
            a_length            => 0,
            short_string_length => 0
        );
        $self->_walk_tree( $node, \%node_hash );
        $node_hash{a_length}            ||= 0;
        $node_hash{option_length}       ||= 0;
        $node_hash{short_string_length} ||= 0;
        $node_hash{text}                ||= $text;
        $data->[$i]->{text} = $node_hash{text};
        push(
            @ratio,
            (
                $text_length -
                  $node_hash{a_length} -
                  $node_hash{option_length} -
                  $node_hash{short_string_length}
              ) * $text_ration
        );
        my $depth;

        for ( $node->{node}->nodePath =~ /(\/)/g ) {
            $depth++;
        }
        $depth -= 2;
        push( @depth, $depth );
        $data->[$i]->{element} = $node;
        $i++;
    }
    for ( 0 .. $i ) {
        push( @order, log( $i - $_ + 1 ) );
    }
    my %ratio = statshash @ratio;
    my %depth = statshash @depth;
    my %order = statshash @order;
    $tree->delete() unless $c->{element_flag};    # avoid memory leak
    my @sorted = sort { $data->[$b]->{score} <=> $data->[$a]->{score} }
      map {
        my $ratio_std =
          ( ( $ratio[$_] || 0 ) - ( $ratio{mean} || 0 ) ) /
          ( $ratio{stddev} + 0.001 );
        my $depth_std =
          ( ( $depth[$_] || 0 ) - ( $depth{mean} || 0 ) ) /
          ( $depth{stddev} + 0.001 );
        my $order_std =
          ( ( $order[$_] || 0 ) - ( $order{mean} || 0 ) ) /
          ( $order{stddev} + 0.001 );
        $data->[$_]->{score} = $ratio_std + $depth_std + $order_std;
        $_;
      } ( 0 .. $i );
    $data->[ $sorted[0] ]->{text}
      and $data->[ $sorted[0] ]->{text} =~ s/ $//s;
    $result->text( $data->[ $sorted[0] ]->{text} );
    if ( $c->{element_flag} ) {
        $result->root($tree);
        $result->element( $data->[ $sorted[0] ]->{element} );
    }
    if ( $result->text ) {
        $result->{matched_engine} = 'TagStructure';
    }
    $tree->delete;
    return $result;
}

sub _walk_tree {
    my $self          = shift;
    my $node          = shift;
    my $node_hash_ref = shift;
    if ( ref $node ) {
        for (qw/a option dt th/) {
            if ( $node->tag eq $_ ) {
                $node_hash_ref->{a_length} += bytes::length( $node->as_text );
            }
        }
        if ( bytes::length( $node->as_text ) < 20 ) {
            $node_hash_ref->{short_string_length} +=
              bytes::length( $node->as_text );
        }
        $self->_walk_tree( $_, $node_hash_ref )
          for $node->findnodes('child::*');
    }
}

sub _tag_cleaning {
    my $self     = shift;
    my $html_ref = shift;
    ## preprocessing
    $$html_ref =~ s{<!-.*?->}{}xmsg;
    $$html_ref =~ s{<script[^>]*>.*?<\/script>}{}xmgs;
    $$html_ref =~ s{&nbsp;}{ }xmg;
    $$html_ref =~ s{&quot;}{\'}xmg;
    $$html_ref =~ s{\r\n}{\n}xmg;
    $$html_ref =~ s{^\s*(.+)$}{$1}xmg;
    $$html_ref =~ s{^\t*(.+)$}{$1}xmg;
    ## control code ( 0x00 - 0x1F, and 0x7F on ascii)
    for ( 0 .. 31 ) {
        next if $_ == 10;    # without NL(New Line)
        my $control_code = '\x' . sprintf( "%x", $_ );
        $$html_ref =~ s{$control_code}{}xmg;
    }
    $$html_ref =~ s{\x7f}{}xmg;
}
1;
__END__

=head1 NAME

HTML::Feature::Engine::TagStructure - default Engine

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 run()

=head1 author

takeshi miki e<lt>miki@cpan.orge<gt>

=head1 license

this library is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=head1 see also

=cut
