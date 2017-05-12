package x::hello_world;
use strict;
use warnings;
use base qw(HTML::Seamstress);

use vars qw($tree);
tree();

# content_accessors;
my $name = $tree->look_down(id => q/name/);
my $date = $tree->look_down(id => q/date/);

# content subs

sub name {
   my $class = shift;
   my $content = shift;
   if (defined($content)) {
      $name->content_handler(name => $content);
      return $tree
   } else {
      return $name
   }

}



sub date {
   my $class = shift;
   my $content = shift;
   if (defined($content)) {
      $date->content_handler(date => $content);
      return $tree
   } else {
      return $date
   }

}



# the html file /home/terry/perl/hax/HTML-Seamstress-2.6/ctb/html/x/hello_world.html
sub tree {
# serial
$tree = bless( {
                 '_done' => 1,
                 '_implicit_tags' => 1,
                 '_tighten' => 1,
                 '_head' => bless( {
                                     '_parent' => {},
                                     '_content' => [
                                                     bless( {
                                                              '_parent' => {},
                                                              '_content' => [
                                                                              'Hello World'
                                                                            ],
                                                              '_tag' => 'title'
                                                            }, 'HTML::Element' )
                                                   ],
                                     '_tag' => 'head'
                                   }, 'HTML::Element' ),
                 '_store_comments' => 0,
                 '_content' => [
                                 {},
                                 bless( {
                                          '_parent' => {},
                                          '_content' => [
                                                          bless( {
                                                                   '_parent' => {},
                                                                   '_content' => [
                                                                                   'Hello World'
                                                                                 ],
                                                                   '_tag' => 'h1'
                                                                 }, 'HTML::Element' ),
                                                          bless( {
                                                                   '_parent' => {},
                                                                   '_content' => [
                                                                                   'Hello, my name is ',
                                                                                   bless( {
                                                                                            '_parent' => {},
                                                                                            '_content' => [
                                                                                                            'ah, Clem'
                                                                                                          ],
                                                                                            '_tag' => 'span',
                                                                                            'id' => 'name',
                                                                                            'klass' => 'content'
                                                                                          }, 'HTML::Element' ),
                                                                                   '. '
                                                                                 ],
                                                                   '_tag' => 'p'
                                                                 }, 'HTML::Element' ),
                                                          bless( {
                                                                   '_parent' => {},
                                                                   '_content' => [
                                                                                   'Today\'s date is ',
                                                                                   bless( {
                                                                                            '_parent' => {},
                                                                                            '_content' => [
                                                                                                            'Oct 6, 2001'
                                                                                                          ],
                                                                                            '_tag' => 'span',
                                                                                            'id' => 'date',
                                                                                            'klass' => 'content'
                                                                                          }, 'HTML::Element' ),
                                                                                   '. '
                                                                                 ],
                                                                   '_tag' => 'p'
                                                                 }, 'HTML::Element' )
                                                        ],
                                          '_tag' => 'body'
                                        }, 'HTML::Element' )
                               ],
                 '_body' => {},
                 '_ignore_unknown' => 1,
                 '_pos' => undef,
                 '_ignore_text' => 0,
                 '_no_space_compacting' => 0,
                 '_implicit_body_p_tag' => 0,
                 '_warn' => 0,
                 '_p_strict' => 0,
                 '_hparser_xs_state' => \138300880,
                 '_element_count' => 3,
                 '_store_declarations' => 0,
                 '_tag' => 'html',
                 '_store_pis' => 0,
                 '_element_class' => 'HTML::Element'
               }, 'x::hello_world' );
$tree->{'_head'}{'_parent'} = $tree;
$tree->{'_head'}{'_content'}[0]{'_parent'} = $tree->{'_head'};
$tree->{'_content'}[0] = $tree->{'_head'};
$tree->{'_content'}[1]{'_parent'} = $tree;
$tree->{'_content'}[1]{'_content'}[0]{'_parent'} = $tree->{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[1]{'_parent'} = $tree->{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[1]{'_content'}[1]{'_parent'} = $tree->{'_content'}[1]{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[2]{'_parent'} = $tree->{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[2]{'_content'}[1]{'_parent'} = $tree->{'_content'}[1]{'_content'}[2];
$tree->{'_body'} = $tree->{'_content'}[1];

}


1;

