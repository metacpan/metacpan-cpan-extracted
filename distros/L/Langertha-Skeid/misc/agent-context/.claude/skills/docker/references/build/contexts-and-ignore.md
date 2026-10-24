# Build contexts, ignore rules, and remote inputs

> Read when: a build sends too much data, cannot COPY a file, or risks exposing credentials.

The build context is the source tree the builder can access; it is not necessarily the directory containing the Dockerfile. `docker build -f docker/Dockerfile .` uses the current directory as context. `COPY ../secret ...` is not a supported way to escape that boundary.

Review `.dockerignore` as a security and reproducibility input. Exclude VCS metadata, local dependencies, editor state, test outputs, caches, credentials, and unrelated data. An allowlist can be appropriate for a small service, but must retain all runtime/build inputs. Dockerfile-specific ignore files can alter which patterns apply; test the actual Dockerfile/context pair.

```dockerignore
.git
.env
.env.*
!.env.example
**/__pycache__
**/*.pyc
node_modules
secrets
artifacts
```

This example is a starting point, not a complete secret detector. Secrets embedded in permitted source files remain permitted. Do not use diagnostic commands that print secret files to “check the context.”

## Named and remote contexts

Named contexts separate independently supplied inputs from the default source tree. Give them explicit names and pin remote source revisions. Remote Git URLs, Dockerfile frontend images, base images, and package repositories are independent supply-chain inputs. Document which credentials are pre-flight context access and which are available only to `RUN` instructions.

## Investigation sequence

Confirm the shell working directory; inspect CLI `-f` and context argument; identify the builder; review applicable ignore files; reproduce a minimal `COPY`; then inspect build output for transfer size. A remote daemon does not mean every build uses the remote daemon's filesystem. Conversely, runtime bind mounts do refer to the daemon host.

For untrusted repository builds, keep credentials and writable shared caches out of the execution environment. A Dockerfile can deliberately transmit any secret granted to it even when a secret mount leaves no layer behind.

## Primary sources

- [Build context](https://docs.docker.com/build/concepts/context/)
- [Build secrets](https://docs.docker.com/build/building/secrets/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
