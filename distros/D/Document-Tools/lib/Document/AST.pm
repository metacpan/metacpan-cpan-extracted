package Document::AST;

sub new {
    my $class = shift;
    my $self = bless { @_ }, ref($class) || $class;
}

sub init {
    my $self = shift;
    die "You need to override Document::AST::insert";
    # $self->{output} = [];
}

sub content {
    my $self = shift;
    return $self->{output};
}

sub insert {
    my $self = shift;
    my $ast = shift;
    die "You need to override Document::AST::insert";
    # $self->{output} .= $ast->{output};
}

sub begin_node {
    my $self = shift;
    my $tag = shift;
    die "You need to override Document::AST::begin_node";
    # $self->{output} .= "+$tag\n";
}

sub end_node {
    my $self = shift;
    my $tag = shift;
    die "You need to override Document::AST::end_node";
    # $self->{output} .= "-$tag\n";
}

sub text_node {
    my $self = shift;
    my $text = shift;
    die;
    # $self->{output} .= " $text\n";
}

1;
