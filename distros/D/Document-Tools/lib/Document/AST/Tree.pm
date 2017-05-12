package Document::AST::Tree;
use base 'Document::AST';

sub init {
    my $self = shift;
    $self->{output} = [];
}

sub insert {
    push @{$_[0]{output}[-1][-1]}, @{$_[1]->{output}};
}

sub begin_node {
    push @{$_[0]->{output}}, [$_[1], []];
}

sub text_node {
    push @{$_[0]->{output}}, $_[1];
}

sub end_node {
}

1;
