package HTML::WikiConverter::FreeStyleWiki;
use 5.008001;
use strict;
use warnings;
use parent 'HTML::WikiConverter';
use Params::Validate ':types';

our $VERSION = "0.03";

sub attributes {
    +{
        p_strict            => { default => 0 },
        escape_entities => { default => 0 },
        preserve_tags   => { default => 0, type => BOOLEAN },
    };
}

sub rules {
    my ($self) = @_;
    my %rules = (
        hr => { replace => "\n----\n" },
        br => { replace => \&_br },

        blockquote => { start => qq{\n}, block => 1, line_format => 'multi', line_prefix => q{""} },
        p => { end => "\n", block => 1, trim => 'both', line_format => 'multi', line_prefix => '' },
        i      => { start => q{''},  end => q{''} },
        em     => { alias => 'i' },
        b      => { start => q{'''}, end => q{'''} },
        strong => { alias => 'b' },
        del    => { start => '==',   end => '==', },
        ins    => { start => '__',   end => '__', },

        img => { replace => \&_image },
        a   => { replace => \&_link },

        ul => { line_format => 'multi',  block => 1 },
        ol => { alias       => 'ul' },
        dl => { line_format => 'blocks', block => 1 },

        li => { start => \&_li_start, trim => 'leading' },
        dt => { start       => '::',    trim        => 'both', 'end' => "\n" },
        dd => { line_format => 'multi', line_prefix => ':::' },

        td => { start => ',', trim => 'both' },
        th => { alias => 'td' },
        tr => { end   => "\n" },

        h1 => { start => '!!!', block => 1, trim => 'both', line_format => 'single' },
        h2 => { start => '!!!', block => 1, trim => 'both', line_format => 'single' },
        h3 => { start => '!!',  block => 1, trim => 'both', line_format => 'single' },
        h4 => { start => '!',   block => 1, trim => 'both', line_format => 'single' },
        h5 => { start => '!',   block => 1, trim => 'both', line_format => 'single' },
        h6 => { start => '!',   block => 1, trim => 'both', line_format => 'single' },

        pre => { start => qq{\n}, end => "\n", line_format => 'multi', line_prefix => ' ' },
    );

    if ($self->preserve_tags) {
        for my $tag (qw/ big small tt abbr acronym cite code dfn kbd samp var sup sub /) {
            $rules{$tag} = { preserve => 1 }
        }
    }

    return \%rules;
}

# Calculates the prefix that will be placed before each list item.
# List item include ordered and unordered list items.
sub _li_start {
    my ( $self, $node, $rules ) = @_;
    my @parent_lists = $node->look_up( _tag => qr/ul|ol/ );
    my $depth = @parent_lists;
    if ( defined $node->{text} ) {
        $node->{text} =~ s/\A\s+//;
    }

    my $bullet = '';
    $bullet = '*' if $node->parent->tag eq 'ul';
    $bullet = '+' if $node->parent->tag eq 'ol';

    my $prefix = ($bullet) x $depth;
    return "\n$prefix ";
}

sub _image {
    my ( $self, $node, $rules ) = @_;
    my $url = $node->attr('src') || '';
    if ( $url =~ m{page=([^&]*)&(?:amp;)?file=([^&]*)&(?:amp;)?action=ATTACH}msx )
    {    # ref_image plugin
        return sprintf "{{ref_image %s,%s}}", $2, $1 if $2;
    }
    elsif ($url) {    # image plugin
        return sprintf "{{image %s}}", $url;
    }
    return '';
}

sub _link {
    my ( $self, $node, $rules ) = @_;
    my $url = $node->attr('href') || '';
    $url =~ s/&amp;/&/g;
    my $title = $self->get_wiki_page($url) || $self->extract_wiki_page($url) || '';
    my $text = $self->get_elem_contents($node) || '';
    return "[[$text]]" if $title eq $text;
    return "[[$text|$title]]" if $title;
    return $url if $url eq $text;

    if ( my $relative_url = $self->get_relative_url($url) ) {
        return "[$text|$relative_url]";
    }
    return "[$text|$url]";
}

sub get_relative_url {
    my ( $self, $url ) = @_;
    return unless $self->base_uri;
    $self->base_uri =~ m{/([^/]*)$};
    my $path   = $1 || '';
    my $re_tmp = '(' . quotemeta($path) . '(/[^/]+)?(\?.*)?)$';
    my $re     = qr($re_tmp);
    $url =~ /$re/ or return;
    return $2 ? $1 : $3;
}

sub extract_wiki_page {
    my ( $self, $url ) = @_;
    my $re_tmp = quotemeta( $self->base_uri ) . '\?page=([^&]+)$';
    my $re     = qr($re_tmp);
    return $url =~ /$re/ && $1;
}

sub _br {
    my ( $self, $node, $rules ) = @_;

    #  print $node->dump;
    #  print $node->right->dump;
    if ( $node->right and $node->right->tag eq '~text' ) {
        $node->right->{text} =~ s/\A\s+//msx;
        $node->right->{text} =~ s/\s+\z//msx;

        #      warn join ':', $node->lineage_tag_names;
    }
    return "\n";
}

sub postprocess_output {
    my ( $self, $outref ) = @_;
    $$outref =~ s/^""""(?!")/""/gmx;       # nested blockquote change to plain blockquote
    $$outref =~ s/^([\*\+]+)\s+/$1/gmx;    # delete space on li start
}

sub preprocess_node {
    my ( $self, $node ) = @_;
    $self->strip_aname($node)  if defined $node->tag and $node->tag eq 'a';
    $self->caption2para($node) if defined $node->tag and $node->tag eq 'caption';
    if (    $node->tag
        and $node->tag eq 'br'
        and $node->right
        and $node->right->tag
        and $node->right->tag eq 'pre'
        and $node->parent->tag
        and $node->parent->tag eq 'p' )
    {
        $node->parent->replace_with_content();
    }
}


1;
__END__

=pod

=encoding utf-8

=head1 NAME

HTML::WikiConverter::FreeStyleWiki - Convert HTML to FreeStyleWiki markup

=head1 SYNOPSIS

    use HTML::WikiConverter;
    my $wc = new HTML::WikiConverter( dialect => 'FreeStyleWiki' );
    print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into FreeStyleWiki
markup. See L<HTML::WikiConverter> for additional usage details.

=head1 ATTRIBUTES

In addition to the regular set of attributes recognized by the
L<HTML::WikiConverter> constructor, this dialect also accepts the
following attributes that can be passed into the C<new()>
constructor. See L<HTML::WikiConverter/ATTRIBUTES> for usage details.

=head2 preserve_tags

Possible values: C<0>, C<1>. Default is C<0>.
Preserve tags: C<'big', 'small', 'tt', 'abbr', 'acronym', 'cite', 'code', 'dfn', 'kbd', 'samp', 'var', 'sup', 'sub>

=head1 LICENSE

Copyright (C) Yusuke Watase.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Watase E<lt>ywatase@gmail.comE<gt>

=cut
