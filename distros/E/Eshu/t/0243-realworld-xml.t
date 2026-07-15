use strict;
use warnings;
use Test::More;
use Eshu;

sub x { Eshu->indent_xml($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple document
{
	my $code = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<document>
	<title>Hello World</title>
	<body>
		<p>Some text here.</p>
	</body>
</document>
END
	is(x($code), $code, 'XML: simple document');
}

# 2. self-closing elements
{
	my $code = <<'END';
<config>
	<database host="localhost" port="5432" name="myapp"/>
	<cache host="localhost" port="6379" ttl="300"/>
	<logging level="info" file="/var/log/app.log"/>
</config>
END
	is(x($code), $code, 'XML: self-closing elements');
}

# 3. nested elements
{
	my $code = <<'END';
<library>
	<book isbn="978-0-13-468599-1">
		<title>The C Programming Language</title>
		<authors>
			<author>Brian W. Kernighan</author>
			<author>Dennis M. Ritchie</author>
		</authors>
		<year>1988</year>
	</book>
</library>
END
	is(x($code), $code, 'XML: deeply nested book');
}

# 4. XML with attributes
{
	my $code = <<'END';
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
	<circle cx="50" cy="50" r="40" fill="blue" stroke="black" stroke-width="2"/>
	<text x="50" y="55" text-anchor="middle" fill="white" font-size="16">Hi</text>
</svg>
END
	is(x($code), $code, 'XML: SVG with attributes');
}

# 5. Atom feed
{
	my $code = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>My Blog</title>
	<link href="https://example.com/blog"/>
	<updated>2024-01-01T00:00:00Z</updated>
	<entry>
		<title>First Post</title>
		<link href="https://example.com/blog/first"/>
		<id>urn:uuid:1234</id>
		<content type="html">Hello world!</content>
	</entry>
</feed>
END
	is(x($code), $code, 'XML: Atom feed');
}

# 6. Maven pom.xml excerpt
{
	my $code = <<'END';
<project xmlns="http://maven.apache.org/POM/4.0.0">
	<modelVersion>4.0.0</modelVersion>
	<groupId>com.example</groupId>
	<artifactId>my-app</artifactId>
	<version>1.0.0</version>
	<dependencies>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-core</artifactId>
			<version>5.3.0</version>
		</dependency>
	</dependencies>
</project>
END
	is(x($code), $code, 'XML: Maven pom.xml');
}

# 7. XSLT template
{
	my $code = <<'END';
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/library">
		<html>
			<body>
				<h1>Books</h1>
				<ul>
					<xsl:for-each select="book">
						<li>
							<xsl:value-of select="title"/>
						</li>
					</xsl:for-each>
				</ul>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
END
	is(x($code), $code, 'XML: XSLT stylesheet');
}

# 8. Spring beans
{
	my $code = <<'END';
<beans xmlns="http://www.springframework.org/schema/beans">
	<bean id="dataSource" class="org.apache.commons.dbcp.BasicDataSource">
		<property name="driverClassName" value="org.postgresql.Driver"/>
		<property name="url" value="jdbc:postgresql://localhost/mydb"/>
		<property name="username" value="user"/>
		<property name="password" value="secret"/>
	</bean>
	<bean id="userService" class="com.example.UserService">
		<constructor-arg ref="dataSource"/>
	</bean>
</beans>
END
	is(x($code), $code, 'XML: Spring beans');
}

# 9. Ant build.xml
{
	my $code = <<'END';
<project name="MyApp" default="compile" basedir=".">
	<property name="src.dir" value="src"/>
	<property name="build.dir" value="build"/>
	<target name="clean">
		<delete dir="${build.dir}"/>
	</target>
	<target name="compile" depends="clean">
		<mkdir dir="${build.dir}"/>
		<javac srcdir="${src.dir}" destdir="${build.dir}"/>
	</target>
</project>
END
	is(x($code), $code, 'XML: Ant build.xml');
}

# 10. SOAP envelope
{
	my $code = <<'END';
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
	<soapenv:Header/>
	<soapenv:Body>
		<m:GetUserRequest xmlns:m="http://example.com/users">
			<m:UserId>42</m:UserId>
		</m:GetUserRequest>
	</soapenv:Body>
</soapenv:Envelope>
END
	is(x($code), $code, 'XML: SOAP envelope');
}

# 11. XSD schema
{
	my $code = <<'END';
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xs:element name="person">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="name" type="xs:string"/>
				<xs:element name="age" type="xs:integer" minOccurs="0"/>
				<xs:element name="email" type="xs:string" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="id" type="xs:ID" use="required"/>
		</xs:complexType>
	</xs:element>
</xs:schema>
END
	is(x($code), $code, 'XML: XSD schema');
}

# 12. JUnit report
{
	my $code = <<'END';
<testsuites>
	<testsuite name="MyTests" tests="3" failures="1" errors="0" time="0.5">
		<testcase name="test_add" classname="MathTests" time="0.01"/>
		<testcase name="test_sub" classname="MathTests" time="0.01">
			<failure message="Expected 3 got 2">AssertionError</failure>
		</testcase>
		<testcase name="test_mul" classname="MathTests" time="0.01"/>
	</testsuite>
</testsuites>
END
	is(x($code), $code, 'XML: JUnit test report');
}

# 13. RSS feed
{
	my $code = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
	<channel>
		<title>Example Feed</title>
		<link>https://example.com</link>
		<description>Latest news</description>
		<item>
			<title>Breaking News</title>
			<link>https://example.com/news/1</link>
			<description>Something happened today.</description>
			<pubDate>Mon, 01 Jan 2024 12:00:00 GMT</pubDate>
		</item>
	</channel>
</rss>
END
	is(x($code), $code, 'XML: RSS feed');
}

# 14. DocBook section
{
	my $code = <<'END';
<chapter xmlns="http://docbook.org/ns/docbook" version="5.0">
	<title>Introduction</title>
	<section>
		<title>Overview</title>
		<para>This chapter introduces the topic.</para>
		<itemizedlist>
			<listitem>
				<para>First point</para>
			</listitem>
			<listitem>
				<para>Second point</para>
			</listitem>
		</itemizedlist>
	</section>
</chapter>
END
	is(x($code), $code, 'XML: DocBook chapter');
}

# 15. OpenAPI stub
{
	my $code = <<'END';
<paths>
	<path item="/users">
		<operation method="get">
			<summary>List users</summary>
			<responses>
				<response code="200">
					<description>Success</description>
				</response>
			</responses>
		</operation>
		<operation method="post">
			<summary>Create user</summary>
			<responses>
				<response code="201">
					<description>Created</description>
				</response>
			</responses>
		</operation>
	</path>
</paths>
END
	is(x($code), $code, 'XML: OpenAPI paths stub');
}

# 16. sitemap
{
	my $code = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>https://example.com/</loc>
		<lastmod>2024-01-01</lastmod>
		<priority>1.0</priority>
	</url>
	<url>
		<loc>https://example.com/about</loc>
		<lastmod>2024-01-01</lastmod>
		<priority>0.8</priority>
	</url>
</urlset>
END
	is(x($code), $code, 'XML: XML sitemap');
}

# 17. CDATA section
{
	my $code = <<'END';
<template>
	<script>
		<![CDATA[
		function hello() {
		if (x < 0 && y > 0) {
		return x + y;
		}
		}
		]]>
	</script>
</template>
END
	is(x($code), $code, 'XML: CDATA section preserved');
}

# 18. XML with comments
{
	my $code = <<'END';
<configuration>
	<!-- Database settings -->
	<database>
		<host>localhost</host>
		<!-- Default port -->
		<port>5432</port>
	</database>
	<!-- Cache settings -->
	<cache>
		<host>localhost</host>
		<port>6379</port>
	</cache>
</configuration>
END
	is(x($code), $code, 'XML: comments preserved');
}

# 19. mixed content
{
	my $code = <<'END';
<article>
	<title>My Article</title>
	<body>
		<p>This is <em>important</em> text with a <a href="http://example.com">link</a>.</p>
		<p>Another paragraph with <strong>bold</strong> content.</p>
	</body>
</article>
END
	is(x($code), $code, 'XML: mixed content');
}

# 20. processing instruction
{
	my $code = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="style.xsl"?>
<root>
	<item>Hello</item>
</root>
END
	is(x($code), $code, 'XML: processing instruction');
}

# 21. deep nesting
{
	my $code = <<'END';
<level1>
	<level2>
		<level3>
			<level4>
				<level5>deep content</level5>
			</level4>
		</level3>
	</level2>
</level1>
END
	is(x($code), $code, 'XML: deeply nested elements');
}

# 22. element with namespace prefix
{
	my $code = <<'END';
<root xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	<rdf:Description rdf:about="http://example.com/doc">
		<dc:title>Example Document</dc:title>
		<dc:creator>John Doe</dc:creator>
		<dc:date>2024-01-01</dc:date>
	</rdf:Description>
</root>
END
	is(x($code), $code, 'XML: RDF with namespace prefixes');
}

# 23. repeated siblings
{
	my $code = <<'END';
<playlist>
	<track>
		<title>Song One</title>
		<artist>Artist A</artist>
		<duration>3:45</duration>
	</track>
	<track>
		<title>Song Two</title>
		<artist>Artist B</artist>
		<duration>4:20</duration>
	</track>
	<track>
		<title>Song Three</title>
		<artist>Artist C</artist>
		<duration>5:10</duration>
	</track>
</playlist>
END
	is(x($code), $code, 'XML: repeated sibling elements');
}

# 24. empty elements
{
	my $code = <<'END';
<form>
	<field name="username" type="text" required="true"/>
	<field name="password" type="password" required="true"/>
	<field name="remember" type="checkbox"/>
	<submit label="Login"/>
</form>
END
	is(x($code), $code, 'XML: form with empty elements');
}

# 25. numeric data
{
	my $code = <<'END';
<metrics>
	<metric name="cpu_usage">
		<value>87.3</value>
		<unit>percent</unit>
		<timestamp>1704067200</timestamp>
	</metric>
	<metric name="memory_used">
		<value>4096</value>
		<unit>MB</unit>
		<timestamp>1704067200</timestamp>
	</metric>
</metrics>
END
	is(x($code), $code, 'XML: metric data');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
<root>
<child>
<grandchild>text</grandchild>
</child>
</root>
END
	my $exp = <<'END';
<root>
	<child>
		<grandchild>text</grandchild>
	</child>
</root>
END
	is(x($in), $exp, 'XML: unindented nesting normalised');
}

# 27
{
	my $in = <<'END';
<people>
<person id="1">
<name>Alice</name>
<age>30</age>
</person>
<person id="2">
<name>Bob</name>
<age>25</age>
</person>
</people>
END
	my $exp = <<'END';
<people>
	<person id="1">
		<name>Alice</name>
		<age>30</age>
	</person>
	<person id="2">
		<name>Bob</name>
		<age>25</age>
	</person>
</people>
END
	is(x($in), $exp, 'XML: unindented person list normalised');
}

# 28
{
	my $in = <<'END';
<config>
<database>
<host>localhost</host>
<port>5432</port>
</database>
<server>
<port>8080</port>
<workers>4</workers>
</server>
</config>
END
	my $exp = <<'END';
<config>
	<database>
		<host>localhost</host>
		<port>5432</port>
	</database>
	<server>
		<port>8080</port>
		<workers>4</workers>
	</server>
</config>
END
	is(x($in), $exp, 'XML: unindented config normalised');
}

# 29
{
	my $in = <<'END';
<books>
<book>
<title>SICP</title>
<authors>
<author>Abelson</author>
<author>Sussman</author>
</authors>
</book>
</books>
END
	my $exp = <<'END';
<books>
	<book>
		<title>SICP</title>
		<authors>
			<author>Abelson</author>
			<author>Sussman</author>
		</authors>
	</book>
</books>
END
	is(x($in), $exp, 'XML: unindented book with authors normalised');
}

# 30
{
	my $in = <<'END';
<menu>
<item id="file">
<label>File</label>
<submenu>
<item id="new">
<label>New</label>
<shortcut>Ctrl+N</shortcut>
</item>
<item id="open">
<label>Open</label>
<shortcut>Ctrl+O</shortcut>
</item>
</submenu>
</item>
</menu>
END
	my $exp = <<'END';
<menu>
	<item id="file">
		<label>File</label>
		<submenu>
			<item id="new">
				<label>New</label>
				<shortcut>Ctrl+N</shortcut>
			</item>
			<item id="open">
				<label>Open</label>
				<shortcut>Ctrl+O</shortcut>
			</item>
		</submenu>
	</item>
</menu>
END
	is(x($in), $exp, 'XML: unindented nested menu normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"<root>\n<a>\n<b/>\n</a>\n<c>\n<d>\n<e>text</e>\n</d>\n</c>\n</root>\n",
	"<?xml version=\"1.0\"?>\n<feed>\n<entry>\n<title>T</title>\n<content>C</content>\n</entry>\n<entry>\n<title>T2</title>\n<content>C2</content>\n</entry>\n</feed>\n",
	"<schema>\n<type name=\"User\">\n<field name=\"id\" type=\"Int\" primary=\"true\"/>\n<field name=\"name\" type=\"String\"/>\n<field name=\"email\" type=\"String\" unique=\"true\"/>\n</type>\n<type name=\"Post\">\n<field name=\"id\" type=\"Int\" primary=\"true\"/>\n<field name=\"userId\" type=\"Int\" references=\"User.id\"/>\n<field name=\"body\" type=\"Text\"/>\n</type>\n</schema>\n",
	"<svg><g id=\"layer1\"><rect x=\"0\" y=\"0\" width=\"100\" height=\"100\"/><circle cx=\"50\" cy=\"50\" r=\"30\"/></g></svg>\n",
	"<project>\n<tasks>\n<task id=\"1\" depends=\"\">\n<name>Init</name>\n</task>\n<task id=\"2\" depends=\"1\">\n<name>Build</name>\n</task>\n<task id=\"3\" depends=\"2\">\n<name>Test</name>\n</task>\n<task id=\"4\" depends=\"3\">\n<name>Deploy</name>\n</task>\n</tasks>\n</project>\n",
	"<responses>\n<response status=\"200\">\n<headers>\n<header name=\"Content-Type\">application/json</header>\n</headers>\n<body><![CDATA[{\"ok\":true}]]></body>\n</response>\n</responses>\n",
	"<xsl:stylesheet version=\"1.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">\n<xsl:template match=\"*\">\n<xsl:copy>\n<xsl:apply-templates select=\"@*|node()\"/>\n</xsl:copy>\n</xsl:template>\n</xsl:stylesheet>\n",
	"<ruleset name=\"Main\">\n<rule ref=\"category/java/bestpractices.xml/AvoidReassigningParameters\"/>\n<rule ref=\"category/java/codestyle.xml/LocalVariableCouldBeFinal\"/>\n<rule ref=\"category/java/design.xml\" excludes=\"NPathComplexity\"/>\n</ruleset>\n",
	"<configuration>\n<appender name=\"STDOUT\" class=\"ch.qos.logback.core.ConsoleAppender\">\n<encoder>\n<pattern>%d{HH:mm:ss} %-5level %logger{36} - %msg%n</pattern>\n</encoder>\n</appender>\n<root level=\"INFO\">\n<appender-ref ref=\"STDOUT\"/>\n</root>\n</configuration>\n",
	"<build>\n<plugins>\n<plugin>\n<groupId>org.springframework.boot</groupId>\n<artifactId>spring-boot-maven-plugin</artifactId>\n<version>2.7.0</version>\n<executions>\n<execution>\n<goals><goal>repackage</goal></goals>\n</execution>\n</executions>\n</plugin>\n</plugins>\n</build>\n",
	"<resources>\n<resource type=\"VPC\" id=\"vpc-1\">\n<tag key=\"Name\">MainVPC</tag>\n<tag key=\"Env\">prod</tag>\n<children>\n<resource type=\"Subnet\" id=\"subnet-1\">\n<tag key=\"Name\">Public</tag>\n</resource>\n</children>\n</resource>\n</resources>\n",
	"<report>\n<summary total=\"100\" passed=\"95\" failed=\"5\"/>\n<failures>\n<case name=\"testA\" class=\"SuiteX\" time=\"0.02\">\n<message>Expected 1 got 2</message>\n</case>\n</failures>\n</report>\n",
	"<workflow name=\"CI\">\n<trigger event=\"push\" branch=\"main\"/>\n<jobs>\n<job id=\"build\">\n<step name=\"checkout\"><action>actions/checkout\@v3</action></step>\n<step name=\"test\"><run>make test</run></step>\n</job>\n</jobs>\n</workflow>\n",
	"<catalog>\n<product id=\"P001\" sku=\"ABC-123\">\n<name>Widget</name>\n<price currency=\"USD\">9.99</price>\n<stock>42</stock>\n<categories>\n<category>Electronics</category>\n<category>Gadgets</category>\n</categories>\n</product>\n</catalog>\n",
	"<pipeline>\n<stage name=\"source\">\n<input>stdin</input>\n<output>stage1</output>\n</stage>\n<stage name=\"transform\">\n<input>stage1</input>\n<filter>uppercase</filter>\n<output>stage2</output>\n</stage>\n<stage name=\"sink\">\n<input>stage2</input>\n<output>stdout</output>\n</stage>\n</pipeline>\n",
) {
	my $once = x($snippet);
	is(x($once), $once, 'XML: snippet idempotent');
}

done_testing;
