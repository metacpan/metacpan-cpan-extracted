# An extension of Graphics::Asymptote for PDL!
# This basically adds the capability of sending a piddle to asymptote.

# working here - consider passing data using a named pipe?

package PDL::Graphics::Asymptote;
use strict;
use warnings;
use Graphics::Asymptote;
use PDL;

use version; our $VERSION = qv('0.0.3');

use PDL::Core;

use vars qw(@ISA);
@ISA = qw(Graphics::Asymptote);

# Override the _init function to set the '-V' command-line option
sub _init {
	my $self = shift;
	$self->{sleepTime} //= 50_000;
	$self->SUPER::_init;
}

sub send_pdl {
	# This takes a hash, where the key of each member will be the asymptote
	# name and the value is the piddle to pass.
	my $self = shift;
	
	# Check that they sent an even number of arguments
	scalar(@_) % 2 == 0  or
		barf("You gave ". scalar(@_). " arguments to send_pdl, I expected an even number.  Usage:\n " . '  send_pdl(asyvar => $piddle, ...)');
	
	my %data = (@_);
	foreach my $name (keys(%data)) {											# For each passed variable name,
		my $pdl = $data{$name};													# get the corresponding piddle,
		my $pdl_asy_type = _pdlAsyType($pdl);									# and get the corresponding asymptote type.

		my $toSend = $pdl_asy_type . " $name = " . _pdlStr($pdl, '') . ';';	# construct the message,
		$self->_pdlSend($pdl, $name, \$toSend);								# and send it.

		# weird memory hack
		# I know that Perl has automatic garbage collection, but it seems like it's
		# not reclaimed as quickly as it could be?  As a result, when I send
		# consecutive large strings, the memory grows and grows.  This helps reduce
		# that problem.
		undef $toSend;
	}
}

# Thanks to Craig DeForest, who supplied this recursive pdl-to-string function!
sub _pdlStr {
    my($pdl,$indent) = @_;

    return "$indent$pdl" unless($pdl->ndims);
    return "$indent\{" . join(", ", list $pdl) . "\}" if($pdl->ndims==1);

    return "$indent\{" .
            join(",", map { _pdlStr( $_, " $indent" ) } $pdl->dog ) . #"\n" .
			"$indent\}";
}

sub _pdlAsyType {
	my $pdl = shift;
	my $asyType;
# working here - should wrap in eval block to capture when user (accidentally)
# passes a non-piddle, so I can give a better error message.
	my $pdlType;
	eval {
		$pdlType = $pdl->type;
	};
	barf("I was expecting a piddle but I got something else.") if $@;
	
	if("$pdlType" eq 'float' or "$pdlType" eq 'double') {
		$asyType = 'real []';
	} else {
		$asyType = 'int []';
	}
	
	# Get the right bracketing for higher dimensions
	if($pdl->getndims > 1) {
		$asyType .= '[]' x ($pdl->getndims - 1);
	}
	return $asyType;
}

sub _pdlSend {
	# This sends the variable named $name to Asymptote.  This business with
	# tempVerbose is a work-around to make sure that send doesn't spew out
	# the sent data unless you set the verbosity setting high enough, i.e.
	# at 2 or higher.  Notice that we use _send, because we don't need the
	# send function checking if we have Perlish comments.
	(my $self, my $pdl, my $name, my $toSend) = @_;
	my $temp_verbose = $self->get_verbosity;
	$self->set_verbosity if($temp_verbose < 2);
	print '*' x 10, ' To Asymptote ', '*' x 10, "\n",
		"pdl with dimensions ", join(', ', $pdl->dims), " as $name\n",
		'*' x 34, "\n\n" if($temp_verbose == 1);
	$self->_send($$toSend);
	$self->set_verbosity($temp_verbose);
}

=pod

=head1 NAME

PDL::Graphics::Asymptote - PDL interface to the Asymptote interpreter

=head1 VERSION

This documentation refers to PDL::Graphics::Asymptote version 0.0.2.

=head1 SYNOPSIS

   use PDL::Graphics::Asymptote;
   use PDL;
   
   # Start a new interpreter
   my $asy = PDL::Graphics::Asymptote->new;
   
   # Generate some data
   my $x = sequence(100) / 10;
   my $y = sin($x);
   
   # Send the data to the interpreter
   $asy->send_pdl(x => $x, y => $y);
   
   # Tell the interpreter what to do with it:
   $asy->send( q{
       import graph;

       picture sine_pic;
       size(sine_pic, 3inches, keepAspect=false);
       draw(sine_pic, graph(x, y));
       yaxis(sine_pic, L = "$sin\left(x\right)$", ticks = Ticks);
       xaxis(sine_pic, L = "$x$", ticks = Ticks);
       shipout(prefix = "mySineGraph", sine_pic);
   });


=head1 DESCRIPTION

C<PDL::Graphics::Asymptote> extends C<Graphics::Asymptote>, adding a function to
help you shuttle data from PDL to Asymptote.  This allows you to do your serious
number crunching in PDL and then quickly and easily move the final to-be-plotted
data to Asymptote to polish it off.

This documentation will discuss the only major addition: C<send_pdl>.  For
general usage of the Asymptote wrapper that underlies this class, see
L<Graphics::Asymptote>.

=head1 SUBROUTINE/METHOD

=over

=item C<< send_pdl(asy_name1 => $pdl1, asy_name2 => $pdl2, ...) >>

Sends the data contained in the given piddles to the asymptote interpreter.  The
routine queries the piddles for their dimensions and datatypes and properly
constructs the resulting arrays in Asymptote for you.

=back

=head1 DIAGNOSTICS

You can make a few mistakes while trying to use this module.  The sorts of
messages you might get include these:

=over

=item You gave E<lt>numberE<gt> arguments to send_pdl, I expected an even number.

When you call the C<send_pdl> command, you must send pairs as 
C<< asy_var => $piddle >>.  It's likely you forgot to give the Asymptote variable
name as the key to this pair.

=item I was expecting a piddle but I got something else.

You'll get this if you try to send something down the pipe that's not a piddle.
To set a normal value in Asymptote, such as a string, simply interpolate the
value into the commnd you send, like so:

 $asy->send( qq{
     int number_of_triangles = $pre_computed_number;
     // more Asymptote code here, if you like.
 });

=back

=head1 DEPENDENCIES

This module depends on having a working version of C<asy>, the Asymptote interpreter.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

While C<send_pdl> allows you to send potentially voluminous quantities of data
from PDL to Asymptote, it appears to have a huge impact on the memory consumption
of both processes.  This is likely due to the fact that any piddle sent to
Asymptote is sent in one shot, rather than one entry at a time.  As such, the
object on PDL's side constructs a huge string, and the interpreter on Asymptote's
side must absorb and process a huge string.  It may be more efficient to work in
interactive mode and send the piddle a single element at a time, keeping the
size of each pipe write/read to only a few bytes.  However, this is pure
speculation and may not ever be implemented...

Please report any bugs or feature requests to
C<bug-graphics-asymptote@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

David Mertens  C<< <dcmertens.perl+Asymptote@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, David Mertens C<< <dcmertens.perl+Asymptote@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 SEE ALSO

L<Graphics::Asymptote>, L<PDL>, http://asymptote.sourceforge.net/

=cut

1;
