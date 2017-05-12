package MyApp::Mason;

# Bring in Mason with Apache support.
use HTML::Mason::ApacheHandler;
use strict;

# List of modules that you want to use within components.
{ package HTML::Mason::Commands;
  use Data::Dumper;
}

# Create ApacheHandler object at startup.
my $ah = new HTML::Mason::ApacheHandler( comp_root => '<component root>',
                                         data_dir => '<data directory>' );

sub handler
{
    my ($r) = @_;

    my $status = $ah->handle_request($r);
    return $status;
}

1;


__END__

In your httpd.conf, add something like this:

 PerlRequire MyApp::Mason

 <LocationMatch "\.html$">
   SetHandler perl-script
   PerlHandler MyApp::Mason
 </LocationMatch>
