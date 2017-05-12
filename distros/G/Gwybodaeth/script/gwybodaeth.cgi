#!/usr/bin/env perl
# Copyright (c) 2009, Iestyn Pryce <imp25@cam.ac.uk>

use warnings;
use strict;
use lib '../lib';
use lib 'lib';

use CGI::Carp qw(fatalsToBrowser set_message);
use CGI;
use URI::Escape;
use XML::Twig;

# gwybodaeth specific modules
use Gwybodaeth::Parsers::N3;
use Gwybodaeth::Read;

BEGIN {
    set_message(\&handle_errors);
}

my $CSS=<<'EOF';
<!--
body {
    font-family: 'DejaVu Sans Condensed', Helevetica, sans-serif;
    font-size: 11pt;
    background-color: #fff;
    }

#problem {
    border: solid;
    border-width: 1px 1px 1px 1px;
    padding: 0px 15px 0px;
    background-color: #ffddee;
    margin: 5px 5px 5px 5px;
    }
-->
EOF

sub handle_errors {
    my $msg = shift;
    if ($msg =~ m!Empty [map|source]|The input data is not XML!x) { 
        print STDERR "FOOO!";
        $msg =~ s/at\s.+$//gx; 
    }
    $msg =~ s!\n!<br />!x;
    $msg =~ s/at\s.+$//gx; 
    my $q = new CGI;
    print $q->start_html( -title=>"Problem", -style=>{-code=>$CSS}),
          $q->h1( "Problem" )."\n",
          $q->start_div({-id=>'problem'}) . "\n",
          $q->p( "Sorry, the following problem has occurred: " ),
          $q->p( "$msg" ) ."\n",
          $q->end_div(),
          $q->end_html;
    return 1;
}

# Load configuration
my $root = File::Spec->rootdir();
my $conf_file = File::Spec->catfile("$root",'etc','gwybodaeth','gwybodaeth.conf');
-e $conf_file or croak "you need a configuration file $conf_file: $!";

my $twig = XML::Twig->new();
$twig->parsefile($conf_file);

my @converters = $twig->root->children( 'converter' );
my %convert = ();

for my $conv (@converters) {
    my $name = $conv->first_child_text('name');
    my $parser = $conv->first_child_text('parser');
    my $writer = $conv->first_child_text('writer');
    
    $convert{$name} = { parser => $parser, writer => $writer };
}

my $cgi = CGI->new();

$CGI::POST_MAX = 1024 * 5000;

my $data = uri_unescape($cgi->param('src'));
my $map  = uri_unescape($cgi->param('map'));
my $in_type = $cgi->param('in');

my @undef;
for ('src', 'map', 'in') {
    unless ( defined( $cgi->param($_) ) ) {
        push @undef, $_;
    }
}

if (@undef) {
    @undef = map { "<li>$_</li>" }  @undef;
    my $err = join("\n", @undef);
    print $cgi->header('text/html'),
          $cgi->start_html('Problems'),
          $cgi->h3('Undefined Parameters'),
          ("The following parameters need to be defined in the URL: <br />\n<ul>\n$err\n</ul>"),
          $cgi->end_html;
    exit 0;
}

my $input = Gwybodaeth::Read->new();

my $len;
if (-f $data) {
    $len = $input->get_file_data($data);
} else {
    $len = $input->get_url_data($data);
}

croak "Empty source: $data" if ($len < 1);

my $mapping = Gwybodaeth::Read->new();

if (-f $map) {
    $len = $mapping->get_file_data($map);
} else {
    $len = $mapping->get_url_data($map);
}

croak "Empty map: $map" if ($len < 1);

my @data = @{$mapping->get_input_data};

my $map_parser = Gwybodaeth::Parsers::N3->new();

my $map_triples = $map_parser->parse(@data);

unless ($map_triples) { croak 'Error while parsing map data'; }

my $parser;
my $writer;
my $write_mod;
my $parse_mod;
if (defined($convert{$in_type})) {
    $write_mod = $convert{$in_type}->{'writer'};
    $parse_mod = $convert{$in_type}->{'parser'};
    eval {
        (my $wpkg = $write_mod) =~ s!::!/!gx;
        (my $ppkg = $parse_mod) =~ s!::!/!gx;
        require "$wpkg.pm";                     ## no critic
        require "$ppkg.pm";                     ## no critic
        import $parse_mod; 
        import $write_mod;
        1;
    }or croak "Module loading failed: $!";
    $parser = $parse_mod->new();
    $writer = $write_mod->new();
} else {
    croak "$in_type is not defined in the config file";
}
my $parsed_data_ref = $parser->parse(@{ $input->get_input_data });

unless ($parsed_data_ref) { croak 'Error while parsing source data'; }

print $cgi->header('Content-type: application/rdf+xml');

$writer->write_rdf($map_triples,$parsed_data_ref);
__END__

=head1 SEE ALSO

L<Gwybodaeth>

=head1 AUTHORS

Iestyn Pryce, <imp25@cam.ac.uk>

=head1 ACKNOWLEDGEMENTS

I'd like to thank the Ensemble project (www.ensemble.ac.uk) for funding me to
work on this project in the summer of 2009.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Iestyn Pryce <imp25@cam.ac.uk>

This library is free software; you can redistribute it and/or modify it under
the terms of the BSD license.
