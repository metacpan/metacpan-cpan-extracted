use Test::More tests=>2;
SKIP: {
  no warnings 'all';
  my $have_httpd = eval ' use HTTP::Server::Simple::Static; $HTTP::Server::Simple::Static::VERSION; ';
  warn "have_httpd : $have_httpd\n";
  skip ('Maypole::HTTPD tests', 2) unless ( $have_httpd );
  use_ok("Maypole::HTTPD");
  use_ok("Maypole::HTTPD::Frontend");
};

