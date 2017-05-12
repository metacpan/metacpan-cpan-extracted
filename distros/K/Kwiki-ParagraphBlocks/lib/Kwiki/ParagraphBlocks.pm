package Kwiki::ParagraphBlocks;
use Kwiki::Plugin -Base;
our $VERSION = '0.12';

const class_id => 'paragraph_blocks';
const class_title => 'Paragraph Blocks';

sub register {
    my $registry = shift;
    $registry->add(wafl => p => 'Kwiki::ParagraphBlocks::Wafl');
}

package Kwiki::ParagraphBlocks::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    my $block = Kwiki::Formatter::Paragraph->new(
        hub => $self->hub, 
        text => $self->block_text,
    );
    $block->parse_phrases;
    my $html = $block->to_html;
    $html =~ s/.*?<p.*?>\n?(.*)<\/p>.*/$1/s;
    $html =~ s/\n/<br \/>\n/g;
    $html =~ s/^( +)/'&nbsp;' x length($1)/gem;
    return "<p>\n$html</p>";
}

__DATA__

=head1 NAME 

Kwiki::ParagraphBlocks - Kwiki Paragraph Blocks Plugin

=head1 SYNOPSIS

    .p
    There once was a man from /New Yiki/,
    Who took up a _penchant for wiki_.

      Though he thought it quite slick,
      He wished it were quick.

    er, you see, the man's wiki was *Kwiki*.
    .p

=head1 DESCRIPTION

Mark paragraphs that have hard line endings and whitespace.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
