# Changelog

## v0.05

- Read and write files in raw mode, preserving line endings
- Use more efficient blank line regexp for processing JSONL files
- Improve memory efficiency of picking lines in streaming mode (S-Algorithm), we now only allocate one integer per picked line rather than per line in the dataset
- Add tests for Windows line endings
- Add `CHANGELOG.md`

## v0.04

- Add ability to select `lines` as well as `percent`

## v0.03

- Add MIT license
- Fix some poorly written tests
- Document `streaming` mode
