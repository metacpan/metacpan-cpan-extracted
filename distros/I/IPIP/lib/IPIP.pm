package IPIP;

use 5.010001;
use strict;
use warnings;
use Carp;
use POSIX ();
use POSIX qw(setsid);
use POSIX qw(:errno_h :fcntl_h);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IPIP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('IPIP', $VERSION);

# Preloaded methods go here.

our $INSTANCE;
sub new {
	my ($class, %connect_args) = @_;
	unless ($INSTANCE) {
		$INSTANCE = bless {}, __PACKAGE__;
		$INSTANCE->{'inited'}=0;
		$INSTANCE->{'last'}=0;
	}
	my $reason=$INSTANCE->init(
		$connect_args{path_info}
	);
	if($reason)
	{		
		$INSTANCE->{'last'}=0;
		warn "Could not init file because:".POSIX::strerror($reason);
		if($INSTANCE->{'inited'})
		{
			return $INSTANCE;
		}
		return undef;
	}
	$INSTANCE->{'last'}=1;
	$INSTANCE->{'inited'}=1;
    return $INSTANCE;
};
sub check_last {
	return $INSTANCE->{'last'};
};
1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Interface to IPIP.net database 

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

  use IPIP;
  $r=IPIP->new(
      path_info => "17monipdb.datx",
  );
  unless($r)
  {
  	  print "init failed\n";
  	  exit();
  }
  $r->find_ex("8.8.8.8");

=head1 DESCRIPTION

ipip.net database download:http://www.ipip.net/index.html#down

=head1 AUTHOR

jin xuhuan <00shcabin00@gmail.com >

=head1 COPYRIGHT AND LICENSE

This is free software  

=cut
