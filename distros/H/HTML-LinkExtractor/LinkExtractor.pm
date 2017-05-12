package HTML::LinkExtractor;

use strict;

use HTML::TokeParser 2; # use HTML::TokeParser::Simple 2;
use URI 1;
use Carp qw( croak );

use vars qw( $VERSION );
$VERSION = '0.13';

## The html tags which might have URLs
# the master list of tagolas and required attributes (to constitute a link)
use vars qw( %TAGS );
%TAGS = (
              a => [qw( href )],
         applet => [qw( archive code codebase src )],
           area => [qw( href )],
           base => [qw( href )],
        bgsound => [qw( src )],
     blockquote => [qw( cite )],
           body => [qw( background )],
            del => [qw( cite )],
            div => [qw( src )], # IE likes it, but don't know where it's documented
          embed => [qw( pluginspage pluginurl src )],
           form => [qw( action )],
          frame => [qw( src longdesc  )],
         iframe => [qw( src )],
         ilayer => [qw( background src )],
            img => [qw( dynsrc longdesc lowsrc src usemap )],
          input => [qw( dynsrc lowsrc src )],
            ins => [qw( cite )],
        isindex => [qw( action )], # real oddball
          layer => [qw( src )],
           link => [qw( src href )],
         object => [qw( archive classid code codebase data usemap )],
              q => [qw( cite )],
         script => [qw( src  )], # HTML::Tagset has 'for' ~ it's WRONG!
          sound => [qw( src )],
          table => [qw( background )],
             td => [qw( background )],
             th => [qw( background )],
             tr => [qw( background )],
  ## the exotic cases
           meta => undef,
     '!doctype' => [qw( url )], # is really a process instruction
);

## tags which contain <.*?> STUFF TO GET </\w+>
use vars qw( @TAGS_IN_NEED );
@TAGS_IN_NEED = qw(
    a
    blockquote
    del
    ins
    q
);

use vars qw( @VALID_URL_ATTRIBUTES );
@VALID_URL_ATTRIBUTES = qw(
        action
        archive
        background
        cite
        classid
        code
        codebase
        data
        dynsrc
        href
        longdesc
        lowsrc
        pluginspage
        pluginurl
        src
        usemap
);


sub new {
    my($class, $cb, $base, $strip) = @_;
    my $self = bless {}, $class;


    $self->{_cb} = $cb if defined $cb;
    $self->{_base} = URI->new($base) if defined $base;
    $self->strip( $strip || 0 );

    return $self;
}

sub strip {
    my( $self, $on ) = @_;
    return $self->{_strip} unless defined $on;
    return $self->{_strip} = $on ? 1 : 0;
}

## $p= HTML::TokeParser->new($filename || FILEHANDLE ||\$filecontents); # ## $p= HTML::TokeParser::Simple->new($filename || FILEHANDLE ||\$filecontents);

sub parse {
    my( $this, $hmmm ) = @_;
    my $tp = new HTML::TokeParser( $hmmm ); #     my $tp = new HTML::TokeParser::Simple( $hmmm );

    unless($tp) {
        croak qq[ Couldn't create a HTML::TokeParser object: $!]; #         croak qq[ Couldn't create a HTML::TokeParser::Simple object: $!];
    }

    $this->{_tp} = $tp;

    $this->_parsola();
    return();
}

sub _parsola {
    my $self = shift;

## a stack of links for keeping track of TEXT
## which is all of "<a href>text</a>"
    my @TEXT = ();
    $self->{_LINKS} = [];


#  ["S",  $tag, $attr, $attrseq, $text]
#  ["E",  $tag, $text]
#  ["T",  $text, $is_data]
#  ["C",  $text]
#  ["D",  $text]
#  ["PI", $token0, $text]

    while (my $T = $self->{_tp}->get_token() ) {
        my $NL; #NewLink
        my $Tag = $T->[1]; #         my $Tag = $T->return_tag;
        my $got_TAGS_IN_NEED=0;
## Start tag?
        if($T->[0] eq 'S' ) { #         if($T->is_start_tag) {
            next unless exists $TAGS{$Tag};

## Do we have a tag for which we want to capture text?
            $got_TAGS_IN_NEED = 0;
            $got_TAGS_IN_NEED = grep { /^\Q$Tag\E$/i } @TAGS_IN_NEED;

## then check to see if we got things besides META :)
            if(defined $TAGS{ $Tag }) {

                for my $Btag(@{$TAGS{$Tag}}) {
## and we check if they do have one with a value
                    if(exists $T->[2]->{ $Btag }) { #                     if(exists $T->return_attr()->{ $Btag }) {

                        $NL = $T->[2]; #                         $NL = $T->return_attr();
## TAGS_IN_NEED are tags in deed (start capturing the <a>STUFF</a>)
                        if($got_TAGS_IN_NEED) {
                            push @TEXT, $NL;
                            $NL->{_TEXT} = "";
                        }
                    }
                }
            }elsif($Tag eq 'meta') {
                $NL = $T->[2]; #                 $NL = $T->return_attr();

                if(defined $$NL{content} and length $$NL{content} and (
                    defined $$NL{'http-equiv'} &&  $$NL{'http-equiv'} =~ /refresh/i
                    or
                    defined $$NL{'name'} &&  $$NL{'name'} =~ /refresh/i
                    ) ) {

                    my( $timeout, $url ) = split m{;\s*?URL=}i, $$NL{content},2;
                    my $base = $self->{_base};
                    $$NL{url} = URI->new_abs( $url, $base ) if $base;
                    $$NL{url} = $url unless exists $$NL{url};
                    $$NL{timeout} = $timeout if $timeout;
                }
            }

            ## In case we got nested tags
            if(@TEXT) {
                $TEXT[-1]->{_TEXT} .= $T->[-1] ; #                 $TEXT[-1]->{_TEXT} .= $T->as_is;
            }

## Text?
        }elsif($T->[0] eq 'T' ) { #         }elsif($T->is_text) {
            $TEXT[-1]->{_TEXT} .= $T->[-2]  if @TEXT; #             $TEXT[-1]->{_TEXT} .= $T->as_is if @TEXT;
## Declaration?
        }elsif($T->[0] eq 'D' ) { #         }elsif($T->is_declaration) {
## We look at declarations, to get anly custom .dtd's (tis linky)
            my $text = $T->[-1] ; #             my $text = $T->as_is;
            if( $text =~ m{ SYSTEM \s \" ( [^\"]* ) \" > $ }ix ) {
                $NL = { raw => $text, url => $1, tag => '!doctype' };
            }
## End tag?
        }elsif($T->[0] eq 'E' ){ #         }elsif($T->is_end_tag){
## these be ignored (maybe not in between <a...></a> tags
## unless we're stacking (bug #5723)
            if(@TEXT and exists $TAGS{$Tag}) {
                $TEXT[-1]->{_TEXT} .= $T->[-1] ; #                 $TEXT[-1]->{_TEXT} .= $T->as_is;
                my $pop = pop @TEXT;
                $TEXT[-1]->{_TEXT} .= $pop->{_TEXT} if @TEXT;
                $pop->{_TEXT} = _stripHTML( \$pop->{_TEXT} ) if $self->strip;
                $self->{_cb}->($self, $pop) if exists $self->{_cb};
            }
        }

        if(defined $NL) {
            $$NL{tag} = $Tag;

            my $base = $self->{_base};

            for my $at( @VALID_URL_ATTRIBUTES ) {
                if( exists $$NL{$at} ) {
                    $$NL{$at} = URI->new_abs( $$NL{$at}, $base) if $base;
                }
            }

            if(exists $self->{_cb}) {
                $self->{_cb}->($self, $NL ) if not $got_TAGS_IN_NEED or not @TEXT; #bug#5470
            } else {
                push @{$self->{_LINKS}}, $NL;
            }
        }
    }## endof while (my $token = $p->get_token)

    undef $self->{_tp};
    return();
}

sub links {
    my $self = shift;
    ## just like HTML::LinkExtor's
    return $self->{_LINKS};
}


sub _stripHTML {
    my $HtmlRef = shift;
    my $tp = new HTML::TokeParser( $HtmlRef ); #     my $tp = new HTML::TokeParser::Simple( $HtmlRef );
    my $t = $tp->get_token(); # MUST BE A START TAG (@TAGS_IN_NEED)
                              # otherwise it ain't come from LinkExtractor
    if($t->[0] eq 'S' ) { #     if($t->is_start_tag) {
        return $tp->get_trimmed_text( '/'.$t->[1] ); #         return $tp->get_trimmed_text( '/'.$t->return_tag );
    } else {
        require Data::Dumper;
        local $Data::Dumper::Indent=1;
        die " IMPOSSIBLE!!!! ",
            Data::Dumper::Dumper(
                '$HtmlRef',$HtmlRef,
                '$t', $t,
            );
    }
}

1;

package main;

unless(caller()) {
    require Data::Dumper;
    if(@ARGV) {
        for my $file( @ARGV ) {
            if( -e $file ) {
                my $LX = new HTML::LinkExtractor( );
                $LX->parse( $file );
                print Data::Dumper::Dumper($LX->links);
                undef $LX;
            } else {
                warn "The file `$file' doesn't exist\n";
            }
        }
        
    } else {
    
        my $INPUT = q{
COUNT THEM BOYS AND GIRLS, LINKS OUTGHT TO HAVE 9 ELEMENTS.

1 <!DOCTYPE HTML SYSTEM "http://www.w3.org/DTD/HTML4-strict.dtd">
2 <meta HTTP-EQUIV="Refresh" CONTENT="5; URL=http://www.foo.com/foo.html">
3 <base href="http://perl.org">
4 <a href="http://www.perlmonks.org">Perlmonks.org</a>
<p>

5 <a href="#BUTTER"  href="#SCOTCH">
    hello there
6 <img src="#AND" src="#PEANUTS">
7    <a href="#butter"> now </a>
</a>

8 <q CITE="http://www.shakespeare.com/">To be or not to be.</q>
9 <blockquote CITE="http://www.stonehenge.com/merlyn/">
    Just Another Perl Hacker,
</blockquote>
    };

        my $LX = new HTML::LinkExtractor();
        $LX->parse(\$INPUT);

        print scalar(@{$LX->links()})." we GOT\n";
        print Data::Dumper::Dumper( $LX->links() );
    }
    
}

__END__


=head1 NAME

HTML::LinkExtractor - Extract I<L<links|/"WHAT'S A LINK-type tag">> from an HTML document

=head1 DESCRIPTION

HTML::LinkExtractor is used for extracting links from HTML.
It is very similar to L<HTML::LinkExtor|HTML::LinkExtor>,
except that besides getting the URL, you also get the link-text.

Example ( B<please run the examples> ):

    use HTML::LinkExtractor;
    use Data::Dumper;

    my $input = q{If <a href="http://perl.com/"> I am a LINK!!! </a>};
    my $LX = new HTML::LinkExtractor();

    $LX->parse(\$input);

    print Dumper($LX->links);
    __END__
    # the above example will yield
    $VAR1 = [
              {
                '_TEXT' => '<a href="http://perl.com/"> I am a LINK!!! </a>',
                'href' => bless(do{\(my $o = 'http://perl.com/')}, 'URI::http'),
                'tag' => 'a'
              }
            ];

C<HTML::LinkExtractor> will also correctly extract nested
I<L<link-type|/"WHAT'S A LINK-type tag">> tags.

=head1 SYNOPSIS

    ## the demo
    perl LinkExtractor.pm
    perl LinkExtractor.pm file.html othefile.html

    ## or if the module is installed, but you don't know where

    perl -MHTML::LinkExtractor -e" system $^X, $INC{q{HTML/LinkExtractor.pm}} "
    perl -MHTML::LinkExtractor -e' system $^X, $INC{q{HTML/LinkExtractor.pm}} '

    ## or

    use HTML::LinkExtractor;
    use LWP qw( get ); #     use LWP::Simple qw( get );

    my $base = 'http://search.cpan.org';
    my $html = get($base.'/recent');
    my $LX = new HTML::LinkExtractor();

    $LX->parse(\$html);

    print qq{<base href="$base">\n};

    for my $Link( @{ $LX->links } ) {
    ## new modules are linked  by /author/NAME/Dist
        if( $$Link{href}=~ m{^\/author\/\w+} ) {
            print $$Link{_TEXT}."\n";
        }
    }

    undef $LX;
    __END__

    ## or

    use HTML::LinkExtractor;
    use Data::Dumper;

    my $input = q{If <a href="http://perl.com/"> I am a LINK!!! </a>};
    my $LX = new HTML::LinkExtractor(
        sub {
            print Data::Dumper::Dumper(@_);
        },
        'http://perlFox.org/',
    );

    $LX->parse(\$input);
    $LX->strip(1);
    $LX->parse(\$input);
    __END__

    #### Calculate to total size of a web-page
    #### adds up the sizes of all the images and stylesheets and stuff

    use strict;
    use LWP; #     use LWP::Simple;
    use HTML::LinkExtractor;
                                                        #
    my $url  = shift || 'http://www.google.com';
    my $html = get($url);
    my $Total = length $html;
                                                        #
    print "initial size $Total\n";
                                                        #
    my $LX = new HTML::LinkExtractor(
        sub {
            my( $X, $tag ) = @_;
                                                        #
            unless( grep {$_ eq $tag->{tag} } @HTML::LinkExtractor::TAGS_IN_NEED ) {
                                                        #
    print "$$tag{tag}\n";
                                                        #
                for my $urlAttr ( @{$HTML::LinkExtractor::TAGS{$$tag{tag}}} ) {
                    if( exists $$tag{$urlAttr} ) {
                        my $size = (head( $$tag{$urlAttr} ))[1];
                        $Total += $size if $size;
    print "adding $size\n" if $size;
                    }
                }
            }
        },
        $url,
        0
    );
                                                        #
    $LX->parse(\$html);
                                                        #
    print "The total size of \n$url\n is $Total bytes\n";
    __END__


=head1 METHODS

=head2 C<$LX-E<gt>new([\&callback, [$baseUrl, [1]]])>

Accepts 3 arguments, all of which are optional.
If for example you want to pass a C<$baseUrl>, but don't
want to have a callback invoked, just put C<undef> in place of a subref.

This is the only class method.

=over 4

=item 1

a callback ( a sub reference, as in C<sub{}>, or C<\&sub>)
which is to be called each time a new LINK is encountered
( for C<@HTML::LinkExtractor::TAGS_IN_NEED> this means
 after the closing tag is encountered )

The callback receives an object reference(C<$LX>) and a link hashref.


=item 2

and a base URL ( URI->new, so its up to you to make sure it's valid
which is used to convert all relative URI's to absolute ones.

    $ALinkP{href} = URI->new_abs( $ALink{href}, $base );

=item 3

A "boolean" (just stick with 1).
See the example in L<"DESCRIPTION">.
Normally, you'd get back _TEXT that looks like

    '_TEXT' => '<a href="http://perl.com/"> I am a LINK!!! </a>',

If you turn this option on, you'll get the following instead

    '_TEXT' => ' I am a LINK!!! ',

The private utility function C<_stripHTML> does this
by using L<HTML::TokeParser|HTML::TokeParser>s
method get_trimmed_text.

You can turn this feature on an off by using
C<$LX-E<gt>strip(undef E<verbar>E<verbar> 0 E<verbar>E<verbar> 1)>

=back

=head2 C<$LX-E<gt>parse( $filename E<verbar>E<verbar> *FILEHANDLE E<verbar>E<verbar> \$FileContent )>

Each time you call C<parse>, you should pass it a
C<$filename> a C<*FILEHANDLE> or a C<\$FileContent>

Each time you call C<parse> a new C<HTML::TokeParser> object 
is created and stored in C<$this-E<gt>{_tp}>.

You shouldn't need to mess with the TokeParser object.

=head2 C<$LX-E<gt>links()>

Only after you call C<parse> will this method return anything.
This method returns a reference to an ArrayOfHashes,
which basically looks like (Data::Dumper output)

    $VAR1 = [ { tag => 'img', src => 'image.png' }, ];

Please note that if yo provide a callback this array will be empty.


=head2 C<$LX-E<gt>strip( [ 0 || 1 ])>

If you pass in C<undef> (or nothing), returns the state of the option.
Passing in a true or false value sets the option.

If you wanna know what the option does see
L<C<$LX-E<gt>new([\&callback, [$baseUrl, [1]]])>|/"METHODS">

=head1 WHAT'S A LINK-type tag

Take a look at C<%HTML::LinkExtractor::TAGS> to see
what I consider to be link-type-tag.

Take a look at C<@HTML::LinkExtractor::VALID_URL_ATTRIBUTES> to see
all the possible tag attributes which can contain URI's (the links!!)

Take a look at C<@HTML::LinkExtractor::TAGS_IN_NEED> to see
the tags for which the C<'_TEXT'> attribute is provided,
like C<E<lt>a href="#"E<gt> TEST E<lt>/aE<gt>>


=head2 How can that be?!?!

I took at look at L<C<%HTML::Tagset::linkElements>|HTML::Tagset>
and the following URL's

    http://www.blooberry.com/indexdot/html/tagindex/all.htm

    http://www.blooberry.com/indexdot/html/tagpages/a/a-hyperlink.htm
    http://www.blooberry.com/indexdot/html/tagpages/a/applet.htm
    http://www.blooberry.com/indexdot/html/tagpages/a/area.htm

    http://www.blooberry.com/indexdot/html/tagpages/b/base.htm
    http://www.blooberry.com/indexdot/html/tagpages/b/bgsound.htm

    http://www.blooberry.com/indexdot/html/tagpages/d/del.htm
    http://www.blooberry.com/indexdot/html/tagpages/d/div.htm

    http://www.blooberry.com/indexdot/html/tagpages/e/embed.htm
    http://www.blooberry.com/indexdot/html/tagpages/f/frame.htm

    http://www.blooberry.com/indexdot/html/tagpages/i/ins.htm
    http://www.blooberry.com/indexdot/html/tagpages/i/image.htm
    http://www.blooberry.com/indexdot/html/tagpages/i/iframe.htm
    http://www.blooberry.com/indexdot/html/tagpages/i/ilayer.htm
    http://www.blooberry.com/indexdot/html/tagpages/i/inputimage.htm

    http://www.blooberry.com/indexdot/html/tagpages/l/layer.htm
    http://www.blooberry.com/indexdot/html/tagpages/l/link.htm

    http://www.blooberry.com/indexdot/html/tagpages/o/object.htm

    http://www.blooberry.com/indexdot/html/tagpages/q/q.htm

    http://www.blooberry.com/indexdot/html/tagpages/s/script.htm
    http://www.blooberry.com/indexdot/html/tagpages/s/sound.htm

    And the special cases 

    <!DOCTYPE HTML SYSTEM "http://www.w3.org/DTD/HTML4-strict.dtd">
    http://www.blooberry.com/indexdot/html/tagpages/d/doctype.htm
    '!doctype'  is really a process instruction, but is still listed
    in %TAGS with 'url' as the attribute

    and

    <meta HTTP-EQUIV="Refresh" CONTENT="5; URL=http://www.foo.com/foo.html">
    http://www.blooberry.com/indexdot/html/tagpages/m/meta.htm
    If there is a valid url, 'url' is set as the attribute.
    The meta tag has no 'attributes' listed in %TAGS.


=head1 SEE ALSO

L<HTML::LinkExtor>, L<HTML::TokeParser>, L<HTML::Tagset>.

=head1 AUTHOR

D.H (PodMaster)


Please use http://rt.cpan.org/ to report bugs.

Just go to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Scrubber
to see a bug list and/or repot new ones.

=head1 LICENSE

Copyright (c) 2003, 2004 by D.H. (PodMaster).
All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut

