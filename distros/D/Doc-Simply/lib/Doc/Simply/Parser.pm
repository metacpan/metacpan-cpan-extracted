package Doc::Simply::Parser;

use Any::Moose;
use Doc::Simply::Carp;

use Doc::Simply::Document;

sub node {
    my $self = shift;
    return Doc::Simply::Parser::Node->new(@_);
}

sub parse {
    my $self = shift;
    my $blocks = shift;

    my $root_node;
    my $document = Doc::Simply::Document->new(root => ($root_node = $self->node(tag => 'root')));

    my (%state, $previous_node, $node);

    $previous_node = $root_node;

    for my $block (@$blocks) {

        my @content = @$block;
        my $content_node;

        for my $line (@content) {
            if ($line =~ m/^[@|=](\w+)(?:\s+(.*))?$/) {
                my ($tag, $content) = ($1, $2);
                $content .= "\n";
                $node = $self->node(tag => $tag, content => $content);
                if ($node->is_stop) {
                    undef $content_node;
                    next; # Nothing to do
                }
                elsif ($node->is_tag->{meta}) {
                }

                $previous_node->add_node($node);
                $content_node = $previous_node = $node;
            }
            elsif ($content_node) {
                my $content = $line;
                $content .= "\n";
                $content_node->add_node($self->node(tag => "body", content => $content));
            }
        }
    }

    return $document;
}

package Doc::Simply::Parser::Node;

use Any::Moose;
use Doc::Simply::Carp;

use base qw/Tree::DAG_Node/;

has tag => qw/is ro required 1 isa Str/;
has content => qw/reader _content isa Str/, default => "";
has tag_meta => qw/is ro lazy_build 1 isa Doc::Simply::Parser::Node::Meta/, handles => [qw/is_inline is_block is_stop is_tag level/];
sub _build_tag_meta {
    my $self = shift;
    return Doc::Simply::Parser::Node::Meta->for($self->tag);
}

sub BUILD {
    my $self = shift;
    $self->_init;
    $self->name( $self->tag );
}

sub _find_enclosing_node {
    my $self = shift;
    my $node = shift;

    return $self->mother->_find_enclosing_node($node) if $self->is_inline || $self->level >= $node->level;
    return $self;
}

sub add_node {
    my $self = shift;
    my $node = shift;

    my $parent_node = $self->_find_enclosing_node($node);
    $parent_node->add_daughter($node);
    return $parent_node;
}

sub content {
    my $self = shift;
    my $content = $self->_content;
    $content =~ s/\s*$// if $self->tag_meta->is->{heading};
    return $content;
}

sub content_of {
    my $self = shift;
    return join " ", $self->tag, $self->content;
}

sub content_from {
    my $self = shift;
    my $content = "";

    $self->walk_down({ callback => sub {
        my $node = shift;
        my $_content = $node->content_of;
        chomp $_content;
        $content .= "$_content\n";
        return 1;
    } });

    return $content;
}

1;

package Doc::Simply::Parser::Node::Meta;

use Any::Moose;
use Doc::Simply::Carp;

has tag => qw/is ro required 1 isa Str/;
has level => qw/is ro required 1 isa Int default 999/;
has is => qw/is ro required 1 isa HashRef/, default => sub { {} };

sub describe($$);
my %META;

for my $is (qw/inline block stop in_flow tag/) {
    no strict 'refs';
    my $method = "is_$is";
    *$method = sub {
        return shift->is->{$is};
    };
}

describe root => {
    level => 0,
    is => {
        block => 1,
    },
};

describe head1 => {
    level => 1,
    is => {
        heading => 1,
        block => 1,
    },
};

describe head2 => {
    level => 2,
    is => {
        heading => 1,
        block => 1,
    },
};

describe head3 => {
    level => 3,
    is => {
        heading => 1,
        block => 1,
    },
};

describe head4 => {
    level => 4,
    is => {
        heading => 1,
        block => 1,
    },
};

describe body => {
    is => {
        inline => 1,
    },
};

describe meta => {
};

describe stop => {
    is => {
        stop => 1,
    },
};

describe cut => {
    is => {
        stop => 1,
    },
};


sub describe($$) {
    my $tag = shift;
    my $given = shift || {};
    croak "Tag \"$tag\" already exists" if $META{$tag};
    return $META{$tag} = __PACKAGE__->new(tag => $tag, %$given);
}

sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->is->{tag}->{$self->tag} = 1;
    $self->is->{in_flow} = $self->is_inline || $self->is_block;
}

sub for {
    my $class = shift;
    my $tag = shift;

    croak "Wasn't given tag" unless $tag;

    my $meta = $META{$tag} or croak "No meta exists for tag \"$tag\"";

    return $meta;
}

1;
