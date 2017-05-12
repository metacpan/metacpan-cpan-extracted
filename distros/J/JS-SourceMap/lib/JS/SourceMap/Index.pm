#! perl

=pod

=head1 NAME

JS::SourceMap::Index - Index into a JS source map

=head1 SYNOPSIS

  $index = JS::SourceMap::load(\*STDIN);
  # ...

=head1 DESCRIPTION

Instances of this class represent an searchable index into a
sourcemap.  There are two ways to use it: The C<lookup> method can be
used to find the closest element of the map to a line/column in the
minified JS code and the C<let>/C<get> methods can be used to iterate
over of the elements of the index.  Elements of the index are
represented by L<JS::SourceMap::Token> instances.

=cut

package JS::SourceMap::Index;
use strict;
use warnings;
use parent qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(token_index);

# used internally to hide the fact that we can't use tuples as indexes
# into an array in Perl like you can in Python :-)

sub token_index { sprintf('%d,%d',@_) }

=pod

=over 4

=item * new $raw, $tokens, $line_index, $index, $sources

Contruct a new index.  This is normally done via the
L<JS::SourceMap::Decoder> class' C<decode> method and not directly by
user code.

=back

=cut

sub new {
	my($class,@args) = @_;
	my $self = {
		raw => shift(@args),
		tokens => shift(@args),
		line_index => shift(@args),
		index => shift(@args),
		sources => shift(@args) || []
	};
	return bless($self,$class);
}

=pod

=over 4

=item * lookup $line, $column

Given line and column numbers in the minified JS source code mapped by
this index, return the location in the map nearest to them,
represented by a L<JS::SourceMap::Token> instance.

=back

=cut

sub lookup {
	my($self,$line,$column) = @_;
	my $tkey = token_index($line, $column);
	my $toke;
	if (exists($self->{'index'}->{$tkey})) {
		$toke = $self->{'index'}->{$tkey};
	} elsif ($line >= 0 && $line < scalar(@{$self->{'line_index'}})) {
		my $line_index = $self->{'line_index'}->[$line];
		my($col,$i);
		for ($i = 0; $i < scalar(@$line_index); ++$i) {
			if ($line_index->[$i] > $column) {
				$col = $i ?
				    $line_index->[$i-1] : $line_index->[0];
				last;
			}
		}
		$col = $line_index->[$i-1] unless defined($col);
		$tkey = token_index($line, $col);
		$toke = exists($self->{'index'}->{$tkey}) ?
		    $self->{'index'}->{$tkey} : undef;
	}
	return $toke;
}

=pod

=over 4

=item * len

Return the number of tokens in the index.

=item * get $index

Return a token in the index by number.

=back

=cut

sub len	{ scalar(@{shift->{'tokens'}}) }
sub get	{ shift->{'tokens'}->[shift] }

=pod

=over 4

=item * as_string

Return a human-readable summary of the data in the index.

=back

=cut

sub as_string {
	my($self) = @_;
	return sprintf(
		q{<Index: %d tokens/%d entries over %d lines in %d sources>},
		scalar(@{$self->{'tokens'}}),
		scalar(keys(%{$self->{'index'}})),
		scalar(@{$self->{'line_index'}}),
		scalar(@{$self->{'sources'}}));
}

1;

__END__

=pod

=head1 SEE ALSO

L<JS::SourceMap::Decoder>, L<JS::SourceMap::Token>

=head1 AUTHOR

attila <attila@stalphonsos.com>

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
