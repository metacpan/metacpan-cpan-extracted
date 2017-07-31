package Log::LogMethods::Log4perlLogToString;

=head1 NAME

Log::LogMethods::Log4perlLogToString - Easy way to validate Logging to Log4Perl

=head1 SYNOPSIS

  use Moder::Perl;
  use Log::LogMethods::Log4perlLogToString;

  my $string='';

  my $class;
  my $string='';
  my $log=LoggerToString($class,$string);
  $log->info("something to log");

  print $string;

=head1 DESCRIPTION

Created as a way to save time writting unit tests, Log::LogMethods::Log4perlLogToString does all the dirty work of creating a logger that writes to a string or File handle..

=cut

=head1 Exports

All functions and variables are exported by default, if you only want to import a single funciton, just provide the statement in the use list.

=over 4

=cut

use Modern::Perl;
use Exporter qw(import);
use IO::Scalar;
use Log::LogMethods;
use Log::Log4perl::Appender;
use Log::Log4perl::Layout::PatternLayout;
use Log::Dispatch::Handle;

our @EXPORT=qw(LoggerToString LoggerToFh $DEFAULT_LAYOUT);
our @EXPORT_OK=@EXPORT;

=item * $DEFAULT_LAYOUT

The default Log::Log4perl::Layout::PatternLayout.

  %H %P %d %p %k %S [%h] [%s] %b %j %B%n

=cut

our $DEFAULT_LAYOUT='%H %P %d %p %k %S [%h] [%s] %b %j %B%n';

=item * my $log=LoggerToString($class,$string,$format);

$log is a loger object created for $class.  If $format is empty then $DEFAULT_FORMAT is used.

=cut

sub LoggerToString {
  my ($class,$string,$format)=@_;
  my $fh=IO::Scalar->new(\$_[1]);

  return LoggerToFh($class,$fh,$format);
}

=item * my $log=LoggerToFh($class,$fh,$format);

Really the guts of this class, it creates a logger that writes to $fh.  

=cut

sub LoggerToFh {
  my ($class,$fh,$format)=@_;
  $format=$DEFAULT_LAYOUT unless defined($format);
 
  my $layout = Log::Log4perl::Layout::PatternLayout->new($format);
  my $appender=Log::Log4perl::Appender->new(
   'Log::Dispatch::Handle',
    min_level=>'info',
    handle=>$fh
  );

  $appender->layout($layout);
  my $log=Log::Log4perl->get_logger($class);
  $log->add_appender($appender);
  $log->level($Log::LogMethods::LEVEL_MAP{DEBUG});
  return $log;
}

=back

=head1 AUTHOR

Mike Shipper <AKALINUX@CPAN.ORG>

=cut

1;
