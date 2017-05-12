# This is a documentation package so return 0 if it is used.

0;

__END__

=head1 NAME

List::Analyse::Sequence::Analyser - Define a sequence to look for.

=head1 DESCRIPTION

This is a namespace for analysers to use in List::Analyse::Sequence.
That module will call new() on each analyser it is told to use, and then
iterate over its analysers, asking whether a particular item fits in 
the list. Then it will call done() on each one, in case the sequence
involves collating all data first.

Any analyser that returns false from analyse() at any point will not
be checked again in that sequence.

=head1 USAGE

Create a module in this namespace and provide:

=head2 new

A new() method to return an instance. Analysers are assumed to be objects
because it is likely they will want to maintain state.

=head2 analyse

An analyse method that will accept a single scalar and return true 
if the scalar is part of their sequence definition; or else false.
Return a true value if you do not want to analyse until you have all the
data, because your analyser will not be called again if you ever return
false.

=head2 done

This method is called when the user asks for the results of their sequence
analysis, and should return true if the sequence passes the test and false
otherwise.
