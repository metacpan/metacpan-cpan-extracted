 package html::productpage;

 use base qw( HTML::Seamstress ) ;

 sub new {
  my ($class, $c) = @_;

  my $html_file = 'html/base.html';

  my $tree = __PACKAGE__->new_from_file($html_file);

  $tree;
 }

 sub process {
  my ($tree, $c, $stash) = @_;

  $tree->content_handler(head => 'Wally World Products');
  $tree->content_handler(body => 
			     HTML::TreeBuilder->new_from_file('html/products.html')->guts )
 }

1;
