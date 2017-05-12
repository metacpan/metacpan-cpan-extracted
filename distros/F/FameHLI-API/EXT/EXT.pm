;#=============================================================================
;#	File:	EXT.pm
;#	Author:	Dave Oberholtzer (daveo@obernet.com)
;#			Copyright (c)2005, David Oberholtzer
;#	Date:	2001/03/23
;#	Use:	Access to FAME from Perl
;#=============================================================================
package FameHLI::API::EXT;

use	FameHLI::API;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
%EXPORT_TAGS = ( 'all'	=>	[ qw(
		FormatDate
		AccessModeDesc
		BasisDesc
		BiWeekdayDesc
		ClassDesc
		ErrDesc
		FreqDesc
		FYLabelDesc
		MonthsDesc
		ObservedDesc
		OldFYEndDesc
		TypeDesc
		WeekdayDesc
	) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
);
	
$VERSION = '2.101';

bootstrap FameHLI::API::EXT $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 COPYRIGHT

Copyright (c) 2005 Dave Oberholtzer (daveo@obernet.com).
All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 REDIRECT

This page is probably out of date.  Please refer to the L<FameHLI::API>
or I<README> file for more accurate info.  This discrepency will be
handled in a later release because I really do want accurate 
documentation.

=head1 NAME

FameHLI::API::EXT - Perl extension for Fame C-HLI functions

=head1 SYNOPSIS

  use FameHLI::API;
  use FameHLI::API::HLI ':all';
  use FameHLI::API::EXT;
  my $rc = FameHLI::API::Cfmxxx(arg_list);
  printf("Cfmini said '%s'\n", FameHLI::API::EXT::ErrDesc($rc));

Where I<Cfmxxx> is a FameHLI::API function.

=head1 FUNCTIONS

  $str = FormatDate($date, $freq, $image, $fmonth, $flabel);
  $str = ClassDesc($class);
  $str = ErrDesc($rc);
  $str = FreqDesc($freq);
  $str = TypeDesc($type);
  $str = AccessModeDesc($mode);
  $str = BasisDesc($basis);
  $str = ObservedDesc($observ);
  $str = MonthsDesc($month);
  $str = OldFYEndDesc($fy);
  $str = WeekdayDesc($date);
  $str = BiWeekdayDesc($date);
  $str = FYLabelDesc($label);

=head1 DESCRIPTION

The FameHLI::API::EXT functions are 'helper' functions, most of which
return the textual description of a FameHLI::API::HLI constant.

The functions are basically self explanitory as they each, with
the exception of I<FormatDate>, return descriptive text about the
code passed in.  If you want to know the textual description of
a FREQUENCY you call FreqDesc() and so on.

=head1 RETURN VALUE

Functions all return strings.  It is assumed that you will pass
in a valid value.  If not, you will get the string "Undefined"
or something equally rude.

=head1 ERRORS

As mentioned in the 'RETURN VALUE' section, invalid values
get useless results.

=head1 EXAMPLES

  my $rc = FameHLI::API::Cfmxxx(arg_list);
  printf("Cfmini said '%s'\n", FameHLI::API::EXT::ErrDesc($rc));

=head1 ENVIRONMENT

You will need to have the I<FAME> environment variable
set as noted in the Fame documentation.

=head1 FILES

As with any installation using the Fame software, you will
need current license files in the path list specified by
either the I<FAME> or I<FAME_PATH> environment variables.

=head1 CAVEATS (WARNINGS)

This module has not yet been tested against a Windows 
installation.  If you do try it there and it works, please
let me know.  If it doesn't work, please let me know how
you fixed it. :-)

=head1 BUGS/TODO

None known at this time.

=head1 RESTRICTIONS

You will need to already have FAME installed on your system.
This module was developed using FAME 8.0.32 and 8.2.3(beta).

Just as the C-HLI is not thread-safe, neither is this library
since it is based entirely on libchli.  You have been warned.

=head1 SEE ALSO

L<perl(1)> L<FameHLI::API(1)> L<FameHLI::API::HLI(1)>.

=head1 AUTHOR

Dave Oberholtzer (daveo@obernet.com)

=head1 HISTORY

=cut
