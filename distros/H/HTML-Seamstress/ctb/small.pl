use strict;
use warnings;
use HTML::Seamstress;
use File::Spec;
use Data::Dumper;


my $file = 'html/hello_world.html';
my $abs  = File::Spec->rel2abs($file);
my $tree = HTML::Seamstress->new_from_file($file);
my $module_file = 'pkg/hello_world.pm';
my $module_pkg  = 'html::hello_world';

my ($content_subs, $look_downs) = find_content_subs();
my $serial = serialize_html_parse($tree);


save_module();
exit;

# subs ------------------------------------------------------------------ 

sub save_module {
  open D, ">$module_file" or die $!;
  print D pkg();
}


sub serialize_html_parse {
  my $tree = shift;
  $Data::Dumper::Purity = 1;
  our $serial = Data::Dumper->Dump([$tree], ['tree']);
  $serial =~ s/HTML::Seamstress/$module_pkg/;
  $serial;
}


sub find_content_subs {
  my @content_sub;
  my @klass_content = $tree->look_down(klass => 'content') ;
  warn "found " . @klass_content . ' nodes ' ;

  my @scalar = map { 
    my $id = $_->attr('id');
    push @content_sub, make_content_sub($id);
    $id
  } @klass_content;

  my $content_subs = join "\n", @content_sub;

  my $look_downs = join ";\n",
    map { 
      sprintf 'my $%s = $tree->look_down(id => q/%s/)', $_, $_ 
    } @scalar;
  

  ($content_subs, $look_downs)
}
  
sub make_content_sub { sprintf <<'EOK', ($_[0]) x 4 }

sub %s {
   my $class = shift;
   my $content = shift;
   if (defined($content)) {
      $%s->content_handler(%s => $content);
      return $tree
   } else {
      return $%s
   }

}

EOK
  

sub pkg { sprintf <<'EOPKG', $module_pkg, $look_downs, $content_subs, $abs, $serial }
package %s;
use strict;
use warnings;
use base qw(HTML::Seamstress);

use vars qw($tree);
tree();

# content_accessors;
%s;

# content subs
%s

# the html file %s
sub tree {
# serial
%s
}

1;

EOPKG
