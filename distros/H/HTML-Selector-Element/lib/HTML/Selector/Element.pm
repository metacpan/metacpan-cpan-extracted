package HTML::Selector::Element;
our $VERSION = '0.95';

## Adapted from HTML::Selector::XPath
## The parser is basically the same, the difference is in what it produces.

use Carp;
use strict;

sub import {
    my($class) = shift;
    if(@_) {
        require HTML::Element;
        package HTML::Element;
        local $^W;  # no warnings 'redefined' doesn't work over there in Exporter
        HTML::Selector::Element::Trait->import(@_);           
    }
}
 
my $ident = qr/(?![0-9]|-[-0-9])[-_a-zA-Z0-9]+/;

my $reg = {
    # tag name/id/class. Caveat: no namespace
    element => qr/^([#.]?)([^\s'"#.\/:@,=~>()\[\]|+]+)/i,
    # attribute presence
    attr1   => qr/^\[ \s* ($ident) \s* \]/x,
    # attribute value match
    attr2   => qr/^\[ \s* ($ident) \s*
        ( [~|*^\$!]? = ) \s*
        (?: ($ident) | "([^"]*)" | '([^']*)') \s* \] /x,
    badattr => qr/^\[/,
    pseudoN   => qr/^:(not|has|is)\(/i, # we chop off the closing parenthesis below in the code
    pseudo  => qr/^:([()a-z0-9_+-]+)/i,
    # adjacency/direct descendance (test for comma first)
    combinator => qr/^\s*([>+~])\s*|^\s+/i, # doesn't capture matched whitespace
    # rule separator
    comma => qr/^\s*,\s*/i,
};

sub new {
    my($class, @expr) = @_;
    my $self = bless {}, $class;
    $self->selector(@expr);
    return $self;
}

sub selector { 
    my $self = shift;
    if (@_) {
        delete @{$self}{qw(find is)};
        $self->{selector} = join ', ', @_;
        $self->{parsed} = \my @parsed;
        foreach (@_) {
            my($parsed, $leftover) = $self->consume($_);
            length $leftover
                and die "Invalid rule, couldn't parse '$leftover'";
            push @parsed, @$parsed;
        }
    }
    return $self->{selector};
}

sub convert_attribute_match {
    my ($left,$op,$right) = @_;
    # negation (e.g. [input!="text"]) isn't implemented in CSS, but include it anyway:
    if ($op eq '!=') {
        $left, qr/^(?!\Q$right\E$)/
    } elsif ($op eq '~=') { # substring attribute match
        $left, qr/(?<!\S)\Q$right\E(?!\S)/
    } elsif ($op eq '*=') { # real substring attribute match
        $left, qr/\Q$right\E/
    } elsif ($op eq '|=') {
        $left, qr/^\Q$right\E(?![^-])/
    } elsif ($op eq '^=') {
        $left, qr/^\Q$right\E/
    } elsif ($op eq '$=') {
        $left, qr/\Q$right\E$/
    } else { # exact match
        $left, $right
    }
}

# for our purpose, "siblings" includes the element itself
sub siblings {
    my($this) = @_;
    return children($this->{_parent}||return $this);
}

sub nth_of_type {
    my($of_type, $backward, $n, $cycle) = @_;
    # nth_child = nth_of_type without type filter
    $cycle ||= 0;
    if($n <= 0 && $cycle > 0) {
        # permanent correction
        $n %= $cycle ||= $cycle;    # first value above 0
    }
    return sub { my($this) = @_;
        my @sibling = siblings($this);
        @sibling = grep $_->{_tag} eq $this->{_tag}, @sibling if $of_type;
        for(my $n = # lexical scratch copy
            $n > @sibling && $cycle < 0
                ? ($n-@sibling) % $cycle + @sibling   # first value below upper bound as modulo <= 0
                : $n ;  # no correction
            $n > 0 && $n <= @sibling;    # give up as soon as we get out of range
            $n += $cycle || last)        # loop only once if $cycle is zero
        {
            return 1 if $this == $sibling[$backward ? -$n : $n - 1];
        }
        return;
    }
}

sub only_child {
    my($this) = @_;
    return 1 == siblings($this);
}

# A hacky recursive descent
# Only descends for :not(...) and :has(...)
sub consume {
    my ($self, $rule) = @_;

    my @alt;
    my $last_rule = '';
    my $set = { static => my $static = [] }; 
    my $hold;  # last valid set
    my $sibling_root;   # root element of search space is sibling of start element
    my($any);  # flags
    my $start_combinators = '';

    $rule =~ s/^\s+//; 
    # Loop through each "unit" of the rule
    while() {
        # Match elements
        for($any = 0;; $any++) {    # endless loop
            if ($rule =~ s/$reg->{element}//) {
                my ($id_class,$name) = ($1,$2);
                if ($id_class eq '#') { # ID
                    unshift @$static, id => $name;
                    # a condition very likely to fail, so try this first
                } elsif ($id_class eq '.') { # class
                    push @$static, convert_attribute_match('class', '~=', $name);
                } elsif (!$set->{tag} && $name ne '*') {
                    # we're not adding '*' yet as that's a very loose condition that seldom fails
                    # It's often not even necessary to test when we have other, more stringent conditions.
                    $set->{tag} = $name;
                    push @$static, _tag => $name;
                }
            }
            # Match attribute selectors
            elsif ($rule =~ s/$reg->{attr2}//) {
                push @$static, convert_attribute_match( $1, $2, $^N );
            } elsif ($rule =~ s/$reg->{attr1}//) {
                # any value, as long as it's defined
                push @$static, convert_attribute_match( $1, '', qr// );
            } elsif ($rule =~ $reg->{badattr}) {
                Carp::croak "Invalid attribute-value selector '$rule'";
            }
            # Match :not and :has
            elsif ($rule =~ s/$reg->{pseudoN}//) {
                my $which = lc $1;
                # Now we parse the rest, and after parsing the subexpression
                # has stopped, we must find a matching closing parenthesis:
                my( $subset, $leftover ) = $self->consume( $rule );
                $rule = $leftover;
                $rule =~ s!^\s*\)!!
                    or die "Unbalanced parentheses at '$rule'";
                if($which eq 'not') {
                    my @params = criteria($subset, undef);
                    push @$static, sub { not look_self($_[0], @params) };
                } elsif($which eq 'is') {
                    my @params = criteria($subset, undef);
                    push @$static, sub { look_self($_[0], @params) };
                } elsif($which eq 'has') {
                    # This is possibly very slow, especially when executed very often, so we keep this criterium for last
                    push @{$set->{has}}, find_closure($subset);
                }
            }
            # other pseudoclasses/pseudoelements
            # "else" because there could be more than one :not/:has
            elsif ($rule =~ s/$reg->{pseudo}//) {
                my $simple = ":$1";
                if ( my @expr = $self->parse_pseudo($1, \$rule) ) {
                    push @$static, @expr;
                } elsif ( $1 eq 'only-child') {
                    push @$static, only_child();
                } elsif (my @m = $1 =~ /^((?:first|last)-(?:child|of-type)$) | ^(nth-(?:last-)?(?:child|of-type)) \((odd|even|(\d+)|(-?\d*)n([\+\-]\d+)?)\)$/x) {
                    # Matches all pseudoelements of the following lists:
                    #  - first-child, last-child, first-of-type, last-of-type: without expression
                    #  - nth-child, nth-of-type, nth-last-child, nth-last-of-type: with an expression between parens
                    #    of one of these types: odd, even, and an+b
                    #    with a lot of freedom for that last one, for example:
                    #    3, 3n, 3n+1, n+5, -n+5, -3n+5, 3n-1
                    my($pseudo, $nth, $expr, $n, $cycle, $offset) = @m;
                    if($nth) {
                        if(defined $cycle) {
                            $cycle .= '1' if $cycle =~ /^(-?)$/;
                            $n = $offset || $cycle;
                        }
                        elsif(!defined $n) {
                            # even / odd
                            $cycle = 2;
                            $n = $expr eq 'odd' ? 1 : 2;
                        }
                        $pseudo = $nth;
                    }
                    else {
                        # first / last
                        $n = 1;
                    }
                    my $of_type = $pseudo =~ /of-type/;
                    my $backward = $pseudo =~ /last/;
                    push @$static, nth_of_type($of_type, $backward, $n+0, $cycle);
                } elsif ($1 =~ /^contains\($/) {
                    # not sure if this will work well in practise, in regards to whitespace
                    if( $rule =~ s/^\s*"([^"]*)"\s*\)// ) {     # "#stupid syntax highlighter
                        my $fragment = $1;
                        push @$static, sub { $_[0]->as_text() =~ /\Q$fragment/ };
                    } elsif( $rule =~ s/^\s*'([^']*)'\s*\)// ) { #'#stupid syntax highlighter
                        my $fragment = $1;
                        push @$static, sub { $_[0]->as_text() =~ /\Q$fragment/ };
                    } else {
                        return( $set, $rule );
                        die "Malformed string in :contains(): '$rule'";
                    };
                } elsif ( $1 eq 'root') {
                    # matches document root, or starting element
                    $set->{is_root} = 1;
                } elsif ( $1 eq 'empty') {
                    push @$static, sub { (shift)->is_empty };
                } else {
                    Carp::croak "Can't translate '$1' pseudo-class";
                }
            }
            else {
                # failed to match anything
                last;
            }
            $any++;
            die  "Endless loop?"if $any > 20000;
            undef $hold;
        }

        # Match commas
        if ($rule =~ s/$reg->{comma}//o) {
            # ending one rule and beginning another
            $set->{tag} ||= do { push  @$static, _tag => qr/^(?!~)/; '*' };
            $set->{sibling_root} ||= $sibling_root if $sibling_root;
            push @alt, $set;
            $set = { static => $static = [] };
            ($any, $hold, $sibling_root) = ();
        }
        # Match combinators (whitespace, >, + and ~)
        elsif ($rule =~ s/$reg->{combinator}//) {
            my $combinator = $1 || ' ';
            unless($any) {
                unless($set->{chained}) {
                    # rule starts with a combinator
                    # add match for start element
                    $set->{is_root} = 1;    # root element / start element
                } else {
                    # 2 subsequent combinators: interject a '*'
                    push @$static, _tag => qr/^(?!~)/;
                    $set->{tag} = '*';
                }
            }
            # new context
            ($any, $hold) = ();
            $hold = $set unless $1;
            $set = { static => $static = [], chained => my $chained = $set, combinator => $combinator };
            if($chained->{is_root} || $chained->{sibling_root}) {
                if($combinator =~ /([+~])/) {
                    $set->{sibling_root}  = ($chained->{sibling_root} || '') . $1;
                    $sibling_root = $set;
                }
            }
        }
        else {
            last;
        }
    }
    # wrap up
    # rule ended in whitespace - This can only happen in nested rules such as :not( ... )
    $set = $hold if $hold;
    $set->{tag} ||= do { push  @$static, _tag => qr/^(?!~)/; '*' };
    $set->{sibling_root} ||= $sibling_root if $sibling_root;

    push @alt, $set;
    return \@alt, $rule; 
}

sub criteria {     
    # returns criteria for look_down, with bound closures
    my($set, $refroot, $strategy) = @_;
    $strategy ||= { banroot => 1 };
    my $recurse;
    for my $root ($refroot ? $$refroot : 0) {
        $recurse = sub {
            # embeds $root
            my($set, $banroot) = @_;
            my @params = @{$set->{static}||[]};

            if($set->{is_root}) {
                $banroot = 0;
                if($refroot) {
                    # relative, top of branch
                    unshift @params, sub { $_[0] == $root };  # unlikely to succeed, so fail fast
                }
                else {
                    # absolute, root of DOM
                    unshift @params, _parent => undef;  # unlikely to succeed, so fail fast
                }
            }

            if($set->{chained}) {
                push @params, do {
                    # Value is an anonymous sub
                    # Recurse into linked list
                    my @params = $recurse->($set->{chained}, $banroot);
                    my $combinator = $set->{combinator};
                    # we're in a chained set, so we have to wrap the criteria into a test in a closure.
                    if ($combinator =~ /^\s+$/) {
                        $banroot ? sub { my($this) = @_;
                            my $rootparent = $root->{_parent} || 0;
                            while($this = $this->{_parent} and $this != $rootparent) {
                                look_self($this, @params) 
                                    and return 1;
                            }
                            return 0;
                        }
                        : sub { my($this) = @_;
                            while($this = $this->{_parent}) {
                                look_self($this, @params) 
                                    and return 1;
                            }
                            return 0;
                        }
                    }
                    elsif ($combinator =~ />/) {
                        $banroot ? sub { my($this) = @_;
                            my $rootparent = $root->{_parent} || 0;
                            if($this = $this->{_parent} and $this != $rootparent) {
                                look_self($this, @params) 
                                    and return 1;
                            }
                            return 0;
                        }
                        : sub { my($this) = @_;
                            if($this = $this->{_parent}) {
                                look_self($this, @params) 
                                    and return 1;
                            }
                            return 0;
                        };
                    }
                    elsif ($combinator =~ /\+/) {
                        sub { my($this) = @_;
                            my @left = $this->left;
                            while(@left) {
                                $this = pop @left;
                                ref $this && $this->{_tag} && $this->{_tag} !~ /^~/ or next;
                                look_self($this, @params) 
                                    and return 1;
                                return 0;
                            }
                            return 0;
                        };
                    }
                    elsif ($combinator =~ /\~/) {
                        sub { my($this) = @_;
                            my @left = $this->left;
                            while(@left) {
                                $this = pop @left;
                                ref $this && $this->{_tag} !~ /^~/ or next;
                                look_self($this, @params) 
                                    and return 1;
                            }
                            return 0;
                        }
                    }
                    else {
                        die "Weird combinator '$combinator'"
                    }
                };
            }
            elsif($banroot && !$set->{is_root}) {
                # if :root was not specified, $root should never match
                push @params, sub { $_[0] != $root };   # likely to succeed, so fail late
            }

            # do the :has tests last, because it's a complete subtree scan and that may be very slow.
            push @params, @{$set->{has}} if $set->{has};
            return wantarray ? @params : \@params;
        };
    }

    if(ref $set eq 'ARRAY') {
        if(@$set > 1) {
            my %tags;
            my @alt = map { $tags{$_->{tag}||'*'} = 1; [ $recurse->($_, !$refroot) ] } @$set;
            my @params = sub { my($this) = @_; look_self($this, @$_) and return 1 foreach @alt; return 0 };;
            unshift @params, sub { $tags{(shift)->{_tag}} } unless $tags{'*'};
            return wantarray ? @params : \@params;
        }
        ($set) = @$set;     # non-destructive
    }
    if(ref $set eq 'HASH') {
        return $recurse->($set, $refroot);
    }    
    elsif(ref $set) {
        # assumed method call
        return criteria($set->{parsed}, $refroot);
    }
}

sub parse_pseudo { 
    # nop, for subclassing
}

sub find_closure {
    my $sets = shift;
    $sets = $sets->{parsed} if ref $sets ne 'ARRAY';
    my $root;   # The embedded variable
    my(@down, @via_right, $right_down, @right_filter);
    foreach my $set (@$sets) {
        unless($set->{sibling_root}) {
            push @down, $set;
        }
        elsif(ref $set->{sibling_root}) {
            push @via_right, $set;
            push @right_filter, $set->{sibling_root};
            $right_down = 1;
        }
        else {
            push @via_right, $set;
            push @right_filter, $set;
        }
    }
    foreach my $array(\@down, \@via_right, \@right_filter) {
        @$array = criteria($array, \$root) if @$array;
    }
    unless(@via_right) {
        # the most common case: down only
        return sub {
            $root = shift; return $root->look_down(@down)
        };
    }
    else {
        return sub {
            $root = shift;
            my($result, @result);
            if(@down) {
                # unlikely, but possible
                unless(wantarray) {
                    $result = $root->look_down(@down) and return $result;
                }
                else {
                    @result = $root->look_down(@down);
                }
            }
            if(my @right = grep { ref and look_self($_, @right_filter) } $root->right) {
                unless($right_down) {
                    return wantarray ? (@result, @right) : shift @right;
                }
                unless(wantarray) {
                    $result = $_->look_down(@via_right) and return $result foreach @right; 
                }
                else {
                    push @result, $_->look_down(@via_right) foreach @right;
                }
            }
            return @result;
        };
    }
}

# flipped
sub find {
    my($self, $element) = @_;
    return ($self->{find} ||= find_closure($self->{parsed}))->($element)
}

package HTML::Selector::Element::Trait;
# core methods for trait that adds or overrides Selector support in HTML::Element
# use as a superclass in a subclass of HTML::Element, putting it before HTML::Element in @ISA
# or monkeypatch HTML::Element: import it into the HTML::Element package

require Carp;

use Exporter 'import';
our @EXPORT = qw(&find is closest);
our @EXPORT_OK = qw(look_self siblings children &select &query);

sub children {  # child elements, no fake elements
    my($this) = @_;
    return grep { ref and $_->{_tag} and $_->{_tag} !~ /^~/ } @{$this->{_content}||return};
}

sub look_self {
    my $this = shift;
    my($attr, $value, $matcher);
    while(@_) {
        # For speed reasons, no nested scopes and no block scope lexical variables
        ref ($attr = shift) or 
            2 != (defined($matcher = shift) + defined($value = $this->{$attr}) || next) ? return
                : ref $value ? # identical class and stringification or fail
                        ref $matcher eq ref $value && $matcher eq $value ? next : return
                    : ref $matcher
                        ? ref $matcher eq 'Regexp' && $value =~ $matcher ? next : return
                        : $value eq $matcher ? next : return;
        ref $attr eq 'CODE' and $attr->($this) ? next : return;
        # standard processing ends here
        if(ref $attr eq 'ARRAY') {
            my $success;
            foreach my $rule (@$attr) {
                next if ref $rule ne 'ARRAY';
                $success = look_self($this, @$rule) and last;
            }
            $success and next;
        }
        # unknown doesn't match
        return;
    }
    return $this;  # matches
}

my %store;
sub find {
    # backward compatible with find_by_tag_name in HTMl::Element if you stick to normal tags
    # If you do need special tags (= starting with "~"), find_by_tag_name is still available, and faster than look_down anyway
    my($element) = shift;
    my $selector = $store{join ', ', @_} ||= HTML::Selector::Element->new(@_);
    return $selector->find($element);
}

sub is {
    my($element) = shift;
    @_ or return;
    my $selector = $store{join ', ', @_} ||= HTML::Selector::Element->new(@_);
    $selector->{is} ||= [$selector->criteria];
    return look_self($element, @{$selector->{is}});
}

sub closest {
    my($element) = shift;
    my $selector = $store{join ', ', @_} ||= HTML::Selector::Element->new(@_);
    $selector->{is} ||= [$selector->criteria];
    return $element->look_up(@{$selector->{is}});
}

sub select {
    # same as find except the criteria are absolute in the DOM, instead of relative to the start element
    # only searches down, never below siblings
    my($element) = shift;
    my $selector = $store{join ', ', @_} ||= HTML::Selector::Element->new(@_);
    $selector->{is} ||= [$selector->criteria];
    return $element->look_down(@{$selector->{is}});
}

# alias
*query = \&select;

package HTML::Selector::Element;  
# round up: import subs from Trait

HTML::Selector::Element::Trait->import(qw(look_self children));

1;
