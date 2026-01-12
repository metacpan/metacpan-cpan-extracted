# This file defines a Docker image for a GreenMail test email server,
# configured for testing EMDIS::ECS (Perl ECS).
#
# For additional information about Docker, see https://www.docker.com/
#
# For additional information about GreenMail, see:
# http://www.icegreen.com/greenmail/
# https://github.com/greenmail-mail-test/greenmail
# https://hub.docker.com/r/greenmail/standalone/
#
# Below are brief notes about using this Dockerfile.
#
# 1) Move to the directory containing this Dockerfile.
#
#    cd docker/greenmail
#
# 2) Build "perlecs/greenmail" Docker image based on the Dockerfile.
#
#    docker build -t perlecs/greenmail:0.48-1 .
#
# 3) Generate a Docker container based on the image, and use it to run a
#    GreenMail server.
#
#    docker run --rm --name=perlecs_greenmail perlecs/greenmail:0.48-1
#
# 4) Get the IP address of the running GreenMail container, and use that,
#    along with the email users defined in GREENMAIL_OPTS below, to test
#    Perl ECS email communications.
#
#    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' perlecs_greenmail

# Image is based on greenmail/standalone.  See also:
# https://github.com/greenmail-mail-test/greenmail/blob/master/greenmail-docker/standalone/Dockerfile

FROM greenmail/standalone:2.1.8
LABEL Maintainer="Joel Schneider <joel@joelschneider.net>"
LABEL Description="GreenMail server for testing EMDIS::ECS (Perl ECS)"
LABEL Version="0.48"

# greenmail.setup.test.all configuration starts all default email services
# with a port offset of 3000
# - SMTP  : 3025
# - SMTPS : 3465
# - IMAP  : 3143
# - IMAPS : 3993
# - POP3  : 3110
# - POP3S : 3995
ENV GREENMAIL_OPTS="\
    -Dgreenmail.setup.test.all \
    -Dgreenmail.hostname=0.0.0.0 \
    -Dgreenmail.verbose \
    -Dgreenmail.users=admin:pass@perlecs.local,node_aa:pwaa@perlecs.local,node_bb:pwbb@perlecs.local,node_cc:pwcc@perlecs.local"

ENTRYPOINT ["/bin/sh", "-c", "/home/greenmail/run_greenmail.sh"]
