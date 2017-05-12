use 5.008;
use strict;
use warnings;

package HTML::Quoted;

our $VERSION = '0.04';

=head1 NAME

HTML::Quoted - extract structure of quoted HTML mail message

=head1 SYNOPSIS

    use HTML::Quoted;
    my $html = '...';
    my $struct = HTML::Quoted->extract( $html );

=head1 DESCRIPTION

Parses and extracts quotation structure out of a HTML message.
Purpose and returned structures are very similar to
L<Text::Quoted>.

=head1 SUPPORTED FORMATS

Variouse MUAs use quite different approaches for quoting in mails.

Some use I<blockquote> tag and it's quite easy to parse.

Some wrap text into I<p> tags and add '>' in the beginning of the
paragraphs.

Things gettign messier when it's an HTML reply on plain text mail
thread.

If B<you found format> that is not supported then file a bug report
via rt.cpan.org with as short as possible example. B<Test file>
is even better. Test file with patch is the best. Not obviouse patches
without tests suck.

=head1 METHODS

=head2 extract

    my $struct = HTML::Quoted->extract( $html );

Takes a string with HTML and returns array reference. Each element
in the array either array or hash. For example:


    [
        { 'raw' => 'Hi,' },
        { 'raw' => '<div><br><div>On date X wrote:<br>' },
        [
             { 'raw' => '<blockquote>' },
             { 'raw' => 'Hello,' },
             { 'raw' => '<div>How are you?</div>' },
             { 'raw' => '</blockquote>' }
        ],
        ...
    ]

Hashes represent a part of the html. The following keys are
meaningful at the moment:

=over 4

=item * raw - raw HTML

=item * quoter_raw, quoter - raw and decoded (entities are converted) quoter if block is prefixed with quoting characters

=back

=cut

sub extract {
    my $self = shift;
    my $parser = HTML::Quoted::Parser->new(
        api_version => 3,
        handlers => {
            start_document => [handle_doc_start => 'self'],
            end_document   => [handle_doc_end => 'self'],
            start   => [handle_start   => 'self, tagname, attr, attrseq, text'],
            end     => [handle_end     => 'self, tagname, text'],
            text    => [handle_text    => 'self, text, is_cdata'],
            default => [handle_default => 'self, event, text'],
        },
    );
    $parser->empty_element_tags(1);
    $parser->parse($_[0]);
    $parser->eof;

    return $parser->{'html_quoted_parser'}{'result'};
}

=head2 combine_hunks

  my $html = HTML::Quoted->combine_hunks( $arrayref_of_hunks );

Takes the output of C<extract> and turns it back into HTML.

=cut

sub combine_hunks {
    my ($self, $hunks) = @_;

    join "",
      map {; ref $_ eq 'HASH' ? $_->{raw} : $self->combine_hunks($_) } @$hunks;
}

package HTML::Quoted::Parser;
use base "HTML::Parser";

sub handle_doc_start {
    my ($self) = @_;
    my $meta = $self->{'html_quoted_parser'} = {};
    my $res = $meta->{'result'} = [{}];
    $meta->{'current'} = $res->[0];
    $meta->{'stack'} = [$res];
    $meta->{'in'} = { quote => 0, block => [0] };
}

sub handle_doc_end {
    my ($self) = @_;

    my $meta = $self->{'html_quoted_parser'};
    pop @{ $meta->{'result'} } if ref $meta->{'result'}[-1] eq 'HASH' && !keys %{ $meta->{'result'}[-1] };
    $self->organize( $meta->{'result'} );
}

sub organize {
    my ($self, $list) = @_;

    my $prev = undef;
    foreach my $e ( splice @$list ) {
        if ( ref $e eq 'ARRAY' ) {
            push @$list, $self->organize($e);
            $prev = undef;
        }
        elsif ( $e->{'block'} ) {
            push @$list, $e;
            $prev = undef;
        }
        elsif ( defined $e->{'quoter'} ) {
            if ( !$prev || $self->combine( $prev, $e ) ) {
                push @$list, $prev = [ $e ];
            }
        } else {
            push @$list, $e;
            $prev = undef;
        }
    }
    return $list;
}

sub combine {
    my ($self, $list, $e) = @_;
    my ($last) = grep ref $_ eq 'HASH', reverse @$list;
    if ( $last->{'quoter'} eq $e->{'quoter'} ) {
        push @$list, $e;
        return ();
    }
    elsif ( rindex( $last->{'quoter'}, $e->{'quoter'}, 0) == 0 ) {
        @$list = ( [@$list], $e );
        return ();
    }
    elsif ( rindex( $e->{'quoter'}, $last->{'quoter'}, 0) == 0 ) {
        if ( ref $list->[-1] eq 'ARRAY' && !$self->combine( $list->[-1], $e ) ) {
            return ();
        }
        push @$list, [ $e ];
        return ();
    }
    else {
        return $e;
    }
}

# XXX: p is treated as inline tag as it's groupping tag that
# can not contain blocks inside, use span for groupping
my %INLINE_TAG = map {$_ => 1 } qw(
    a br span bdo map img
    tt i b big small
    em strong dfn code q
    samp kbd var cite abbr acronym sub sup
    p
);

my %ENTITIES = (
    '&gt;' => '>',
    '&#62;' => '>',
    '&#x3e;' => '>',
);

my $re_amp = join '|', map "\Q$_\E", '>', grep $ENTITIES{$_} eq '>', keys %ENTITIES;
$re_amp = qr{$re_amp};
my $re_quote_char  = qr{[!#%=|:]};
my $re_quote_chunk = qr{ $re_quote_char(?!\w) | \w*$re_amp+ }x;
my $re_quoter     = qr{ $re_quote_chunk (?:[ \\t]* $re_quote_chunk)* }x;

sub handle_start {
    my ($self, $tag, $attr, $attrseq, $text) = @_;

    my $meta = $self->{'html_quoted_parser'};
    my $stack = $meta->{'stack'};

    if ( $meta->{'in'}{'br'} ) {
        $meta->{'in'}{'br'} = 0;
        push @{ $stack->[-1] }, $meta->{'current'} = {};
    }

    if ( $tag eq 'blockquote' ) {
        my $new = [{ quote => 1, block => 1 }];
        push @{ $stack->[-1] }, $new;
        push @$stack, $new; # HACK: everything pushed into this
        $meta->{'current'} = $new->[0];
        $meta->{'in'}{'quote'}++;
        push @{ $meta->{'in'}{'block'} }, 0;
        $meta->{'current'}{'raw'} .= $text;
        push @{ $stack->[-1] }, $meta->{'current'} = {};
    }
    elsif ( $tag eq 'br' && !$meta->{'in'}{'block'}[-1] ) {
        $meta->{'current'}{'raw'} .= $text;
        my $line = $meta->{'current'}{'raw'};
        if ( $line =~ /^\n*($re_quoter)/ ) {
            $meta->{'current'}{'quoter_raw'} = $1;
            $meta->{'current'}{'quoter'} = $self->decode_entities(
                $meta->{'current'}{'quoter_raw'}
            );
        }
        $meta->{'in'}{'br'} = 1;
    }
    elsif ( !$INLINE_TAG{ $tag } ) {
        if ( !$meta->{'in'}{'block'}[-1] && keys %{ $meta->{'current'} } ) {
            push @{ $stack->[-1] }, $meta->{'current'} = { raw => '' };
        }
        $meta->{'current'}{'block'} = 1;
        $meta->{'current'}{'raw'} .= $text;

        $meta->{'in'}{'block'}[-1]++;
    }
    else {
        $meta->{'current'}{'raw'} .= $text;
    }
}

sub handle_end {
    my ($self, $tag, $text) = @_;

    my $meta = $self->{'html_quoted_parser'};
    my $stack = $meta->{'stack'};

    if ( $meta->{'in'}{'br'} && $tag ne 'br' ) {
        $meta->{'in'}{'br'} = 0;
        push @{ $stack->[-1] }, $meta->{'current'} = {}
    }

    $meta->{'current'}{'raw'} .= $text;

    if ( $tag eq 'blockquote' ) {
        pop @$stack;
        pop @{ $meta->{'in'}{'block'} };
        push @{ $stack->[-1] }, $meta->{'current'} = {};
        $meta->{'in'}{'quote'}--;
    }
    elsif ( $tag eq 'br' ) {
        $meta->{'in'}{'br'} = 0;
        push @{ $stack->[-1] }, $meta->{'current'} = {}
    }
    elsif ( $tag eq 'p' ) {
        push @{ $stack->[-1] }, $meta->{'current'} = {}
    }
    elsif ( !$INLINE_TAG{ $tag } ) {
        $meta->{'in'}{'block'}[-1]--;
        if ( $meta->{'in'}{'block'}[-1] ) {
            $meta->{'current'}{'block'} = 1;
        } else {
            push @{ $stack->[-1] }, $meta->{'current'} = {};
        }
    }
}

sub decode_entities {
    my ($self, $string) = @_;
    $string =~ s/(&(?:[a-z]+|#[0-9]|#x[0-9a-f]+);)/ $ENTITIES{$1} || $ENTITIES{lc $1} || $1 /ge;
    return $string;
}

sub handle_text {
    my ($self, $text) = @_;
    my $meta = $self->{'html_quoted_parser'};
    if ( $meta->{'in'}{'br'} ) {
        $meta->{'in'}{'br'} = 0;
        push @{ $meta->{'stack'}[-1] }, $meta->{'current'} = {};
    }
    $self->{'html_quoted_parser'}{'current'}{'raw'} .= $text;
}

sub handle_default {
    my ($self, $event, $text) = @_;
    my $meta = $self->{'html_quoted_parser'};
    if ( $meta->{'in'}{'br'} ) {
        $meta->{'in'}{'br'} = 0;
        push @{ $meta->{'stack'}[-1] }, $meta->{'current'} = {};
    }
    $self->{'html_quoted_parser'}{'current'}{'raw'} .= $text;
}

=head1 AUTHOR

Ruslan.Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
