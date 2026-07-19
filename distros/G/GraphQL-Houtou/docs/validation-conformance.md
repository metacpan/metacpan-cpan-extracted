# Executable document validation conformance

Baseline: [GraphQL Specification, September 2025, section 5](https://spec.graphql.org/September2025/#sec-Validation).

GraphQL::Houtou validates executable documents in XS. The public Perl module
is only a facade; validation does not perform a second Pure Perl AST walk.
The table below is the implementation index for every stable
executable-document rule in the baseline specification. The named subtests are
the primary regression entry points; each contains multiple valid and invalid
documents rather than claiming that a filename alone is exhaustive evidence.

| Specification rule | Status | Primary coverage |
| --- | --- | --- |
| Executable Definitions | implemented | `t/08_validation.t` |
| Operation Type Existence | implemented | `t/08_validation.t` |
| Operation Name Uniqueness | implemented | `t/08_validation.t` |
| Lone Anonymous Operation | implemented | `t/08_validation.t` |
| Subscription Single Root Field | implemented | `t/08_validation.t` |
| Field Selection Merging | implemented | `t/08_validation.t` |
| Leaf Field Selections | implemented | `t/08_validation.t` |
| Field Selections on Objects, Interfaces, and Unions | implemented | `t/08_validation.t` |
| Fragment Name Uniqueness | implemented | `t/08_validation.t` |
| Fragment Spread Target Defined | implemented | `t/08_validation.t` |
| Fragments on Composite Types | implemented | `t/08_validation.t` |
| Fragments Must Be Used | implemented | `t/08_validation.t` |
| Fragment Spreads Must Not Form Cycles | implemented | `t/08_validation.t` |
| Fragment Spread Is Possible | implemented | `t/08_validation.t` |
| Argument Names | implemented | `t/08_validation.t` |
| Argument Uniqueness | implemented | `t/08_validation.t` |
| Required Arguments | implemented | `t/08_validation.t` |
| Values of Correct Type | implemented | `literal shape and non-null values are validated in XS`; `non-null list wrappers validate compiled schema types`; `t/33_oneof_input_objects.t` |
| Input Object Field Names | implemented | `t/08_validation.t` |
| Input Object Field Uniqueness | implemented | `t/08_validation.t` |
| Input Object Required Fields | implemented | `t/08_validation.t` |
| Directives Are Defined | implemented | `t/08_validation.t` |
| Directives Are in Valid Locations | implemented | `t/08_validation.t` |
| Directives Are Unique per Location | implemented | `t/08_validation.t` |
| Variable Uniqueness | implemented | `t/08_validation.t` |
| Variables Are Input Types | implemented | `t/08_validation.t` |
| All Variable Uses Defined | implemented | `t/08_validation.t` |
| All Variables Used | implemented | `t/08_validation.t` |
| All Variable Usages Are Allowed | implemented | `t/08_validation.t` |

Parser-only syntax rules, schema type-system validation, runtime variable
coercion, and result coercion have separate test suites. Experimental
incremental delivery is outside the 0.01 feature set; unknown `@defer` and
`@stream` directives are rejected like any unsupported service directive.

Performance characteristics:

- document, selection, value, directive, and usage passes are implemented in XS;
- name and duplicate checks use Perl HV lookup (average O(1) per item);
- fragment traversal uses visited sets to terminate cycles;
- identical merge candidates collapse before recursive comparison;
- cached compiled programs bypass document validation.
