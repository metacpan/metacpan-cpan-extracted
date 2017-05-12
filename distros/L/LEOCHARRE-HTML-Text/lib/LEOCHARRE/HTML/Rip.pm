package LEOCHARRE::HTML::Rip;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION @ISA);
$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(find_tag rip_tag);
%EXPORT_TAGS = ( all => \@EXPORT_OK );





sub find_tag {
   my($html,$tag)=@_;
   $html and $tag or die;



   
   my @return;
   while( $html=~/(<$tag[^<>]*>(.*?)<\/$tag>)/sig ){ # this minimal matching works right
      push @return, $1;
   }
   
   if( !@return or (scalar @return == 0) ){
      #maybe it's a single
      while( $html=~/(<$tag[^<>]*\/>)/sig ){
         push @return, $1;
      }
   }
   

   return @return;
}


sub rip_tag {
   my($html,$tag) =@_;
   $html and $tag or die;
   my @have = find_tag($html,$tag);
   for my $what (@have) {
      $html=~s/\Q$what\E//s;
   }
   return $html;
}


1;

__END__

=pod

=head1 NAME

LEOCHARRE::HTML::Rip

=head1 SUBS

=head2 find_tag()

Argument is html scalar and tag name.
Returns array of found.

   find_tag($html,'meta');



