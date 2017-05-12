# Why use HPC::Runner ?

HPC-Runner-App optimizations your workflows by batching them and submitting
them as various jobs over an HPC cluster. It does this by completing the
following objectives:

1. Templates away your business logic - without the need to rewrite any
   of your existing analysis. 
2. Makes your workflows reproducible and easily shared.
3. Takes advantage of HPC resources by splitting your jobs into the
   components.
4. Total transparency - because the workflow itself is not rewritten,
   your workflow is transparent and easy understood by support staff.


## Template away your business logic

Many HPC submission wrappers require a user to rewrite their job into a
specific syntax. HPC-Runner-App borrows from the simple syntax of HPC
schedulers. There is no need to re engineer your code into python or complex
configuration files.

## Reproducible Workflows

Workflows are saved in a single file that is easily shared with collaborators.
Parameters can be changed with a simple text substitution.

## Make the best use of HPC resources

The logic of your workflows remains the same whether processing 1 or 1000
samples. HPC-Runner-App splits your workflow into efficient chunks, and lets
the scheduler take care of the rest.

## Total Transparency

Your code is passed to the scheduler and run as is. Everything is bash based
and uses standard templates. Trouble shooting your jobs and getting support
from your HPC admins becomes a straight forward task without the need to dig
through a separate layer of logic.
