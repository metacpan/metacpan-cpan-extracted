use strict;
use warnings;
package HTML::Element::AbsoluteXPath;

# ABSTRACT: Add absolute XPath support to HTML::Element

our $VERSION = '1.0'; # VERSION

use HTML::Element 5.03;

sub HTML::Element::abs_xpath{
    my $self = shift;
    my @hint = @_;
   
    push(@hint,'_tag') unless grep{$_ eq '_tag'}@hint;

    my $raddr = $self->root()->address;
    my @lin;
    my $ee = $self; 
    while( $ee->address ne $raddr ){
        my $p = $ee->parent();
        my %filters;
        foreach (sort @hint){
            my $v = $ee->attr($_);
            next unless $v;
            $filters{$_} = $v;
        }   
        my @sib = $p->look_down(%filters);

        @sib = grep{$_->depth() == $ee->depth()}@sib;
        my $idx = 1;
        foreach (@sib){
            last if $_->address eq $ee->address;
            $idx++;
        }   

        my @attrs;
        foreach (sort keys %filters){
            next if $_ eq '_tag';
            my $v = $filters{$_};
            my $pat = "\@$_='$v'";
            push(@attrs,$pat);
        }   

        my $attr = ''; 
        $attr = "[".join(' and ',@attrs)."]" if @attrs;

        push(@lin, $ee->tag() . $attr . "[$idx]" );
        $ee = $p; 
    }   
    push(@lin, $ee->tag().'[1]' );
    return '/'.join('/',reverse @lin);
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Element::AbsoluteXPath - Add absolute XPath support to HTML::Element

=head1 VERSION

version 1.0

=head1 DESCRIPTION

HTML::Element::AbsoluteXPath adds ABSOLUTE XPath support to HTML::Element by adding 'abs_xpath' method to HTML::Element package.

It generates smarter XPaths with HINTS which are attributes name of HTML element, like 'class','id','width','name' and etc.

=head1 SYSNOPSIS

    use HTML::Element;
    use HTML::Element::AbsoluteXPath;

    ...

    print $elem->abs_xpath;
    # output like '/html[1]/body[1]/div[1]'

more

    use 5.010;
    use HTML::TreeBuilder->new;
    use HTML::Element::AbsoluteXPath;
    
    my $root = HTML::TreeBuilder->new;
    my $html = <<END;
    <html>
        <body>
            <div id="test" class="testclass"></div>
            <div class="testclass"></div>
            <div>
                <div class="innerclass"></div>
                <div></div>
            </div>
        </body>
    </html>
    END
    $root->parse($html);
    $root->eof();

    # get abs xpath of root
    say $root->abs_xpath; # '/html[1]' 
    
    my @found = $root->find_by_tag_name('div');
    
    # get abs xpath
    say $found[0]->abs_xpath; # '/html[1]/body[1]/div[1]' 
    
    # get abs xpath with 'id' hint.
    say $found[0]->abs_xpath('id'); #, "/html[1]/body[1]/div[@id='test'][1]"
    
    # get abs xpath with 'id' and 'class' hints.
    say $found[0]->abs_xpath('id','class'); # "/html[1]/body[1]/div[@id='test' and @class='testclass'][1]"
    
    # get abs xpath hints for elem has just 'class' attr.
    say $found[1]->abs_xpath('id','class'); # "/html[1]/body[1]/div[@class='testclass'][2]"
    
    # get abs xpath with hints for elem has no attrs
    say $found[2]->abs_xpath('id','class'); # "/html[1]/body[1]/div[3]"
    
    # get abs xpath overwrapped one
    say $found[2]->content->[0]->abs_xpath('id','class'); # "/html[1]/body[1]/div[3]/div[@class='innerclass'][1]"
    
    # get abs xpath overwrapped sibling
    say $found[2]->content->[1]->abs_xpath('id','class'); # "/html[1]/body[1]/div[3]/div[2]"

=head1 METHODS

=head3 abs_xpath( [ $hint, ... ] )

Returns an absolute xpath of current HTML::Element object.

Hints are optional. Internally, '_tag' is added to hints.

With no hints, it generates an xpath with only ordinary expressions like "/html[1]/body[1]/div[1]", "/html[1]/body[1]/a[13]".

If you set 'class' as hint, it generates a smarter xpath like "/html[1]/body[1]/div[@class='SOME'][1]","/html[1]/body[1]/div[2]".

Hints work for being matched attribute names which have values.

=head1 SEE ALSO

=over

=item *

L<HTML::TreeBuilder>

=item *

L<HTML::TreeBuilder::XPath>

=item *

L<HTML::Element>

=back

=head1 SOURCE

L<https://github.com/sng2c/HTML-Element-AbsoluteXPath>

=head1 AUTHOR

HyeonSeung Kim <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
