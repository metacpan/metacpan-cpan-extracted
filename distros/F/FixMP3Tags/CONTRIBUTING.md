# 🤝 Contributing to FixMP3Tags

Thank you for your interest in contributing! Whether you're fixing bugs, improving documentation, testing with different MP3 files, or adding features — your help is welcome and appreciated.

---

## 📦 Project Scope

FixMP3Tags is a command-line tool for fixing and normalizing MP3 ID3 tags. It aims to be:

- Lightweight and dependency-minimal (core Perl + essential MP3 modules)
- Cross-platform (Linux, macOS, Windows with Perl)
- Destructive tag replacement, with a dry-run mode and backup guidance
- Flexible with user-defined patterns and rules

---

## 🧰 How to Contribute

### 🐛 Report Bugs
- Search [issues](https://github.com/vr-ski/fix-mp3-tags/issues) first to avoid duplicates
- Include:
  - OS and Perl version (`perl -v`)
  - MP3 file examples (if possible)
  - Steps to reproduce
  - Error messages or unexpected behavior

### ✨ Suggest Features
- Open an issue with a clear description
- Explain the use case and why it's valuable
- Bonus: suggest how it could be implemented

### 🛠️ Submit Code
1. Fork the repo
2. Create a new branch (`feature/my-feature` or `fix/my-bug`)
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request with a clear summary

### 📚 Improve Docs
- Typos, formatting, or clarity improvements are always welcome
- You can edit `README.md`, `CONTRIBUTING.md`, or add new docs
- Help improve POD documentation in the modules

### 🎵 Test with Different MP3 Files
- Test with various MP3 encodings and ID3 tag versions
- Report compatibility issues
- Share test files (if possible) or detailed descriptions

---

## 🧪 Development Setup

```bash
git clone https://github.com/vr-ski/fix-mp3-tags.git
cd fix-mp3-tags

# Install dependencies
cpanm --installdeps .

# Run tests
make test

# Or directly with prove
prove -l t/

# Test the script
perl -Ilib bin/fix-mp3-tags --help
```

For development with a local Perl environment:

```bash
# Using perlbrew (recommended)
perlbrew install perl-5.36.0
perlbrew switch perl-5.36.0

# Using plenv
plenv install 5.36.0
plenv global 5.36.0
```

---

## 🧼 Code Style

This project uses:

- **Perl Best Practices**: Follows Perl::Critic standards (see `.perlcriticrc`)
- **Automatic Formatting**: Uses `perltidy` (see `.perltidyrc`)
- **Code Quality**: Enforced with pre-commit hooks (see `.pre-commit-config.yaml`)

### Before submitting:
```bash
# Format code
perltidy lib/**/*.pm bin/fix-mp3-tags

# Check code quality
perlcritic lib/**/*.pm bin/fix-mp3-tags

# Run tests
make test

# Or run specific tests
prove -lv t/01-processor.t
```

### Key Style Points:
- Use strict and warnings in all files
- Follow Perl Best Practices (Damian Conway)
- Write tests for new functionality
- Add POD documentation for new modules/methods
- Keep functions focused and single-purpose

---

## 🧪 Testing

### Running Tests:
```bash
# Basic test suite
make test

# With verbose output
prove -lv t/

# Specific test file
prove -lv t/02-user-patterns.t

# Test coverage (if Devel::Cover installed)
cover -test
```

### Adding Tests:
- New features should include tests in `t/`
- Test both success and failure cases
- Use `Test::More` for new test files
- Consider edge cases with different MP3 formats

---

## 📦 Release Process

For maintainers:

1. Update `$VERSION` in `lib/FixMP3Tags/Processor.pm`
2. Update `Changes` file with release notes
3. Commit and tag: `git tag -a v0.02 -m "Release 0.02"`
4. Push tags: `git push --tags`

---

## 📄 License and Attribution

By contributing, you agree that your code will be released under the BSD 2-Clause License.

This project builds upon the Perl ecosystem and MP3::Tag library. Special thanks to all the CPAN contributors whose modules make this tool possible.

---

## 🙌 Thank You

Your contributions help make this tool more reliable and useful for everyone. If you've tested this with different MP3 files, tag formats, or operating systems, please share your experience!

---

## 🔍 Need Help?

- Check existing issues and discussions
- Review the Perl documentation: `perldoc perlintro`
- MP3::Tag documentation: `perldoc MP3::Tag`
- Open an issue for questions about the codebase

*Happy hacking! 🎵*
