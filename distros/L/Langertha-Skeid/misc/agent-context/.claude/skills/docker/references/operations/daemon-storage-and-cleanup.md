# Daemon storage, disk accounting, and safe cleanup

> Read when: moving Docker data or reclaiming space.

Inventory before deleting: image content, container writable layers, volumes, logs, BuildKit caches, and the underlying filesystem can each dominate disk use. `docker system df` is useful but not a complete filesystem audit; also examine available bytes, inodes, and builder-specific usage.

Docker's classic storage layout and the containerd image store differ. With the containerd store, image content/snapshots can live under `/var/lib/containerd` while other daemon state remains under `/var/lib/docker`. Setting `data-root` does not automatically relocate all containerd data. On Desktop, storage is mediated through a VM; do not apply Linux host paths directly to Windows/macOS.

## Migration plan

Identify the active daemon and containerd configuration, back up stateful volumes using application-aware procedures, stop relevant writers, preserve permissions/xattrs, and follow a version/backend-specific move procedure. Never point two live daemons at the same data directory. Validate both existing images and persistent data after the move, and retain a rollback copy until recovery is proven.

Do not manually remove files under Docker/containerd content stores to reclaim space. Their metadata and content references are coupled. Use supported deletion/prune interfaces after an explicit inventory and ownership review.

## Cleanup classes

Remove an identified stopped disposable container rather than issuing global prune. Separate build-cache retention from image-retention policy. A dangling image is not the same as an unused image, and an unused image may be a rollback artifact. A detached volume can be a needed database backup.

For a destructive change, present resource IDs/names, estimated effect, ownership, last use, backup status, and exact deletion command before approval. A label filter helps selection but is not authorization; verify the resulting set. Follow cleanup with disk measurement and a retention fix so the same incident does not recur.

## Primary sources

- [Daemon configuration and data directories](https://docs.docker.com/engine/daemon/)
- [Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Cache backends](https://docs.docker.com/build/cache/backends/)
