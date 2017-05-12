#!/usr/bin/perl

use strict;
use warnings;
use Carp;

use Test::More;

use lib qw(lib t/lib);

use MyTestTools qw(:all);
use IkiWiki q(2.0);

use IO::File;
use HTML::Template;

my $examples_dir = q(examples/sources);
my %examples = (
    'sarajevo.conf'         =>  'conf',
    'smart_comments.pl'     =>  'perl',
    'page.tmpl'             =>  'html',
    'function.pl'           =>  'perl',
    'bash.sh'               =>  'bash',
    'fragment.html'         =>  'html',
    'text.pod'              =>  'pod',
);
my @engines = MyTestTools::Engines();
my %options = (
    linenumbers => 1,
    bars        => 0,
);

my $html_path = q(examples/example.html);
if (not ResultsFile( $html_path )) {
    plan( skip_all => "Could not write to the ${html_path} file" );
}
else {
    my $ntests = ( (scalar keys %examples) * (scalar @engines) ) + 1;
    plan(tests => $ntests);
}

use_ok('IkiWiki::Plugin::syntax');

## initialize the output HTML page
_init_output();

#   build the HTML examples
EXAMPLES:    
foreach my $page (keys %examples) {
    my $html = undef;
    my $example_path = "${examples_dir}/$page";

    ## and loop around the engines using the same source
    ENGINES:
    foreach my $engine (@engines) {
        #   Setting global parameters
        $IkiWiki::config{syntax_engine} = $engine;
        $IkiWiki::config{debug} = 0;

        #   Initialize the plugin
        eval {   
            IkiWiki::Plugin::syntax::checkconfig();
        };

        if ($@) {
            fail("Engine ${engine} not installed");
            next ENGINES;
        }
        else {
            eval {
                $html = IkiWiki::Plugin::syntax::preprocess( 
                        file        => $example_path,
                        language    => $examples{$page}, 
                        %options );
                };
            
            if ($@) {
                fail("built page ${example_path} with engine ${engine}");
            }
            else {
                _add_result( engine => $engine, page => $page, 
                             language => $examples{$page}, text => $html);
                pass("syntax highlight from ${page} using engine ${engine}");
            }
        }
    } ## foreach engines
} ## foreach pages

my $final = HTML::Template->new( filename => q(examples/sources/page.tmpl), no_includes => 1 );

$final->param( title => q(Examples page for IkiWiki::Plugin::syntax),
               results => [ _get_output() ],
           );

# write the final output to a permanent file
my $example_html = ResultsFile();
$example_html->print($final->output());
$example_html->close();

{

    my @blocks = ();

    sub _init_output {
        @blocks = ();    
    }

    sub _get_output {
        return @blocks;
    }

    sub _add_result {
        my  %params =   (
            engine  =>  undef,
            page    =>  undef,
            text    =>  undef,
            @_ );
        my $description = undef;

        if (ref $params{text} eq 'SCALAR') {
            $params{text} = _slurp_page( ${$params{text}} );
        }

        my  $html = HTML::Template->new( filename => q(examples/results.tmpl), 
                        no_includes => 1 );

        if (not $params{engine}) {
            $description = sprintf 'Source from %s', $params{page};
        }
        else {
            $description = sprintf 'Source %s using %s engine', $params{page}, 
                                    $params{engine};
        }

        $html->param( description   => $description,
                    text          => $params{text} );

        push(@blocks, { output => $html->output() } );
    }

    sub _slurp_page {
        my  $path       =   shift;
        my  $content    =   undef;

        if (my $fh = IO::File->new( $path )) {
            local $/;
            
            $content = <$fh>;

            $fh->close;
        }
        else {
            croak "could not open ${path} - ${!}";
        }

        return $content;
    }
}        
