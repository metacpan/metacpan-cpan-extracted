#! perl

=pod

=head1 NAME

JS::SourceMap::Decoder - Decoder for JS source maps

=head1 SYNOPSIS

  use JS::SourceMap::Decoder;
  JS::SourceMap::Decoder->new->decode($sourcemap_string);

=head1 DESCRIPTION

=cut

package JS::SourceMap::Decoder;
use strict;
use warnings;
use JSON;
use JS::SourceMap::Token;
use JS::SourceMap::Index qw/token_index/;
use vars qw($B64chrs @B64);

$B64chrs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
@B64 = map { -1 } (1..123);
for (my $i = 0; $i < length($B64chrs); ++$i) {
	$B64[ord(substr($B64chrs,$i,1))] = $i;
}
	
sub assert { my($cond,$msg) = @_; die("ASSERTION FAILED: $msg") unless $cond; }

=pod

=over 4

=item * new [ %options ]

Construct a decoder instance.  Options:

=over 8

=item * json_options => $options_as_arrayref

Specify an array of options to pass to the L<JSON> constructor when
parsing JSON.  We use the JSON defaults unless this option is given.

=item * assertions => 0|1

If turned on this option will force every token parsed to pass a
series of assertions which will C<die> if failed.  Useful for testing,
defaults to off.

=back

=back

=cut

sub new {
	my($class,@options) = @_;
	my $self = { @options };
	return bless($self,$class);
}

# internal

sub opt {
	my($self,$opt) = @_;
	my $val = exists($self->{$opt}) ? $self->{$opt} : undef;
	return $val unless wantarray;
	return @$val if defined($val);
	return ();
}

# internal: parse a VLQ segment -> list of integers

sub parse_vlq {
	my($segment) = @_;
	my @values = ();
	my($cur,$shift,$cont,$sign) = (0,0,0,0);
	foreach my $c (split('',$segment)) {
		my $val = $B64[ord($c)];
		($val,$cont) = ($val & 0b11111, $val >> 5);
		$cur += $val << $shift;
		$shift += 5;
		if (!$cont) {
			($cur,$sign) = ($cur >> 1, $cur & 1);
			$cur = -$cur if $sign;
			push(@values,$cur);
			($cur,$shift) = (0,0);
		}
	}

	warn("VLQ decode error (leftover cur/shift $cur/$shift)")
	    if ($cur || $shift);

	return @values;
}

=pod

=over 4

=item * decode $string

Parse a sourcemap and return a L<JS::SourceMap::Index> instance that
can be used to query the data it contains.

Returns C<undef> if the decoding failed for any reason; in this case
at least one call to C<warn> will have been made with more information
about why.  Otherwise returns a L<JS::SourceMap::Index> instance.

=back

=cut

sub decode {
	my($self,$string) = @_;
	$string = (split(/\n/,$string,2))[1] if $string =~ /^\)\]}/;
	my $json = JSON->new($self->opt('json_options'))->decode($string);
	my @sources = @{$json->{'sources'}};
	my $sourceRoot = $json->{'sourceRoot'} if exists $json->{'sourceRoot'};
	my @names = @{$json->{'names'}};
	my @lines = split(/;/,$json->{'mappings'});
	@sources = map { join('/',$sourceRoot,$_) } @sources if $sourceRoot;
	my @tokens = ();
	my @line_index = ();
	my $index = {};
	my($dst_col,$src_id,$src_line,$src_col,$name_id) = (0,0,0,0,0,0);
	my $dst_line = 0;
	foreach my $line (@lines) {
		push(@line_index,[]);
		my @segments = split(/,/,$line);
		$dst_col = 0;
		foreach my $segment (@segments) {
			next unless length($segment);
			my @parse = parse_vlq($segment);
			if ($self->opt('assertions')) {
				assert(@parse > 0, "empty VLQ parse");
			}
			return undef unless @parse;
			$dst_col += $parse[0];
			my($src,$name);
			if (scalar(@parse) > 1) {
				$src_id += $parse[1];
				if (($src_id < 0) ||
				    ($src_id >= scalar(@sources))) {
					warn(sprintf(
						"%s: Seg %s ref source %d ".
						"w/%d sources: %s (%s)",
						ref($self), $segment, $src_id,
						scalar(@sources),"@sources",
						"@parse"));
					return undef;
				}
				$src = $sources[$src_id];
				$src_line += $parse[2];
				$src_col += $parse[3];
				if (scalar(@parse) > 4) {
					$name_id += $parse[4];
					if (($name_id < 0) ||
					    ($name_id >= scalar(@names))) {
						warn(sprintf(
							"%s: Seg %s refs name".
							" %d w/%d: %s (%s)",
							ref($self),$segment,
							$name_id,
							scalar(@names),
							"@names","@parse"));
						return undef;
					}
					$name = $names[$name_id];
				}
			}

			if ($self->opt('assertions')) {
				assert($dst_line >= 0,
				       "dst_line >= 0 ($dst_line)");
				assert($dst_col >= 0,
				       "dst_col >= 0 ($dst_col)");
				assert($src_line >= 0,
				       "src_line >= 0 ($src_line)");
				assert($src_col >= 0,
				       "src_col >= 0 ($src_col)");
			}

			my $token = JS::SourceMap::Token->new(
				$dst_line, $dst_col, $src, $src_line, $src_col,
				$name);
			push(@tokens,$token);
			my $tkey = token_index($dst_line,$dst_col);
			$index->{$tkey} = $token;
			push(@{$line_index[$dst_line]},$dst_col);
		}
		++$dst_line;
	}
	return JS::SourceMap::Index->new(
		$json, \@tokens, \@line_index, $index, \@sources);
}

1;

__END__

=pod

=head1 SEE ALSO

L<JS::SourceMap::Index>, L<JS::SourceMap::Token>

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
