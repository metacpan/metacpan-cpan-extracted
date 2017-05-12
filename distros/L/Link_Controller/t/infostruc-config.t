=head1 DESCRIPTION

tests for reading infostructure configuration.

=cut


BEGIN {print "1..9\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use WWW::Link_Controller::InfoStruc;
$loaded=1;

$WWW::Link_Controller::InfoStruc::no_warn=1;

ok(1);

$::infostrucs="test-data/infostruc-defs/good";

WWW::Link_Controller::InfoStruc::default_infostrucs();

ok(2);

$::infostrucs{"http://www.example.com/first"}->{file_base}
  eq  "/var/www/first" or nogo;

ok(3);

WWW::Link_Controller::InfoStruc::url_to_file
  ("http://www.example.com/first/somedir/somefile")
  eq  "/var/www/first/somedir/somefile" or nogo;


ok(4);

WWW::Link_Controller::InfoStruc::file_to_url
  ("/var/www/first/somedir/somefile")
  eq  "http://www.example.com/first/somedir/somefile" or nogo;


ok(5);

defined WWW::Link_Controller::InfoStruc::url_to_file
  ("http://dynamic.example.com/second/reallydynamic")
  and nogo;

ok(6);

defined WWW::Link_Controller::InfoStruc::file_to_url("/etc/passwd")
  and nogo;

ok(7);

%::infostrucs = ();
@::infostruc_urls_sorted = ();
@::infostruc_files_sorted = ();


$::infostrucs="test-data/infostruc-defs/bad";

eval { default_infostrucs() };

nogo unless $@;

ok(8);


%::infostrucs = ();
@::infostruc_urls_sorted = ();
@::infostruc_files_sorted = ();

%::infostrucs=(
    "http://advanced.example.com/" => {
		   file_base => "/var/www/advanced/",
		   includere => "*.html",
				     }
	      );
$::infostrucs="test-data/infostruc-defs/ugly";

WWW::Link_Controller::InfoStruc::default_infostrucs();

@::infostruc_urls_sorted > 0 or nogo;

ok(9);
