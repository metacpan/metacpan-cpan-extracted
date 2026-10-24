# Application-aware backup and disaster recovery

> Read when: protecting named volumes or preparing an upgrade/recovery test.

A container image is not a backup of a mounted database. A volume snapshot taken during writes is not automatically application-consistent. Separate image recovery, configuration recovery, credential recovery, and persistent-data recovery.

## Backup design

For each data owner, choose the application's supported dump/snapshot mechanism and record required quiescence or transaction/WAL coordination. Store backups off the failure domain, encrypt sensitive material, retain version and checksum metadata, and test restore. A generic `tar` of an actively changing database directory is not a universal procedure.

A backup record should include service/data-format version, image digest, volume mapping, backup tool version, time, consistency method, encryption/key reference, and recovery dependencies. Keep the key recovery process separate from the encrypted backup location.

## Restore drill

Create new isolated volumes and a new project identity. Restore there, apply correct ownership, start a compatible application version, and run integrity/application checks. Prove a known record or object can be read. Verify external dependencies and authentication. Measure actual recovery time; a successful archive listing is not a restore test.

Keep the old live volume untouched until a reviewed cutover. Do not launch two writers against the same state while testing. If promotion changes DNS or credentials, include their rollback and cache-expiry behavior in the plan.

## Upgrade checkpoint

Before a major application or storage-backend change, confirm that the last backup can be restored with the target recovery procedure. Write the schema-compatibility/rollback boundary explicitly. Volume survival through `docker compose down` only describes object lifetime; it provides no protection against host loss, corruption, or an approved-but-mistaken `down -v`.

## Primary sources

- [Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Compose in production](https://docs.docker.com/compose/how-tos/production/)
- [Daemon configuration and data directories](https://docs.docker.com/engine/daemon/)
