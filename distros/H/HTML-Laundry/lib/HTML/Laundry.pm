########################################################
# Copyright © 2009 Six Apart, Ltd.

package HTML::Laundry;

use strict;
use warnings;

use 5.008;
use version; our $VERSION = 0.0107;

=head1 NAME

HTML::Laundry - Perl module to clean HTML by the piece

=head1 VERSION

Version 0.0107

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;
    use HTML::Laundry;
    my $laundry = HTML::Laundry->new();
    my $snippet = q{
        <P STYLE="font-size: 300%"><BLINK>"You may get to touch her<BR>
        If your gloves are sterilized<BR></BR>
        Rinse your mouth with Listerine</BR>
        Blow disinfectant in her eyes"</BLINK><BR>
        -- X-Ray Spex, <I>Germ-Free Adolescents<I>
        <SCRIPT>alert('!!');</SCRIPT>
    };
    my $germfree = $laundry->clean($snippet);
    # $germfree is now:
    #   <p>&quot;You may get to touch her<br />
    #   If your gloves are sterilized<br />
    #   Rinse your mouth with Listerine<br />
    #   Blow disinfectant in her eyes&quot;<br />
    #   -- X-Ray Spex, <i>Germ-Free Adolescents</i></p>
        
=head1 DESCRIPTION

HTML::Laundry is an L<HTML::Parser|HTML::Parser>-based HTML normalizer, 
meant for small pieces of HTML, such as user comments, Atom feed entries,
and the like, rather than full pages. Laundry takes these and returns clean,
sanitary, UTF-8-based XHTML. The parser's behavior may be changed with
callbacks, and the whitelist of acceptable elements and attributes may be
updated on the fly.

A snippet is cleaned several ways:

=over 4

=item * Normalized, using HTML::Parser: attributes and elements will be
lowercased, empty elements such as <img /> and <br /> will be forced into
the empty tag syntax if needed, and unknown attributes and elements will be
stripped.

=item * Sanitized, using an extensible whitelist of valid attributes and 
elements based on Mark Pilgrim and Aaron Swartz's work on C<sanitize.py>: tags
and attributes which are known to be possible attack vectors are removed.

=item * Tidied, using L<HTML::Tidy|HTML::Tidy> or L<HTML::Tidy::libXML|HTML::Tidy::libXML>
(as available): unclosed tags will be closed and the output generally 
neatened; future version may also use tidying to deal with character encoding
issues.

=item * Optionally rebased, to turn relative URLs in attributes into
absolute ones.

=back

HTML::Laundry provides mechanisms to extend the list of known allowed 
(and disallowed) tags, along with callback methods to allow scripts using
HTML::Laundry to extend the behavior in various ways. Future versions
may provide additional options for altering the rules used to clean 
snippets.

Out of the box, HTML::Laundry does not currently know about the <head> tag
and its children. For santizing full HTML pages, consider using L<HTML::Scrubber|HTML::Scrubber>
or L<HTML::Defang|HTML::Defang>.

=cut

require HTML::Laundry::Rules;
require HTML::Laundry::Rules::Default;

require HTML::Parser;
use HTML::Entities qw(encode_entities encode_entities_numeric);
use URI;
use URI::Escape qw(uri_unescape uri_escape uri_escape_utf8);
use URI::Split qw();
use Scalar::Util 'blessed';

my @fragments;
my $unacceptable_count;
my $local_unacceptable_count;
my $cdata_dirty;
my $in_cdata;
my $tag_leading_whitespace = qr/
    (?<=<)  # Left bracket followed by
    \s*     # any amount of whitespace
    (\/?)   # optionally with a forward slash
    \s*     # and then more whitespace
/x;

=head1 FUNCTIONS

=head2 new

Create an HTML::Laundry object.

    my $l = HTML::Laundry->new();

Takes an optional anonymous hash of arguments:

=over 4

=item * base_url

This turns relative URIs, as in C<<img src="surly_otter.png">>, into 
absolute URIs, as for use in feed parsing.

    my $l = HTML::Laundry->new({ base_uri => 'http://example.com/foo/' });
    

=item * notidy

Disable use of HTML::Tidy or HTML::Tidy::libXML, even if
they are available on your system.

    my $l = HTML::Laundry->new({ notidy => 1 });
    
=back

=cut

sub new {
    my $self  = {};
    my $class = shift;
    my $args  = shift;

    if ( blessed $args ) {
        if ( $args->isa('HTML::Laundry::Rules') ) {
            $args = { rules => $args };
        }
        else {
            $args = {};
        }
    }
    elsif ( ref $args ne 'HASH' ) {
        my $rules;
        {
            local $@;
            eval {
                        $args->isa('HTML::Laundry::Rules')
                    and $rules = $args->new;
            };
        }
        if ($rules) {
            $args = { rules => $args };
        }
        else {
            $args = {};
        }
    }

    $self->{tidy}              = undef;
    $self->{tidy_added_inline} = {};
    $self->{tidy_added_empty}  = {};
    $self->{base_uri}          = q{};
    bless $self, $class;
    $self->clear_callback('start_tag');
    $self->clear_callback('end_tag');
    $self->clear_callback('uri');
    $self->clear_callback('text');
    $self->clear_callback('output');
    $self->{parser} = HTML::Parser->new(
        api_version => 3,
        utf8_mode   => 1,
        start_h => [ sub { $self->_tag_start_handler(@_) }, 'tagname,attr' ],
        end_h  => [ sub { $self->_tag_end_handler(@_) }, 'tagname,attr' ],
        text_h => [ sub { $self->_text_handler(@_) },    'dtext,is_cdata' ],
        empty_element_tags => 1,
        marked_sections    => 1,
    );
    $self->{cdata_parser} = HTML::Parser->new(
        api_version => 3,
        utf8_mode   => 1,
        start_h => [ sub { $self->_tag_start_handler(@_) }, 'tagname,attr' ],
        end_h  => [ sub { $self->_tag_end_handler(@_) }, 'tagname,attr' ],
        text_h => [ sub { $self->_text_handler(@_) },    'dtext' ],
        empty_element_tags => 1,
        unbroken_text      => 1,
        marked_sections    => 0,
    );
    $self->initialize($args);

    if ( !$args->{notidy} ) {
        $self->_generate_tidy;
    }
    return $self;
}

=head2 initialize

Instantiates the Laundry object properties based on an
HTML::Laundry::Rules module.

=cut

sub initialize {
    my ( $self, $args ) = @_;

    # Set defaults
    $self->{tidy_added_tags}          = undef;
    $self->{tidy_empty_tags}          = undef;
    $self->{trim_trailing_whitespace} = 1;
    $self->{trim_tag_whitespace}      = 0;
    $self->{base_uri}                 = URI->new( $args->{base_uri} )
        if $args->{base_uri};
    my $rules = $args->{rules};
    $rules ||= HTML::Laundry::Rules::Default->new();

    $self->{ruleset} = $rules;

    # Initialize based on ruleset
    $self->{acceptable_a}    = $rules->acceptable_a();
    $self->{acceptable_e}    = $rules->acceptable_e();
    $self->{empty_e}         = $rules->empty_e();
    $self->{unacceptable_e}  = $rules->unacceptable_e();
    $self->{uri_list}        = $rules->uri_list();
    $self->{allowed_schemes} = $rules->allowed_schemes();
    $rules->finalize_initialization($self);

    return;
}

=head2 add_callback

Adds a callback of type "start_tag", "end_tag", "text", "uri", or "output" to
the appropriate internal array.

    $l->add_callback('start_tag', sub {
        my ($laundry, $tagref, $attrhashref) = @_;
        # Now, perform actions and return
    });

start_tag, end_tag, text, and uri callbacks that return false values will
suppress the return value of the element they are processing; this allows
additional checks to be done (for instance, images can be allowed only from
whitelisted source domains).

=cut

sub add_callback {
    my ( $self, $action, $ref ) = @_;
    return if ( ref($ref) ne 'CODE' );
    if ($action eq q{start_tag}) {
        push @{ $self->{start_tag_callback} }, $ref;
    } elsif ($action eq q{end_tag}) {
        push @{ $self->{end_tag_callback} }, $ref;
    } elsif ($action eq q{text}) {
        push @{ $self->{text_callback} }, $ref;
    } elsif ($action eq q{uri}) {
        push @{ $self->{uri_callback} }, $ref;
    } elsif ($action eq q{output}) {
        push @{ $self->{output_callback} }, $ref;
    }
    return;
}

=head2 clear_callback

Removes all callbacks of given type.

    $l->clear_callback('start_tag');

=cut

sub clear_callback {
    my ( $self, $action ) = @_;
    if ($action eq q{start_tag}) {
        $self->{start_tag_callback} = [ sub { 1; } ];
    } elsif ($action eq q{end_tag}) {
        $self->{end_tag_callback} = [ sub { 1; } ];
    } elsif ($action eq q{text}) {
        $self->{text_callback} = [ sub { 1; } ];
    } elsif ($action eq q{uri}) {
        $self->{uri_callback} = [ sub { 1; } ];
    } elsif ($action eq q{output}) {
        $self->{output_callback} = [ sub { 1; } ];
    }
    return;
}

=head2 clean

Cleans a snippet of HTML, using the ruleset and object creation options given
to the Laundry object. The snippet should be passed as a scalar.

    $output1 =  $l->clean( '<p>The X-rays were penetrating' );
    $output2 =  $l->clean( $snippet );

=cut

sub clean {
    my ( $self, $chunk, $args ) = @_;
    $self->_reset_state();
    if ( $self->{trim_tag_whitespace} ) {
        $chunk =~ s/$tag_leading_whitespace/$1/gs;
    }
    my $p  = $self->{parser};
    my $cp = $self->{cdata_parser};
    $p->parse($chunk);
    if ( !$in_cdata && !$unacceptable_count ) {
        $p->eof();
    }
    if ( $in_cdata && !$local_unacceptable_count ) {
        $cp->eof();
    }
    my $output = $self->gen_output;
    $cp->eof();    # Clear buffer if we haven't already
    if ($cdata_dirty) {    # Overkill to get out of CDATA parser state
        $self->{parser} = HTML::Parser->new(
            api_version => 3,
            start_h =>
                [ sub { $self->_tag_start_handler(@_) }, 'tagname,attr' ],
            end_h => [ sub { $self->_tag_end_handler(@_) }, 'tagname,attr' ],
            text_h => [ sub { $self->_text_handler(@_) }, 'dtext,is_cdata' ],
            empty_element_tags => 1,
            marked_sections    => 1,
        );
    }
    else {
        $p->eof();         # Clear buffer if we haven't already
    }
    return $output;
}

=head2 base_uri

Used to get or set the base_uri property, used in URI rebasing.

    my $base_uri = $l->base_uri; # returns current base_uri
    $l->base_uri(q{http://example.com}); # return 'http://example.com'
    $l->base_uri(''); # unsets base_uri

=cut

sub base_uri {
    my ( $self, $new_base ) = @_;
    if ( defined $new_base and !ref $new_base ) {
        $self->{base_uri} = $new_base;
    }
    return $self->{base_uri};
}

sub _run_callbacks {
    my $self   = shift;
    my $action = shift;
    return unless $action;
    my $type = $action . q{_callback};
    for my $callback ( @{ $self->{$type} } ) {
        my $result = $callback->( $self, @_ );
        return unless $result;
    }
    return 1;
}

=head2 gen_output

Used to generate the final, XHTML output from the internal stack of text and 
tag tokens. Generally meant to be used internally, but potentially useful for
callbacks that require a snapshot of what the output would look like
before the cleaning process is complete.

    my $xhtml = $l->gen_output;

=cut

sub gen_output {
    my $self = shift;
    if ( !$self->_run_callbacks( q{output}, \@fragments ) ) {
        return q{};
    }
    my $output = join '', @fragments;
    if ( $self->{tidy} ) {
        if ( $self->{tidy_engine} eq q{HTML::Tidy} ) {
            $output = $self->{tidy}->clean($output);
            $self->{tidy}->clear_messages;
        }
        elsif ( $self->{tidy_engine} eq q{HTML::Tidy::libXML} ) {
            my $clean
                = $self->{tidy}
                ->clean( $self->{tidy_head} . $output . $self->{tidy_foot},
                'UTF-8', 1 );
            $output = substr( $clean, length $self->{tidy_head} );
            $output = substr( $output, 0, -1 * length $self->{tidy_foot} );
        }
    }
    if ( $self->{trim_trailing_whitespace} ) {
        $output =~ s/\s+$//;
    }
    return $output;
}

=head2 empty_elements

Returns a list of the Laundry object's known empty elements: elements such
as <img /> or <br /> which must not contain any children.

=cut

sub empty_elements {
    my ( $self, $listref ) = @_;
    if ($listref) {
        my @list = @{$listref};
        my %empty = map { ( $_, 1 ) } @list;
        $self->{empty_e} = \%empty;
    }
    return keys %{ $self->{empty_e} };
}

=head2 remove_empty_element

Removes an element (or, if given an array reference, multiple elements) from
the "empty elements" list maintained by the Laundry object.

    $l->remove_empty_element(['img', 'br']); # Let's break XHTML!
    
This will not affect the acceptable/unacceptable status of the elements.

=cut

sub remove_empty_element {
    my ( $self, $new_e, $args ) = @_;
    my $empty = $self->{empty_e};
    if ( ref($new_e) eq 'ARRAY' ) {
        foreach my $e ( @{$new_e} ) {
            $self->remove_empty_element( $e, $args );
        }
    }
    else {
        delete $empty->{$new_e};
    }
    return 1;
}

=head2 acceptable_elements

Returns a list of the Laundry object's known acceptable elements, which will
not be stripped during the sanitizing process.

=cut

sub acceptable_elements {
    my ( $self, $listref ) = @_;
    if ( ref($listref) eq 'ARRAY' ) {
        my @list = @{$listref};
        my %acceptable = map { ( $_, 1 ) } @list;
        $self->{acceptable_e} = \%acceptable;
    }
    return keys %{ $self->{acceptable_e} };
}

=head2 add_acceptable_element

Adds an element (or, if given an array reference, multiple elements) to the
"acceptable elements" list maintained by the Laundry object. Items added in
this manner will automatically be removed from the "unacceptable elements"
list if they are present.

    $l->add_acceptable_element('style');

Elements which are empty may be flagged as such with an optional argument.
If this flag is set, all elements provided by the call will be added to
the "empty element" list.

    $l->add_acceptable_element(['applet', 'script'], { empty => 1 });

=cut

sub add_acceptable_element {
    my ( $self, $new_e, $args ) = @_;
    my $acceptable   = $self->{acceptable_e};
    my $empty        = $self->{empty_e};
    my $unacceptable = $self->{unacceptable_e};
    if ( ref($new_e) eq 'ARRAY' ) {
        foreach my $e ( @{$new_e} ) {
            $self->add_acceptable_element( $e, $args );
        }
    }
    else {
        $acceptable->{$new_e} = 1;
        if ( $args->{empty} ) {
            $empty->{$new_e} = 1;
            if ( $self->{tidy} ) {
                $self->{tidy_added_inline}->{$new_e} = 1;
                $self->{tidy_added_empty}->{$new_e}  = 1;
                $self->_generate_tidy;
            }
        }
        elsif ( $self->{tidy} ) {
            $self->{tidy_added_inline}->{$new_e} = 1;
            $self->_generate_tidy;
        }
        delete $unacceptable->{$new_e};

    }
    return 1;
}

=head2 remove_acceptable_element

Removes an element (or, if given an array reference, multiple elements) to the
"acceptable elements" list maintained by the Laundry object. These items 
(although not their child elements) will now be stripped during parsing.

    $l->remove_acceptable_element(['img', 'h1', 'h2']);
    $l->clean(q{<h1>The Day the World Turned Day-Glo</h1>});
    # returns 'The Day the World Turned Day-Glo'

=cut

sub remove_acceptable_element {
    my ( $self, $new_e, $args ) = @_;
    my $acceptable = $self->{acceptable_e};
    if ( ref($new_e) eq 'ARRAY' ) {
        foreach my $e ( @{$new_e} ) {
            $self->remove_acceptable_element( $e, $args );
        }
    }
    else {
        delete $acceptable->{$new_e};
    }
    return 1;
}

=head2 unacceptable_elements

Returns a list of the Laundry object's unacceptable elements, which will be 
stripped -- B<including> child objects -- during the cleaning process.

=cut

sub unacceptable_elements {
    my ( $self, $listref ) = @_;
    if ( ref($listref) eq 'ARRAY' ) {
        my @list = @{$listref};
        my %unacceptable
            = map { $self->remove_acceptable_element($_); ( $_, 1 ); } @list;
        $self->{unacceptable_e} = \%unacceptable;
    }
    return keys %{ $self->{unacceptable_e} };
}

=head2 add_unacceptable_element

Adds an element (or, if given an array reference, multiple elements) to the
"unacceptable elements" list maintained by the Laundry object.

    $l->add_unacceptable_element(['h1', 'h2']);
    $l->clean(q{<h1>The Day the World Turned Day-Glo</h1>});
    # returns null string

=cut

sub add_unacceptable_element {
    my ( $self, $new_e, $args ) = @_;
    my $unacceptable = $self->{unacceptable_e};
    if ( ref($new_e) eq 'ARRAY' ) {
        foreach my $e ( @{$new_e} ) {
            $self->add_unacceptable_element( $e, $args );
        }
    }
    else {
        $self->remove_acceptable_element($new_e);
        $unacceptable->{$new_e} = 1;
    }
    return 1;
}

=head2 remove_unacceptable_element

Removes an element (or, if given an array reference, multiple elements) from 
the "unacceptable elements" list maintained by the Laundry object. Note that
this does not automatically add the element to the acceptable_element list.

    $l->clean(q{<script>alert('!')</script>});
    # returns null string
    $l->remove_unacceptable_element( q{script} );
    $l->clean(q{<script>alert('!')</script>});
    # returns "alert('!')"

=cut

sub remove_unacceptable_element {
    my ( $self, $new_e, $args ) = @_;
    my $unacceptable = $self->{unacceptable_e};
    if ( ref($new_e) eq 'ARRAY' ) {
        foreach my $a ( @{$new_e} ) {
            $self->remove_unacceptable_element( $a, $args );
        }
    }
    else {
        delete $unacceptable->{$new_e};
    }
    return 1;
}

=head2 acceptable_attributes

Returns a list of the Laundry object's known acceptable attributes, which will
not be stripped during the sanitizing process.

=cut

sub acceptable_attributes {
    my ( $self, $listref ) = @_;
    if ( ref($listref) eq 'ARRAY' ) {
        my @list = @{$listref};
        my %acceptable = map { ( $_, 1 ) } @list;
        $self->{acceptable_a} = \%acceptable;
    }
    return keys %{ $self->{acceptable_a} };
}

=head2 add_acceptable_attribute

Adds an attribute (or, if given an array reference, multiple attributes) to the
"acceptable attributes" list maintained by the Laundry object.

    my $snippet = q{ <p austen:id="3">"My dear Mr. Bennet," said his lady to 
        him one day, "have you heard that <span austen:footnote="netherfield">
        Netherfield Park</span> is let at last?"</p>
    };
    $l->clean( $snippet );
    # returns:
    #   <p>&quot;My dear Mr. Bennet,&quot; said his lady to him one day, 
    #   &quot;have you heard that <span>Netherfield Park</span> is let at 
    #   last?&quot;</p>
    $l->add_acceptable_attribute([austen:id, austen:footnote]);
    $l->clean( $snippet );
    # returns:
    #   <p austen:id="3">&quot;My dear Mr. Bennet,&quot; said his lady to him
    #   one day, &quot;have you heard that <span austen:footnote="netherfield">
    #   Netherfield Park</span> is let at last?&quot;</span></p>
    
=cut

sub add_acceptable_attribute {
    my ( $self, $new_a, $args ) = @_;
    my $acceptable = $self->{acceptable_a};
    if ( ref($new_a) eq 'ARRAY' ) {
        foreach my $a ( @{$new_a} ) {
            $self->add_acceptable_attribute( $a, $args );
        }
    }
    else {
        $acceptable->{$new_a} = 1;
    }
    return 1;
}

=head2 remove_acceptable_attribute

Removes an attribute (or, if given an array reference, multiple attributes)
from the "acceptable attributes" list maintained by the Laundry object.

    $l->clean(q{<p id="plugh">plover</p>});
    # returns '<p id="plugh">plover</p>'
    $l->remove_acceptable_element( q{id} );
    $l->clean(q{<p id="plugh">plover</p>});
    # returns '<p>plover</p>

=cut

sub remove_acceptable_attribute {
    my ( $self, $new_a, $args ) = @_;
    my $acceptable = $self->{acceptable_a};
    if ( ref($new_a) eq 'ARRAY' ) {
        foreach my $a ( @{$new_a} ) {
            $self->remove_acceptable_attribute( $a, $args );
        }
    }
    else {
        delete $acceptable->{$new_a};
    }
    return 1;
}

sub _generate_tidy {
    my $self  = shift;
    my $param = shift;
    $self->_generate_html_tidy;
    if ( !$self->{tidy} ) {
        $self->_generate_html_tidy_libxml;
    }
    return;
}

sub _generate_html_tidy_libxml {
    my $self = shift;
    {
        local $@;
        eval {
            require HTML::Tidy::libXML;
            $self->{tidy}      = HTML::Tidy::libXML->new();
            $self->{tidy_head} = q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD  HTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/ html1/DTD/ html1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml"><body>};
            $self->{tidy_foot} = q{</body></html>
};
            $self->{tidy_engine} = q{HTML::Tidy::libXML};
            1;
        };
    }
}

sub _generate_html_tidy {
    my $self = shift;
    {
        local $@;
        eval {
            require HTML::Tidy;
            $self->{tidy_ruleset} = $self->{ruleset}->tidy_ruleset;
            if ( keys %{ $self->{tidy_added_inline} } ) {
                $self->{tidy_ruleset}->{new_inline_tags}
                    = join( q{,}, keys %{ $self->{tidy_added_inline} } );
            }
            if ( keys %{ $self->{tidy_added_empty} } ) {
                $self->{tidy_ruleset}->{new_empty_tags}
                    = join( q{,}, keys %{ $self->{tidy_added_empty} } );
            }
            $self->{tidy}        = HTML::Tidy->new( $self->{tidy_ruleset} );
            $self->{tidy_engine} = q{HTML::Tidy};
            1;
        };
    }
}

sub _reset_state {
    my ($self) = @_;
    @fragments                = ();
    $unacceptable_count       = 0;
    $local_unacceptable_count = 0;
    $in_cdata                 = 0;
    $cdata_dirty              = 0;
    return;
}

sub _tag_start_handler {
    my ( $self, $tagname, $attr ) = @_;
    if ( !$self->_run_callbacks( q{start_tag}, \$tagname, $attr ) ) {
        return;
    }
    if ( !$in_cdata ) {
        $cdata_dirty = 0;
    }
    my @attributes;
    foreach my $k ( keys %{$attr} ) {
        if ( $self->{acceptable_a}->{$k} ) {
            if ( grep {/^$k$/} @{ $self->{uri_list}->{$tagname} } ) {
                $self->_uri_handler( $tagname, \$k, \$attr->{$k},
                    $self->{base_uri} );
            }

            # Allow uri handler to suppress insertion
            if ($k) {
                push @attributes, $k . q{="} . $attr->{$k} . q{"};
            }
        }
    }
    my $attributes = join q{ }, @attributes;
    if ( $self->{acceptable_e}->{$tagname} ) {
        if ( $self->{empty_e}->{$tagname} ) {
            if ($attributes) {
                $attributes = $attributes . q{ };
            }
            push @fragments, "<$tagname $attributes/>";
        }
        else {
            if ($attributes) {
                $attributes = q{ } . $attributes;
            }
            push @fragments, "<$tagname$attributes>";
        }
    }
    else {
        if ( $self->{unacceptable_e}->{$tagname} ) {
            if ($in_cdata) {
                $local_unacceptable_count += 1;
            }
            else {
                $unacceptable_count += 1;
            }
        }
    }
    return;
}

sub _tag_end_handler {
    my ( $self, $tagname ) = @_;
    if ( !$self->_run_callbacks( q{end_tag}, \$tagname ) ) {
        return;
    }
    if ( !$in_cdata ) {
        $cdata_dirty = 0;
    }
    if ( $self->{acceptable_e}->{$tagname} ) {
        if ( !$self->{empty_e}->{$tagname} ) {
            push @fragments, "</$tagname>";
        }
    }
    else {
        if ( $self->{unacceptable_e}->{$tagname} ) {
            if ($in_cdata) {
                $local_unacceptable_count -= 1;
                $local_unacceptable_count = 0
                    if ( $local_unacceptable_count < 0 );
            }
            else {
                $unacceptable_count -= 1;
                $unacceptable_count = 0 if ( $unacceptable_count < 0 );
            }
        }
    }
    return;
}

sub _text_handler {
    my ( $self, $text, $is_cdata ) = @_;
    if ( $in_cdata && $local_unacceptable_count ) {
        return;
    }
    if ($unacceptable_count) {
        return;
    }
    if ($is_cdata) {
        my $cp = $self->{cdata_parser};
        $in_cdata = 1;
        $cp->parse($text);
        if ( !$local_unacceptable_count ) {
            $cp->eof();
        }
        $cdata_dirty = 1;
        $in_cdata    = 0;
        return;
    }
    else {
        if ( !$self->_run_callbacks( q{text}, \$text, $is_cdata ) ) {
            return q{};
        }
        $text = encode_entities( $text, '<>&"' );
        $cdata_dirty = 0;
    }
    push @fragments, $text;
    return;
}

sub _uri_handler {
    my ( $self, $tagname, $attr_ref, $value_ref, $base ) = @_;
    my ( $attr, $value ) = ( ${$attr_ref}, ${$value_ref} );
    $value =~ s/[`\x00-\x1f\x7f]+//g;
    $value =~ s/\ufffd//g;
    my $uri = URI->new($value);
    $uri = $uri->canonical;
    if ( !$self->_run_callbacks( q{uri}, $tagname, $attr, \$uri ) ) {
        ${$attr_ref} = q{};
        return undef;
    }
    if ( $self->{allowed_schemes} and $uri->scheme ) {
        unless ( $self->{allowed_schemes}->{ $uri->scheme } ) {
            ${$attr_ref} = q{};
            return undef;
        }
    }
    if ( $self->{base_uri} ) {
        $uri = URI->new_abs( $uri->as_string, $self->{base_uri} );
    }
    if ( $uri->scheme ) {    # Not a local URI
        my $host;
        {
            local $@;
            eval { $host = $uri->host; };
        }
        if ($host) {

            # We may need to manually unescape domain names
            # to deal with issues like tinyarro.ws
            my $utf8_host = $self->_decode_utf8($host);
            utf8::upgrade($utf8_host);
            if ( $uri->host ne $utf8_host ) {

                # TODO: Optionally use Punycode in this case

                if ( $uri->port and $uri->port == $uri->default_port ) {
                    $uri->port(undef);
                }
                my $escaped_host = $self->_encode_utf8( $uri->host );
                my $uri_str      = $uri->canonical->as_string;
                $uri_str =~ s/$escaped_host/$utf8_host/;
                utf8::upgrade($uri_str);
                ${$value_ref} = $uri_str;
                return;
            }
        }
    }
    ${$value_ref} = $uri->canonical->as_string;
    return;
}

sub _decode_utf8 {
    my $self = shift;
    my $orig = my $str = shift;
    $str =~ s/\%([0-9a-f]{2})/chr(hex($1))/egi;
    return $str if utf8::decode($str);
    return $orig;
}

sub _encode_utf8 {
    my $self    = shift;
    my $str     = shift;
    my $highbit = qr/[^\w\$-_.+!*'(),]/;
    $str =~ s/($highbit)/ sprintf ("%%%02X", ord($1)) /ge;
    utf8::upgrade($str);
    return $str;
}

=head1 SEE ALSO

There are a number of tools designed for sanitizing HTML, some of which
may be better suited than HTML::Laundry to particular circumstances. In 
addition to L<HTML::Scrubber|HTML::Scrubber>, you may want to consider
L<HTML::StripScripts::Parser|HTML::StripScripts::Parser>, an C<HTML::Parser>-based module designed 
solely for the purposes of  sanitizing HTML from potential XSS attack vectors; 
L<HTML::Defang|HTML::Defang>, a whitelist-based, pure-Perl module; or
L<HTML::Restrict|HTML::Restrict>, an HTML tag whitelist using C<HTML::Parser>.

=head1 AUTHOR

Steve Cook, C<< <scook at sixapart.com> >>

=head1 BUGS

Please report any bugs or feature requests on the GitHub page for this project,
http://github.com/snark/html-laundry.

=head1 ACKNOWLEDGMENTS 

Thanks to Dave Cross and Vera Tobin.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Laundry

=head1 COPYRIGHT & LICENSE

Copyright 2009 Six Apart, Ltd., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of HTML::Laundry
