package HTML::Feature::Engine::GoogleADSection;
use strict;
use warnings;
use HTML::TreeBuilder::LibXML;
use base qw(HTML::Feature::Base);

sub run {
    my $self     = shift;
    my $html_ref = shift;
    my $url      = shift;
    my $result   = shift;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($$html_ref);
    $tree->eof;

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
    my $regexp =
'<!--\s+google_ad_section_start\s+-->(.+)<!--\s+google_ad_section_end\s+-->';

    if ( $$html_ref =~ m |$regexp|os ) {
        my $html = $1;
        my $tree = HTML::TreeBuilder::LibXML->new;
        $tree->parse($html);
        $tree->eof;
        my $text = $tree->as_text;
        $result->text($text);
        $result->{matched_engine} = 'GoogleADSection';
    }
    $tree->delete;
    return $result;
}
1;
__END__

=head1 NAME

HTML::Feature::Engine::GoogleADSection - An engine module that uses Google AD Section tag.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 run

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
