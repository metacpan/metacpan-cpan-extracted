// JavaScript: a template literal without ${ is a msgid.
l(`JS template plain`);
l(`JS template "double" 'single' \` backtick ä \n newline`);
l(`JS template
over two lines`);
l(`JS template ` + "joined");
l(`JS dollar $ and brace { alone`);
l(`JS escaped \${name}`);
l(`JS template ${name} is not read`, l(`JS inner of template`));
l(tag`JS tagged is not read`);
