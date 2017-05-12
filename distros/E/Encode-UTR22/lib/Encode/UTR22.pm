package Encode::UTR22;

=head1 NAME

Encode::UTR22 - Implement Unicode TR22 complex conversions

=head1 DESCRIPTION

Implements all of UTR22 except: validity, header, bidirectional re-ordering,
history, v attribute for versioning, aliases - that's the job of another module
fbu and fub are treated synonymously with single directional a, with equal priority

Supports UTR22c extensions including: contexts, reordering

=head1 INSTANCE VARIABLES

=over

=item 'info'

Hash containing attributes from the C<< <characterMapping> >> element.

=item 'sub'

Two element array containing, in order, the bytes and Unicode replacement characters

=item 'classes'

Hash, indexed by classname, returning L<Encode::UTR22::Regexp::class|Encode::UTR22::Regexp::class> object.

=item 'rules'

Array of rules, each rule being a hash. 

=item 'contexts'

Hash, indexed by contextname, returning L<Encode::UTR22::Regexp::group|Encode::UTR22::Regexp::group> object representing a context expression.

=item 'orders'

Hash, indexed by 'bytes' or 'unicode', returning hash containing ordering elements 'b', 'u', 'bctxt', 'actxt'

=back

=head1 METHODS

=cut

require 5.8.0;

use XML::Parser::Expat;
use Unicode::Normalize;
use Encode;
use Carp;
use strict;

use vars qw($curr_side $VERSION);

$VERSION = 0.03;    #   MJPH     6-FEB-2004     Add Normalization to encode()
# $VERSION = 0.02;    #   MJPH     7-JUL-2004     Add bctxt to reorder rules

=over 8

=item	new( $infile [, %parms ] )

Create new instance, parsing and compiling the UTR22 xml

=cut

sub new
{
    my ($class, $infile, %attrs) = @_;
    my ($self) = $class->process_file($infile, %attrs) || return undef;
    $self->compile(%attrs);
    $self;
}

=item	process_file( $infile [, %params ] )

Create and return a new instance, and parse (but do not compile) a UTR22 xml file

=cut

sub process_file
{
    my ($class, $infile, %attrs) = @_;
    my ($xml) = XML::Parser::Expat->new();
    my ($context) = {};
    my ($r);
    bless $context, ref $class || $class;
    
    $xml->{' mycontext'} = $context;

    my (%regex_classes) = (
        'group' => 'Encode::UTR22::Regexp::Group',
        'class-ref' => 'Encode::UTR22::Regexp::classRef',
        'context-ref' => 'Encode::UTR22::Regexp::contextRef',
        'eos' => 'Encode::UTR22::Regexp::EOS'
        );

	my $current ;
	
    $xml->setHandlers('Start' => sub {
        my ($xml, $tag, %attrs) = @_;
        my ($this, $temp);

        $attrs{'line'} = $xml->current_line;

        if ($tag eq 'characterMapping')
        { $xml->{' mycontext'}{'info'} = {%attrs}; }
        elsif ($tag eq 'assignments')
        {
            $xml->{' mycontext'}{'sub'}[0] = pack('C', hex($attrs{'sub'}));
          
            $xml->{' mycontext'}{'sub'}[1] = pack('U', 0xFFFD);
        }
        elsif ($tag eq 'a' || $tag eq 'fbu' || $tag eq 'fub')
        {
            error($xml, undef, "b and u attributes are required in a element")
                    unless (defined $attrs{'b'} && defined $attrs{'u'});
            push(@{$xml->{' mycontext'}{'rules'}}, {
                    'line' => $xml->current_line,
#                    'b' => pack('C0C*', map {hex($_)} $attrs{'b'} =~ m/\G\s*([0-9a-fA-F]{2})/og),
#                    'u' => pack('U0U*', map {hex($_)} $attrs{'u'} =~ m/\G\s*([0-9a-fA-F]{4,6})/og),
                    'b' => pack('C*', map {hex($_)} split(' ', $attrs{'b'})),
                    'u' => pack('U*', map {hex($_)} split(' ', $attrs{'u'})),
                    'type' => $tag,
                    'bactxt' => $attrs{'bactxt'},
                    'bbctxt' => $attrs{'bbctxt'},
                    'uactxt' => $attrs{'uactxt'},
                    'ubctxt' => $attrs{'ubctxt'},
                    'priority' => $attrs{'priority'}});
        }
        elsif ($tag eq 'range')
        {
            $xml->{' mycontext'}{'rules'} = [] unless $xml->{' mycontext'}{'rules'};
            process_range($xml, $xml->{' mycontext'}{'rules'}, %attrs);
        }
        elsif (defined($regex_classes{$tag}))
        {
            $this = $regex_classes{$tag}->new(%attrs) || error($xml, undef, "illegal $tag element");
            if ($current)
            { $current = $current->add_child($this); }
            else
            {
                error($xml, $this, "top level regexps must be named") unless ($attrs{'id'});
                error($xml, $this, "top level regexps may not share names")
                        if (defined $xml->{' mycontext'}{'contexts'}{$attrs{'id'}});
                $xml->{' mycontext'}{'contexts'}{$attrs{'id'}} = $this;
                $current = $this;
            }
            $this->{'owner'} = $xml->{' mycontext'};
            error($xml, $this, "context name $attrs{'id'} must not include /")
                    if ($attrs{'id'} && $attrs{'id'} =~ m|/|o);
        }
        elsif ($tag eq 'class')
        {
            error($xml, undef, "classes must be named") unless ($attrs{'name'});
            error($xml, undef, "size must be 'bytes' in class definition $attrs{'name'}")
                    if (defined $attrs{'size'} && $attrs{'size'} ne 'bytes');
            $this = Encode::UTR22::Regexp::class->new(%attrs);
            $current = $this;
            $xml->{' mycontext'}{'classes'}{$attrs{'name'}} = $this;
        }
        elsif ($tag eq 'class-include')
        {
            error($xml, undef, "class-include $attrs{'name'} not in classes element")
                    unless (defined $current && $current->can('add_from'));
            $temp = $xml->{' mycontext'}{'classes'}{$attrs{'name'}} 
                    || error($xml, $current, "Class $attrs{'name'} not yet defined");
            error($xml, $current, "Class-include $attrs{'name'} must be the same data size")
                    if ($temp->{'size'} ne $current->{'size'});
            $current->add_from($temp);
        }
        elsif ($tag eq 'class-range')
        {
            $current->add_range(hex($attrs{'first'}), hex($attrs{'last'}));
        }
        elsif ($tag eq 'ordering')
        {
            $curr_side = lc($attrs{'side'});
            error($xml, undef, "ordering must have a side of 'unicode' or 'bytes'")
                    unless ($curr_side eq 'unicode' || $curr_side eq 'bytes');
        }
        elsif ($tag eq 'order')
        {
            error($xml, undef, "order element must have b and u attributes")
                    unless (defined $attrs{'b'} && defined $attrs{'u'});
            error($xml, undef, "order must occur inside ordering")
                    unless (defined $curr_side);
            push(@{$xml->{' mycontext'}{'orders'}{$curr_side}}, {
                    'line' => $xml->current_line,
                    'b' => $attrs{'b'},
                    'u' => $attrs{'u'},
                    'bctxt' => $attrs{'bctxt'},
                    'actxt' => $attrs{'actxt'}});
        }
    }, 'End' => sub {
        my ($xml, $tag) = @_;

        if ($tag eq 'class')
        { undef $current; }
        elsif (defined $regex_classes{$tag})
        { $current = $current->{'parent'}; }
        elsif ($tag eq 'ordering')
        { $curr_side = ''; }
    }, 'Char' => sub {
        my ($xml, $str) = @_;

        if (defined $current && $current->can('add_elements'))
        {
            if ($current->{'size'} && $current->{'size'} eq 'bytes')
            { $current->add_elements(map {pack('C', hex($_))} split(' ', $str)); }
#            { $current->add_elements(map {pack('C0C', hex($_))} $str =~ m/\G\s*([0-9a-fA-F]{2})\s*/og); }
            else
            { $current->add_elements(map {pack('U', hex($_))} split(' ', $str)); }
#            { $current->add_elements(map {pack('U0U', hex($_))} $str =~ m/\G\s*([0-9a-fA-F]{4,6})\s*/og); }
        }
        elsif ($str !~ /^\s*$/ && !$xml->in_element('modified'))
        {error($xml, undef, "unexpected text '$str' ignored"); }
    });

    if ($attrs{'-path'})
    {
        my ($done);
        
        foreach $r (@{$attrs{'-path'}})
        {
            if (-f "$r/$infile")
            {
                $xml->parsefile("$r/$infile");
                $done = 1;
                last;
            }
        }
        $xml->parsefile($infile) unless $done;
    }
    elsif (ref $infile)
    { $xml->parse($infile); }
    else
    { $xml->parsefile($infile); }
    
    return $context;
}

=item	compile( [ %params ] )

Compile a UTR22 object.  Parameters recognized

=over 4

=item 'toBytes'

Determines which direction that map will be compiled. True = compile for Unicode to Bytes. False = compile for Bytes to Unicode. Default is both.

=item 'debug'

Turn on debugging.

=back

=cut

sub compile
{
    my ($self, %attrs) = @_;
    my ($r);

    foreach $r (sort {$self->{'contexts'}{$a}{'line'} <=> $self->{'contexts'}{$b}{'line'}}
                keys %{$self->{'contexts'}})
    { $self->{'regexps'}{$r} = $self->{'contexts'}{$r}->as_perl(1); }

    if (defined $attrs{'toBytes'})
    {
        $self->compile_map($attrs{'toBytes'});
        $self->compile_order($attrs{'toBytes'});
    }
    else
    {
        $self->compile_map(0);
        $self->compile_order(0);
        $self->compile_map(1);
        $self->compile_order(1);

        unless($attrs{'debug'})
        {
            foreach $r (qw(rules classes contexts regexps orders))
            { delete $self->{$r}; }
        }
    }
    $self;
}

=item	decode( $sourceByteString [, CHECK] )

Perform Bytes to Unicode conversion.

=cut

sub decode($$;$)
{
    my ($self, $str, $check) = @_;
    my ($res, $len, $c, $temp, $r, $count, $tpos, $found);

    return undef unless ($self->{'bsimple'} || $self->{'bconv'});

    Encode::_utf8_on($res);

    $str = $self->reorder($str, $self->{'border'}[0], 1) if (defined $self->{'border'}[0]);

    $len = length($str);
    pos($str) = 0;
    while (pos($str) < $len)
    {
        $found = 0;
        $temp = pos($str);
        $str =~ m/\G(.)/ogcs;
        $c = $1;
        $tpos = pos($str);
        pos($str) = $temp;
        
        if (defined $self->{'bconv'}{$c})
        {
            foreach $r (@{$self->{'bconv'}{$c}})
            {
                if ($str =~ m/$r->[0]/gcs)
                {
                    $res .= $r->[1];
                    $found = 1;
                    last;
                }
            }
        }
        unless ($found)
        {
            if (defined $self->{'bsimple'}{$c})
            { $res .= $self->{'bsimple'}{$c}; }
            elsif (ref $check eq 'CODE')
            { $res .= &{$check}($str, pos($str)); }
            elsif ($check)
            { $res .= $check; }
            else
            { $res .= pack('U', 0xFFFD); }
            pos($str) = $tpos;
        }
    }

    $res = $self->reorder($res, $self->{'border'}[1], 0) if (defined $self->{'border'}[1]);
    $res;
}

=item	encode( $sourceUnicodeString [, CHECK])

Perform Unicode to Bytes conversion.

=cut

sub encode($$;$)
{
    my ($self, $str, $check) = @_;
    my ($res, $len, $c, $temp, $r, $tpos, $found);

    return undef unless ($self->{'usimple'} || $self->{'uconv'});

    if ($self->{'info'}{'normalization'} eq 'NFD')
    { $str = NFD($str); }
    elsif ($self->{'info'}{'normalization'} eq 'NFC')
    { $str = NFC($str); }

    Encode::_utf8_off($res);

    $str = $self->reorder($str, $self->{'uorder'}[0], 0) if (defined $self->{'uorder'}[0]);

    $len = length($str);
    pos($str) = 0;
    while (pos($str) < $len)
    {
        $found = 0;
        $temp = pos($str);
        $str =~ m/\G(.)/ogcs;
        $c = $1;
        $tpos = pos($str);
        pos($str) = $temp;
        
        if (defined $self->{'uconv'}{$c})
        {
            foreach $r (@{$self->{'uconv'}{$c}})
            {
                if ($str =~ m/$r->[0]/gcs)
                {
                    $res .= $r->[1];
                    $found = 1;
                    last;
                }
            }
        }
        unless ($found)
        {
            if (defined $self->{'usimple'}{$c})
            { $res .= $self->{'usimple'}{$c}; }
            elsif (ref $check eq 'CODE')
            { $res .= &{$check}($str, pos($str)); }
            elsif ($check)
            { $res .= $check; }
            else
            { $res .= $self->{'sub'}[0]; }
            pos($str) = $tpos;
        }
    }

    $res = $self->reorder($res, $self->{'uorder'}[1], 1) if (defined $self->{'uorder'}[1]);
    $res;
}

sub debug_decode
{
    my ($self, $str, $check) = @_;
    my ($res, $len, $c, $temp, $r, $count, $tpos, $found, $debug, $debstr);

    return undef unless ($self->{'bsimple'} || $self->{'bconv'});

    Encode::_utf8_on($res);

    ($str, $debug) = $self->debug_reorder($str, $self->{'border'}[0], 1) if (defined $self->{'border'}[0]);

    $debug .= "\nMapping from Bytes to Unicode\n";
    $len = length($str);
    pos($str) = 0;
    while (pos($str) < $len)
    {
        $found = 0;
        $temp = pos($str);
        $str =~ m/\G(.)/ogcs;
        $c = $1;
        $tpos = pos($str);
        pos($str) = $temp;
        
        if (defined $self->{'bconv'}{$c})
        {
            foreach $r (@{$self->{'bconv'}{$c}})
            {
                if ($str =~ m/$r->[0]/gcs)
                {
                    $res .= $r->[1];
                    $found = 1;
                    $debug .= "matched line $r->[2]: " . debug_blist($str, $temp) . " =~ $r->[0] -> " 
                        . debug_ulist($r->[1]) . "\n\n";
                    last;
                }
                else
                {
                    $debug .= "tried line $r->[2]: " . debug_blist($str, $temp) . " =~ $r->[0]\n";
                }
            }
        }
        unless ($found)
        {
            if (defined $self->{'bsimple'}{$c})
            {
                $res .= $self->{'bsimple'}{$c};
                $debug .= "simple: " . debug_blist($c) . " = " . debug_ulist($self->{'bsimple'}{$c}) . "\n\n";
            }
            elsif (ref $check eq 'CODE')
            {
                $debug .= "checked at " . pos($str) . "\n\n";
                $res .= &{$check}($str, pos($str));
            }
            elsif ($check)
            {
                $debug .= "added check: $check\n\n";
                $res .= $check;
            }
            else
            {
                $debug .= "failed\n\n";
                $res .= pack('U', 0xFFFD);
            }
            pos($str) = $tpos;
        }
    }

    ($res, $debstr) = $self->debug_reorder($res, $self->{'border'}[1], 0) if (defined $self->{'border'}[1]);
    ($res, $debug . $debstr);
}

sub debug_encode
{
    my ($self, $str, $check) = @_;
    my ($res, $len, $c, $temp, $r, $tpos, $found, $debug, $debstr);

    return undef unless ($self->{'usimple'} || $self->{'uconv'});

    if ($self->{'info'}{'normalization'} eq 'NFD')
    { $str = NFD($str); }
    elsif ($self->{'info'}{'normalization'} eq 'NFC')
    { $str = NFC($str); }

    Encode::_utf8_off($res);

    ($str, $debug) = $self->debug_reorder($str, $self->{'uorder'}[0], 0) if (defined $self->{'uorder'}[0]);
    $debug .= "\nMapping from Unicode to Bytes\n";

    $len = length($str);
    pos($str) = 0;
    while (pos($str) < $len)
    {
        use utf8;
        $found = 0;
        $temp = pos($str);
        $str =~ m/\G(.)/ogcs;
        $c = $1;
        $tpos = pos($str);
        pos($str) = $temp;
        
        if (defined $self->{'uconv'}{$c})
        {
            foreach $r (@{$self->{'uconv'}{$c}})
            {
                if ($str =~ m/$r->[0]/gcs)
                {
                    $res .= $r->[1];
                    $debug .= "matched line $r->[2]: " . debug_ulist($str, $temp) . " =~ $r->[0] -> " 
                        . debug_blist($r->[1]) . "\n\n";
                    $found = 1;
                    last;
                }
                else
                {
                    $debug .= "tried line $r->[2]: " . debug_ulist($str, $temp) . " =~ $r->[0]\n";
                }
            }
        }
        unless ($found)
        {
            if (defined $self->{'usimple'}{$c})
            {
                $debug .= "simple: " . debug_ulist($c) . " = " . debug_blist($self->{'usimple'}{$c}) . "\n\n";
                $res .= $self->{'usimple'}{$c};
            }
            elsif (ref $check eq 'CODE')
            {
                $debug .= "check at " . pos($str) . "\n\n";
                $res .= &{$check}($str, pos($str));
            }
            elsif ($check)
            {
                $debug .= "check: $check\n\n";
                $res .= $check;
            }
            else
            {
                $debug .= "failed: $self->{'sub'}[0]\n\n";
                $res .= $self->{'sub'}[0];
            }
            pos($str) = $tpos;
        }
    }

    ($res, $debstr) = $self->debug_reorder($res, $self->{'uorder'}[1], 1) if (defined $self->{'uorder'}[1]);
    ($res, $debug . $debstr);
}

sub name
{
    my ($self) = @_;

    return $self->{'info'}{'id'};
}


sub new_sequence
{ return $_[0]; }


sub compile_map
{
    my ($self, $toBytes) = @_;
    my ($srcl) = $toBytes ? 'u' : 'b';
    my ($destl) = $toBytes ? 'b' : 'u';
    my ($r, $res, $pre, $post, $lres, $lpre, $lpost, $line, $first, $dump);

    return $self if ($self->{"${srcl}simple"} || $self->{"${srcl}conv"});

    foreach $r (@{$self->{'rules'}})
    {
        next if ($r->{'type'} ne 'a' && (($toBytes == 1) ^ ($r->{'type'} eq 'fub')));
        $pre = ''; $post = ''; $res = ''; $lpre = 0; $lpost = 0;
        $line = $r->{'line'};
        
        if ($r->{"${srcl}bctxt"})
        {
            error (undef, undef, "No regexp " . $r->{"${srcl}bctxt"} . " for ${srcl}bctxt at line $r->{line}")
                    unless ($self->{'regexps'}{$r->{"${srcl}bctxt"}}[0]);
            ($pre, $dump, $lpre) = @{$self->{'regexps'}{$r->{"${srcl}bctxt"}}};
        }

        $res = $r->{$srcl};
        error (undef, undef, "Empty mapping to " . strerror($r->{$destl}, $toBytes) . " not allowed")
                if ($res eq '');

        if ($r->{"${srcl}actxt"})
        {
            error (undef, undef, "No regexp " . $r->{"${srcl}actxt"} . " for ${srcl}actxt at line $r->{line}")
                    unless ($self->{'regexps'}{$r->{"${srcl}actxt"}}[0]);
            ($post, $dump, $lpost) = @{$self->{'regexps'}{$r->{"${srcl}actxt"}}};
            $post = "(?=" . $post . ")";
        }

        if ($toBytes)
        {
            use utf8;
            $r->{'u'} =~ m/^(.)/os;
            $first = $1;       # substr() not working yet

#            $line = -length($res) if (length($res) > 1);        # doesn't work yet
            my (@temp) = unpack('U*', $res);
            if ($#temp == 0 && $pre eq '' and $post eq '')
            {
                error (undef, undef, "Ambiguous mapping from " . strerror($first, !$toBytes) .
                    " to at least " . strerror($self->{'usimple'}{$first}, $toBytes) . " and " .
                    strerror($r->{$destl}, $toBytes)) if (defined $self->{'usimple'}{$first});
                $self->{'usimple'}{$first} = $r->{$destl};
            }
            else
            {
                $lres = $#temp + 1;
                $res =~ s/([$%\\^&*(){}\[\]|"'?\/+.`~\-])/\\$1/ogs;         #"
                $res =~ s/([^\x21-\x7e])/sprintf("\\x{%04X}", unpack('U', $1))/ogse;
                push (@{$self->{"uconv"}{$first}}, [qr/$pre\G$res$post/, $r->{$destl}, $line,
                                                    $lres, $lpre, $lpost, $r->{'priority'}]);
#                print STDERR "qr/$pre\\G$res$post/, $r->{$destl}, $line\n";
            }
        }
        else
        {
            use bytes;
            
            $first = substr($res, 0, 1);
            if (length($res) == 1 && $pre eq '' && $post eq '')
            {
                error (undef, undef, "Ambiguous mapping from " . strerror($first, !$toBytes) .
                    " to at least " . strerror($self->{'bsimple'}{$first}, $toBytes) . " and " .
                    strerror($r->{$destl}, $toBytes)) if (defined $self->{'bsimple'}{$first});
                $self->{'bsimple'}{$first} = $r->{$destl};
            }
            else
            {
                $lres = length($res);
                $res =~ s/([$%\\^&*(){}\[\]|"'?\/+.`~\-])/\\$1/ogs;     #"
                $res =~ s/([^\x21-\x7e])/sprintf("\\x%02x", ord($1))/ogse;
                push (@{$self->{"bconv"}{$first}}, [qr/$pre\G$res$post/, $r->{$destl}, $line,
                                                    $lres, $lpre, $lpost, $r->{'priority'}]);
            }
        }
    }

    $res = $self->{"${srcl}conv"};
    foreach $first (keys %{$res})
    {
        my ($has_short);
        $r = $res->{$first};
        $res->{$first} =
                [sort {
                        $b->[6] <=> $a->[6] ||                      # highest priority attribute first
                        $b->[3] <=> $a->[3] ||                      # longest match string first
                        $b->[4] + $b->[5] <=> $a->[4] + $a->[5] ||  # pre+post longest first
                        $a->[2] <=> $b->[2];                        # lowest line number first
                    } @{$r}];

        foreach (@{$res->{$first}})
        { $has_short ||= ($_->[3] == 0);}

        error (undef, undef, 'No default mapping for ' .
                ($toBytes ? sprintf("U+%04X", unpack('U', $first)) : sprintf("0x%02x", ord($first))))
                unless (!$has_short || defined $self->{"${srcl}simple"}{$first});
    }
    $self;
}


sub compile_order
{
    my ($self, $toBytes) = @_;
    my ($srcl) = $toBytes ? 'u' : 'b';
    my ($destl) = $toBytes ? 'b' : 'u';
    my ($output) = $toBytes ? 'uorder' : 'border';
    my (@sides) = $toBytes ? ('unicode', 'bytes') : ('bytes', 'unicode');
    my ($count, $r, $obj, $i, $reg, $list, %names, @nums, $name, $reg1, $eval, $rega, $regb, $namec);

    for ($count = 0; $count < 2; $count++)
    {
        $obj = $self->{'orders'}{$sides[$count]};
        next unless defined $obj;

        foreach $r (@{$obj})
        {
            @nums = ();
            %names = ();
            if ($r->{'bctxt'})
            { 
                ($regb, $list) = @{$self->{'regexps'}{$r->{'bctxt'}}};
                $namec = scalar @{$list};
            }
            else
            { 
                $regb = '';
                $namec = 0;
            }
            
            if ($r->{'actxt'})
            { ($rega) = @{$self->{'regexps'}{$r->{'actxt'}}}; }
            else
            { $rega = ''; }

            error(undef, undef, "No regexp called $r->{$srcl} available") unless defined $r->{$srcl};
            ($reg, $list) = @{$self->{'regexps'}{$r->{$srcl}}};
            for ($i = 0; $i <= $#{$list}; $i++)
            {
                $name = $list->[$i];
                if ($name =~ s{^\Q$r->{$srcl}\E(?:/|$)}{})
                { $name =~ s{^\Q$r->{$destl}\E(?:/|$)}{}; }
#                next unless ($name !~ m|/|o && $name ne '');
                $names{$name} = $i;
            }

            error(undef, undef, "No regexp called $r->{$destl} available") unless defined $r->{$destl};
            ($reg1, $list) = @{$self->{'regexps'}{$r->{$destl}}};
            for ($i = 0; $i <= $#{$list}; $i++)
            {
                $name = $list->[$i];
                if ($name =~ s{^\Q$r->{$destl}\E(?:/|$)}{})
                { $name =~ s{^\Q$r->{$srcl}\E(?:/|$)}{}; }
#                next unless ($name !~ m|/|o && $name ne '');
                push (@nums, $names{$name}+1+$namec) if ($name && $names{$name});
            }

            $eval = join('', map {"\$$_"} @nums);
            if ($sides[$count] eq 'unicode')
            {
                use utf8;
                push (@{$self->{$output}[$count]}, [qr/$regb\G$reg$rega/, $eval, $r->{'line'}, $namec]);
            }
            else
            {
                use bytes;
                push (@{$self->{$output}[$count]}, [qr/$regb\G$reg$rega/, $eval, $r->{'line'}, $namec]);
            }
        }
    }
    $self;
}


sub reorder
{
    my ($self, $str, $rules, $isbytes) = @_;
    my ($r, $res, $found, $len, @ress, $temp, $oldpos);

    if ($isbytes || $] < 5.008)
    {
        use bytes;
        $len = length($str);
    }
    else
    {
        use utf8;
        $len = length($str);
    }
    while (pos($str) < $len)
    {
        $found = 0;

        foreach $r (@{$rules})
        {
            if ($isbytes)
            {
                use bytes;
                # the \G seems to be anchoring the global search
                # here so it only finds $r->[0] once
                next unless (@ress = $str =~ m/$r->[0]/gcs);
            } else
            {
                use utf8;
                # and here
                next unless (@ress = $str =~ m/$r->[0]/gcs);
            }
            $oldpos += length($ress[$r->[3]]);
            pos($str) = $oldpos;
            $temp = $r->[1];
            $temp =~ s/\$(\d+)/$ress[$1 - 1]/og;
            $res .= $temp;
            $found = 1;
            last;
        }
        unless ($found)
        {
            if ($isbytes)
            {
                use bytes;
                $str =~ m/\G(.)/ogcs;
                $res .= $1;
            } else
            {
                use utf8;
                $str =~ m/\G(.)/ogcs;
                $res .= $1;
            }
            $oldpos++;
        }
    }
    $res;
}


sub debug_reorder
{
    my ($self, $str, $rules, $isbytes) = @_;
    my ($r, $res, $found, $len, @ress, $temp, $debug, $oldpos);

    $debug = "\nRe-ordering:\n";
    if ($isbytes || $] < 5.008)
    {
        use bytes;
        $len = length($str);
    }
    else
    {
        use utf8;
        $len = length($str);
    }
    foreach $r (@{$rules})
    {
        if ($isbytes)
        {
            $debug .= "reorder(line $r->[2]): $r->[0] = ";
            $debug .= " -> $r->[1]\n";
        } else {
            $debug .= "reorder(line $r->[2]): $r->[0] = ";
            $debug .= " -> $r->[1])\n";
        }
    }
    while (pos($str) < $len)
    {
        $found = 0;

        foreach $r (@{$rules})
        {
            if ($isbytes)
            {
                use bytes;
                # the \G seems to be anchoring the global search
                # here so it only finds $r->[0] once
                next unless (@ress = $str =~ m/$r->[0]/gcs)
            } else
            {
                use utf8;
                # and here
                next unless (@ress = $str =~ m/$r->[0]/gcs);
            }
            $oldpos += length($ress[$r->[3]]);
            pos($str) = $oldpos;
            $temp = $r->[1];
            $temp =~ s/\$(\d+)/$ress[$1 - 1]/og;
            $res .= $temp;
            if ($isbytes)
            {
                $debug .= "reorder(line $r->[2]): " . join(",", map {debug_blist($_)} @ress);
                $debug .= " -> $r->[1] = ";
                $debug .= debug_blist($temp) . "\n\n";
            } else {
                $debug .= "reorder(line $r->[2]): $r->[0]" . join(",", map {debug_ulist($_)} @ress);
                $debug .= " -> $r->[1]) = ";
                $debug .= debug_ulist($temp) . "\n\n";
            }
            $found = 1;
            last;
        }
        unless ($found)
        {
            if ($isbytes)
            {
                use bytes;
                $str =~ m/\G(.)/ogcs;
                $res .= $1;
            } else
            {
                use utf8;
                $str =~ m/\G(.)/ogcs;
                $res .= $1;
            }
            $oldpos++;
        }
    }
    if ($isbytes)
    { $debug .= "Final result: " . debug_blist($res) . "\n"; }
    else
    { $debug .= "Final result: " . debug_ulist($res) . "\n"; }
    
    ($res, $debug);
}


sub process_range
{
    my ($xml, $store, %attrs) = @_;
    my (@first, @last, @max, @min, $uFirst, $uLast);
    my (@current, $i, $j, $done);

    @first = map {hex($_)} ($attrs{'bFirst'} =~ m/\G\s*([0-9a-fA-F]{2})\s*/og)
            or return error($xml, undef, "bFirst attribute required in range");
    @last = map {hex($_)} ($attrs{'bLast'} =~ m/\G\s*([0-9a-fA-F]{2})\s*/og)
            or return error($xml, undef, "bLast attribute required in range");
    @max = map {hex($_)} ($attrs{'bMax'} =~ m/\G\s*([0-9a-fA-F]{2})\s*/og);
    @min = map {hex($_)} ($attrs{'bMin'} =~ m/\G\s*([0-9a-fA-F]{2})\s*/og);
    $uFirst = hex($attrs{'uFirst'});
    $uLast = hex($attrs{'uLast'}) || return error($xml, undef, "uLast attribute require in range");

    @current = @first;
    for ($i = $uFirst; $i <= $uLast; $i++)
    {
        push(@{$store}, {
                    'line' => $xml->current_line,
                    'b' => pack('C0C*', @current),
                    'u' => pack('U0U', $i),
                    'type' => 'a',
                    'bactxt' => $attrs{'bactxt'},
                    'bbctxt' => $attrs{'bbctxt'},
                    'uactxt' => $attrs{'uactxt'},
                    'ubctxt' => $attrs{'ubctxt'},
                    'priority' => $attrs{'priority'}});
        last if $i == $uLast;
        for ($j = 0; $j <= $#current; $j++)
        {
            $current[$j]++;
            if (defined $max[$j] && $current[$j] > $max[$j])
            { $current[$j] = $min[$j]; }
            else
            {
                last;
            }
        }
    }

    for ($j = 0; $j <= $#current; $j++)
    {
        if ($current[$j] != $last[$j])
        {
            error($xml, undef, "Number of byte codes does not correspond to number of Unicodes in range");
            last;
        }
    }
}


sub strerror
{
    my ($str, $isBytes) = @_;
    my ($res);

    if ($isBytes)
    {
        use bytes;
        $res = join(" ", map {sprintf("0x%02x", ord($_))} split('', $str));
    } else
    {
        use utf8;
        $res = join(" ", map {sprintf("U+%04X", unpack('U', $_))} split('', $str));
    }
    $res;
}

sub error
{
    my ($xml, $obj, $str, $die) = @_;

    if (defined $obj && $obj->can('as_error'))
    { $str .= "\n    in " . $obj->as_error; }
    if ($die)
    {
        if ($xml)
        { $xml->xpcroak($str); }
        else
        { die($str); }
    }
    else
    {
        if ($xml)
        { $xml->xpcarp($str); }
        else
        { print STDERR "$str\n"; }
    }
    undef;
}

sub debug_ulist
{
    my ($str, $pos) = @_;
    my (@res1) = map{sprintf("%04X",$_)} unpack('U*', substr($str, 0, $pos));
    my (@res2) = map{sprintf("%04X",$_)} unpack('U*', substr($str, $pos));

    return join(" ", defined $pos ? (@res1, '|') : (), @res2);
}


sub debug_blist
{
    my ($str, $pos) = @_;
    my (@res) = map{sprintf("x%02X",$_)} unpack('C*', $str);

    splice(@res, $pos, 0, '|') if defined $pos;
    return join(" ", @res);
}

no strict 'refs';

package Encode::UTR22::Regexp::Element;
use Carp;

sub new
{
    my ($class, %attrs) = @_;
    my ($self) = {%attrs};
    bless $self, ref ($class) || $class;

    $self;
}

sub add_child
{
    my ($self, $child) = @_;
    my ($name);

    $child->{'parent'} = $self;
    push (@{$self->{'child'}}, $child);
    if ($name = $child->{'id'})
    {
    	if (defined $self->{'named'}{$name})
    	{ carp("child with duplicate name at line $child->{'line'}"); }
    }
    else
    {
        $name = $child->{'name'};
        while (defined $self->{'named'}{$name})
        { $name =~ s/(\d*)$/$1 + 1/oe; }
    }
    $self->{'named'}{$name} = $child;
    $child;
}

# returns two-element array containing minimum and maximum length of the resultant regex element

sub count
{
	my $self = shift;
	my ($mymin, $mymax);
	
	if (exists $self->{'child'} && $#{$self->{'child'}} >= 0)
	{
		foreach (@{$self->{'child'}})
		{
			unless (defined $mymin)
			{
				($mymin, $mymax) = $_->count();
			}
			else
			{
				my ($cmin, $cmax) = $_->count();
				if ($self->{'alt'})
				{
					$mymin = $cmin if $cmin < $mymin;
					$mymax = $cmax if $cmax > $mymax;
				}
				else
				{
					$mymin += $cmin;
					$mymax += $cmax;
				}
			}
		}
	}
	else
	{ $mymin = $mymax = 0; }
	$mymin *= $self->{'min'} if defined $self->{'min'};
	$mymax *= $self->{'max'} if defined $self->{'max'};
	return ($mymin, $mymax);
}

sub as_error
{ $_[0]->{'id'}; }

package Encode::UTR22::Regexp::Group;

use vars qw(@ISA);

BEGIN { @ISA = qw(Encode::UTR22::Regexp::Element); }

sub as_perl
{
    my ($self, $atstart, %opts) = @_;
    my ($r, $res, $names, $count, $text, $sub, $subl, $lacc);
    my ($min, $max);
    my ($fn) = $opts{'-fn'} || "as_perl";

    $min = defined $self->{'min'} ? $self->{'min'} : 1;
    $max = defined $self->{'max'} ? $self->{'max'} : 1;

    $names = [];
    if ($self->{'id'} ne '' && !$opts{'-noref'})
    {
        $res = "(";
        $names = [$self->{'id'}];
    }

    if ($self->{'id'} eq '' || $min != 1 || $max != 1)
    { $res .= "(?:"; }

    $lacc = 0;
    foreach $r (@{$self->{'child'}})
    {
        ($text, $sub, $subl) = @{$r->${fn}($atstart, %opts)};
        if (defined $self->{'alt'})
        {
            if ($count)
            { $res .= "|"; }
            else
            { $count = 1; }
            $res .= $text;
            $lacc = $subl if $subl > $lacc;
        }
        else
        {
            $res .= $text;
            $atstart = 0;
            $lacc += $subl;
        }
        push (@{$names}, map {"$self->{'id'}/$_"} @{$sub});
    }
    $res .= ')' if ($self->{'id'} eq '' || $min != 1 || $max != 1);
    if ($max > 1)
    {
        if ($max != $min)
        { $res .= "{$min,$max}"; }
        else
        { $res .= "{$max}"; }
    } elsif ($min == 0)
    { $res .= "?"; }
    $res .= ")" if ($self->{'id'} ne '' && !$opts{'-noref'});
    
    return [$res, $names, $lacc * $max];
}


package Encode::UTR22::Regexp::classRef;

use vars qw(@ISA);

BEGIN { @ISA = qw(Encode::UTR22::Regexp::Element); }

sub count
{
	my $self = shift;
	my ($min, $max);
	$min = defined $self->{'min'} ? $self->{'min'} : 1;
    $max = defined $self->{'max'} ? $self->{'max'} : 1;
    return ($min, $max);
}

sub as_perl
{
    my ($self, $atstart, %opts) = @_;
    my ($class) = $self->{'owner'}{'classes'}{$self->{'name'}};
    my ($res, $temp, $wrap);
    my ($min, $max);

    $min = defined $self->{'min'} ? $self->{'min'} : 1;
    $max = defined $self->{'max'} ? $self->{'max'} : 1;

    return warn("No class defined for $self->{'name'}\n    in " . $self->as_error) unless defined $class;
    return warn("Empty class $self->{'name'}\n    in ". $self->as_error) unless (defined $class->{'elements'});

    if ($class->{'size'} && $class->{'size'} eq 'bytes')
    {
        $temp = join('', @{$class->{'elements'}});
        $temp =~ s/([$%\\^&*(){}\[\]|+"'?\/.`~\-])/\\$1/og;
        $temp =~ s/([^\x21-\x7e])/sprintf("\\x%02x", ord($1))/oge;
    } else
    {
        use utf8;
        $temp = join('', @{$class->{'elements'}});
        $temp =~ s/([$%\\^&*(){}\[\]|+"'?\/.`~\-])/\\$1/og;
        $temp =~ s/([^\x21-\x7e])/sprintf("\\x{%04X}", unpack('U', $1))/oge;
    }
    $res = "(" if ($self->{'id'} && !$opts{'-noref'});
    $wrap = ($#{$class->{'elements'}} > 0 || defined $self->{'neg'} || $min != 1 || $max != 1);
    $res .= "[" if $wrap;
    $res .= '^' if (defined $self->{'neg'});
    $res .= "$temp";
    $res .= "]" if $wrap;

    if ($max > 1)
    {
        if ($min != $max)
        { $res .= "{$min,$max}"; }
        else
        { $res .= "{$max}"; }
    } elsif ($min == 0)
    { $res .= "?"; }
    
    if ($self->{'id'})
    {
        $res .= ')' unless ($opts{'-noref'});
        return [$res, [$self->{'id'}], $max];
    }
    else
    { return [$res, [], $max]; }
}


package Encode::UTR22::Regexp::contextRef;

use vars qw(@ISA);

BEGIN { @ISA = qw(Encode::UTR22::Regexp::Element); }

sub as_perl
{
    my ($self, $atstart, %opts) = @_;
    my ($ref, $n, $res, $ind, $temp, $len, $id);

    my ($fn) = $opts{'-fn'} || "as_perl";
    unless ($self->{'name'})
    {
        print STDERR "No name attribute in context-ref at line $self->{'line'}\n";
        return [undef, '', 0];
    }

    foreach $n (split('/', $self->{'name'}))
    {
        if ($ref)
        { $ref = $ref->{'named'}{$n}; }
        else
        { $ref = $self->{'owner'}{'contexts'}{$n}; }
        unless ($ref)
        {
            print STDERR "Can't find reference to $n in $self->{'name'} at line $self->{'line'}\n";
            return ['', []];
        }
    }

    $self->{'named'} = $ref->{'named'};

    if (defined $self->{'max'} || defined $self->{'min'})
    {
        $temp = bless {%$ref}, ref $ref;
        $temp->{'max'} = $self->{'max'} if defined $self->{'max'};
        $temp->{'min'} = $self->{'min'} if defined $self->{'min'};
        ($res, $ind, $len) = @{$temp->${fn}($atstart, %opts)};
    } else
    { ($res, $ind, $len) = @{$ref->${fn}($atstart, %opts)}; }

    $id = $self->{'id'} || $self->{'name'};
    foreach $n (@{$ind}) { $n =~ s|^[^/]+|$id|o; }
    
    return [$res, $ind, $len];
}

package Encode::UTR22::Regexp::EOS;

use vars qw(@ISA);

BEGIN { @ISA = qw(Encode::UTR22::Regexp::Element); }

sub as_perl
{
    my ($self, $atstart, %opts) = @_;

    return [$atstart ? '^' : '$', [], 0];
}


package Encode::UTR22::Regexp::class;

sub new
{
    my ($class, %attrs) = @_;
    my ($self) = {%attrs};
    bless $self, ref $class || $class;
}

sub add_elements
{
    my ($self) = shift;

    push (@{$self->{'elements'}}, @_);
    $self;
}

sub add_from
{
    my ($self, $other) = @_;

    push (@{$self->{'elements'}}, @{$other->{'elements'}});
    $self;
}

sub add_range
{
    my ($self, $start, $end) = @_;

    push (@{$self->{'elements'}}, map {pack($self->{'size'} eq 'bytes' ? 'C' : 'U', $_)}
                                      ($start .. $end));
    $self;
}

1;

=head1 COPYRIGHT

This module is copyright SIL International and is distributed under the same terms as Perl itself.

