
package My::CPANAuthors;

use strict;
use warnings 'all';
use base 'Iterator::Paged';
use LWP::UserAgent;
use HTTP::Request::Common;

my @pages = ('A'..'Z');


#==============================================================================
sub next_page
{
  my $s = shift;
  
  
  $s->{ua} ||= LWP::UserAgent->new();
  
  $s->{page_number} = shift(@pages)
    or return;
  my $url = "http://search.cpan.org/author/?$s->{page_number}";
  my $res = eval { $s->{ua}->request( GET $url )->content }
    or return;

  my @items = ( );
  while(
    my ($chunk, $url, $id, $name) = $res =~ m{(<a href="(/~.*?/)"><b>(.*?)</b></a><br/><small>(.*?)</small>)}i
  )
  {
    $res =~ s/\Q$chunk\E//;
    push @items, {
      url   => "http://search.cpan.org$url",
      id    => $id,
      name  => $name,
    };
  }# end while()
  
  return unless @items;
  return \@items;
}# end get_page()

1;# return true:

