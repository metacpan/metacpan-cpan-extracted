package Language::AttributeGrammar::Engine;

=head1 NAME

Language::AttributeGrammar::Engine - Attribute grammar combinators

=head1 DESCRIPTION

=over

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use Carp::Clan '^Language::AttributeGrammar';
use Perl6::Attributes;
use Language::AttributeGrammar::Thunk;

sub new {
    my ($class) = @_;
    bless {
        cases => {},
    } => ref $class || $class;
}

=item * new

Create a new engine.  No initialization is needed.

=cut

sub add_case {
    my ($self, $case) = @_;
    $.cases{$case}{visit} ||= [];
}

=item * $engine->add_case($case_name)

Make sure a visitor is installed for class $case_name.  Usually this is not necessary.
You need this only when you want a visitor installed for a class that has no attributes
defined.

=cut

sub add_visitor {
    my ($self, $case, $visitor) = @_;
    push @{$.cases{$case}{visit}}, $visitor;
}

=item * $engine->add_visitor($case, $visitor)

Add an action to perform when the an object of class $case is visited.

    $engine->add_visitor(Foo => sub { ... });

=cut

sub make_visitor {
    my ($self, $visit) = @_;
    
    for my $case (keys %.cases) {
        $.cases{$case}{visit_all} = sub {
            $_->(@_) for @{$.cases{$case}{visit}};
        };
        next if $case eq 'ROOT';
        no strict 'refs';
        *{"$case\::$visit"} = $.cases{$case}{visit_all};
    }
}

=item * $engine->make_visitor($method_name)

Install a visitor named $method_name in all the defined cases.  This actually
modifies the packages, so it's probably a good idea to choose a non-conflicting
method name like 'MODULENAME_visit0001'.

=cut

sub annotate {
    my ($self, $visit, $top, $topattr) = @_;
    my @nodeq;
    
    my $attrs = Language::AttributeGrammar::Engine::Vivifier->new(sub {
                    push @nodeq, $_[0];
                    Language::AttributeGrammar::Engine::Vivifier->new(sub {
                        Language::AttributeGrammar::Thunk->new;
                    });
                });

    if ($topattr) {
        for my $key (keys %$topattr) {
            $attrs->get($top)->get($key)->set(sub { $topattr->{$key} });
        }
    }

    $attrs->get($top);   # seed the queue
                
    if ($.cases{ROOT}{visit_all}) {
        $.cases{ROOT}{visit_all}->($top, $attrs);
    }

    while (my $node = shift @nodeq) {
        if ($node->can($visit)) {
            $node->$visit($attrs);
        }
        else {
            croak "No case defined: " . ref($node);
        }
    }

    return $attrs;
}

=item * $engine->annotate($method_name, $tree, $top_attrs)

Run the visitors on $tree, after having installed a visitor using
C<make_visitor> in the method name $method_name.  Set attributes $top_attrs (a
hash) on the top node of the tree.  Returns a structure where you can query
any attribute of any visited node using:

    my $attrs = $engine($method_name, $tree, {});
    my $attr_value = $attrs->get($node)->get('attr')->get;

Using the annotated tree directly uses a bunch of memory, since it has to hold
every attribute pair.  If you are only interested in one attribute of the top node,
use:

=cut

sub evaluate {
    my ($self, $visit, $top, $attr, $topattr) = @_;
    my $attrs = $self->annotate($visit, $top, $topattr);
    my $head = $attrs->get($top)->get($attr);
    undef $attrs;   # allow intermediate values to go away
    $head->get($attr, 'top level');
}

=item * $engine->evaluate($method_name, $tree, $attr, $top_attrs)

Does the same as annotate, but returns the value of $attr on the root node of
the tree all in one pass.  Doing this in one pass allows the engine to clean up
intermediate values when they are not needed anymore.  This is the preferred
form of usage.

=back

=cut

package Language::AttributeGrammar::Engine::Vivifier;

use overload ();

sub new {
    my ($class, $vivi) = @_;
    bless {
        hash => {},
        vivi => $vivi,
    } => ref $class || $class;
}

sub get {
    my ($self, $key) = @_;
    my $kval = overload::StrVal($key);
    unless (exists $.hash{$kval}) {
		my $value = $.vivi->($key);
		$.hash{$kval} = { key => $key, value => $value };
		$value;
    }
    else {
        $.hash{$kval}{value}
    }
}

sub put {
    my ($self, $key, $value) = @_;
    $.hash{overload::StrVal($key)} = { key => $key, value => $value };
	$value;
}

sub keys {
    my ($self) = @_;
    keys %.hash;
}

1;
