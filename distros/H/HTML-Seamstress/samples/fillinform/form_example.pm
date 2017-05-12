package form_example;

# cmdline: /usr/bin/spkg.pl --base_pkg=HTMLBase form_example.html

use strict;
use warnings;

use base qw(Class::Prototyped HTML::Seamstress);


;
use base qw(HTMLBase); 
use vars qw($html);

our $tree;

#warn HTMLBase->comp_root(); 
#HTMLBase


#$html = __PACKAGE__->html(__FILE__ => 'html') ;
$html = __FILE__;

sub new {
#  my $file = __PACKAGE__->comp_root() . '' ;
  my $file = __PACKAGE__->html($html => 'html');

  -e $file or die "$file does not exist. Therefore cannot load";

  $tree =HTML::TreeBuilder->new;
  $tree->store_declarations;
  $tree->parse_file($file);
  $tree->eof;
  
  bless $tree, __PACKAGE__;
}

sub process {
  my ($tree, $c, $stash) = @_;

  use Data::Dumper;
  warn "PROCESS_TREE: ", $tree->as_HTML;

  # $tree->look_down(id => $_)->replace_content($stash->{$_})
  #     for qw(name date);

  $tree;
}

sub fixup {
  my ($tree, $c, $stash) = @_;

  $tree;
}




1;
