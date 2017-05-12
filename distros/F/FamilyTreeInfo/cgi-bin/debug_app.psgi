use strict;
use warnings;

use CGI::Emulate::PSGI;
use CGI::Compile;
$CGI::Compile::RETURN_EXIT_VAL = 1;
use Plack::Builder;

my $cgi_script = "ftree.cgi";
my $sub = CGI::Compile->compile($cgi_script);
my $app = CGI::Emulate::PSGI->handler($sub);

my $cgi_person = "person_page.cgi";
my $sub_person = CGI::Compile->compile($cgi_person);
my $app2 = CGI::Emulate::PSGI->handler($sub_person);

  builder {
      # Enable Interactive debugging
      #enable "InteractiveDebugger";
      #enable 'Debug'; # load defaults
      enable "Plack::Middleware::Static",
          path => qr{[gif|png|jpg|swf|ico|mov|mp3|pdf|js|css]$}, root => './';

	  # Let Plack care about length header
      #enable "ContentLength";

	  mount "/person_page" => $app2;
	  mount "/ftree" => $app;
	  mount "/" => builder { $app };
  };
