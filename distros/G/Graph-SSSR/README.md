Graph::SSSR
===========

This is an implementation of Smallest Set of Smallest Rings (SSSR) finding algorithm based on [Perl `Graph` library](https://metacpan.org/pod/Graph).
Thus it should work with any `Graph::Undirected` object.
The code is largely taken from the [cod-tools](https://wiki.crystallography.net/cod-tools/) package.

The Smallest Set of Smallest Rings
----------------------------------

The algorithm returns a superset of minimum cycle basis of a graph in order to produce deterministic results.
As a result it does not succumb to the [counterexample of oxabicyclo[2.2.2]octane](https://depth-first.com/articles/2020/08/31/a-smallest-set-of-smallest-rings/) (section "SSSR and Uniqueness").
The algorithm has means to control the maximum size of rings included in the SSSR to reduce its complexity.
The default value of `undef` stands for no limit.
