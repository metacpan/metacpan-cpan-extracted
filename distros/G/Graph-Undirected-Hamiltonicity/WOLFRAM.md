
# Verification via the Wolfram Cloud

## Description

The optional module, `Graph::Undirected::Hamiltonicity::Wolfram` lets you determine
the Hamiltonicity of a given undirected graph, by evaluating the graph in the
Wolfram Open Cloud, using a built-in function of the Wolfram Programming Language.
This feature is quite useful in cross-checking the result you get from the algorithm
implemented in this Perl distribution.

## Synopsis

    use Graph::Undirected::Hamiltonicity::Wolfram;

    if ( is_hamiltonian_per_wolfram( $g ) ) {
        say "The graph contains a Hamiltonian Cycle.";
    } else {
        say "The graph does not contain a Hamiltonian Cycle.";
    }

## Installation

**Step 1:** Go to the [Wolfram Programming Lab](https://lab.wolframcloud.com/app/ "Wolfram Programming Lab").

**Step 2:** Create a Wolfram ID ( if you don't have one ).

**Step 3:** Sign in, and click "Create a New Notebook"

**Step 4:** In the Wolfram notebook, paste in the following code and evaluate it:

    CloudDeploy[ APIFunction[ {"x" -> "String"}, ( Length[ FindHamiltonianCycle[ Graph[ ToExpression[ StringSplit[ StringReplace[ #x, "=" -> "<->" ], "," ]]], 1 ]]  & ), "JSON"]]

**Step 5:** The output will be a cloud object with a URL. Copy just the URL.

    CloudObject[https://www.wolframcloud.com/objects/194a2864-c60b-4925-9ec0-1c51c2b64984]


**Step 6:** Copy the `hamilton.ini` file to your home directory.

    cp hamilton.ini $HOME

**Step 7:** Edit the copy of `hamilton.ini` you made in your home directory. ( `$HOME/hamilton.ini` )

**Step 8:** Find the `[wolfram]` section and paste in the URL copied from the Wolfram notebook:

Before:

    [wolfram]
    url =

After:

    [wolfram]
    url = https://www.wolframcloud.com/objects/194a2864-c60b-4925-9ec0-1c51c2b64984

## Notes

**1.** The Cloud Object you created in step 5, will expire after a month. You will then have to repeat steps 3-8.
