package Log::AndError::Constants;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

# debugging and logging constants

use constant ALWAYSLOG		=> 	-3;
use constant INFO		=> 	-2;
use constant DEBUG0		=>	0; 
use constant DEBUG1		=>	1; 
use constant DEBUG2		=>	2; 
use constant DEBUG3		=>	3; 
use constant DEBUG4		=>	4; 
use constant DEBUG5		=>	5; 

my  @Debug	= qw( DEBUG0 DEBUG1 DEBUG2 DEBUG3 DEBUG4 DEBUG5 );
my  @Log	= qw( ALWAYSLOG INFO );

@EXPORT_OK   =   (  @Debug, @Log );
%EXPORT_TAGS = (
	'all'           =>      [ @EXPORT_OK ],
	'debug'		=>	[ @Debug ],
	'log'		=>	[ @Log ],
	);
1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

  Log::AndError::Constants - Log::AndError constants module.

=head1 SYNOPSIS

  use Log::AndError::Constants qw( :all :debug :log );

=head1 DESCRIPTION

  This module provides constants for use with any LCM class module.
  Currently the following tags are supported.
      :debug  - Exports DEBUG0 DEBUG1 DEBUG2 DEBUG3 DEBUG4 DEBUG5 constants.
      :log    - Exports ALWAYSLOG constant.
      :all    - Exports all of the above. 


=head1 AUTHOR

John Ballem of Brown University

=head1 SEE ALSO

perl(1).

=cut
1;
