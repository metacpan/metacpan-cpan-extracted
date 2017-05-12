<?xml version="1.0"?>
<sj>
	<name>sleeper</name>
	<class>sleeper</class>
	<var name="test.value" value="test"/>
	<property name="ORBSingletonClass" value="JacORB"/>
	<environment name="RUBYLIB" value="${base.dir}/lib/ruby"/>

	<classpath>
		<dir path="/home/wiggly/src/Java-SJ/sample"/>
		<!-- <jar file="/home/wiggly/lib/java/commons-cli-1.0.jar"/> -->
	</classpath>

	<vm ref="blackdown">
		<environment name="IBM_ENV" value="BIG_BLUE"/>
	</vm>
</sj>
