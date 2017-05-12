## ----------------------------------------------------------------------------
#  Devel::RunBlock.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package Devel::RunBlock;
use strict;
use warnings;
use base qw(Exporter DynaLoader);
our @EXPORT_OK = qw(
	runblock runblock_state long_wantarray long_return
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.01';
our ($Result, @Result);

(__PACKAGE__)->bootstrap($VERSION);

# -----------------------------------------------------------------------------
# runblock_state($coderef, @args).
#
sub runblock_state($)
{
	my $code = shift;
	my ($rtype, @retval) = _runblock($code, @_);
	wantarray ? ($rtype, @retval) : $rtype;
}

# -----------------------------------------------------------------------------
# runblock($coderef).
#
sub runblock($)
{
	my $code = shift;
	my ($rtype, @retval) = _runblock($code);
	if( $rtype )
	{
		# return by 'return' statement.
		long_return(2, ($rtype, @retval));
	}
	wantarray ? ($rtype, @retval ) : $rtype;
}

# -----------------------------------------------------------------------------
# long_wantarray($up);
#
sub long_wantarray(;$)
{
	_long_wantarray(shift||0);
}

# -----------------------------------------------------------------------------
# long_return($up, $retval).
#
sub long_return($@)
{
	my $up = shift;
	my $wantarray = long_wantarray($up+1);
	#print "up#$up+1 "._ris($wantarray)."\n";
	if( defined($wantarray) )
	{
		if( $wantarray )
		{
			@Result = @_;
		}else
		{
			$Result = $_[0];
		}
	}
	#print "..call _long_return xsub..\n";
	_long_return($up+1);
	die "NOT_REACH_HERE";
}

sub _ris
{
	my $wa = shift;
	!defined $wa ? 'G_VOID'   # void:2
	  : !$wa     ? 'G_SCALAR' # scalar:1
	  : 'G_ARRAY';            # array:0
}

sub __ret_array  { my@r=@Result; undef @Result; @r }
sub __ret_scalar { my$r=$Result; undef $Result; $r }
sub __ret_void   { return; }

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT
	runblock

=head1 NAME

Devel::RunBlock - run coderef as block


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

 use Devel::RunBlock qw(runblock);

=head1 EXPORT

This module can three functions.


=head1 FUNCTIONS

=head2 runblock

 runblock $sub;

run C<$sub> as code block. 
if C<return>ed in block, it returns from sub which 
calls C<runblock> function.


=head2 runblock_state

 my $rstate = runblock_state { code.. };

run C<$sub> and return whether C<$sub> is returned by C<return> statement
or leave scope.


C<$rstate==1> means returned by C<return> statement.
C<$rstate==0> means returned by left scope.


=head2 long_wantarray

 my $wa = long_wantarray $uplevel;

like a C<wantarray> builtin function, but can test
caller's wantarray state.


=head2 long_return

 long_return $uplevel;
 #long_return $uplevel, $rval..;

long jump return.
currently, could not return values.


$uplevel=0 means no return (just return your sub).
$uplevel=1 means normal return, just same as normal return statement.


=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-runblock at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-RunBlock>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head2 KNOWN BUGS

- long_return could not return values.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.


    perldoc Devel::RunBlock

You can also look for information at:


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-RunBlock>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-RunBlock>


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-RunBlock>


=item * Search CPAN

L<http://search.cpan.org/dist/Devel-RunBlock>


=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


