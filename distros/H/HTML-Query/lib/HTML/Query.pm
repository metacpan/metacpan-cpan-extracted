package HTML::Query;

our $VERSION = '0.09';

use Badger::Class
    version   => $VERSION,
    debug     =>  0,
    base      => 'Badger::Base',
    utils     => 'blessed',
    import    => 'class CLASS',
    vars      => 'AUTOLOAD',
    constants => 'ARRAY',
    constant  => {
        ELEMENT => 'HTML::Element',
        BUILDER => 'HTML::TreeBuilder',
    },
    exports   => {
        any   => 'Query',
        hooks => {
            query => \&_export_query_to_element,
        },
    },
    messages  => {
        no_elements => 'No elements specified to query',
        no_query    => 'No query specified',
        no_source   => 'No argument specified for source: %s',
        bad_element => 'Invalid element specified: %s',
        bad_source  => 'Invalid source specified: %s',
        bad_query   => 'Invalid query specified: %s',
        bad_spec    => 'Invalid specification "%s" in query: %s',
        is_empty    => 'The query does not contain any elements',
    };

our $SOURCES = {
    text => sub {
        class(BUILDER)->load;
        BUILDER->new_from_content(shift);
    },
    file => sub {
        class(BUILDER)->load;
        BUILDER->new_from_file(shift);
    },
    tree => sub {
        $_[0]
    },
    query => sub {
        ref $_[0] eq ARRAY
            ? @{ $_[0] }
            :    $_[0];
    },
};

sub Query (@) {
    CLASS->new(@_);
}

sub new {
    my $class = shift;
    my ($element, @elements, $type, $code, $select);

    # expand a single list ref into items
    unshift @_, @{ shift @_ }
        if @_ == 1 && ref $_[0] eq ARRAY;

    $class = ref $class || $class;

    my $self = {
                error => undef,
                suppress_errors => undef,
                match_self => undef,
                elements => \@elements,
                specificity => {}
               };

    # each element should be an HTML::Element object, although we might
    # want to subclass this module to recognise a different kind of object,
    # so we get the element class from the ELEMENT constant method which a
    # subclass can re-define.
    my $element_class = $class->ELEMENT;

    while (@_) {
        $element = shift;
        $class->debug("argument: ".$element) if DEBUG;

        if (! ref $element) {
            # a non-reference item is a source type (text, file, tree)
            # followed by the source, or if it's the last argument following
            # one ore more element options or named argument pairs then it's
            # a selection query
            if (@_) {
                $type = $element;
                $code = $SOURCES->{ $type }
                    || return $class->error_msg( bad_source => $type );
                $element = shift;
                $class->debug("source $type: $element") if DEBUG;
                unshift(@_, $code->($element));
                next;
            }
            elsif (@elements) {
                $select = $element;
                last;
            }
        }
        elsif (blessed $element) {
            # otherwise it should be an HTML::Element object or another
            # HTML::Query object
            if ($element->isa($element_class)) {
                push(@elements, $element);
                next;
            }
            elsif ($element->isa($class)) {
                push(@elements, @{$element->get_elements});
                next;
            }
        }

        return $class->error_msg( bad_element => $element );
    }

    bless $self, $class;

    return defined $select ? $self->query($select) : $self;
}

sub query {
    my ($self, $query) = @_;
    my @result;
    my $ops = 0;
    my $pos = 0;

    $self->{error} = undef;

    return $self->error_msg('no_query')
        unless defined $query && length $query;

    # multiple specs can be comma separated, e.g. "table tr td, li a, div.foo"
    COMMA: while (1) {
        # each comma-separated traversal spec is applied downward from
        # the source elements in the $self->{elements} query
        my @elements = @{$self->get_elements};
        my $comops   = 0;

        my $specificity = 0;
        my $startpos = pos($query) || 0;

        my $hack_sequence = 0; # look for '* html'

        warn "Starting new COMMA" if DEBUG;

        # for each whitespace delimited descendant spec we grok the correct
        # parameters for look_down() and apply them to each source element
        # e.g. "table tr td"
        SEQUENCE: while (1) {
            my @args;
            $pos = pos($query) || 0;
            my $relationship = '';
            my $leading_whitespace;

            warn "Starting new SEQUENCE" if DEBUG;

            # ignore any leading whitespace
            if ($query =~ / \G (\s+) /cgsx) {
              $leading_whitespace = defined($1) ? 1 : 0;
              warn "removing leading whitespace\n" if DEBUG;
            }

            # grandchild selector is whitespace sensitive, requires leading whitespace
            if ($leading_whitespace && $comops && ($query =~ / \G (\*) \s+ /cgx)) {
              # can't have a relationship modifier as the first part of the query
              $relationship = $1;
              warn "relationship = $relationship\n" if DEBUG;
            }

            # get other relationship modifiers
            if ($query =~ / \G (>|\+) \s* /cgx) {
              # can't have a relationship modifier as the first part of the query
              $relationship = $1;
              warn "relationship = $relationship\n" if DEBUG;
              if (!$comops) {
                return $self->_report_error( $self->message( bad_spec => $relationship, $query ) );
              }
            }

            # optional leading word is a tag name
            if ($query =~ / \G ([\w\*]+) /cgx) {
              my $tag = $1;

              if ($tag =~ m/\*/) {
                if (($leading_whitespace || $comops == 0) && ($tag eq '*')) {
                  warn "universal tag\n" if DEBUG;
                  push(@args, _tag => qr/\w+/);

                  if ($comops == 0) {  #we need to catch the case where we see '* html'
                    $hack_sequence++;
                  }
                }
                else {
                  return $self->_report_error( $self->message( bad_spec => $tag, $query ) );
                }
              }
              else {
                warn "html tag\n" if DEBUG;
                $specificity += 1; # standard tags are worth 1 point
                push( @args, _tag => $tag );

                if ($comops == 1 && $tag eq 'html') {
                  $hack_sequence++;
                }
              }
            }

            # loop to collect a description about this specific part of the rule
            while (1) {
                my $work = scalar @args;

                # that can be followed by (or the query can start with) a #id
                if ($query =~ / \G \# ([\w\-]+) /cgx) {
                    $specificity += 100;
                    push( @args, id => $1 );
                }

                # and/or a .class
                if ($query =~ / \G \. ([\w\-]+) /cgx) {
                   $specificity += 10;
                   push( @args, class => qr/ (^|\s+) $1 ($|\s+) /x );
                }

                # and/or none or more [ ] attribute specs
                if ($query =~ / \G \[ (.*?) \] /cgx) {
                    my $attribute = $1;
                    $specificity += 10;

                    #if we have an operator
                    if ($attribute =~ m/(.*?)\s*([\|\~]?=)\s*(.*)/) {
                        my ($name,$attribute_op,$value) = ($1,$2,$3);

                        unless (defined($name) && length($name)) {
                             return $self->_report_error( $self->message( bad_spec => $name, $query ) );
                        }

                        warn "operator $attribute_op" if DEBUG;

                        if (defined $value) {
                            for ($value) {
                                s/^['"]//;
                                s/['"]$//;
                            }
                            if ($attribute_op eq '=') {
                                push( @args, $name => $value);
                            }
                            elsif ($attribute_op eq '|=') {
                                push(@args, $name => qr/\b${value}-?/)
                            }
                            elsif ($attribute_op eq '~=') {
                                push(@args, $name => qr/\b${value}\b/)
                            }
                            else {
                                return $self->_report_error( $self->message( bad_spec => $attribute_op, $query ) );
                            }
                        }
                        else {
                            return $self->_report_error( $self->message( bad_spec => $attribute_op, $query ) );
                        }
                    }
                    else {
                        unless (defined($attribute) && length($attribute)) {
                          return $self->_report_error( $self->message( bad_spec => $attribute, $query ) );
                        }

                        # add a regex to match anything (or nothing)
                        push( @args, $attribute => qr/.*/ );
                    }
                }
                # and/or one or more pseudo-classes
                if ($query =~ / \G : :? ([\w\-]+) /cgx) {
                    my $pseudoclass = $1;
                    $specificity += 10;

                    if ($pseudoclass eq 'first-child') {
                        push( @args, sub { ! grep { ref $_ } $_[0]->left() } );
                    } elsif ($pseudoclass eq 'last-child') {
                        push( @args, sub { ! grep { ref $_ } $_[0]->right() } );
                    } else {
                        warn "Pseudoclass :$pseudoclass not supported";
                        next;
                    }
                }

                # keep going until this particular expression is fully processed
                last unless scalar(@args) > $work;
            }

            # we must have something in @args by now or we didn't find any
            # valid query specification this time around
            last SEQUENCE unless @args;

            $self->debug(
                'Parsed ', substr($query, $pos, pos($query) - $pos),
                ' into args [', join(', ', @args), ']'
            ) if DEBUG;

            # we want to skip certain hack sequences like '* html'
            if ($hack_sequence == 2) {
              @elements = []; # clear out our stored elements to match behaviour of modern browsers
            }
            # we're just looking for any descendent
            elsif( !$relationship ) {
              if ($self->{match_self}) {
                # if we are re-querying, be sure to match ourselves not just descendents
                @elements = map { $_->look_down(@args) } @elements;
              } else {
                # look_down() will match self in addition to descendents,
                # so we explicitly disallow matches on self as we iterate
                # thru the list.  The other cases below already exclude self.
                # https://rt.cpan.org/Public/Bug/Display.html?id=58918
                my @accumulator;
                foreach my $e (@elements) {
                  if ($e->root() == $e) {
                    push(@accumulator, $e->look_down(@args));
                  }
                  else {
                    push(@accumulator, grep { $_ != $e } $e->look_down(@args));
                  }
                }
                @elements = @accumulator;
              }
            }
            # immediate child selector
            elsif( $relationship eq '>' ) {
              @elements = map {
                $_->look_down(
                  @args,
                  sub {
                    my $tag = shift;
                    my $root = $_;

                    return $tag->depth == $root->depth + 1;
                  }
                )
              } @elements;
            }
            # immediate sibling selector
            elsif( $relationship eq '+' ) {
              @elements = map {
                $_->parent->look_down(
                  @args,
                  sub {
                    my $tag = shift;
                    my $root = $_;
                    my @prev_sibling = $tag->left;
                    # get prev next non-text sibling
                    foreach my $sibling (reverse @prev_sibling) {
                      next unless ref $sibling;
                      return $sibling == $root;
                    }
                  }
                )
              } @elements;
            }
            # grandchild selector
            elsif( $relationship eq '*' ) {
              @elements = map {
                $_->look_down(
                  @args,
                  sub {
                    my $tag = shift;
                    my $root = $_;

                    return $tag->depth > $root->depth + 1;
                  }
                )
              } @elements;
            }

            # so we can check we've done something
            $comops++;

            # dedup the results we've gotten
            @elements = $self->_dedup(\@elements);

            map { warn $_->as_HTML } @elements if DEBUG;
        }

        if ($comops) {
            $self->debug(
                'Added', scalar(@elements), ' elements to results'
            ) if DEBUG;

            my $selector = substr ($query,$startpos, $pos - $startpos);
            $self->_add_specificity($selector,$specificity);

            #add in the recent pass
            push(@result,@elements);

            # dedup the results across the result sets, necessary for comma based selectors
            @result = $self->_dedup(\@result);

            # sort the result set...
            @result = sort _by_address @result;

            # update op counter for complete query to include ops performed
            # in this fragment
            $ops += $comops;
        }
        else {
            # looks like we got an empty comma section, e.g. : ",x, ,y,"
            # so we'll ignore it
        }

        last COMMA unless $query =~ / \G \s*,\s* /cgsx;
    }

    # check for any trailing text in the query that we couldn't parse
    if ($query =~ / \G (.+?) \s* $ /cgsx) {
        return $self->_report_error( $self->message( bad_spec => $1, $query ) );
    }

    # check that we performed at least one query operation
    unless ($ops) {
        return $self->_report_error( $self->message( bad_query => $query ) ); 
    }

    return wantarray ? @result : $self->_new_match_self(@result);
}

# return elements stored from last query
sub get_elements {
  my $self = shift;

  return wantarray ? @{$self->{elements}} : $self->{elements};
}

###########################################################################################################
# from CSS spec at http://www.w3.org/TR/CSS21/cascade.html#specificity
###########################################################################################################
# A selector's specificity is calculated as follows:
#      
#     * count the number of ID attributes in the selector (= a)
#     * count the number of other attributes and pseudo-classes in the selector (= b)
#     * count the number of element names in the selector (= c)
#     * ignore pseudo-elements.
#
# Concatenating the three numbers a-b-c (in a number system with a large base) gives the specificity.
#
# Example(s):
#                                                                                    
# Some examples:
#
# *             {}  /* a=0 b=0 c=0 -> specificity =   0 */
# LI            {}  /* a=0 b=0 c=1 -> specificity =   1 */
# UL LI         {}  /* a=0 b=0 c=2 -> specificity =   2 */
# UL OL+LI      {}  /* a=0 b=0 c=3 -> specificity =   3 */
# H1 + *[REL=up]{}  /* a=0 b=1 c=1 -> specificity =  11 */
# UL OL LI.red  {}  /* a=0 b=1 c=3 -> specificity =  13 */
# LI.red.level  {}  /* a=0 b=2 c=1 -> specificity =  21 */
# #x34y         {}  /* a=1 b=0 c=0 -> specificity = 100 */
###########################################################################################################

# calculate and return the specificity for the provided selector
sub get_specificity {
  my ($self,$selector) = @_;

  unless (exists $self->{specificity}->{$selector}) {

   # if the invoking tree happened to be large this could get expensive real fast
   # instead load up an empty instance and query that.
   local $self->{elements} = [];
   $self->query($selector);
  }

  return $self->{specificity}->{$selector};
}

sub suppress_errors {
    my ($self, $setting) = @_;

    if (defined($setting)) {
      $self->{suppress_errors} = $setting;
    }

    return $self->{suppress_errors};
}

sub get_error {
    my ($self) = @_;

    return $self->{error};
}

sub list {
    # return list of items or return unblessed list ref of items
    return wantarray ? @{ $_[0] } : [ @{ $_[0] } ];
}

sub size {
  my $self = shift;
  return scalar @{$self->get_elements};
}

sub first {
    my $self = shift;

    return @{$self->get_elements} ? $self->get_elements->[0] : $self->error_msg('is_empty');
}

sub last {
    my $self = shift;

    return @{$self->get_elements} ? $self->get_elements->[-1] : $self->error_msg('is_empty');
}

####################################################################
#
# Everything below here is a private method subject to change
#
####################################################################

sub _add_specificity {
  my ($self, $selector, $specificity) = @_;

  $self->{specificity}->{$selector} = $specificity;

  return();
}

sub _report_error {
    my ($self, $message) = @_;

    if ($self->suppress_errors()) {
      if (defined($message)) { 
        $self->{error} = $message;
      }
      return undef;
    }
    else {
      $self->error($message);   # this will DIE
    }
}

    # this Just Works[tm] because first arg is HTML::Element object
sub _export_query_to_element {
    class(ELEMENT)->load->method(
        query => \&Query,
    );
}

# remove duplicate elements in the case where elements are nested between multiple matching elements
sub _dedup {
  my ($self,$elements) = @_;

  my %seen = ();
  my @unique = ();

  foreach my $item (@{$elements}) {
    if (!exists($seen{$item})) {
      push(@unique, $item);
    }

    $seen{$item}++;
  }

  return @unique;
}

# utility method to assist in sorting of query return sets
sub _by_address
{
  my $self = shift;

  my @a = split /\./, $a->address();
  my @b = split /\./, $b->address();

  my $max = (scalar @a > scalar @b) ? scalar @a : scalar @b;

  for (my $index=0; $index<$max; $index++) {

    if (!defined($a[$index]) && !defined($b[$index])) {
      return 0;
    }
    elsif (!defined($a[$index])) {
      return -1;
    }
    elsif(!defined($b[$index])) {
      return 1;
    }

    if ($a[$index] == $b[$index]) {
      next; #move to the next
    }
    else {
      return $a[$index] <=> $b[$index];
    }
  }
}

# instantiate an instance with match_self turned on, for use with
# follow-up queries, so they match the top-most elements.
sub _new_match_self {
  my $self = shift;

  my $result = $self->new(@_);

  $result->{match_self} = 1;
  return $result;
}

sub AUTOLOAD {
    my $self     = shift;
    my ($method) = ($AUTOLOAD =~ /([^:]+)$/ );
    return if $method eq 'DESTROY';

    # we allow Perl to catch any unknown methods that the user might
    # try to call against the HTML::Element objects in the query
    my @results =
        map  { $_->$method(@_) }
        @{$self->get_elements};

    return wantarray ? @results : \@results;
}

1;

=head1 NAME

HTML::Query - jQuery-like selection queries for HTML::Element

=head1 SYNOPSIS

Creating an C<HTML::Query> object using the L<Query()|Query> constructor
subroutine:

    use HTML::Query 'Query';

    # using named parameters
    $q = Query( text  => $text  );          # HTML text
    $q = Query( file  => $file  );          # HTML file
    $q = Query( tree  => $tree  );          # HTML::Element object
    $q = Query( query => $query );          # HTML::Query object
    $q = Query(
        text  => $text1,                    # or any combination
        text  => $text2,                    # of the above
        file  => $file1,
        file  => $file2,
        tree  => $tree,
        query => $query,
    );

    # passing elements as positional arguments
    $q = Query( $tree );                    # HTML::Element object(s)
    $q = Query( $tree1, $tree2, $tree3, ... );

    # or from one or more existing queries
    $q = Query( $query1 );                  # HTML::Query object(s)
    $q = Query( $query1, $query2, $query3, ... );

    # or a mixture
    $q = Query( $tree1, $query1, $tree2, $query2 );

    # the final argument (in all cases) can be a selector
    my $spec = 'ul.menu li a';              # <ul class="menu">..<li>..<a>

    $q = Query( $tree, $spec );
    $q = Query( $query, $spec );
    $q = Query( $tree1, $tree2, $query1, $query2, $spec );
    $q = Query( text  => $text,  $spec );
    $q = Query( file  => $file,  $spec );
    $q = Query( tree  => $tree,  $spec );
    $q = Query( query => $query, $spec );
    $q = Query(
        text => $text,
        file => $file,
        # ...etc...
        $spec
    );

Or using the OO L<new()> constructor method (which the L<Query()|Query>
subroutine maps onto):

    use HTML::Query;

    $q = HTML::Query->new(
        # accepts the same arguments as Query()
    )

Or by monkey-patching a L<query()> method into L<HTML::Element|HTML::Element>.

    use HTML::Query 'query';                # note lower case 'q'
    use HTML::TreeBuilder;

    # build a tree
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);

    # call the query() method on any element
    my $query = $tree->query($spec);

Once you have a query, you can start selecting elements:

    @r = $q->query('a')->get_elements();            # all <a>...</a> elements
    @r = $q->query('a#menu')->get_elements();       # all <a> with "menu" id
    @r = $q->query('#menu')->get_elements();        # all elements with "menu" id
    @r = $q->query('a.menu')->get_elements();       # all <a> with "menu" class
    @r = $q->query('.menu')->get_elements();        # all elements with "menu" class
    @r = $q->query('a[href]')->get_elements();      # all <a> with 'href' attr
    @r = $q->query('a[href=foo]')->get_elements();  # all <a> with 'href="foo"' attr

    # you can specify elements within elements...
    @r = $q->query('ul.menu li a')->get_elements(); # <ul class="menu">...<li>...<a>

    # and use commas to delimit multiple path specs for different elements
    @r = $q->query('table tr td a, form input[type=submit]')->get_elements();

    # query() in scalar context returns a new query
    $r = $q->query('table')->get_elements();;       # find all tables
    $s = $r->query('tr')->get_elements();           # find all rows in all those tables
    $t = $s->query('td')->get_elements();           # and all cells in those rows...

Inspecting query elements:

    # get number of elements in query
    my $size  = $q->size

    # get first/last element in query
    my $first = $q->first;
    my $last  = $q->last;

    # convert query to list or list ref of HTML::Element objects
    my $list = $q->list;            # list ref in scalar context
    my @list = $q->list;            # list in list context

All other methods are mapped onto the L<HTML::Element|HTML::Element> objects
in the query:

    print $query->as_trimmed_text;  # print trimmed text for each element
    print $query->as_HTML;          # print each element as HTML
    $query->delete;                 # call delete() on each element

=head1 DESCRIPTION

The C<HTML::Query> module is an add-on for the L<HTML::Tree|HTML::Tree> module
set. It provides a simple way to select one or more elements from a tree using
a query syntax inspired by jQuery. This selector syntax will be reassuringly
familiar to anyone who has ever written a CSS selector.

C<HTML::Query> is not an attempt to provide a complete (or even near-complete)
implementation of jQuery in Perl (see Ingy's L<pQuery|pQuery> module for a
more ambitious attempt at that). Rather, it borrows some of the tried and
tested selector syntax from jQuery (and CSS) that can easily be mapped onto
the C<look_down()> method provided by the L<HTML::Element|HTML::Element>
module.

=head2 Creating a Query

The easiest way to create a query is using the exportable L<Query()|Query>
subroutine.

    use HTML::Query 'Query';        # note capital 'Q'

It accepts a C<text> or C<file> named parameter and will create an
C<HTML::Query> object from the HTML source text or file, respectively.

    my $query = Query( text => $text );
    my $query = Query( file => $file );

This delegates to L<HTML::TreeBuilder|HTML::TreeBuilder> to parse the
HTML into a tree of L<HTML::Element|HTML::Element> objects.  The root
element returned is then wrapped in an C<HTML::Query> object.

If you already have one or more L<HTML::Element|HTML::Element> objects that
you want to query then you can pass them to the L<Query()|Query> subroutine as
arguments. For example, you can explicitly use
L<HTML::TreeBuilder|HTML::TreeBuilder> to parse an HTML document into a tree:

    use HTML::TreeBuilder;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);

And then create an C<HTML::Query> object for the tree either using an
explicit C<tree> named parameter:

    my $query = Query( tree => $tree );

Or implicitly using positional arguments.

    my $query = Query( $tree );

If you want to query across multiple elements, then pass each one as a
positional argument.

    my $query = Query( $tree1, $tree2, $tree3 );

You can also create a new query from one or more existing queries,

    my $query = Query( query => $query );   # named parameter
    my $query = Query( $query1, $query2 );  # positional arguments.

You can mix and match these different parameters and positional arguments
to create a query across several different sources.

    $q = Query(
        text  => $text1,
        text  => $text2,
        file  => $file1,
        file  => $file2,
        tree  => $tree,
        query => $query,
    );

The L<Query()|Query> subroutine is a simple wrapper around the L<new()>
constructor method. You can instantiate your objects manually if you prefer.
The L<new()> method accepts the same arguments as for the L<Query()|Query>
subroutine (in fact, the L<Query()|Query> subroutine simply forwards all
arguments to the L<new()> method).

    use HTML::Query;

    my $query = HTML::Query->new(
        # same argument format as for Query()
    );

A final way to use C<HTML::Query> is to have it add a L<query()|query> method
to L<HTML::Element|HTML::Element>.  The C<query> import hook (all lower
case) can be specified to make this so.

    use HTML::Query 'query';                # note lower case 'q'
    use HTML::TreeBuilder;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);

    # now all HTML::Elements have a query() method
    my @items = $tree->query('ul li')->get_elements();  # find all list items

This approach, often referred to as I<monkey-patching>, should be used
carefully and sparingly. It involves a violation of
L<HTML::Element|HTML::Element>'s namespace that could have unpredictable
results with a future version of the module (e.g. one which defines its own
C<query()> method that does something different). Treat it as something that
is great to get a quick job done right now, but probably not something to be
used in production code without careful consideration of the implications.

=head2 Selecting Elements

Having created an C<HTML::Query> object by one of the methods outlined above,
you can now fetch descendant elements in the tree using a simple query syntax.
For example, to fetch all the C<< E<lt>aE<gt> >> elements in the tree, you can
write:

    @links = $query->query('a')->get_elements();

Or, if you want the elements that have a specific C<class> attribute defined
with a value of, say C<menu>, you can write:

    @links = $query->query('a.menu')->get_elements();

More generally, you can look for the existence of any attribute and optionally
provide a specific value for it.

    @links = $query->query('a[href]')->get_elements();            # any href attribute
    @links = $query->query('a[href=index.html]')->get_elements(); # specific value

You can also find an element (or elements) by specifying an id.

    @links = $query->query('#menu')->get_elements();         # any element with id="menu"
    @links = $query->query('ul#menu')->get_elements();       # ul element with id="menu"

You can provide multiple selection criteria to find elements within elements
within elements, and so on.  For example, to find all links in a menu,
you can write:

    # matches: <ul class="menu"> <li> <a>
    @links = $query->query('ul.menu li a')->get_elements();

You can separate different criteria using commas.  For example, to fetch all
table rows and C<span> elements with a C<foo> class:

    @elems = $query->('table tr, span.foo')->get_elements();

=head2 Query Results

When called in list context, as shown in the examples above, the L<query()>
method returns a list of L<HTML::Element|HTML::Element> objects matching the
search criteria. In scalar context, the L<query()> method returns a new
C<HTML::Query> object containing the L<HTML::Element|HTML::Element> objects
found. You can then call the L<query()> method against that object to further
refine the query. The L<query()> method applies the selection to all elements
stored in the query.

    my $tables = $query->query('table');             # query for tables
    my $rows   = $tables->query('tr');               # requery for all rows in those tables
    my $cells  = $rows->query('td')->get_elements(); # return back all the cells in those rows

=head2 Inspection Methods

The L<size()> method returns the number of elements in the query. The
L<first()> and L<last()> methods return the first and last items in the
query, respectively.

    if ($query->size) {
        print "from ", $query->first->as_trimmed_text, " to ", $query->last->as_trimmed_text;
    }

If you want to extract the L<HTML::Element|HTML::Element> objects from the
query you can call the L<list()> method. This returns a list of
L<HTML::Element|HTML::Element> objects in list context, or a reference to a
list in scalar context.

    @elems = $query->list;
    $elems = $query->list;

=head2 Element Methods

Any other methods are automatically applied to each element in the list. For
example, to call the C<as_trimmed_text()> method on all the
L<HTML::Element|HTML::Element> objects in the query, you can write:

    print $query->as_trimmed_text;

In list context, this method returns a list of the return values from
calling the method on each element.  In scalar context it returns a
reference to a list of return values.

    @text_blocks = $query->as_trimmed_text;
    $text_blocks = $query->as_trimmed_text;

See L<HTML::Element|HTML::Element> for further information on the methods it
provides.

=head1 QUERY SYNTAX

=head2 Basic Selectors

=head3 element

Matches all elements of a particular type.

    @elems = $query->query('table')->get_elements();     # <table>

=head3 #id

Matches all elements with a specific id attribute.

    @elems = $query->query('#menu')->get_elements()     # <ANY id="menu">

This can be combined with an element type:

    @elems = $query->query('ul#menu')->get_elements();  # <ul id="menu">

=head3 .class

Matches all elements with a specific class attribute.

    @elems = $query->query('.info')->get_elements();     # <ANY class="info">

This can be combined with an element type and/or element id:

    @elems = $query->query('p.info')->get_elements();     # <p class="info">
    @elems = $query->query('p#foo.info')->get_elements(); # <p id="foo" class="info">
    @elems = $query->query('#foo.info')->get_elements();  # <ANY id="foo" class="info">

The selectors listed above can be combined in a whitespace delimited
sequence to select down through a hierarchy of elements.  Consider the
following table:

    <table class="search">
      <tr class="result">
        <td class="value">WE WANT THIS ELEMENT</td>
      </tr>
      <tr class="result">
        <td class="value">AND THIS ONE</td>
      </tr>
      ...etc..
    </table>

To locate the cells that we're interested in, we can write:

    @elems = $query->query('table.search tr.result td.value')->get_elements();

=head2 Attribute Selectors

W3C CSS 2 specification defines new constructs through which to select
based on specific attributes within elements. See the following link for the spec:
L<http://www.w3.org/TR/css3-selectors/#attribute-selectors>

=head3 [attr]

Matches elements that have the specified attribute, including any where
the attribute has no value.

    @elems = $query->query('[href]')->get_elements();        # <ANY href="...">

This can be combined with any of the above selectors.  For example:

    @elems = $query->query('a[href]')->get_elements();       # <a href="...">
    @elems = $query->query('a.menu[href]')->get_elements();  # <a class="menu" href="...">

You can specify multiple attribute selectors.  Only those elements that
match I<all> of them will be selected.

    @elems = $query->query('a[href][rel]')->get_elements();  # <a href="..." rel="...">

=head3 [attr=value]

Matches elements that have an attribute set to a specific value.  The
value can be quoted in either single or double quotes, or left unquoted.

    @elems = $query->query('[href=index.html]')->get_elements();
    @elems = $query->query('[href="index.html"]')->get_elements();
    @elems = $query->query("[href='index.html']")->get_elements();

You can specify multiple attribute selectors.  Only those elements that
match I<all> of them will be selected.

    @elems = $query->query('a[href=index.html][rel=home]')->get_elements();

=head3 [attr|=value]

Matches any element X whose foo attribute has a hyphen-separated list of
values beginning (from the left) with bar. The value can be quoted in either
single or double quotes, or left unquoted.

    @elems = $query->query('[lang|=en]')->get_elements();
    @elems = $query->query('p[class|="example"]')->get_elements();
    @elems = $query->query("img[alt|='fig']")->get_elements();

You can specify multiple attribute selectors.  Only those elements that
match I<all> of them will be selected.

    @elems = $query->query('p[class|="external"][lang|="en"]')->get_elements();

=head3 [attr~=value]

Matches any element X whose foo attribute value is a list of space-separated
values, one of which is exactly equal to bar. The value can be quoted in either
single or double quotes, or left unquoted.

    @elems = $query->query('[lang~=en]')->get_elements();
    @elems = $query->query('p[class~="example"]')->get_elements();
    @elems = $query->query("img[alt~='fig']")->get_elements();

You can specify multiple attribute selectors.  Only those elements that
match I<all> of them will be selected.

    @elems = $query->query('p[class~="external"][lang~="en"]')->get_elements();

KNOWN BUG: you can't have a C<]> character in the attribute value because
it confuses the query parser.  Fixing this is TODO.

=head2 Universal Selector

W3C CSS 2 specification defines a new construct through which to select
any element within the document below a given hierarchy.

http://www.w3.org/TR/css3-selectors/#universal-selector

  @elems = $query->query('*')->get_elements();

=head2 Combinator Selectors

W3C CSS 2 specification defines new constructs through which to select
based on heirarchy with the DOM. See the following link for the spec:
L<http://www.w3.org/TR/css3-selectors/#combinators>

=head3 Immediate Descendents (children)

When you combine selectors with whitespace elements are selected if
they are descended from the parent in some way. But if you just want
to select the children (and not the grandchildren, great-grandchildren,
etc) then you can combine the selectors with the C<< > >> character.

 @elems = $query->query('a > img')->get_elements();

=head3 Non-Immediate Descendents

If you just want any descendents that aren't children then you can combine
selectors with the C<*> character.

 @elems = $query->query('div * a')->get_elements();

=head3 Immediate Siblings

If you want to use a sibling relationship then you can can join selectors
with the C<+> character.

 @elems = $query->query('img + span')->get_elements();

=head2 Pseudo-classes

W3C CSS 2 and CSS 3 specifications define new concepts of pseudo-classes to 
permit formatting based on information that lies outside the document tree. 
See the following link for the most recent spec:
L<http://www.w3.org/TR/css3-selectors/#pseudo-classes>

HTML::Query currently has limited support for CSS 2, and no support for CSS 3.

Patches are *highly* encouraged to help add support here.

=head3 -child pseudo-classes

If you want to return child elements within a certain position then -child
pseudo-classes (:first-child, :last-child) are what you're looking for.

 @elems = $query->query('table td:first-child')->get_elements;

=head3 Link pseudo-classes: :link and :visited

Unsupported.

The :link pseudo-class is to be implemented, currently unsupported.

It is not possible to locate :visited outside of a browser context due to it's
dynamic nature.

=head3 Dynamic pseudo-classes

Unsupported.

It is not possible to locate these classes(:hover, :active, :focus) outside
of a browser context due to their dynamic nature.

=head3 Language pseudo-class

Unsupported.

Functionality for the :lang pseudo-class is largely replicated by using an 
attribute selector for lang combined with a universal selector query.

If this is insufficient I'd love to see a patch adding support for it.

=head3 Other pseudo-classes

W3C CSS 3 added a number of new behaviors that need support. At
this time there is no support for them, but we should work on adding support.

Patches are very welcome.

=head2 Pseudo-elements

W3C CSS 2 and CSS 3 specification defines new concepts of pseudo-elements to
permit formatting based on information that lies outside the document tree.
See the following link for the most recent spec:
L<http://www.w3.org/TR/css3-selectors/#pseudo-elements>

At this time there is no support for pseudo-elements, but we are working
on adding support.

Patches are very welcome.

=head2 Combining Selectors

You can combine basic and hierarchical selectors into a single query
by separating each part with a comma.  The query will select all matching
elements for each of the comma-delimited selectors.  For example, to
find all C<a>, C<b> and C<i> elements in a tree:

    @elems = $query->query('a, b, i')->get_elements();

Each of these selectors can be arbitrarily complex.

    @elems = $query->query(
        'table.search[width=100%] tr.result[valign=top] td.value,
         form.search input[type=submit],
         a[href=index.html]'
    )->get_elements();

=head1 EXPORT HOOKS

=head2 Query

The C<Query()> constructor subroutine (note the capital letter) can be
exported as a convenient way to create C<HTML::Query> objects. It simply
forwards all arguments to the L<new()> constructor method.

    use HTML::Query 'Query';

    my $query = Query( file => $file, 'ul.menu li a' );

=head2 query

The C<query()> export hook can be called to monkey-patch a L<query()> method
into the L<HTML::Element|HTML::Element> module.

This is considered questionable behaviour in polite society which regards it
as a violation of the inner sanctity of the L<HTML::Element|HTML::Element>.

But if you're the kind of person that doesn't mind a bit of occasional
namespace abuse for the sake of getting the job done, then go right ahead.
Just don't blame me if it all blows up later.

    use HTML::Query 'query';                # note lower case 'q'
    use HTML::TreeBuilder;

    # build a tree
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);

    # call the query() method on any element
    my $query = $tree->query('ul li a');

=head1 METHODS

The C<HTML::Query> object is a subclass of L<Badger::Base|Badger::Base> and
inherits all of its method.

=head2 new(@elements,$selector)

This constructor method is used to create a new C<HTML::Query> object. It
expects a list of any number (including zero) of
L<HTML::Element|HTML::Element> or C<HTML::Query> objects.

    # single HTML::Element object
    my $query = HTML::Query->new($elem);

    # multiple element object
    my $query = HTML::Query->new($elem1, $elem2, $elem3, ...);

    # copy elements from an existing query
    my $query = HTML::Query->new($another_query);

    # copy elements from several queries
    my $query = HTML::Query->new($query1, $query2, $query3);

    # or a mixture
    my $query = HTML::Query->new($elem1, $query1, $elem2, $query3);

You can also use named parameters to specify an alternate source for a
element.

    $query = HTML::Query->new( file => $file );
    $query = HTML::Query->new( text => $text );

In this case, the L<HTML::TreeBuilder|HTML::TreeBuilder> module is used to
parse the source file or text into a tree of L<HTML::Element|HTML::Element>
objects.

For the sake of completeness, you can also specify element trees and queries
using named parameters:

    $query = HTML::Query->new( tree  => $tree );
    $query = HTML::Query->new( query => $query );

You can freely mix and match elements, queries and named sources.  The
query will be constructed as an aggregate across them all.

    $q = HTML::Query->new(
        text  => $text1,
        text  => $text2,
        file  => $file1,
        file  => $file2,
        tree  => $tree,
        query => $query1,
    );

The final, optional argument can be a selector specification.  This is
immediately passed to the L<query()> method which will return a new query
with only those elements selected.

    my $spec = 'ul.menu li a';              # <ul class="menu">..<li>..<a>

    my $query = HTML::Query->new( $tree, $spec );
    my $query = HTML::Query->new( text => $text, $spec );
    my $query = HTML::Query->new(
        text => $text,
        file => $file,
        $spec
    );

The list of arguments can also be passed by reference to a list.

    my $query = HTML::Query->new(\@args);

=head2 query($spec)

This method locates the descendant elements identified by the C<$spec>
argument for each element in the query. It then interally stores the results 
for requerying or return. See get_elements().

    my $query = HTML::Query->new(\@args);
    my $results = $query->query($spec);

See L<"QUERY SYNTAX"> for the permitted syntax of the C<$spec> argument.

=head2 get_elements()

This method returns the stored results from a query. In list context it returns a list of
matching L<HTML::Element|HTML::Element> objects. In scalar context it returns a reference to
the results array.

    my $query = HTML::Query->new(\@args);
    my $results = $query->query($spec);

    my @elements  = $results->query($spec)->get_elements();
    my $elements  = $results->query($spec)->get_elements();

=head2 get_specificity()

Calculate the specificity for any given passed selector, a critical factor in determining how best to apply the cascade

A selector's specificity is calculated as follows:

* count the number of ID attributes in the selector (= a)
* count the number of other attributes and pseudo-classes in the selector (= b)
* count the number of element names in the selector (= c)
* ignore pseudo-elements.

The specificity is based only on the form of the selector. In particular, a selector of the form "[id=p33]" is counted
as an attribute selector (a=0, b=0, c=1, d=0), even if the id attribute is defined as an "ID" in the source document's DTD.

See the following spec for additional details:
L<http://www.w3.org/TR/CSS21/cascade.html#specificity>

=head2 size()

Returns the number of elements in the query.

=head2 first()

Returns the first element in the query.

    my $elem = $query->first;

If the query is empty then an exception will be thrown. If you would rather
have an undefined value returned then you can use the C<try> method inherited
from L<Badger::Base|Badger::Base>. This effectively wraps the call to
C<first()> in an C<eval> block to catch any exceptions thrown.

    my $elem = $query->try('first') || warn "no first element\n";

=head2 last()

Similar to L<first()>, but returning the last element in the query.

    my $elem = $query->last;

=head2 list()

Returns a list of the L<HTML::Element|HTML::Element> object in the query in
list context, or a reference to a list in scalar context.

    my @elems = $query->list;
    my $elems = $query->list;

=head2 AUTOLOAD

The C<AUTOLOAD> method maps any other method calls to the
L<HTML::Element|HTML::Element> objects in the list. When called in list
context it returns a list of the values returned from calling the method on
each element. In scalar context it returns a reference to a list of return
values.

    my @text_blocks = $query->as_trimmed_text;
    my $text_blocks = $query->as_trimmed_text;

=head1 KNOWN BUGS

=head2 Attribute Values

It is not possible to use C<]> in an attribute value.  This is due to a
limitation in the parser which will be fixed RSN.

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 MAINTAINER

Kevin Kamel <kamelkev@mailermailer.com>

=head1 CONTRIBUTORS

Vivek Khera <vivek@khera.org>
Michael Peters <wonko@cpan.org>
David Gray <cpan@doesntsuck.com>

=head1 COPYRIGHT

Copyright (C) 2010 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::Tree|HTML::Tree>, L<HTML::Element|HTML::Element>,
L<HTML::TreeBuilder|HTML::TreeBuilder>, L<pQuery|pQuery>, L<http://jQuery.com/>

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
