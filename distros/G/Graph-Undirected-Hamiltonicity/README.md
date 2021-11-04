[![Build Status](https://travis-ci.org/ownlifeful/Graph-Undirected-Hamiltonicity.svg?branch=master)](https://travis-ci.org/ownlifeful/Graph-Undirected-Hamiltonicity)

# NAME

Graph::Undirected::Hamiltonicity - determine the Hamiltonicity of a given undirected graph.

# VERSION

version 0.013

# SYNOPSIS


    use Graph::Undirected;
    use Graph::Undirected::Hamiltonicity;

    # Create and initialize an undirected graph.
    my $g = Graph::Undirected->new( vertices => [ 0..3 ] );
    $g->add_edge(0,1);
    $g->add_edge(0,3);
    $g->add_edge(1,2);
    $g->add_edge(1,3);

    if ( graph_is_hamiltonian( $g ) ) {
        say "The graph contains a Hamiltonian Cycle.";
    } else {
        say "The graph does not contain a Hamiltonian Cycle.";
    }

# DESCRIPTION


This module is dedicated to the Quixotic quest of determining whether "[P=NP](https://en.wikipedia.org/wiki/P_versus_NP_problem "P versus NP")".
It decides whether a given `Graph::Undirected` contains a Hamiltonian Cycle.

The non-deterministic algorithm systematically simplifies the input graph in a series of recursive tests. This module is not object-oriented, though once work on it is sufficiently advanced, it could be rolled up into an `is_hamiltonian()` method in `Graph::Undirected`. For now, it serves as a framework for explorers of this frontier of Computer Science.

The modules in this distribution are:


* [Graph::Undirected::Hamiltonicity](lib/Graph/Undirected/Hamiltonicity.pod) - the core algorithm.

* [Graph::Undirected::Hamiltonicity::Tests](lib/Graph/Undirected/Hamiltonicity/Tests.pod) - a set of subroutines, each of which is a polynomial time test for Hamiltonicity.

* [Graph::Undirected::Hamiltonicity::Transforms](lib/Graph/Undirected/Hamiltonicity/Transforms.pod) - a set of subroutines, each of which optionally returns a transformed copy of the input graph.

* [Graph::Undirected::Hamiltonicity::Spoof](lib/Graph/Undirected/Hamiltonicity/Spoof.pod) - a set to subroutines to spoof random graphs with defined properties.

* [Graph::Undirected::Hamiltonicity::Wolfram](lib/Graph/Undirected/Hamiltonicity/Wolfram.pod) - an optional module to enable result cross-verfication via the Wolfram Open Cloud. Please read [WOLFRAM.md](WOLFRAM.md "Verification via Wolfram Cloud").

* [Graph::Undirected::Hamiltonicity::Output](lib/Graph/Undirected/Hamiltonicity/Output.pod) - a set of subroutines used by `output()`, a polymorphic subroutine that supports different output formats.

## INSTALLATION



### To install from CPAN:
If you just want to use the module, choose this method.
Install [Graph::Undirected::Hamiltonicity](https://metacpan.org/pod/Graph::Undirected::Hamiltonicity) from cpan.

    cpan Graph::Undirected::Hamiltonicity

### To install the code repositories:
If you want to tinker with the module and/or contribute bugfixes and enhancements, choose this method.

If you need to get `cpanm`:

    curl -L https://cpanmin.us | perl - App::cpanminus

then:

    perl ./Build.PL
    ./Build

If all goes well, you will see output like this:


    ...
    All tests successful.
    Files=15, Tests=604,  4 wallclock secs ( 0.08 usr  0.02 sys +  4.20 cusr  0.13 csys =  4.43 CPU)
    Result: PASS
    [DZ] all's well; removing .build/xHNLTYlN9o


If all is well, then proceed to install the module:

    dzil install


If you run into trouble installing `Net::SSLeay` as part of `Dist::Zilla`, try the following.

On Fedora / Red Hat / CentOS / Rocky Linux:

    sudo yum install openssl-devel

On Debian / Ubuntu:

    sudo apt-get install libssl-dev


### To install the optional CGI script:

Copy the script to the appropriate location for your web server.


On macOS:


    sudo cp cgi-bin/hc.cgi /Library/WebServer/CGI-Executables/

On Fedora / Red Hat / CentOS / Rocky Linux:

    sudo cp cgi-bin/hc.cgi /var/www/cgi-bin/

### To enable verification via Wolfram Open Cloud:

( Optional, but recommended ). To enable result cross-verification via the Wolfram Open Cloud,
please read [WOLFRAM.md](WOLFRAM.md "Verification via Wolfram Cloud").

    use Graph::Undirected::Hamiltonicity::Wolfram;

    if ( is_hamiltonian_per_wolfram( $g ) ) {
        say "The graph contains a Hamiltonian Cycle.";
    } else {
        say "The graph does not contain a Hamiltonian Cycle.";
    }

## USAGE

### CGI script:
The included CGI script ( `cgi-bin/hc.cgi` ) lets you visualize and edit graphs through a browser. It draws graphs using inline SVG.
A demo of this script is hosted at: [http://ownlifeful.com/hamilton.html](http://ownlifeful.com/hamilton.html "Hamiltonian Cycle Detector" )


### Command-line tool:

To test whether a given graph is Hamiltonian:


    perl bin/hamilton.pl --graph_text 0=1,0=2,1=2


To test multiple graphs:


    perl bin/hamilton.pl --graph_file list_of_graphs.txt


To spoof a random Hamiltonian graph with 42 vertices and test it for Hamiltonicity:


    perl bin/hamilton.pl --vertices 42



To get more detailed help:


    perl bin/hamilton.pl --help

# SUPPORT

Please report issues [on GitHub](https://github.com/ownlifeful/Graph-Undirected-Hamiltonicity/issues).


# ACKNOWLEDGEMENTS

Thanks to Larry Wall, for creating Perl; to Jarkko Hietaniemi, for creating the `Graph` module; and to Dr. Stephen Wolfram,
for creating the Wolfram Programming Language. Thanks to Dirac and Ore, for their results utilized here.



# SEE ALSO

1. [Graph](http://search.cpan.org/perldoc?Graph "Graph module") - the `Graph` module.
2. [Hamiltonian Cycle](http://mathworld.wolfram.com/HamiltonianCycle.html "Hamiltonian Cycle")
3. [P versus NP](https://en.wikipedia.org/wiki/P_versus_NP_problem "P versus NP")
4. [Hamiltonian Path](https://en.wikipedia.org/wiki/Hamiltonian_path "Hamiltonian Path")

# REPOSITORY

[https://github.com/ownlifeful/Graph-Undirected-Hamiltonicity](https://github.com/ownlifeful/Graph-Undirected-Hamiltonicity "github repository")

# AUTHOR


Ashwin Dixit &lt;ashwin at ownlifeful dot com&gt;


# COPYRIGHT AND LICENSE


This software is copyright (c) 2016-2021 by Ashwin Dixit.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
