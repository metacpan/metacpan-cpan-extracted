#!/home/markt/usr/local/Linux/bin/perl -w
use strict;
no strict 'subs';
use lib '..';
use Java;

###
# Practice catching Exceptions
###

my $java = new Java();

print "Gimmie an Integer to try to convert -> ";
my $int = <STDIN>;
chomp $int;

my $I;
eval 
{
	$I = $java->java_lang_Integer("parseInt","$int:string");
};
if ($@)
{
	$@ =~ s/ERROR: //;
	$@ =~ s/at $0.*$//;
	
	print "$@\n";

	my @st = $java->get_stack_trace;
	print "Stack Trace:\n";
	local($") = "\n";
	print "@st\n";

	print "\n\nOr The Hard Way...\n";

        # This is the actual NumberFormatException object
        my $exception_object = $java->get_exception;

	# Get the Stack Trace - blame Java for this mess!
        my $string_writer = $java->create_object("java.io.StringWriter");
        my $print_writer = $java->create_object("java.io.PrintWriter", $string_writer);
        $exception_object->printStackTrace($print_writer);
	
        print "Stack Trace: \n",$string_writer->toString->get_value;
}	

print $I->get_value, "\n" if $I;
