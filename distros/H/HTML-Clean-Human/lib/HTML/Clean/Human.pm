package HTML::Clean::Human;
use strict;
use LEOCHARRE::Class2;
__PACKAGE__->make_accessor_setget_ondisk_file('abs_path');
#__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget('errstr','html_original','html_cleaned');

use Exporter;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION @ISA);
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(
fix_whitespace
rip_tag 
rip_tables
rip_lists
rip_fonts
rip_formatting
rip_headers
rip_comments
rip_forms
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );



sub _read {
   my $self = shift;
   my $abs_path = $self->abs_path 
      or $self->errstr("no abs_path set") and return;
   
   local $/;
   open(FILE,'<',$abs_path) 
      or $self->errstr("Cant open $abs_path for reading, $!") and return;
   my $text = <FILE>;
   close FILE;
   
   $self->html_original($text);
   $self->html_cleaned($text);

   return $text;
}

sub new {
   my $class = shift;
   my $self = {};
   bless $self, $class;

   while ( my $arg = shift @_ ){
      defined $arg or next;
      if( ref $arg eq 'HASH'){ 
         $self = $arg;
      }
      else {
         $self->{abs_path} = $arg;
      }
   }
   
   $self->_read;
   return $self;   
}

sub clean {
   my $self = shift;

   #all
   
   my $html = $self->html_cleaned;
   
   no strict 'refs';
   for my $sub ( qw(rip_headers rip_tables rip_lists rip_fonts rip_formatting fix_whitespace) ){
      $html = &$sub($html);
   }

   return $self->html_cleaned($html);
}

=pod
for my $methname( qw() ){

   my $subname = __PACKAGE__."::$methname";
   
   *{__PACKAGE__."\::$methname
   sub {
      my $self = shift;
      return $self->html_cleaned( $subname($self->html_cleaned) );
   }


}
=cut





# NON OO



# takes a tag and rips all out, including with atts
sub rip_tag {
   my $html = shift;
   
   for my $tag ( @_ ){
      defined $tag or next;
      
      # no atts
      $html=~s/<$tag>|<\/$tag>/ /sig;

      # with atts
      $html=~s/<$tag [^<>]+>/ /sig;

      # without endtag
      $html=~s/<$tag +\/>/ /sig;
   }

   return $html;
}

sub _rip_chunk { # needs to be refined, careful using this
   my $html = shift;

   for my $tag ( @_ ){
      defined $tag or next;
        

      # no atts
      $html=~s/<$tag><\/$tag>/ /sig;

      # with atts
      $html=~s/<$tag [^<>]+>/ /sig;

      # without endtag
      $html=~s/<$tag +\/>/ /sig;
   }

   return $html;


   
}

sub rip_forms {
   my $html = shift;

   $html = rip_tag($html,qw(input option form textarea checkbox));
   return $html;
}

sub fix_whitespace { # in question
   my $html = shift;
      
   $html=~s/\t|&nbsp;/ /sig;   
   
   $html=~s/([\w\,])\s+([a-z])/$1 $2/sg; # no linebreaks between words

   $html=~s/([,])\s+([a-z])/$1 $2/sig; # no linebreaks between word chars

   
   #$html=~s/(\w)\s{2,}(\w)/$1 $2/sig; # no more then x whitespace between word chars

   $html=~s/(\S) {2,}/$1 /sig;

   $html=~s/\n[ \t]+/\n/g;

   $html=~s/\n\s+\n\s*/\n\n/g;      

   return $html;
}


sub rip_tables {
   return rip_tag(+shift, qw(table tr td tbody));
}

sub rip_fonts {
   return rip_tag(+shift, qw(font i b ul strike em strong cite u));
}

sub rip_lists {
   return rip_tag(+shift, qw(ul ol li));
}

sub rip_formatting {
   return rip_tag(+shift, qw(div br hr p span blockquote center));   
}


sub rip_headers { #tags
   my $html = shift;
   $html = rip_tag($html,qw(html));

   $html=~s/.+<body[^<>]*>//is;
   $html=~s/<\/body>//i;

   return $html;
   
}

sub rip_comments {
   my $html = shift;
   $html=~s/\<\!\-\-[^<>]+\-\-\>//sg;
   return $html;
}

sub rip_javascript {}
sub rip_styles {}









1;



sub headings2text {
   my $html = shift;
   my $change = $html;

   HEADING: while( $html=~/<h(\d)[^<>]*>([^<>]+)<\/h\1>/i ){
      my($h,$text) = ($1,$2);
      
      my $text_altered;
      if($h == 1 ){
         $text_altered = uc($text);
         $change=~s/<h$h[^<>]*>$text<\/h$h>/\n$text_altered\n/sig;
         next HEADING;
      }
      
      else {
         $text_altered = lc($text);
         $text_altered=~tr/\b[a-z]/[A-Z]/;
         
         $change=~s/<h$h[^<>]*>$text<\/h$h>/\n$text_altered\n/sig;
         next HEADING;

      }
      
      
      
   }

   # turn <h1> to CAPITALIZED and turn <h2> To Cap First Letter
   return $change;
   
}
# inverse..
#sub text2headings {}


