
# Rendering

## 1. Purpose
This document explains how the IR produced by the extractor can be used for rendering with Graphviz or other layout engines. The extractor itself does not perform layout; it prepares clean, explicit data for downstream tools.

## 2. Rendering Workflow
Typical steps:
1. take the IR
2. serialize it to DOT or JSON
3. feed it to a layout engine
4. render to SVG, PNG, or other formats

The IR ensures stable ordering and explicit structure, which leads to predictable rendering.

## 3. DOT Serialization
When converting IR back to DOT:
- nodes and edges are emitted explicitly
- attributes are taken from the final merged maps
- subgraphs are emitted in hierarchical order
- ordering is deterministic for reproducible output

## 4. Layout Engines
The IR is compatible with:
- Graphviz (dot, neato, fdp, sfdp)
- libcola‑based engines
- custom layout systems

Subgraph boundaries, chain metadata, and attribute maps provide useful hints for layout algorithms.

## 5. Layout Hints
The IR may include layout‑related attributes such as:
- rank direction
- grouping or cluster labels
- edge weights
- chain positions
- alignment hints

These are preserved during serialization and interpreted by layout engines.

## 6. Post‑Layout Processing
After rendering, tools may:
- annotate the IR with positions
- detect crossings or violations
- generate reports or visual overlays

The IR structure makes these tasks straightforward.

End of rendering.
