#! perl

=pod

=head1 NAME

JS::SourceMap - Parse and use JS source maps in Perl

=head1 SYNOPSIS

  use JS::SourceMap qw/load loads discover/;

  # parse a file into a sourcemap
  $map = load($filename);

  # parse a string into a sourcemap
  $map = loads($string);

  # find the URL for a sourcemap from some JS code:
  $url = discover($web_goo);

=head1 DESCRIPTION

Current web development techniques like minification can make
debugging deployed JS code a pain.  Source maps are a compact
representation of the data necessary to turn a filename/line/column in
a JS runtime error thrown e.g. in your browser into the real
filename/line/column in the source code where the error occurred.

This is a set of Perl modules that allow you to decode and use JS
source maps.  A typical use case for this module is a server-side
component in Perl that receives JS runtime error information somehow
from a web application's JS front end.  You usually have the source
map available on the server already but there is a `discover` function
in `JS::SourceMap` that will search JS code for a pointer to its
source map as per convention.  You'll have to fetch the URL that
`discover` finds yourself, though.

We have adapted much of this Perl implementation from the Python
implementation at https://github.com/mattrobenolt/python-sourcemap,
which is BSD-licensed.  Our API is very similar to that Python
module's.

=cut

package JS::SourceMap;
use strict;
use warnings;
use parent qw(Exporter);
use JS::SourceMap::Decoder;
use vars qw(@EXPORT_OK $VERSION);

@EXPORT_OK = qw(load loads discover);
$VERSION = '0.1.2';

=pod

=over 4

=item * load $stream_or_filename [, @options ]

Our first argument can either be a filename or an open file handle of
some kind; in the former case the file is opened, read and closed by
us, in latter it is only read.  The contents are passed to L<loads>,
along with any options.

=back

=cut

sub load {
	my($filething,@options) = @_;
	my $opened = 0;
	local($/);
	$/ = undef;
	if (defined($filething) && (-f $filething)) {
		open(F, $filething) or die ("$filething: $!");
		$filething = \*F;
		$opened = 1;
	}
	my $slurp = <$filething>;
	close($filething) if $opened;
	return loads($slurp,@options);
}

=pod

=over 4

=item * loads $string [, @options ]

Decodes a sourcemap passed as a string.  Returns a
L<JS::SourceMap::Index> instance or throws an error.

If any C<@options> are given they are passed to the
L<JS::SourceMap::Decoder> constructor.

=back

=cut

sub loads {
	my($string,@options) = @_;
	return JS::SourceMap::Decoder->new(@options)->decode($string);
}

=pod

=over 4

=item * discover $string

Examine the contents of a file of JS code for the marker that points
to its source map.  If found we return the URL to the source map.  If
not we return C<undef>.  We search the five first and five last lines
in the source code we're given, since the token we're looking for is
supposed to be in there somewhere.

=back

=cut

sub discover {
	my($string) = @_;
	my @source = split(/\n/,$string);
	my @search = ((scalar(@source) <= 10) ? @source :
		      (@source[0..4],@source[-5..-1]));
	foreach my $line (@search) {
		if ($line =~ m,^//[#@]\ssourceMappingURL=(.*)$,) {
			return $1;
		}
	}
	return undef;
}

1;

__END__

=pod

=head1 SEE ALSO

L<JS::SourceMap::Decoder>

=head1 AUTHOR

attila <attila@stalphonsos.com>

The most recent sourcecode can be found at the github repository:
L<https://github.com/StAlphonsos/perl-sourcemap>.

=head1 LICENSE

ISC/BSD c.f. LICENSE in the source distribution.

=cut

##
# Local variables:
# mode: perl
# tab-width: 8
# perl-indent-level: 8
# cperl-indent-level: 8
# cperl-continued-statement-offset: 8
# indent-tabs-mode: t
# comment-column: 40
# End:
##
