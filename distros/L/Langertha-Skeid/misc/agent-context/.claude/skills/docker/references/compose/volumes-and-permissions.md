# Compose storage, ownership, and persistence

> Read when: choosing mounts, changing image versions, or debugging missing data/permission failures.

A named volume is managed storage; a bind mount points at a host path; tmpfs is ephemeral memory-backed storage. Choose based on ownership, lifecycle, portability, backup method, and write patterns—not shorthand syntax.

A new empty named volume can be populated from existing image content at its mountpoint unless copy behavior is disabled. Once mounted, volume content shadows the image path. Updating the image therefore does not update files already stored there. A bind mount also obscures image content but is not automatically seeded in the same way.

Prefer long mount syntax for clarity. For bind mounts, consider `bind.create_host_path: false` so a typo fails rather than silently creating a directory where a file was expected. Inspect UID/GID, rootless/user-namespace mappings, SELinux labels, mount access mode, and filesystem behavior before changing permissions. `chmod -R 777` is not a diagnosis.

## Lifecycle contract

Ordinary `down` does not remove named volumes. `down -v` can delete Compose-managed named and attached anonymous volumes; external volumes have independent ownership. An anonymous volume surviving removal is not necessarily reattached on the next `up`. Use explicit names for data that must be recovered predictably.

When renaming a project or changing a volume key, confirm the intended existing volume is still selected. “The database is empty after deployment” can mean a new volume was mounted, not that the old data was erased. Inventory before cleanup.

## Upgrade procedure

Record actual mounted volume IDs, database/application format version, ownership, and a tested backup. Review image-specific data-path changes; do not substitute a generic mount location across major versions. Restore to a new volume and isolated stack for validation. An image rollback cannot undo an irreversible data migration. Deletion requires an explicit target list and confirmation separate from container recreation.

## Primary sources

- [Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Rootless mode](https://docs.docker.com/engine/security/rootless/)
