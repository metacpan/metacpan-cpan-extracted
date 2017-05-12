#!/usr/bin/perl

use EmbedIT::WebIT;

# ----------------------------------------------------------------------------------------------------------

sub index_html {
  print "
<html>
<body>
<h1>This is a test index page</h1>
</body>
</html>
";
}

# ----------------------------------------------------------------------------------------------------------

sub error_html {
  my $c = $ENV{ERROR_CODE};
  my $t = $ENV{ERROR_TEXT};
  my $u = $ENV{ERROR_URI};
  my $m = $ENV{ERROR_METHOD};

  print "
<html>
<body>
<h1>This is a test error page</h1>
<h2>Error is : $c - $t</h2>
<h2>on page  : $u</h2>
<h2>with method : $m</h2>
</body>
</html>
";
}

# ----------------------------------------------------------------------------------------------------------

sub no_page_html {
  my $f = $ENV{SCRIPT_FILENAME};
  print "
<html>
<body>
<h1>The page $f does not exist on this server</h1>
</body>
</html>
";
}

# ----------------------------------------------------------------------------------------------------------

my $server = new EmbedIT::WebIT(  SERVER_NAME     => 'localhost',
                                  SERVER_IP       => '127.0.0.1',
                                  SERVER_PORT     => 8089,
                                  SOFTWARE        => 'MyApp',
                                  QUEUE_SIZE      => 100,
                                  WAIT_RESPONSE   => 1,
                                  IMMED_CLOSE     => 0,
                                  EMBED_PERL      => 1,
                                  FORK_CONN       => 0,
                                  SETUP_ENV       => 1,
                                  SERVER_ADMIN    => 'info@my.org',
                                  SERVERS         => 1,
                                  WORKERS         => 0,
                                  DOCUMENT_ROOT   => 'test_site',
                                  DOCUMENTS       => {
                                                       '/index.html' => 'main::index_html',
                                                       '/error.html' => 'main::error_html',
                                                     },
                                  ERROR_PAGES     => { 
                                                       'ALL' => '/error.html', 
                                                     },
                                  EXPIRATIONS     => { 
                                                       'image/jpg' => 86400,
                                                       'ALL' => 3600, 
                                                     },
                                  CGI_PATH        => '/cgi',
                                  PROC_PREFIX     => 'test:',
                                  LOG_HEADERS     => 0,
                                  LOG_PACKETS     => 0,
                                  ENV_KEEP        => [ 'PERL5LIB', 'LD_LIBRARY_PATH' ],
                                  NO_LOGGING      => 0,
                             );

$server->execute();

# ----------------------------------------------------------------------------------------------------------

