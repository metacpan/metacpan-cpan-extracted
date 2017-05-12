${T_perl{$java_home = property('foo.java_home'); $java_home?"JAVA_HOME=\"$java_home\"":''}}

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
${T_perl{
$trust_store = property('foo.tomcat.trust_store.file');
$trust_store
? "    -Djavax.net.ssl.trustStore=$trust_store \\\n" .
  "    -Djavax.net.ssl.trustStoreType=JKS \\\n" .
  "    -Djavax.net.ssl.trustStorePassword=" . default('foo.tomcat.trust_store.password:changeme') . " \\\n"
: ''
}}    "

JMX_OPTS="\
${T_perl{
$port = property('foo.tomcat.jmx_port');
$port
? "    -Dcom.sun.management.jmxremote \\\n" .
  "    -Dcom.sun.management.jmxremote.port=$port \\\n" .
  "    -Dcom.sun.management.jmxremote.ssl=false \\\n" .
  "    -Dcom.sun.management.jmxremote.authenticate=false \\\n"
: ''
}}    "

JPDA_OPTS="\
${T_perl{
$port = property('foo.tomcat.jpda_port');
$port
? "    -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$port \\\n"
: ''
}}    "

CATALINA_OPTS=$JMX_OPTS
CATALINA_PID=${T{foo.tomcat.service.pid_file:/var/run/gis-tomcat/catalina.pid}}
JAVA_OPTS="$JAVA_OPTS $MEMORY_JAVA_OPTS $APP_JAVA_OPTS $SSL_JAVA_OPTS $SERVLET_OPTS"

export JAVA_HOME CATALINA_OPTS JAVA_OPTS CATALINA_PID
