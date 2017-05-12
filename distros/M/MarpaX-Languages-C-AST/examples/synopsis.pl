#!env perl
use strict;
use warnings FATAL => 'all';
use MarpaX::Languages::C::AST;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use Data::Dumper;
#
# Init log
#
our $defaultLog4perlConf = <<DEFAULT_LOG4PERL_CONF;
log4perl.rootLogger              = INFO, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
DEFAULT_LOG4PERL_CONF
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');
#
# Parse C
#
my $cSourceCode = do { local $/; <DATA> };
$log->infof("\n----------Source code:\n%s", $cSourceCode);
$log->infof("\n------------------AST:\n%s", Dumper(MarpaX::Languages::C::AST->new()->parse(\$cSourceCode)));
__DATA__
int main() {
  char text1[20]="martin";		/* string buffer	*/
  char text2[20]="leslie";		/* string buffer	*/

  printf (" original string contents are: %s\n", text1);
					/* Copy text2 into text1.
					   If text1 is smaller that text2
					   it will probably overwrite
					   something!		*/
  strcpy(text1, text2);
  printf (" new string contents are: %s\n", text1);

  strcpy(text1, "linux");
  printf (" final string contents are: %s\n", text1);
}
