

APP_JAVA_OPTS="\
    -Dfile.encoding=UTF8 \
    -Djava.awt.headless=true \
    -Duser.timezone=GMT \
    -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false \
    -Djava.net.preferIPv4Stack=true\
    "

MEMORY_JAVA_OPTS="\
    -Xms256m \
    -Xmx512m \
    "

SERVLET_OPTS="\
    -Dorg.apache.el.parser.COERCE_TO_ZERO=false \
    "

SSL_JAVA_OPTS="\
    -Djavax.net.ssl.trustStore=/opt/pastdev/foo-tomcat/certs/truststore.jks \
    -Djavax.net.ssl.trustStoreType=JKS \
    -Djavax.net.ssl.trustStorePassword=password \
    "

JMX_OPTS="\
    -Dcom.sun.management.jmxremote \
    -Dcom.sun.management.jmxremote.port=8587 \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.authenticate=false \
    "

JPDA_OPTS="\
    -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8586 \
    "

CATALINA_OPTS=$JMX_OPTS
CATALINA_PID=/var/run/foo/catalina.pid
JAVA_OPTS="$JAVA_OPTS $MEMORY_JAVA_OPTS $APP_JAVA_OPTS $SSL_JAVA_OPTS $SERVLET_OPTS"

export JAVA_HOME CATALINA_OPTS JAVA_OPTS CATALINA_PID
