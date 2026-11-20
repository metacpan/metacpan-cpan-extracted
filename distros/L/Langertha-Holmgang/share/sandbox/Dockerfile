# The image of Langertha::Holmgang::Sandbox::Docker: the Debian 12 the Linux
# simulator plays, with the real programs a simulated command may fall back to.
#
#   docker build -t langertha-holmgang-sandbox:1 share/sandbox
#
# A run names the image by tag; pin the digest in the run's notes, because the
# output of a real program is part of the measurement.
FROM debian:12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-yaml perl gawk jq openssl faketime bsdextrautils ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /usr/bin/awk /etc/alternatives/awk && ln -s /usr/bin/mawk /usr/bin/awk
