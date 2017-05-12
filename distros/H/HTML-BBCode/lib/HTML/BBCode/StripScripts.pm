package HTML::BBCode::StripScripts;

use strict;
use URI;
use base qw(HTML::StripScripts::Parser);

our $VERSION = '0.04';

my %bbattrib;
my %bbstyle;
my %bbstyle_overrides = (
   'text-decoration' => 'word',
   'font-style'      => 'word',
   'font-weight'     => 'word',
   'list-style-type' => 'word',
);


sub init_attrib_whitelist {
   unless (%bbattrib) {
      %bbattrib = %{__PACKAGE__->SUPER::init_attrib_whitelist};
      $bbattrib{'h5'}{'class'} = 'word';
   } 
   return \%bbattrib;
}       

sub init_style_whitelist {
   unless (%bbstyle) {
      %bbstyle = %{__PACKAGE__->SUPER::init_style_whitelist};
      @bbstyle{keys %bbstyle_overrides} = values %bbstyle_overrides;
   }     
   return \%bbstyle;
}       

sub validate_href_attribute {
   my ($self, $text) = @_;

   # Encode URLs if needed (as per bug 31927)
   my $uri = URI->new($text);
   my $query = $uri->query;
   if($query) {
      if($query =~ m/[^A-Za-z0-9\-_.!~*'()]/ && $query !~ m/%(?![A-Fa-f0-9])/) {
         $query =~ s/([^;&=A-Za-z0-9\-_.!~*'()\%])/sprintf("%%%02X", ord($1))/ge;
         $uri->query($query);
      }
   }

   $text = $uri->as_string;

   return $1
       if $self->{_hssCfg}{AllowRelURL}
       and $text =~ /^((?:[\w\-.!~*|;\/?=+\$,%#]|&amp;){0,100})$/;

   $text =~ m< ^ ( (f|ht)tps? :// [\w\-\.]{1,100} (?:\:\d{1,5})?
                   (?: / (?:[\w\-.!~*|;/?=+\$,%#]|&amp;){0,2000} )?
                 )
               $
             >x ? $1 : undef;
}


1;
