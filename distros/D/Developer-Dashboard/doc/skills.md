# Skills Documentation

The long-form skill authoring guide lives in [`../SKILL.md`](../SKILL.md).

Use it when you need:

- how `dashboard skills install` accepts Git URLs and qualified local checked-out skill directories
- that repeated `dashboard skills install ...` calls reinstall or refresh the installed isolated copy
- the expected skill directory structure
- the meaning of each folder
- the skill CLI and `cli/<command>.d/` hook model, including `RESULT`, `LAST_RESULT`, and `[[STOP]]`
- executable `.go` hook files running through `go run` and executable `.java` hook files compiling through `javac` before they run through `java`
- the difference between skill-local commands and dashboard-wide custom CLI hooks
- bookmark syntax, bookmark browser helpers, and route details
- app-style skill routes such as `/app/<repo-name>` and `/app/<repo-name>/<page>`
- underscored config merge keys such as `_<repo-name>`
- `aptfile`-before-`cpanfile` dependency bootstrap and skill docker layering
- current limitations of skill bookmark routes versus normal saved runtime bookmarks

The shipped POD version of the same topic lives in
`Developer::Dashboard::SKILLS`.
