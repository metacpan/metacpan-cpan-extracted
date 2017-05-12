package html::abstract::common;

use base qw(HTML::Seamstress Class::Prototyped);


sub head { 'ABSTRACT BASE METHOD' }
sub body { 'ABSTRACT BASE METHOD' }

__PACKAGE__->reflect->addSlots(
  html_file => 'html/base.html',
 );

sub new {
  my $self = shift;

  my $tree = $self->new_from_file($self->html_file);
}

sub process {   
  my ($tree, $c, $stash) = @_;
  $tree->content_handler(head => $tree->head);
  $tree->content_handler(body => $tree->body);
}

1;
