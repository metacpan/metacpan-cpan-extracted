use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'GoogleGadget' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== Google Gadget 1
--- input
<script src="http://gmodules.com/ig/ifr?url=http://www.google.com/ig/modules/datetime.xml&amp;synd=open&amp;w=320&amp;h=136&amp;title=__MSG_title__&amp;lang=all&amp;country=ALL&amp;border=http%3A%2F%2Fgmodules.com%2Fig%2Fimages%2F&amp;output=js"></script>
--- expected
Google Gadget

=== Google Gadget 2
--- input
<script src="http://gmodules.com/ig/ifr?url=http://www.google.com/ig/modules/datetime.xml&amp;synd=open&amp;w=320&amp;h=136&amp;title=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A&amp;lang=all&amp;country=ALL&amp;border=%23ffffff%7C1px%2C1px+solid+black%7C1px%2C1px+solid+black%7C0px%2C1px+black&amp;output=js"></script>
--- expected
Google Gadget

===  Google Gadget 3
--- input
<script src="http://gmodules.com/ig/ifr?url=http://www.schulz.dk/pacman.xml&amp;synd=open&amp;w=320&amp;h=420&amp;title=PacMan+v2.4&amp;border=%23ffffff%7C0px%2C1px+solid+%23ff9977%7C0px%2C1px+solid+%23ffddcc%7C0px%2C1px+solid+%23ff9977%7C0px%2C1px+solid+%23ffddcc%7C0px%2C1px+solid+%23ff9977&amp;output=js"></script>
--- expected
Google Gadget

===  Google Gadget 4
--- input
<script src="http://gmodules.com/ig/ifr?url=http://g.1o4.jp/module/finance-index.xml&amp;up_gmindex=NIK&amp;up_gmlink=http%3A%2F%2Fquote.yahoo.co.jp%2Fq%3Fs%3D998407.o%26d%3Dc%26k%3Dc3%26a%3Dv%26p%3Dm25%2Cm75%2Cs%26t%3D3m%26l%3Doff%26z%3Dm%26q%3Dc&amp;synd=open&amp;w=320&amp;h=192&amp;title=__UP_gmtitle__&amp;border=%23ffffff%7C3px%2C1px+solid+%23999999&amp;output=js"></script>
--- expected
Google Gadget

===  Google Gadget 5
--- input
<script src="http://gmodules.com/ig/ifr?url=http://gadget.fans.googlepages.com/tv.xml&amp;up_gmtitle=Gadget%20TV&amp;synd=open&amp;w=320&amp;h=160&amp;title=__UP_gmtitle__&amp;border=%23ffffff%7C3px%2C1px+solid+%23999999&amp;output=js"></script>
--- expected
Google Gadget
