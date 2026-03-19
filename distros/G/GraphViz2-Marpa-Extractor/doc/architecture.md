

# GraphViz2::Marpa Hierarchical Extraction & Rendering Architecture

## 1. Overview

This system provides a production‑grade pipeline for:

- Parsing DOT using GraphViz2::Marpa.
- Extracting a rich, hierarchical graph IR.
- Performing validation, analysis, and transformation.
- Rendering or exporting to layout engines (e.g. GraphViz, libcola, custom).

The core design goal is to separate **parsing**, **semantics**, **constraints**, and **rendering** into clean, composable layers.

---

## 2. Major components

### 2.1 DOT parser

- **Responsibility:** Turn DOT text into an AST.
- **Implementation:** GraphViz2::Marpa.
- **Output:** Perl data structure with `name`, `attributes`, `daughters`, etc.

The parser is treated as a black box; all semantics are handled downstream.

### 2.2 Hierarchical extractor

- **Module:** `GraphViz2::Marpa::HierExtractor`.
- **Responsibility:** Convert the AST into a structured graph IR.
- **Key features:**
  - Supports graphs, subgraphs, clusters.
  - Handles edge chains, grouped RHS, grouped LHS.
  - Merges node/edge/graph defaults hierarchically.
  - Auto‑declares dangling nodes with `_auto_declared`.
  - Tracks node order (`node_order`) for deterministic output.
  - Builds adjacency and scoped adjacency.
  - Builds a flat view (`flat`) of nodes and edges.
  - Maintains a symbol table (`symbols`) for nodes, subgraphs, ports, attributes.

**Output structure (per graph):**

- `name`, `kind` (`graph`, `digraph`, `subgraph`, `cluster`)
- `attrs`
- `node_defaults`, `edge_defaults`
- `nodes` (hash), `node_order` (array)
- `edges` (array)
- `subgraphs` (array of same structure)
- `adjacency` (hash)
- `adjacency_scoped` (hash)
- `flat` (global nodes/edges)
- `symbols` (global symbol table)

### 2.3 Constraint extraction layer

- **Responsibility:** Derive layout‑relevant constraints from the IR.
- **Inputs:**
  - Subgraph attributes (`rank`, `label`, etc.).
  - Cluster names (`cluster_*`).
  - Edge attributes (`minlen`, `constraint`, `weight`, `style`).
- **Outputs:**
  - `constraints` structure attached to the graph:
    - rank groups
    - cluster membership and padding
    - separation preferences
    - visibility/importance flags

This layer is layout‑engine‑agnostic.

### 2.4 Transformation pipeline

- **Responsibility:** Apply transformations to the IR:
  - Node/edge renaming.
  - Subgraph collapsing or expansion.
  - Attribute normalization.
  - Schema‑driven rewrites.

Transformations are pure functions: IR in, IR out.

### 2.5 Validation & diagnostics

- **Responsibility:** Check IR against rules:
  - Invalid compass points.
  - Dangling nodes (auto‑declared, flagged).
  - Duplicate edges (optional).
  - Attribute schema violations.

Produces warnings/errors, optionally attached to nodes/edges.

### 2.6 Renderers

- **Responsibility:** Consume the IR (and constraints) and:
  - Emit DOT.
  - Drive GraphViz.
  - Drive libcola.
  - Or log operations (debug renderer).

Renderers are pluggable and operate on the IR, not on raw DOT.

---

## 3. Data flow

1. **DOT text → AST**  
   `GraphViz2::Marpa` parses DOT into an AST.

2. **AST → IR**  
   `HierExtractor` walks the AST and builds the hierarchical IR.

3. **IR → constraints**  
   Constraint extractor derives rank/cluster/separation semantics.

4. **IR → transforms (optional)**  
   Transform pipeline modifies the IR as needed.

5. **IR + constraints → renderer**  
   Renderer produces visual output or serialized formats.

---

## 4. Extensibility

- New validators can be added without touching the extractor.
- New renderers can be added without touching parsing or extraction.
- New transformations can be composed in a pipeline.
- The IR is stable and documented, enabling external tools to integrate.

---

## 5. Non‑goals

- Re‑implementing DOT parsing (delegated to GraphViz2::Marpa).
- Hard‑wiring to a single layout engine.
- Mixing parsing, semantics, and rendering in one layer.

The architecture is intentionally layered to support long‑term evolution.


## 5. Graph and Subgraph Representation

Each graph or subgraph contains:

- **id** — stable identifier (DOT name or synthesized).
- **kind** — `graph`, `digraph`, or `subgraph`.
- **attributes** — merged attribute map.
- **nodes** — ordered list of node references.
- **edges** — ordered list of edge references.
- **subgraphs** — ordered list of child subgraphs.
- **parent** — reference to parent graph/subgraph.

Subgraphs are first‑class IR objects with the same structure as the root graph.

## 6. Node Representation

Each node has:

- **id** — canonical identifier.
- **attributes** — final merged attributes.
- **owner** — graph/subgraph that contains it.
- **kind/role** (optional) — semantic classification.

Nodes may be **auto‑declared** if referenced only in edges.

## 7. Edge Representation

Each edge has:

- **from**, **to** — node ids.
- **attributes** — merged attributes.
- **owner** — graph/subgraph where it appears.
- **chain metadata** (optional):
  - chain id,
  - chain position.

Edges are always explicit in the IR, even if DOT uses chain syntax.

## 8. Attribute Handling and Merging

DOT allows attributes at multiple levels:

- graph defaults,
- node defaults,
- edge defaults,
- per‑entity attributes.

The extractor:

1. collects defaults at each scope,
2. merges inherited attributes,
3. applies explicit attributes last,
4. stores only the **final merged map**.

Optional provenance tracking can record where each attribute came from.

## 9. Deterministic Ordering

Ordering rules ensure reproducibility:

- **Subgraphs**  
  Ordered by appearance; ties broken by id.

- **Nodes**  
  Either appearance order or sorted by id (configurable).

- **Edges**  
  Appearance order or sorted by `(from, to, chain_pos)`.

Once chosen, ordering rules are applied consistently.

## 10. Symbol Table

The extractor builds a global symbol table:

- node id → node object  
- subgraph id → subgraph object  
- optional edge indices

This enables:

- fast lookup,
- validation,
- detection of dangling references,
- consistent auto‑declaration.

The symbol table is part of the IR, not an external cache.


## 11. Subgraph Handling and Recursion

Subgraphs are processed recursively:

- create subgraph object,
- attach to parent,
- inherit defaults,
- process nodes/edges inside,
- recurse into nested subgraphs.

Anonymous subgraphs receive stable synthesized ids (`__subgraph_1`, etc.).

## 12. Implicit and Auto‑Declared Nodes

If an edge references a node not explicitly declared:

- the extractor creates the node,
- assigns it to the appropriate graph/subgraph,
- applies defaults,
- registers it in the symbol table.

This guarantees a complete, explicit IR.

## 13. Chain Parsing

DOT chains like:

a -> b -> c -> d [color=red];



are normalized into:

- explicit edges,
- shared attributes applied to each edge,
- optional chain metadata:
  - chain id,
  - chain position.

This supports layout engines and path‑based analysis.


## 14. Constraint Model

Constraints are semantic annotations attached to:

- graphs,
- subgraphs,
- nodes,
- edges.

Examples:

- no cycles in a subgraph,
- node must have incoming edges,
- edge must not cross boundaries.

Constraints are stored as structured objects:

```perl
{
  kind   => 'no_cycle',
  scope  => 'subgraph',
  target => 'cluster_core',
  meta   => { severity => 'error' },
}

15. Layout and Rendering Integration
The IR is layout‑aware:

preserves layout‑relevant attributes,

keeps subgraph boundaries explicit,

supports layout hints (alignment, grouping, compactness),

can serialize back to DOT or JSON for layout engines.

Layout is a consumer of the IR, not part of extraction.



---

# **[ARCH 6/8]**
## 16. Error Handling and Robustness

The extractor handles:

- malformed DOT,
- conflicting attributes,
- invalid references.

Strategy:

- parsing errors → clear messages,
- normalization errors → structured exceptions,
- non‑fatal issues → diagnostics array.

The IR is emitted only if internally consistent.

## 17. CI and Reproducibility

The architecture is CI‑friendly:

- deterministic ordering,
- stable serialization,
- small diffs for small changes,
- golden‑file comparison workflow.

Typical CI pattern:

1. run extractor,
2. serialize IR,
3. compare with committed IR,
4. fail on mismatch.


## 18. Extensibility and Plugin Points

The IR supports:

- new node/edge kinds,
- new attributes,
- custom constraints,
- post‑processing passes,
- validation layers.

Post‑processors operate as pure functions:  
IR in → IR out.

## 19. Implementation Layering

Layers:

1. parser wrapper,
2. normalizer,
3. IR utilities,
4. post‑processors,
5. serializers.

Each layer is isolated and testable.

## 20. Order‑Preserving Traversal

Canonical traversal:

- depth‑first subgraph walk,
- nodes in IR order,
- edges in IR order.

Consumers may sort differently, but canonical order is stable.


## 21. Naming Conventions

- node ids: DOT ids, normalized if needed,
- subgraph ids: DOT names or synthesized stable names,
- chain ids: stable, derived from appearance order.

## 22. Example IR Sketch

```perl
{
  id         => 'G',
  kind       => 'digraph',
  attributes => { rankdir => 'LR' },

  nodes => [
    { id => 'A', attributes => { shape => 'box' }, owner => 'G' },
    { id => 'B', attributes => { shape => 'ellipse' }, owner => 'G' },
  ],

  edges => [
    {
      from       => 'A',
      to         => 'B',
      attributes => { color => 'red', chain_id => 'chain_1', chain_pos => 1 },
      owner      => 'G',
    },
  ],

  subgraphs => [
    {
      id         => 'cluster_core',
      kind       => 'subgraph',
      attributes => { label => 'Core' },
      nodes      => [ ... ],
      edges      => [ ... ],
      subgraphs  => [ ... ],
      parent     => 'G',
    },
  ],

  symbols => {
    nodes     => { A => $node_a, B => $node_b },
    subgraphs => { cluster_core => $sg_core },
  },

  constraints => [
    {
      kind   => 'no_cycle',
      scope  => 'subgraph',
      target => 'cluster_core',
      meta   => { severity => 'error' },
    },
  ],
}
```

23. Summary
The extractor is:

deterministic,

explicit,

hierarchical,

symbol‑rich,

constraint‑aware,

CI‑friendly,

extensible.

It transforms DOT into a clean, reproducible IR suitable for tooling, validation, and layout.

