
# User Guide

## 1. Overview

This guide explains how to use the hierarchical extractor built on GraphViz2::Marpa. It focuses on practical usage: how to run the extractor, how to interpret the output, and how to integrate it into workflows.

The extractor converts DOT input into a structured internal representation, called the IR. The IR is deterministic, explicit, and suitable for CI and tooling.


## 2. Basic Usage

The extractor takes DOT text as input. You provide a file or string containing a graph definition. The extractor parses it, normalizes it, and returns a structured representation.

Typical steps:
1. load DOT text,
2. call the extractor,
3. receive the IR as a Perl structure or serialized form.

The IR always contains explicit nodes, edges, subgraphs, and attributes.

## 3. What the Extractor Guarantees

The extractor ensures:
- deterministic ordering,
- explicit nodes and edges,
- merged attributes,
- stable subgraph hierarchy,
- complete symbol tables.

This means the same DOT always produces the same IR, which is essential for reproducible builds and CI.


## 4. Understanding the IR

The IR is a nested structure representing:
- the root graph,
- its subgraphs,
- nodes,
- edges,
- attributes,
- symbol tables.

Each graph or subgraph contains lists of nodes, edges, and child subgraphs. Each node and edge has a final attribute map.


## 5. Nodes and Edges

Nodes are identified by stable ids. If a node appears only in an edge, it is auto‑declared.

Edges always appear explicitly in the IR. If DOT uses chain syntax, the extractor expands it into individual edges and may attach chain metadata such as chain position.


## 6. Subgraphs

Subgraphs form a tree. Each subgraph has:
- an id,
- attributes,
- its own nodes and edges,
- child subgraphs.

Anonymous subgraphs receive stable generated ids. Subgraphs inherit defaults from their parents.


## 7. Attribute Behavior

Attributes may appear at multiple levels in DOT. The extractor merges them into a final map for each node and edge.

Defaults from graph and subgraph scopes are applied first. Explicit attributes override inherited ones. The IR stores only the final merged result.


## 8. CI and Workflow Integration

The IR is ideal for CI:
- serialize it,
- commit it as a golden file,
- compare it on each run.

If the IR changes unexpectedly, CI can flag the difference. This makes the extractor suitable for stable documentation, dependency graphs, and layout pipelines.

