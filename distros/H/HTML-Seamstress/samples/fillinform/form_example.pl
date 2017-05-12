
my %form = 
  (
   age => 77,
   email => 'ben@perlmon.com',
   zipcode => '29063-2134'
  );


use form_example;
my $tree = form_example->new;


# calls 
my $html = $tree->fillinform(\%form) ;

warn $html;
