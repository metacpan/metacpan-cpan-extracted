use File::Spec::Functions;
use File::Copy;
use Socket qw(:crlf);

print "This will attempt to install JavaServer.jar somewhere & then tell you$CRLF";
print "how to run it... hopefully!$CRLF";

my $jhome = $ENV{JAVA_HOME};
my $line;
if ($jhome)
{
	my $lib = File::Spec->catdir($jhome, "lib");
	print "Cool - your JAVA_HOME environment variable is set to $jhome.$CRLF";
	print "If you let me copy it into $lib it'll be easier to run.$CRLF";
	print "Do I have permission to copy 'JavaServer.jar' to $lib? (Y/n)? ";
	my $in = <STDIN>;
	if ($in !~ /^n/i)
	{
        copy('JavaServer.jar', $lib);
		$jar = $lib;
	}
	else
	{
		$jar = ".";
	}

    my @classpath = map { File::Spec->catdir($lib, $_) } 
        qw(classes.zip swingall.jar swing.jar);
    push @classpath, File::Spec->catdir($jar, 'JavaServer.jar');

    local($") = ":";
	$line = "java -classpath @classpath com.zzo.javaserver.JavaServer$CRLF";

    my $OS = $^O;
	if ($OS =~ /mswin/i)
	{
		open(O,">run_js.bat");
		print O "$line";
		close(O);
		$f = ".bat";
	}
	else
	{
		open(O,">run_js.sh");
		print O "#!/bin/sh$CRLF";
		print O "$line";
		close(O);
		$f = ".sh";
		chmod 0777,"run_js.sh";
	}

	print "To run JavaServer type this line:$CRLF";
	print "run_js${f}$CRLF";
}
else
{
	my $cp = $ENV{CLASSPATH};
	if ($cp)
	{
		print "Add the directory where 'JavaServer.jar' will sit to your$CRLF";
		print "CLASSPATH environment variable and then type:$CRLF";
		print "java JavaServer$CRLF";
		print "to run JavaServer.$CRLF";
	}
	else
	{
		print "Yer gonna hafta hunt down your 'classes.zip' file as$CRLF";
		print "well as 'swing.jar' and 'swingall.jar' if you want to$CRLF";
		print "use Swing, and manually list all of those files including$CRLF";
		print "the directories they're in on the 'java' command line like -$CRLF";
		print "As well as putting JavaServer.jar someplace and then execute:$CRLF";
		print "/path/to/java -classpath /path/to/classes.zip:/path/to/swing.jar:/path/to/swingall/jar:/path/to/JavaServer.jar JavaServer$CRLF";
		print "to run JavaServer.$CRLF";
	}
}

