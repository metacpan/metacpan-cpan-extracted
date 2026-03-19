
# Constraints

## 1. Purpose
Constraints describe semantic rules that apply to graphs, subgraphs, nodes, or edges. They are not DOT attributes; they are annotations used for validation, CI, or layout‑aware tooling.

## 2. Types of Constraints
Common categories:
- structural constraints: no cycles, required nodes, forbidden edges
- grouping constraints: nodes must belong to specific subgraphs
- boundary constraints: edges must not cross certain subgraphs
- degree constraints: minimum or maximum incoming or outgoing edges
- layout constraints: alignment, grouping, ordering hints

## 3. Structure of a Constraint
Each constraint is a structured object with:
- kind: the rule type
- scope: graph, subgraph, node, or edge
- target: the entity the rule applies to
- meta: optional fields such as severity or notes

## 4. Attachment Points
Constraints may be attached to:
- the root graph
- any subgraph
- individual nodes
- individual edges

They are stored in a list within the IR and preserved during serialization.

## 5. Validation Workflow
A validator or CI step evaluates constraints by:
1. scanning the IR
2. locating constraint targets
3. checking rule conditions
4. reporting violations

The extractor does not enforce constraints; it only records them.

## 6. CI Integration
Constraints allow automated checks such as:
- preventing regressions in dependency graphs
- enforcing architectural boundaries
- ensuring required nodes or edges exist

Violations can fail CI or produce structured reports.

End of constraints.
