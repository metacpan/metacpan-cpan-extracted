#!/bin/bash

CATALINA_HOME="${T_os_path{base_tomcat.catalina_base:/opt/apache/tomcat}}"
CATALINA_BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

export CATALINA_BASE CATALINA_HOME

$CATALINA_HOME/bin/catalina.sh "$@"
