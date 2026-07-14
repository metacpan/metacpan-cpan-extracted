# Contributing to Digest::xxHash

First off, thank you for considering contributing! Digest::xxHash is a Perl XS
wrapper around the [xxHash](https://github.com/Cyan4973/xxHash) library, and we
value high-quality, well-researched technical contributions. We welcome
submissions of all kinds, from documentation fixes to the implementation of
support for new hash variants.

## Code of Conduct

This project and everyone participating in it is governed by our
[Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to
uphold this code.

## How to Contribute

We use a standard GitHub fork-and-pull-request workflow.

1.  **Find or Create an Issue**: Before starting significant work, please check
    the [issue tracker](https://github.com/sanko/digest-xxhash/issues) to see if
    there's an existing issue for what you want to do. If not, please create one
    to start a discussion. This ensures that your proposed change aligns with the
    project's goals before you invest time in it.
2.  **Fork the Repository**: Start by forking the main repository to your own
    GitHub account.
3.  **Create a Branch**: Create a new branch for your feature or bugfix from the
    `main` branch. Please use a descriptive name.

    ```bash
    # For a new feature:
    git checkout -b feature/add-xxh3-avx2-support
    # For a bug fix:
    git checkout -b fix/streaming-digest-returns
    ```

4.  **Make Your Changes**: Write your code. Please adhere to the existing coding
    style and add comments to new or complex logic.
5.  **Test Your Changes**: A pull request is far more likely to be accepted if it
    includes tests. If you add new functionality, please add a corresponding test
    case. Run the full suite before submitting:

    ```bash
    perl Build && perl Build test
    ```

6.  **Update the Changelog**: Add an entry to the `[Unreleased]` section of
    `Changes` describing your change.
7.  **Submit a Pull Request**: Push your branch to your fork and open a pull
    request against the `main` branch of the original repository. Please provide
    a clear description of your changes and link to the relevant issue
    (e.g., `Fixes #123`).

## Development Setup

```bash
git clone https://github.com/sanko/digest-xxhash.git
cd digest-xxhash
git submodule update --init --recursive
cpanm --installdeps .
perl Build.PL
perl Build
perl Build test
```

## Style

- Follow the existing code conventions. The project uses `perltidy` for
  formatting (see `.tidyallrc`).
- XS code should follow the conventions already present in `xxHash.xs`.
- Perl modules follow standard CPAN conventions.
