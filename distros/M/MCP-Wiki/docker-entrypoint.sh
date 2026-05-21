#!/bin/bash
set -e

WIKI_DIR="/wiki"

# Get UID/GID of mounted wiki directory
if [ -d "$WIKI_DIR" ]; then
    MOUNT_UID=$(stat -c '%u' "$WIKI_DIR" 2>/dev/null || echo "1000")
    MOUNT_GID=$(stat -c '%g' "$WIKI_DIR" 2>/dev/null || echo "1000")
else
    MOUNT_UID=1000
    MOUNT_GID=1000
fi

# Create group and user with matching UID/GID if they don't match our default
if [ "$MOUNT_UID" != "1000" ] || [ "$MOUNT_GID" != "1000" ]; then
    echo "Adapting user to mounted volume UID:GID = $MOUNT_UID:$MOUNT_GID"
    groupadd --gid "$MOUNT_GID" appgroup 2>/dev/null || true
    useradd --uid "$MOUNT_UID" --gid "$MOUNT_GID" --create-home --shell /bin/bash appuser 2>/dev/null || true
    chown -R "$MOUNT_UID:$MOUNT_GID" "$WIKI_DIR"
fi

# Run the actual command as the appuser
exec su - appuser -c "PERL5LIB=$PERL5LIB /usr/local/bin/mcp-wiki $*"
