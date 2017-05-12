 package html::homepage;

 use base qw( HTML::Seamstress ) ;

 sub new {
  my ($class, $c) = @_;

  my $html_file = 'html/base.html';

  my $tree = __PACKAGE__->new_from_file($html_file);

  $tree;
 }

 sub process {
  my ($tree, $c, $stash) = @_;

  $tree->content_handler(head => 'Wally World Home');
  $tree->content_handler(body => 
   "Here at Wally World you'll find all the finest accoutrements.");
 }

1;
