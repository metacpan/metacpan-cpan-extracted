#!/usr/bin/perl -T
use strict;
use warnings;

package Mediawiki::Blame::Server;
use lib qw(lib);
use Mediawiki::Blame qw();
use HTML::Entities qw(encode_entities);
use Encode;
use base qw(HTTP::Server::Simple::CGI);

our $HEAD = <<"";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
    <meta http-equiv="content-type" content="application/xhtml+xml;charset=UTF-8" />
    <title>Mediawiki::Blame/$Mediawiki::Blame::VERSION</title>
    <style type="text/css">
        fieldset ul {clear: both;}
        fieldset div label {float: left; text-align: right; width: 3em;}
        fieldset div input {float: right; text-align: left; width: 90%;}
        fieldset ul li {font-family: monospace;}
        table:nth-child(even) {background-color: #eee;}
    </style>
    </head>
    <body>


sub handle_request {
    my ($self, $cgi) = @_;

    if ($cgi->param('export')) {
        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header('application/xhtml+xml;charset=UTF-8');

        my $mb = Mediawiki::Blame->new(
            export => $cgi->param('export'),
            page => $cgi->param('page'),
        );
        $mb->fetch(
            before => 'now',
        );

        print $HEAD;
        print q(
            <table border="1">
            <tr>
                <th>revision</th>
                <th>timestamp</th>
                <th>contributor</th>
                <th>text</th>
            </tr>);

        foreach ($mb->blame) {
            print encode_utf8
                "<tr><td>".
                $_->r_id.
                "</td><td>".
                $_->timestamp.
                "</td><td>".
                encode_entities($_->contributor, '<>&"').
                "</td><td>".
                encode_entities($_->text, '<>&"').
                "</td></tr>";
        };

        print "</table></body></html>";
    } else {
        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header('application/xhtml+xml;charset=UTF-8');
        print $HEAD;
        print <<"END_OF_HTML";
        <form method="post" action="/" accept-charset="UTF-8">
            <fieldset>
                <div>
                    <label for="export" title="URL to a Mediawiki export page">Export</label>
                    <input name="export" id="export" accesskey="5" />
                </div>
                <ul>
                    <li>http://example.org/wiki/Special:Export</li>
                    <li>http://example.org/w/index.php?title=Special:Export</li>
                </ul>
                <div>
                    <label for="page" title="page name">Page</label>
                    <input name="page" id="page" accesskey="6" />
                </div>
                <ul>
                    <li>User:The Demolished Man</li>
                    <li>Liberté, égalité, fraternité</li>
                </ul>
                <input accesskey="7" type="submit" />
            </fieldset>
        </form>
    </body>
</html>
END_OF_HTML
    };
};

package main;
my $server = Mediawiki::Blame::Server->new(12345);
$server->run;

1;
