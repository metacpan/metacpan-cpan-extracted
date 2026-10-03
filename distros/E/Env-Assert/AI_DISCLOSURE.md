# AI Disclosure Statement

## Overview

This project uses AI-assisted development tools as part of its
engineering workflow. This document describes how AI is used, what
safeguards are in place, and what downstream users and contributors
should know.

## AI Tools Used

AI tools used during development have included, but are not limited
to, Claude AI, Copilot and Gemini.
This list may not be comprehensive as tools and workflows evolve
over time.

## Nature of AI Use

AI assistance has been or may be used for the following activities:

- **Code generation** - writing new code for the module and the
  executable, including subroutines, data structures, and logic.
- **Documentation** - drafting and refining POD documentation,
  README content, and inline comments.
- **Architectural design** - exploring design alternatives, evaluating
  trade-offs, and structuring the module interface.
- **Test generation** - creating test cases and test scaffolding.
- **Debugging and troubleshooting** - diagnosing issues, analysing
  error output, and suggesting fixes.
- **Refactoring** - restructuring existing code for clarity,
  performance, or maintainability.

## Human Review and Oversight

All AI-generated or AI-assisted output has been reviewed, understood,
tested, and where necessary modified by a human developer before being
committed to the repository. No code or documentation has been
committed as raw, unreviewed AI output.

This project does not engage in so-called "vibe coding", where AI
output is accepted without understanding or verification.

## Intellectual Property and Licensing

The copyright status of AI-generated code is legally unsettled in most
jurisdictions as of this writing. Users and distributors should be
aware of this uncertainty and assess their own risk accordingly.

The author(s) have made a good-faith effort to ensure that AI tools
were not used in a way that knowingly infringes on third-party
intellectual property. However, no guarantee can be made that
AI-generated output is free from similarity to existing copyrighted
code.

## Ethical Considerations

This project favours AI tools whose developers have made reasonable
efforts toward responsible and transparent data practices. This
includes, but is not limited to, consideration of how training data
was acquired, whether creators and rights holders were respected in
that process, and whether the tool provider is transparent about
their data sourcing and labour practices.

We acknowledge that full visibility into the training data and
practices of any AI provider is not currently possible from the
outside. This is a good-faith commitment to prefer tools that align
with ethical principles, not a guarantee that every tool used meets
any particular standard. As industry norms, transparency, and
available information evolve, so will our assessment of which tools
are appropriate.

## Scope

AI assistance has been used throughout the development process rather
than being confined to specific files or modules. It is not practical
to annotate individual lines or sections as "AI-generated" versus
"human-written", because most code has been iteratively developed
with a mix of both.

## Contributor Expectations

Contributors to this project are expected to:

- Disclose if they have used AI tools in preparing their contribution.
- Ensure all submitted code has been reviewed, understood, and tested
  by the contributor.
- Not submit raw, unreviewed AI output.
- Consider the ethical implications of their choice of AI tools,
  particularly regarding how the tool's model was trained and whether
  its data sourcing practices are consistent with respect for
  creators and rights holders.
- Be prepared to identify which AI tools were used if asked.

## Contact

If you have questions about AI usage in this project, please open an
issue or contact the maintainer at Mikko Koivunalho <mikkoi@cpan.org>.

---

*This disclosure is provided voluntarily in the interest of
transparency. It will be updated as the project evolves and as
norms around AI-assisted development continue to develop.*
