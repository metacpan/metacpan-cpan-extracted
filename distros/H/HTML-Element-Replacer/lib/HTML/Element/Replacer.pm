package HTML::Element::Replacer;
# ABSTRACT: Simplify the HTML::Element clone() - push_content() ritual 
use HTML::TreeBuilder;
use HTML::Element::Library;

use Moose;

has 'tree' => ( is => 'rw', required => 1 ) ;
has 'elem' => ( is => 'rw', lazy => 1, default => sub { $_[0]->tree->look_down(@{$_[0]->look_down}) } ) ;
has 'elem_clone' => ( is => 'rw' ) ;
has 'look_down'   => ( is => 'rw', required => 1 ) ;
has 'replacements' => ( is => 'rw', isa => 'ArrayRef') ;

our $VERSION = '0.08';

sub BUILD {
    my($self)=@_;
    $self->replacements([]);
}

sub DESTROY {
    my($self)=@_;
    $self->elem->replace_with( @ { $self->replacements } ) ;
}

sub push_clone {

    my($self)=@_;

    my $clone = $self->elem->clone;
    push @{$self->replacements}, $clone;

    $clone;
}


1; # End of HTML::Element::Replacer
