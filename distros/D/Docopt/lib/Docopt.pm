use 5.008005;
use strict;
use warnings FATAL => 'all';

package Docopt;

use Docopt::Util qw(string_partition in serialize defined_or);

package Docopt::Pattern;

use Docopt::Util qw(defined_or);

sub new {
    my $class = shift;
    bless [], $class;
}

sub fix {
    my $self = shift;
    $self->fix_identities();
    $self->fix_repeating_arguments();
    return $self;
}
use Docopt::Util qw(in serialize);

# Make pattern-tree tips point to same object if they are equal.
sub fix_identities {
    my ($self, $uniq) = @_;

    if (!$self->can('children')) {
        return $self;
    }
    $uniq = defined_or($uniq, $self->flat);
    for (my $i=0; $i<@{$self->children}; $i++) {
        my $child = $self->children->[$i];
        if (not $child->can('children')) {
            local $Storable::canonical=1;
            in(serialize($child), [map { serialize($_) } @$uniq]) or die;
            ($self->children->[$i], ) = grep { serialize($_) eq serialize($child) } @$uniq;
        } else {
            $child->fix_identities($uniq);
        }
    }

#   def fix_identities(self, uniq=None):
#       """Make pattern-tree tips point to same object if they are equal."""
#       if not hasattr(self, 'children'):
#           return self
#       uniq = list(set(self.flat())) if uniq is None else uniq
#       for i, child in enumerate(self.children):
#           if not hasattr(child, 'children'):
#               assert child in uniq
#               self.children[i] = uniq[uniq.index(child)]
#           else:
#               child.fix_identities(uniq)
}

use Scalar::Util qw(refaddr);
use Docopt::Util qw(repl serialize);

# Fix elements that should accumulate/increment values.
sub fix_repeating_arguments {
    my $self = shift;

    my $list_count = sub {
        my ($list, $stuff) = @_;
        my $n = 0;
        for (@$list) {
            $n++ if serialize($stuff) eq serialize($_);
        }
        return $n;
    };

    # print repl(Docopt::transform($self));
    my @either = map { $_->children } @{Docopt::transform($self)->children};
    for my $case (@either) {
        for my $e (grep { $list_count->($case, $_) > 1 } @$case) {
            if ($e->isa('Docopt::Argument') || ($e->isa('Docopt::Option') && $e->argcount)) {
                if (not defined $e->value) {
                    $e->value([]);
                } elsif (ref($e->value) ne 'ARRAY') {
                    $e->value([split /\s+/, $e->value]);
                }
            }
            if ($e->isa('Docopt::Command') || ($e->isa('Docopt::Option') && $e->argcount==0)) {
                $e->value(0);
            }
        }
    }
    return $self;

#       either = [list(child.children) for child in transform(self).children]
#       for case in either:
#           for e in [child for child in case if case.count(child) > 1]:
#               if type(e) is Argument or type(e) is Option and e.argcount:
#                   if e.value is None:
#                       e.value = []
#                   elif type(e.value) is not list:
#                       e.value = e.value.split()
#               if type(e) is Command or type(e) is Option and e.argcount == 0:
#                   e.value = 0
#       return self
}

package Docopt;

use parent qw(Exporter);

our @EXPORT = qw(docopt);

use List::MoreUtils qw(any);
use Scalar::Util qw(blessed refaddr);
use Docopt::Util qw(repl pyprint serialize);

# Expand pattern into an (almost) equivalent one, but with single Either.
#   Example: ((-a | -b) (-c | -d)) => (-a -c | -a -d | -b -c | -b -d)
#   Quirks: [-a] => (-a), (-a...) => (-a -a)
sub transform {
    my ($pattern) = @_;

#   pyprint($pattern);
    my @results;
    my @groups = [$pattern];
    while (@groups) {
        my $children = shift @groups;
#       pyprint($children);
        my @parents = qw(Docopt::Required Docopt::Optional Docopt::OptionsShortcut Docopt::Either Docopt::OneOrMore);
        if (any { in($_, [map { blessed $_ } @$children]) } @parents) {
#           print "  ANY\n";
            my $child = [grep { in(blessed $_, \@parents) } @$children]->[0];
            $children = [ grep { refaddr($child) ne refaddr($_) } @$children ];
            if ($child->isa('Docopt::Either')) {
#               print "    EITHER\n";
                for (@{$child->children}) {
                    push @groups, [$_, @{$children}];
                }
            } elsif ($child->isa('Docopt::OneOrMore')) {
#               print "    ONEORMORE\n";
                # I need copying.
                push @groups, [@{$child->children}, @{Storable::dclone($child->children)}, @$children];
            } else {
#               print "    OTHER\n";
                push @groups, [@{$child->children}, @$children];
            }
        } else {
#           print "  JUST PUSH\n";
            push @results, $children;
        }
    }
#   pyprint(\@results);
    return Docopt::Either->new([map { Docopt::Required->new($_) } @results]);

#ef transform(pattern):
#   result = []
#   groups = [[pattern]]
#   while groups:
#       children = groups.pop(0)
#       parents = [Required, Optional, OptionsShortcut, Either, OneOrMore]
#       if any(t in map(type, children) for t in parents):
#           child = [c for c in children if type(c) in parents][0]
#           children.remove(child)
#           if type(child) is Either:
#               for c in child.children:
#                   groups.append([c] + children)
#           elif type(child) is OneOrMore:
#               groups.append(child.children * 2 + children)
#           else:
#               groups.append(child.children + children)
#       else:
#           result.append(children)
#   return Either(*[Required(*e) for e in result])
}

# Leaf/terminal node of a pattern tree
package Docopt::LeafPattern;
use parent -norequire, qw(Docopt::Pattern);

use Docopt::Util qw(repl class_name True False is_number);

use Class::Accessor::Lite (
    rw => [qw(name)],
);

sub value {
    my $self = shift;
    return $self->{value} if @_==0;
    if (@_==1) {
        # warn "SET: $_[0]";
        $self->{value} = $_[0];
    } else {
        Carp::confess("Too much arguments");
    }
}

sub new {
    my ($class, $name, $value) = @_;
    bless {
        name => $name,
        value => $value,
    }, $class;
}


sub __repl__ {
    my $self = shift;
    sprintf '%s(%s, %s)',
        class_name($self),
        repl($self->name),
        repl($self->value);
}
sub flat {
    my ($self, $types) = @_;
    if (!defined($types) || $self->isa($types)) {
        return [$self];
    } else {
        return [];
    }
}
sub match {
    my $self = shift;
    my @left = @{+shift};
    my @collected = @{ +shift || +[] };

    my ($pos, $match) = $self->single_match(\@left);
    unless ($match) {
        return (False, \@left, \@collected);
    }
    my @left_ = (@left[0..$pos-1], @left[$pos+1..@left-1]);
    my @same_name = grep { $_->name eq $self->name } @collected;
    if (is_number($self->value) || ref($self->value) eq 'ARRAY') {
        my $increment;
        if (is_number($self->value)) {
            $increment = 1;
        } else {
            $increment = ref($match->value) eq 'ARRAY' ? $match->value : [$match->value];
        }
        unless (@same_name) {
            # warn "NO SAME: " . ' . ' . repl($self->value) . ' : ' . repl($increment);
            $match->value($increment);
            return (True, \@left_, [@collected, $match]);
        }
        if (ref $same_name[0]->value eq 'ARRAY') {
            $same_name[0]->value([@{$same_name[0]->value}, ref($increment) eq 'ARRAY' ? @$increment : $increment]);
        } else {
            ref($increment) ne 'ARRAY' or Carp::confess("Invalid addition");
            $same_name[0]->value($same_name[0]->value + $increment);
        }
        return (True, \@left_, \@collected);
    }
    return (True, \@left_, [@collected, $match]);
}

package Docopt::BranchPattern;

use parent -norequire, qw(Docopt::Pattern);

use Carp;

use Docopt::Util qw(repl class_name);
use Scalar::Util qw(blessed);

sub new {
    my ($class, $children) = @_;
    Carp::croak("Too much arguments") unless @_==2;
    Carp::confess "Children must be arrayref: $class, $children" unless ref $children eq 'ARRAY';

    # zjzj FIXME ad-hoc hack
    $children = [ map { ref($_) eq 'ARRAY' ? @$_ : $_ } @$children];

    bless {
        children => [@$children],
    }, $class;
}

sub children {
    my $self = shift;
    return $self->{children} if @_==0;
    if (@_==1) {
        ref($_[0]) eq 'ARRAY' or Carp::confess("Argument must be ArrayRef but: " . $_[0]);
        $self->{children} = $_[0];
    } else {
        Carp::confess("Too much arguments");
    }
}

sub __repl__ {
    my $self = shift;
    sprintf '%s(%s)',
        class_name($self),
        join(', ', map { repl($_) } @{$self->{children}});
}

sub flat {
    my $self = shift;
    my $types = shift;
    if (defined($types) && $self->isa($types)) {
        return [$self];
    }
    my @ret = map { ref($_) eq 'ARRAY' ? @$_ : $_ } map { $_->flat($types) } @{$self->children};
    return \@ret;
#       if type(self) in types:
#           return [self]
#       return sum([child.flat(*types) for child in self.children], [])
}

package Docopt::Argument;
use parent -norequire, qw(Docopt::LeafPattern);

sub single_match {
    my ($self, $left) = @_;
    ref $left eq 'ARRAY' or die;

    for (my $n=0; $n<@$left; $n++) {
        my $pattern = $left->[$n];
        if ($pattern->isa(Docopt::Argument::)) {
            return ($n, Docopt::Argument->new($self->name, $pattern->value));
        }
    }
    return (undef, undef);
}

sub parse {
    my ($class, $source) = @_;
    $source =~ /(<\S*?>)/;
    my $name = $1;
    $source =~ /\[default: (.*)\]/i;
    my $value = $1;
    return $class->new($name, $value);
}

package Docopt::Command;
use parent -norequire, qw(Docopt::Argument);

use Class::Accessor::Lite (
    rw => [qw(name value)]
);
use boolean;

sub new {
    my ($class, $name, $value) = @_;
    bless {
        name => $name,
        value => $value,
    }, $class;
}

sub single_match {
    my ($self, $left) = @_;
    ref $left eq 'ARRAY' or die;

    for (my $n=0; $n<@$left; $n++) {
        my $pattern = $left->[$n];
        if ($pattern->isa(Docopt::Argument::)) {
            if ($pattern->value eq $self->name) {
                return ($n, Docopt::Command->new($self->name, true));
            } else {
                last;
            }
        }
    }
    return (undef, undef);
}

package Docopt::Required;

use parent -norequire, qw(Docopt::BranchPattern);
use boolean;

sub match {
    my ($self, $left, $collected) = @_;
    $collected ||= [];

    my $l = $left;
    my $c = $collected;
    for my $pattern (@{$self->children}) {
        my $matched;
        ($matched, $l, $c) = $pattern->match($l, $c);
        unless ($matched) {
            ref($c) eq 'ARRAY' or Carp::confess("c is not arrayref");
            return (false, $left, $collected);
        }
    }
    ref($c) eq 'ARRAY' or Carp::confess("c is not arrayref: " . join(', ', @{$self->children}));
    return (true, $l, $c);

    
#   def match(self, left, collected=None):
#       collected = [] if collected is None else collected
#       l = left
#       c = collected
#       for pattern in self.children:
#           matched, l, c = pattern.match(l, c)
#           if not matched:
#               return False, left, collected
#       return True, l, c
}

package Docopt::Optional;

use parent -norequire, qw(Docopt::BranchPattern);

use boolean;

sub match {
    my ($self, $left, $collected) = @_;
    $collected ||= [];
    ref($collected) eq 'ARRAY' or Carp::confess("collected is not arrayref: " . join(', ', @{$self->children}));

    my $m;
    for my $pattern (@{$self->children}) {
        ($m, $left, $collected) = $pattern->match($left, $collected);
    }
    ref($collected) eq 'ARRAY' or Carp::confess("collected is not arrayref: " . join(', ', @{$self->children}));
    return (true, $left, $collected);

#   def match(self, left, collected=None):
#       collected = [] if collected is None else collected
#       for pattern in self.children:
#           m, left, collected = pattern.match(left, collected)
#       return True, left, collected
}

package Docopt::OptionsShortcut;
# Marker/placeholder for [options] shortcut.

use parent -norequire, qw(Docopt::Optional);

package Docopt::OneOrMore;

use parent -norequire, qw(Docopt::BranchPattern);
use boolean;
use Storable;
use Docopt::Util qw(serialize);

sub match {
    my ($self, $left, $collected) = @_;
    @{$self->children} == 1 or die;
    $collected ||= [];

    my $l = $left;
    my $c = $collected;
    my $l_ = undef;
    my $matched = true;
    my $times = 0;

    while ($matched) {
        # could it be that something didn't match but changed l or c?
        ($matched, $l, $c) = $self->children->[0]->match($l, $c);
        $times++ if $matched;
        if (serialize(\$l_) eq serialize(\$l)) {
            last;
        }
        $l_ = $l;
    }
    if ($times >= 1) {
        return (true, $l, $c);
    }
    return (false, $left, $collected);

#   def match(self, left, collected=None):
#       assert len(self.children) == 1
#       collected = [] if collected is None else collected
#       l = left
#       c = collected
#       l_ = None
#       matched = True
#       times = 0
#       while matched:
#           # could it be that something didn't match but changed l or c?
#           matched, l, c = self.children[0].match(l, c)
#           times += 1 if matched else 0
#           if l_ == l:
#               break
#           l_ = l
#       if times >= 1:
#           return True, l, c
#       return False, left, collected
}

package Docopt::Either;

use parent -norequire, qw(Docopt::BranchPattern);
use boolean;

sub match {
    my ($self, $left, $collected) = @_;
    $collected ||= [];
    my @outcomes;
    for my $pattern (@{$self->children}) {
        my @outcome = $pattern->match($left, $collected);
        my $matched = $outcome[0];
        if ($matched) {
            push @outcomes, \@outcome;
        }
    }
    if (@outcomes) {
        my $retval = shift @outcomes;
        for (@outcomes) {
            if (@{$_->[1]} < @{$retval->[1]}) {
                $retval = $_;
            }
        }
        return @$retval;
    }
    return (false, $left, $collected);

#   def match(self, left, collected=None):
#       collected = [] if collected is None else collected
#       outcomes = []
#       for pattern in self.children:
#           matched, _, _ = outcome = pattern.match(left, collected)
#           if matched:
#               outcomes.append(outcome)
#       if outcomes:
#           return min(outcomes, key=lambda outcome: len(outcome[1]))
#       return False, left, collected
}

package Docopt::Tokens;

use Docopt::Util qw(repl);
use Class::Accessor::Lite 0.05 (
    rw => [qw(error source)],
);

sub new {
    my ($class, $source, $error) = @_;
    $error ||= 'Docopt::Exceptions::DocoptExit';

    unless (ref $source) {
        $source = [split /\s+/, $source];
    }
    bless {source => [@$source], error => $error}, $class;
}

sub from_pattern {
    my ($class, $source) = @_;

    $source =~ s/([\[\]\(\)\|]|\.\.\.)/ $1 /g;
    my @source = grep { defined($_) && length $_ > 0 } split /\s+|(\S*<.*?>)/, $source;
    return Docopt::Tokens->new(\@source, 'Docopt::Exceptions::DocoptLanguageError');
}

sub move {
    my $self = shift;
    shift @{$self->{source}};
}

sub current {
    my $self = shift;
    $self->source->[0];
}

sub __repl__ {
    my $self = shift;
    '[' . join(', ', map { repl($_) } @{$self->source}) . ']';
}


package Docopt;

our $VERSION = "0.03";

package Docopt::Option;

use parent -norequire, qw(Docopt::LeafPattern);

use Docopt::Util qw(repl string_strip string_partition defined_or);

use Class::Accessor::Lite 0.05 (
    rw => [qw(short long argcount)],
);

sub new {
    my ($class, $short, $long, $argcount, $value) = @_;
    if (@_<= 3) { $argcount = 0 }

    return bless {
        short => $short,
        long => $long,
        argcount => $argcount,
        value => !defined($value) && $argcount ? undef : $value,
    }, $class;
}

sub value {
    my $self = shift;
    return $self->{value} if @_==0;
    if (@_==1) {
        # Carp::cluck("SET: $_[0], $self->{long}, $self->{value}") if $_[0] eq 1;
        $self->{value} = $_[0];
    } else {
        Carp::confess("Too much arguments");
    }
}


sub single_match {
    my ($self, $left) = @_;
    ref $left eq 'ARRAY' or die;

    for (my $n=0; $n<@$left; $n++) {
        my $pattern = $left->[$n];
        if ($self->name eq defined_or($pattern->name, '')) {
            return ($n, $pattern);
        }
    }
    return (undef, undef);
}

sub name {
    my $self = shift;
    if (defined($self->long) && !ref($self->long)) {
        $self->long;
    } else {
        $self->short;
    }
}

sub parse {
    my ($class, $option_description) = @_;
    my ($short, $long, $argcount, $value) = (undef, undef, 0, undef);

    my ($options, undef, $description) = string_partition(string_strip($option_description), '  ');

    $options =~ s/,/ /g;
    $options =~ s/=/ /g;
    for my $s (split /\s+/, $options) {
        if ($s =~ /^--/) {
            $long = $s;
        } elsif ($s =~ /^-/) {
            $short = $s;
        } else {
            $argcount = 1;
        }
    }
    if ($argcount) {
        if (defined($description) && $description =~ /\[default: (.*)\]/i) {
            $value = $1;
        }
    }
    return $class->new($short, $long, $argcount, $value);
}

sub __repl__ {
    my ($self) = @_;
    sprintf 'Option(%s, %s, %s, %s)',
        repl($self->{short}),
        repl($self->{long}),
        repl($self->{argcount}),
        repl($self->{value});
}

package Docopt;

use boolean;

# long ::= '--' chars [ ( ' ' | '=' ) chars ] ;
sub parse_long {
    my ($tokens, $options) = @_;
    ref($options) eq 'ARRAY' or Carp::confess "Options must be arrayref";

    my ($long, $eq, $value) = string_partition($tokens->move, '=');
    $long =~ /\A--/ or die;
    $value = $eq eq '' && $value eq '' ? undef : $value;
    my @similar = grep { $_->long && $_->long eq $long } @$options;
    if ($tokens->error eq 'Docopt::Exceptions::DocoptExit' && @similar == 0) { # if no exact match
        @similar = grep { $_->long && $_->long =~ /$long/ } @$options;
    }
    my $o;
    if (@similar > 1) { # might be simply specified ambiguously 2+ times?
        $tokens->error->throw(sprintf '%s is not a unique prefix: %s?',
            $long, join(', ', map { $_->long } @similar));
    } elsif (@similar < 1) {
        my $argcount = $eq eq '=' ? 1 : 0;
        $o = Docopt::Option->new(undef, $long, $argcount);
        push @$options, $o;
        if ($tokens->error eq 'Docopt::Exceptions::DocoptExit') {
            $o = Docopt::Option->new(undef, $long, $argcount, $argcount ? $value : true);
        }
    } else {
        $o = Docopt::Option->new(
            $similar[0]->short,
            $similar[0]->long,
            $similar[0]->argcount,
            $similar[0]->value,
        );
        if ($o->argcount == 0) {
            if (defined $value) {
                $tokens->error->throw(sprintf "%s must not have an argument", $o->long);
            }
        } else {
            if (not defined $value) {
                if (
                    (not defined $tokens->current() ) || $tokens->current eq '--') {
                    $tokens->error->throw(sprintf "%s requires argument", $o->long);
                } 
                $value = $tokens->move;
            }
        }
        if ($tokens->error eq 'Docopt::Exceptions::DocoptExit') {
            $o->value(defined($value) ? $value : true);
        }
    }
    return [$o];

#   long, eq, value = tokens.move().partition('=')
#   assert long.startswith('--')
#   value = None if eq == value == '' else value
#   similar = [o for o in options if o.long == long]
#   if tokens.error is DocoptExit and similar == []:  # if no exact match
#       similar = [o for o in options if o.long and o.long.startswith(long)]
#   if len(similar) > 1:  # might be simply specified ambiguously 2+ times?
#       raise tokens.error('%s is not a unique prefix: %s?' %
#                          (long, ', '.join(o.long for o in similar)))
#   elif len(similar) < 1:
#       argcount = 1 if eq == '=' else 0
#       o = Option(None, long, argcount)
#       options.append(o)
#       if tokens.error is DocoptExit:
#           o = Option(None, long, argcount, value if argcount else True)
#   else:
#       o = Option(similar[0].short, similar[0].long,
#                  similar[0].argcount, similar[0].value)
#       if o.argcount == 0:
#           if value is not None:
#               raise tokens.error('%s must not have an argument' % o.long)
#       else:
#           if value is None:
#               if tokens.current() in [None, '--']:
#                   raise tokens.error('%s requires argument' % o.long)
#               value = tokens.move()
#       if tokens.error is DocoptExit:
#           o.value = value if value is not None else True
#   return [o]
}

# shorts ::= '-' ( chars )* [ [ ' ' ] chars ] ;
sub parse_shorts {
    my ($tokens, $options) = @_;

    my $token = $tokens->move;
    (my $left = $token) =~ s/^-//;
    my @parsed;
    while ($left ne '') {
        my $o;
        $left =~ s/\A(.)//;
        my $short = '-' . $1;
        my @similar = grep { defined_or($_->short, '') eq $short } @$options;
        if (@similar > 1) {
            $tokens->error->throw(sprintf "%s is specified ambiguously %d times",
                $short, 0+@similar);
        } elsif (@similar < 1) {
            $o = Docopt::Option->new($short, undef, 0);
            push @$options, $o;
            if ($tokens->error eq 'Docopt::Exceptions::DocoptExit') {
                $o = Docopt::Option->new($short, undef, 0, undef)
            }
        } else {
            # why copying is necessary here?
            $o = Docopt::Option->new($short, $similar[0]->long,
                $similar[0]->argcount, $similar[0]->value);
            my $value = undef;
            if ($o->argcount != 0) {
                if ($left eq '') {
                    if (!defined($tokens->current) || $tokens->current eq '--') {
                        $tokens->error->throw("$short requires argument");
                    }
                    $value = $tokens->move;
                } else {
                    $value = $left;
                    $left = '';
                }
            }
            if ($tokens->error eq 'Docopt::Exceptions::DocoptExit') {
                $o->value(defined($value) ? $value : true);
            }
        }
        push @parsed, $o;
    }
    return \@parsed;

# def parse_shorts(tokens, options):
#   token = tokens.move()
#   assert token.startswith('-') and not token.startswith('--')
#   left = token.lstrip('-')
#   parsed = []
#   while left != '':
#       short, left = '-' + left[0], left[1:]
#       similar = [o for o in options if o.short == short]
#       if len(similar) > 1:
#           raise tokens.error('%s is specified ambiguously %d times' %
#                              (short, len(similar)))
#       elif len(similar) < 1:
#           o = Option(short, None, 0)
#           options.append(o)
#           if tokens.error is DocoptExit:
#               o = Option(short, None, 0, True)
#       else:  # why copying is necessary here?
#           o = Option(short, similar[0].long,
#                      similar[0].argcount, similar[0].value)
#           value = None
#           if o.argcount != 0:
#               if left == '':
#                   if tokens.current() in [None, '--']:
#                       raise tokens.error('%s requires argument' % short)
#                   value = tokens.move()
#               else:
#                   value = left
#                   left = ''
#           if tokens.error is DocoptExit:
#               o.value = value if value is not None else True
#       parsed.append(o)
#   return parsed
}
use Docopt::Util qw(repl);

sub parse_pattern {
    my ($source, $options) = @_;
    my $tokens = Docopt::Tokens->from_pattern($source);
    my $result = parse_expr($tokens, $options);
    if (defined $tokens->current()) {
        $tokens->error->throw("unexpected ending: " . repl(join(' ', $tokens)));
    }
    return Docopt::Required->new($result);

#   def parse_pattern(source, options):
#       tokens = Tokens.from_pattern(source)
#       result = parse_expr(tokens, options)
#       if tokens.current() is not None:
#           raise tokens.error('unexpected ending: %r' % ' '.join(tokens))
#       return Required(*result)
}

# $tokens: Docopt::Tokens
# $options: ARRAY
sub parse_expr {
    # expr ::= seq ( '|' seq )* ;
    my ($tokens, $options) = @_;

    my $seq = parse_seq($tokens, $options);
    if (!defined($tokens->current) || $tokens->current ne '|') {
        return $seq;
    }

#   result = [Required(*seq)] if len(seq) > 1 else seq
    my @result = @$seq > 1 ? Docopt::Required->new($seq) : @$seq;
    while (defined($tokens->current) && $tokens->current eq '|') {
        $tokens->move();
        $seq = parse_seq($tokens, $options);
        push @result, @$seq > 1 ? Docopt::Required->new($seq) : @$seq;
    }
    # zjzj This map() is so bad. But i can't remove this correctly...
    return @result > 1 ? [Docopt::Either->new([map { ref($_) eq 'ARRAY' ? @$_ : $_ } @result])] : \@result;

#   seq = parse_seq(tokens, options)
#   if tokens.current() != '|':
#       return seq
#   result = [Required(*seq)] if len(seq) > 1 else seq
#   while tokens.current() == '|':
#       tokens.move()
#       seq = parse_seq(tokens, options)
#       result += [Required(*seq)] if len(seq) > 1 else seq
#   return [Either(*result)] if len(result) > 1 else result
}

# seq ::= ( atom [ '...' ] )* ;
sub parse_seq {
    my ($tokens, $options) = @_;
    my @result;
    while (not in($tokens->current, [undef, ']', ')', '|'])) {
        my $atom = parse_atom($tokens, $options);
        if (defined($tokens->current) && $tokens->current eq '...') {
            $atom = Docopt::OneOrMore->new($atom);
            $tokens->move;
        }
        push @result, $atom;
    }
    return [map { ref($_) eq 'ARRAY' ? @$_ : $_ } @result];
#   def parse_seq(tokens, options):
#       """seq ::= ( atom [ '...' ] )* ;"""
#       result = []
#       while tokens.current() not in [None, ']', ')', '|']:
#           atom = parse_atom(tokens, options)
#           if tokens.current() == '...':
#               atom = [OneOrMore(*atom)]
#               tokens.move()
#           result += atom
#       return result
}

#  atom ::= '(' expr ')' | '[' expr ']' | 'options'
#        | long | shorts | argument | command ;
sub parse_atom {
    my ($tokens, $options) = @_;

    my $token = $tokens->current();
    my @result;
    if ($token eq '(' || $token eq '[') {
        $tokens->move;
        my ($matching, $pattern) = @{{
            '(' => [')', Docopt::Required::],
            '[' => [']', Docopt::Optional::]
        }->{$token}};
        my $expr = parse_expr($tokens, $options);
        my $result = $pattern->new($expr);
        if (($tokens->move ||'') ne $matching) {
            Docopt::Exceptions::DocoptLanguageError->throw("unmatched '$token'");
        }
        return [$result];
    } elsif ($token eq 'options') {
        $tokens->move;
        return [Docopt::OptionsShortcut->new([])];
    } elsif ($token =~ /^--/ && $token ne '--') {
        return parse_long($tokens, $options);
    } elsif ($token =~ /^-/ && ($token ne '-' && $token ne '--')) {
        return parse_shorts($tokens, $options);
    } elsif (($token =~ /^</ && $token =~ />$/) or $token =~ /\A[A-Z]+\z/) {
        return [Docopt::Argument->new($tokens->move)];
    } else {
        return [Docopt::Command->new($tokens->move)];
    }

#   token = tokens.current()
#   result = []
#   if token in '([':
#       tokens.move()
#       matching, pattern = {'(': [')', Required], '[': [']', Optional]}[token]
#       result = pattern(*parse_expr(tokens, options))
#       if tokens.move() != matching:
#           raise tokens.error("unmatched '%s'" % token)
#       return [result]
#   elif token == 'options':
#       tokens.move()
#       return [OptionsShortcut()]
#   elif token.startswith('--') and token != '--':
#       return parse_long(tokens, options)
#   elif token.startswith('-') and token not in ('-', '--'):
#       return parse_shorts(tokens, options)
#   elif token.startswith('<') and token.endswith('>') or token.isupper():
#       return [Argument(tokens.move())]
#   else:
#       return [Command(tokens.move())]
}

#   Parse command-line argument vector.
#
#   If options_first:
#       argv ::= [ long | shorts ]* [ argument ]* [ '--' [ argument ]* ] ;
#   else:
#       argv ::= [ long | shorts | argument ]* [ '--' [ argument ]* ] ;
sub parse_argv {
    my ($tokens, $options, $options_first) = @_;
    ref($options) eq 'ARRAY' or Carp::confess "Options must be arrayref";

    my @parsed;
    while (defined $tokens->current()) {
        if ($tokens->current() eq '--') {
            return [@parsed, map { Docopt::Argument->new(undef, $_) } @{$tokens->source}];
        } elsif ($tokens->current() =~ /\A--/) {
            push @parsed, @{parse_long($tokens, $options)};
        } elsif ($tokens->current() =~ /\A-/ && $tokens->current ne '-') {
            push @parsed, @{parse_shorts($tokens, $options)};
        } elsif ($options_first) {
            return [@parsed, map { Docopt::Argument->new(undef, $_) } @{$tokens->source}];
        } else {
            push @parsed, Docopt::Argument->new(undef, $tokens->move);
        }
    }
    return \@parsed;
}

sub parse_defaults {
    my ($doc) = @_;

    my @defaults;

    for my $s (parse_section('options:', $doc)) {
        # FIXME corner case "bla: options: --foo"
        (undef, undef, $s) = string_partition($s, ':');
        my @split = split /\n *(-\S+?)/, "\n" . $s;
        shift @split;
        my @split2;
        for (my $i=0; $i<@split; $i+=2) {
            push @split2, $split[$i].defined_or($split[$i+1], '');
        }
#       options = [Option.parse(s) for s in split if s.startswith('-')]
        for my $s (grep /^-/, @split2) {
            push @defaults, Docopt::Option->parse($s);
        }
    }
    return @defaults;
}

sub parse_section {
    my ($name, $source) = @_;
    defined($source) or Carp::confess("Missing source");
    my @s;
    while ($source =~ /^([^\n]*${name}[^\n]*\n?(?:[ \t].*?(?:\n|$))*)/img) {
        local $_ = $1;
        s/\A\s+//;
        s/\s+\z//;
        push @s, $_;
    }
    return @s;
}

sub formal_usage {
    my ($section) = @_;
    # _, _, section = section.partition(':')  # drop "usage:"
    (undef, undef, $section) = string_partition($section, ':');
    my @pu = grep { /\S/ } split /\s+/, $section;
    my $cmd = shift @pu;
    return '( ' . join(' ', map { $_ eq $cmd ? ') | (' : $_ } @pu) . ' )';
}


use List::MoreUtils qw(any);
sub extras {
    my ($help, $version, $options, $doc) = @_;
    if ($help && any { in($_->name, ['-h', '--help']) && $_->value } @$options) {
        print $doc . "\n";
        exit(0);
    }
    if ($version && grep { defined($_->name) && $_->name eq '--version' } @$options) {
        print "$version\n";
        exit(0);
    }

#ef extras(help, version, options, doc):
#   if help and any((o.name in ('-h', '--help')) and o.value for o in options):
#       print(doc.strip("\n"))
#       sys.exit()
#   if version and any(o.name == '--version' and o.value for o in options):
#       print(version)
#       sys.exit()
}

sub docopt {
    # def docopt(doc, argv=None, help=True, version=None, options_first=False):
    @_%2==0 or Carp::confess("You need to pass arguments are hash");

    my %args = @_;

    my $doc = delete $args{doc};
    my $argv = delete $args{argv} || \@ARGV;
    my $help = exists($args{help}) ? delete $args{help} : true;
    my $version = delete $args{version};
    my $option_first = delete $args{option_first};

    if (%args) {
        Carp::confess("Unknown argument passed to docopt(): " . join(", ", keys %args));
    }

    if (not defined $doc) {
        # Should I selecte 'SYNOPSIS' section?
        require Pod::Usage;
#       require Pod::Simple::Text;

        open my $fh, '>', \$doc
            or die $!;
        my $parser = Pod::Usage->new(USAGE_OPTIONS => +{});
        $parser->select('(?:SYNOPSIS|USAGE)\s*');
        $parser->parse_from_file($0, $fh);
#       my $parser = Pod::Simple::Text->new();
#       $parser->{output_fh} = $fh;
#       $parser->parse_file($0);
    }

    my @usage_sections = parse_section('usage:', $doc);
    if (@usage_sections == 0) {
        Docopt::Exceptions::DocoptLanguageError->throw('"usage:" (case-insensitive) not found.');
    }
    if (@usage_sections > 1) {
        Docopt::Exceptions::DocoptLanguageError->throw('More than one "usage:" (case-insensitive).');
    }
    $Docopt::Exceptions::DocoptExit::USAGE = $usage_sections[0];

    my $options = [parse_defaults($doc)];
    my $pattern = parse_pattern(formal_usage($usage_sections[0]), $options);
    # pyprint($pattern);
    # [default] syntax for argument is disabled
    #for a in pattern.flat(Argument):
    #    same_name = [d for d in arguments if d.name == a.name]
    #    if same_name:
    #        a.value = same_name[0].value
    # pyprint($argv);
    $argv = parse_argv(Docopt::Tokens->new($argv), $options, $option_first);
    my $parse_options = $pattern->flat(Docopt::Option::);
    for my $options_shortcut (@{$pattern->flat(Docopt::OptionsShortcut::)}) {
        my @doc_options = parse_defaults($doc);
        $options_shortcut->children([grep { !in(serialize($_), [map { serialize($_) } @$parse_options]) } @doc_options]);
        # pyprint($options_shortcut);

        #if any_options:
        #    options_shortcut.children += [Option(o.short, o.long, o.argcount)
        #                    for o in argv if type(o) is Option]
    }
    extras($help, $version, $argv, $doc);
    #pyprint($pattern->fix);
    # pyprint($argv);
    my ($matched, $left, $collected) = $pattern->fix->match($argv);
    #pyprint([$matched, $left, $collected]);
    if ($matched && serialize($left) eq serialize([])) { # better error message if left?
        return +{
            map {
                $_->name => $_->value
            } @{$pattern->flat}, @$collected
        };
    }
    Docopt::Exceptions::DocoptExit->throw();

#   argv = parse_argv(Tokens(argv), list(options), options_first)
#   pattern_options = set(pattern.flat(Option))
#   for options_shortcut in pattern.flat(OptionsShortcut):
#       doc_options = parse_defaults(doc)
#       options_shortcut.children = list(set(doc_options) - pattern_options)
#       #if any_options:
#       #    options_shortcut.children += [Option(o.short, o.long, o.argcount)
#       #                    for o in argv if type(o) is Option]
#   extras(help, version, argv, doc)
#   matched, left, collected = pattern.fix().match(argv)
#   if matched and left == []:  # better error message if left?
#       return Dict((a.name, a.value) for a in (pattern.flat() + collected))
#   raise DocoptExit()
}

package Docopt::Exception;

use overload (
    q{""} => 'stringify',
);

sub stringify {
    my $self = shift;
    sprintf "[%s] %s", ref $self, $self->{message} || 'Died';
}

sub new {
    my ($class, $message) = @_;
    bless {message => $message}, $class;
}
sub throw {
    my ($class, $message) = @_;
    die $class->new($message);
}

package Docopt::Exceptions::DocoptLanguageError;
use parent -norequire, qw(Docopt::Exception);

package Docopt::Exceptions::DocoptExit;
use parent -norequire, qw(Docopt::Exception);

our $USAGE;

sub stringify {
    my $self = shift;
    sprintf "%s\n%s\n", $self->{message} || '', $USAGE;
}

1;
__END__

=for stopwords kn docopt parens docopt-py

=encoding utf-8

=head1 NAME

Docopt - Command-line interface description language

=head1 SYNOPSIS

    use Docopt;

    my $opts = docopt();
    ...

    __END__

    =head1 SYNOPSIS

        log-aggregate [--date=<ymd>]

=head1 DESCRIPTION

B<Docopt.pm is still under development. I may change interface without notice.>

Docopt is command-line interface description language.

docopt helps you:

=over 4

=item define interface for your command-line app, and

=item automatically generate parser for it.

=back

docopt is based on conventions that are used for decades in help messages and man pages for program interface description. Interface description in docopt is such a help message, but formalized. Here is an example:

    Naval Fate.

    Usage:
        naval_fate ship new <name>...
        naval_fate ship <name> move <x> <y> [--speed=<kn>]
        naval_fate ship shoot <x> <y>
        naval_fate mine (set|remove) <x> <y> [--moored|--drifting]
        naval_fate -h | --help
        naval_fate --version

    Options:
        -h --help     Show this screen.
        --version     Show version.
        --speed=<kn>  Speed in knots [default: 10].
        --moored      Moored (anchored) mine.
        --drifting    Drifting mine.

The example describes interface of executable naval_fate, which can be invoked with different combinations of commands (ship, new, move, etc.), options (-h, --help, --speed=<kn>, etc.) and positional arguments (<name>, <x>, <y>).

Example uses brackets "[ ]", parens "( )", pipes "|" and ellipsis "..." to describe optional, required, mutually exclusive, and repeating elements. Together, these elements form valid usage patterns, each starting with program's name naval_fate.

Below the usage patterns, there is a list of options with descriptions. They describe whether an option has short/long forms (-h, --help), whether an option has an argument (--speed=<kn>), and whether that argument has a default value ([default: 10]).

docopt implementation will extract all that information and generate a command-line arguments parser, with text of the example above being the help message, which is shown to a user when the program is invoked with -h or --help options.

=head1 Usage patterns

You can read official document: L<http://docopt.org/>

=head1 FUNCTIONS

=over 4

=item C<< my $opts = docopt(%args) >>

Analyze argv by Docopt!

Return value is HashRef.

You can pass following options in C<%args>:

=over 4

=item doc

It's Docopt documentation.

If you don't provide this argument, Docopt.pm uses pod SYNOPSIS section in $0.

=item argv

Argument in arrayref.

Default: C<\@ARGV>

=item help

If it's true value, Docopt.pm enables C< --help > option automatically.

Default: true.

=item version

Version number of the script. If it's not undef, Docopt.pm enables C< --version > option.

Default: undef

=item option_first

    if (options_first) {
        argv ::= [ long | shorts ]* [ argument ]* [ '--' [ argument ]* ] ;
    } else {
        argv ::= [ long | shorts | argument ]* [ '--' [ argument ]* ] ;
    }

Default: undef

=back

=back

=head1 BASED ON

This version is based on docopt-py e495aaaf0b9dcea6bc8bc97d9143a0d7a649fa06.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

