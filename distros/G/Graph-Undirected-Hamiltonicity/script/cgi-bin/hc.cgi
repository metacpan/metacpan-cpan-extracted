#!/usr/bin/env perl

#
# This script demonstrates the functionality of the
# Graph::Undirected::Hamiltonicity module.
#
# It uses CGI::Minimal to keep it fairly portable.
#
use Modern::Perl;

use CGI::Minimal;
use Graph::Undirected;
use Graph::Undirected::Hamiltonicity;
use Graph::Undirected::Hamiltonicity::Transforms qw(&string_to_graph);

$ENV{HC_OUTPUT_FORMAT} = 'html';
$| = 1;


my ( $self_url ) = split /\?/, $ENV{REQUEST_URI};

say qq{Content-Type: text/html\n};

say <<'END_OF_HEADER';
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">

<title>Hamiltonian Cycle Detector</title>

<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.css" integrity="sha256-rll6wTV76AvdluCY5Pzv2xJfw2x7UXnK+fGfj9tQocc=" crossorigin="anonymous" />

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.8.0/jquery.modal.min.js" integrity="sha256-UeH9wuUY83m/pXN4vx0NI5R6rxttIW73OhV0fE0p/Ac=" crossorigin="anonymous"></script>

<script>

// -----------------------------------------------------------------------------
function random_integer(min,max) {
    return Math.floor((Math.random() * max) + min);
}
// -----------------------------------------------------------------------------
function spoof_graph(v, min_e) {
     if ( min_e < v ) {
         min_e =  random_integer(v, ( v * v - v ) / 2 );
     }

     var X = new Array();
     for ( var h=0; h < v; h++ ) {
        X[h] = new Array();
     }

     for ( var i=0; i < min_e; i++ ) {
        var vertex1 = random_integer(0,v);
        var vertex2 = random_integer(0,v);
        if (vertex1 == vertex2) continue;
        if ( X[vertex1].indexOf(vertex2) !== -1 ) continue;
        X[vertex1].push(vertex2);
        X[vertex2].push(vertex1);
     }

     for ( var j=0; j < v; j++ ) {
        var neighbors = X[j].length;
        if (neighbors > 1) continue;
        while ( neighbors < 2 ) {
            var vertex1 = j;
            var vertex2 = random_integer(0,v);
            if (vertex1 == vertex2) continue;
            if (X[vertex1].indexOf(vertex2) !== -1) continue;
            X[vertex1].push(vertex2);
            X[vertex2].push(vertex1);
            neighbors++;
         }
    }

    var edge_pairs = new Array();
    for ( var m=0; m < v; m++ ) {
       for ( var n=0; n < X[m].length; n++ ) {
           if ( m > X[m][n] ) continue;
           edge_pairs.push( m + "=" + X[m][n] );
       }
    }

   var result = edge_pairs.join(",");
   return result;
}
// -----------------------------------------------------------------------------
    $(document).ready(function(){

       if (typeof window.is_hamiltonian !== 'undefined') {
           var modal_to_open = window.is_hamiltonian ? '#ham' : '#non';
           $( modal_to_open ).modal();
       }

       $( "#spoof_button" ).click(function() {
          var x = $('#graph_text').val();
          var v = parseInt(x);
          if ( ( v > 100 ) or ( v < 1 ) ) {
            v = random_integer(10,50);
          }
          $('#graph_text').val( spoof_graph(v,0) );
       });
    });
</script>

</head>
<body bgcolor="white">
<div class="container">
<br/><br/>


END_OF_HEADER

say qq{<form method="post" action="$self_url" enctype="multipart/form-data">};

my $cgi = CGI::Minimal->new;
if ($cgi->truncated) {
    say qq{<H2>There was an error. The input size might be too big.</H2>};
    say get_textarea();
    say qq{</form></div></body></html>};
    exit;
}

my $graph_text = $cgi->param('graph_text') // '';
$graph_text =~ s/[^0-9=,]+//g;
$graph_text =~ s/([=,])\D+/$1/g;
$graph_text =~ s/^\D+|\D+$//g;

my $g;
if ( $graph_text =~ /\d/ ) {
    eval { $g = string_to_graph($graph_text); };
    if ( my $exception = $@ ) {
        say "That was not a valid graph, ";
        say "according to the Graph::Undirected module.<BR/>";
        say "[$graph_text][$exception]<BR/>";
        print_instructions();
    }
} else {
    if ( $ENV{QUERY_STRING} =~ /\bgraph_text=/ ) {
        say "Here is the Null Graph <TT>K<sub>0</sub></TT>. ";
        say "It is not Hamiltonian.\n<BR/><P/>;
    }
    print_instructions();
}

say get_textarea($g);
say qq{</form>};
say qq{<br/><br/>};

if ( $graph_text =~ /\d/ ) {

    say qq{<h2>Here is the program's trace output:</h2><BR/>};

    my ( $is_hamiltonian, $reason, $params ) = graph_is_hamiltonian($g);
    say qq{<BR/>};
    say qq{<A NAME="conclusion"></A><B>Conclusion:</B>};
    say qq{<span style="background: yellow;">};
    if ( $is_hamiltonian ) {
        say qq{The graph is Hamiltonian.};
        say qq{<script>window.is_hamiltonian = true;</script>};
    } else {
        say qq{The graph is not Hamiltonian.};
        say qq{<script>window.is_hamiltonian = false;</script>};
    }
    say qq{</span>};
    say qq{($reason)};

    say qq{<HR NOSHADE><BR/>};
    say qq{vertices: }, scalar($g->vertices()), qq{<BR/>};
    say qq{edges: }, scalar($g->edges()), qq{<BR/>};
    say qq{calls: }, $params->{calls}, qq{<BR/>};
    say qq{time: };
    my $s = $params->{time_elapsed} == 1 ? "" : "s";
    say $params->{time_elapsed}, qq{ second$s};
    say qq{<BR/><P/>};
}

say q{
 <!-- Hamiltonian modal -->
  <div id="ham" style="display:none; overflow: visible;">
    <H1>The graph is Hamiltonian!</H1>
  </div>

 <!-- Non-Hamiltonian modal -->
  <div id="non" style="display:none; overflow: visible;">
    <H1>The graph is <u>not</u> Hamiltonian!</H1>
  </div>
</div>

<BR/><P/>
</BODY></HTML>
};

### say qq{<a href="#" rel="modal:close">Close</a> or press ESC};

############################################################

sub get_textarea {
    my $g = $_[0];
    my $printable_string = defined $g ? $g->stringify() : '';
    my $result = <<END_OF_TEXTAREA;
        <DIV style="background-color: #DDD; padding-top: 10px; padding-bottom: 10px;">
            <div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px;">
                <textarea id="graph_text" name="graph_text"  rows="3" cols="100" placeholder="Example: 0=1,0=2,1=2,2=3" style="font-family: monospace;">$printable_string</textarea>
            </div>
            <div style="padding-top: 10px; padding-bottom: 10px; padding-left: 20px; padding-right: 10px;">
            <input type="submit" name=".submit" value="Is this graph, Hamiltonian or not?" class="btn btn-primary">
            <input type="button" id="spoof_button" value="Spoof a Graph!" class="btn btn-primary">
            </div>
        </DIV>
END_OF_TEXTAREA

    return $result;

}

##########################################################################

sub print_instructions {
    say "Please enter an undirected graph's edge list.";
    say "e.g., <TT>0=1,1=2,0=2</TT><BR/>";
    say "Each vertex should be 0, or a positive integer.<BR/>";
}

__END__
