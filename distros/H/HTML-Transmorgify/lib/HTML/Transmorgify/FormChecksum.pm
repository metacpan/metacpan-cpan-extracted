
package HTML::Transmorgify::FormChecksum;

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use HTML::Transmorgify qw(dangling %variables queue_intercept queue_capture run);
use URI::Escape;
use Scalar::Util qw(refaddr blessed);
use YAML;
require Exporter;

our @ISA = qw(HTML::Transmorgify Exporter);
our @EXPORT = qw(validate_form_submission);

my %tags;
my $tag_package = { tag_package => __PACKAGE__ };

our @rtmp;

sub add_tags
{
	my ($self, $tobj) = @_;
	$self->intercept_shared($tobj, __PACKAGE__, 85, %tags);
}

sub return_true { 1 }

$tags{input} = undef;
$tags{button} = undef;
$tags{textarea} = undef;
$tags{"/textarea"} = undef;
$tags{select} = undef;
$tags{"/select"} = undef;
$tags{option} = undef;
$tags{"/option"} = undef;
$tags{"/form"} = \&dangling;
$tags{form} = \&form_tag;

sub form_tag 
{
	my ($fattr, $closed) = @_;
	die if $closed;

#print STDERR "FORM CALLBACK CALLED\n" if $HTML::Transmorgify::debug;

	my (@input_tags);

	my %options;

	my $cb = sub {
		my ($attr, $closed) = @_;
		return 1 if $attr->static('disabled');
		push(@input_tags, $attr);
		my $id = $attr->raw('id');
		my $name = $attr->raw('name');
		$attr->set(name => $id) 
			if $id && ((! defined $name) || ($name ne $id));
		# $attr->eval_at_runtime(1);
		return 1;
	};

	my %tac;
	my $textarea_cb = sub {
		my ($tattr, $closed) = @_;
		die if $closed;
		return 1 if $tattr->static('disabled');
		$cb->($tattr, $closed);
		my $tacid = refaddr($tattr);
		queue_capture(sub {
			my ($b) = @_;
			$tac{$tacid} = $b;
		});
		return 1;
	};

	my $select_cb = sub {
#print STDERR "SELECT CALLBACK\n";
		my ($sattr, $closed) = @_;
		return 1 if $sattr->static('disabled');
		$cb->($sattr, $closed, "select");
		my $opad = refaddr($sattr);
		$options{$opad} = [];
		my $option_cb = sub {
#print STDERR "OPTION CALLBACK\n";
			my ($oattr, $closed) = @_;

			my $tuple = [$oattr];
			push(@{$options{$opad}}, $tuple);
			if (defined $oattr->raw('value')) {
#print STDERR "Remembering attribute value '$oattr' for $opad\n";
			} elsif (! $closed) {
				queue_capture(sub {
					my ($b) = @_;
					push(@$tuple, $b);
				});
#print STDERR "Remembering inline value '@$b' for $opad\n";
			} else {
				die "<option> with no value";
			}
			return 1;
		};
		queue_intercept(__PACKAGE__,
			option		=> $option_cb,
			"/select",	=> \&return_true,
		);
		return 1;
	};
	my $close_cb_rt = sub {
#print STDERR "# CLOSE </form> CALLBACK\n" if $HTML::Transmorgify::debug;
		my %vtype;		# value type
		my %pval;		# possible value
		my %hval;		# hidden (readonly) value
		my %can_collapse;	# if there is only one possible, it can be readonly/hidden

		my %vdata;

		for my $input (@input_tags) {
			next if $input->boolean('disabled');

			my $tag = $input->tag();
			my $type = $input->get('type');
			my $name = $input->get('name');
			my $value = $input->get('value');
			my $readonly = $input->boolean('readonly');

#print STDERR "READONLY $tag $type $name = '$readonly'\n";

			$vtype{$name} = 'x';
			if ($tag eq 'input') {
				if ($type eq 'hidden') {
					# XXX 2 hidden with the same name
					$value = "" unless defined $value;
					$hval{$name} = $value;
					$vtype{$name} = 'v';
				} elsif ($type eq 'radio') {
					$value = "on" unless defined $value;
					$pval{$name}{$value} = 1;
					$vtype{$name} = 'm';
					if ($readonly) {
						$vtype{$name} = 'v';
						$hval{$name} = $value
							if $input->get('checked');
					}
					$can_collapse{$name} = 1 
						if $input->get('checked');
				} elsif ($type eq 'submit') {
					$value = "Submit Query" unless defined $value;
					$pval{$name}{$value} = 1;
					$vtype{$name} = 'm';
				} elsif ($type eq 'image') {
					delete $vtype{$name};
					$vtype{"$name.x"} = 1;
					$vtype{"$name.y"} = 1;
				} elsif ($type eq 'checkbox') {
					$value = "on" unless defined $value;
					if ($readonly) {
						$vtype{$name} = 'v';
						$hval{$name} = $value;
					} else {
						$vtype{$name} = 'M';
						$pval{$name}{$value} = 1;
					}
				} elsif ($type eq 'password' || $type eq 'text' || ! $type) {
					if ($readonly) {
						$vtype{$name} = 'v';
						$hval{$name} = $value;
					}
				} elsif ($type eq 'file') {
					# nada
				} else {
					die "unknown <$tag> type: '$type'";
				}
			} elsif ($tag eq 'button') {
				if ($type eq 'submit') {
					$pval{$name}{$value} = 1;
					$vtype{$name} = 'm';
				} elsif ($type eq 'button') {
					# XXX push button
					die;
				} else {
					die "unknown <$tag> type: '$type'";
				}
			} elsif ($tag eq 'select') {
				my $a = refaddr($input);
				for my $o (@{$options{$a}}) {
					my ($oattr, $obuf) = @$o;
					my $v;
					if ($obuf) {
						local(@rtmp) = ( '' );
						run($obuf, \@rtmp);
						$v = $rtmp[0];
					} else {
						$v = $oattr->get('value');
					}
#print STDERR "Adding option $a - $oattr - $v\n";
					$pval{$name}{$v} = 1;
					$can_collapse{$name} = 1 if $oattr->get('selected');
				}
				$vtype{$name} = 'm';
				if ($input->boolean('multiple', undef, 0)) {
					$vtype{$name} = 'M';
				}
			} elsif ($tag eq 'textarea') {
				if ($readonly) {
					# XXX needs regression test
					my $a = refaddr($input);
					$vtype{$name} = 'v';
					local(@rtmp) = ( '' );
					run($tac{$a}, \@rtmp);
					$hval{$name} = $rtmp[0];
				}
			} else {
				die "tag='$tag'";
			}
#print STDERR "VTYPE{$name} = $vtype{$name}\n";
		}

		for my $p (keys %pval) {
			if ($can_collapse{$p} && scalar(keys %{$pval{$p}}) == 1) {
				($hval{$p}) = keys %{$pval{$p}};
				delete $pval{$p};
				$vtype{$p} = 'v';
			} 
			if (! keys %{$pval{$p}}) {
				die;
			} 
		}

		my $vtype_str = join("'", map { uri_escape($_) => $vtype{$_} } sort keys %vtype);

		my $particular_values = join(" ",
			map { 
				join("'", 
					map { uri_escape($_) } sort keys %{$pval{$_}}
				)
			} sort keys %pval
		);

		my $constraint = "$vtype_str $particular_values";

		$HTML::Transmorgify::result->[0] .= qq'<input type="hidden" name=" constraint" value="$constraint"\n>';
		$hval{" constraint"} = $constraint;

		my $str = $vtype_str . " " . $HTML::Transmorgify::variables{" secret"} . ' ';

		$str .= join(" ", map { $_ => uri_escape($hval{$_}) } sort keys %hval );
		my $csum = md5_hex($str);
#print STDERR "STR = '$str' = $csum\n";

		if ($HTML::Transmorgify::debug) {
#print STDERR Dumper(\%pval);
			print STDERR "SPVALKEY = " . join(' ', sort keys %pval) . "\n";
			print STDERR "PARTICULAR VALUES = $particular_values.\n";
			print STDERR "CSUMSTR=$str.\n";
		}

		$HTML::Transmorgify::result->[0] .= qq'<input type="hidden" name=" csum" value="$csum"\n>';
	};

	print STDERR "SECRET SET\n" if $HTML::Transmorgify::debug && $HTML::Transmorgify::variables{' secret'};
	print STDERR "NO SECRET SET\n" if $HTML::Transmorgify::debug && ! $HTML::Transmorgify::variables{' secret'};

	my $wrap = sub {
		my (@args) = @_;
		push(@$HTML::Transmorgify::rbuf, sub {
			$close_cb_rt->(@args)
		});
	};

	queue_intercept(__PACKAGE__,
		input		=> $cb,
		button		=> $cb,
		textarea	=> $cb,
		select		=> $select_cb,
		"/form" 	=> ($HTML::Transmorgify::variables{" secret"} 
			? $wrap
			: \&return_true),
	);
	return 1;
};

sub validate_form_submission
{
	my ($formdata, $secret) = @_;
	return undef unless defined $secret;			# no signing key

	return 0 unless defined $formdata->{' constraint'};	# no constraint sent
	return 0 unless defined $formdata->{' csum'};		# no checksum sent
	my $constraint = $formdata->{' constraint'};
	$constraint =~ s/^(\S+) //;
	my $vtype_str = $1;
	my %vtypes = map { uri_unescape($_) } split(/'/, $vtype_str, -1);
	my @sorted = sort keys %vtypes;

	my %pval;
	@pval{grep { $vtypes{$_} eq 'm' || $vtypes{$_} eq 'M' } @sorted}
		= map { 
			{
				map { 
					uri_unescape($_) => 1
				} split(/'/, $_, -1) 
			} 
		} split(/ /, $constraint, -1);


#use Data::Dumper;
#print Dumper(\%vtypes, \%pval);
	my $str = "$vtype_str $secret ";
	$str .= join(' ', map { $_ => uri_escape($formdata->{$_}) } ' constraint', grep { $vtypes{$_} eq 'v' } @sorted);

	if ($HTML::Transmorgify::debug) {
		print STDERR "CPVALKEY = " . join(' ', grep { $vtypes{$_} eq 'm' || $vtypes{$_} eq 'M' } @sorted) . "\n";
		print STDERR "CPARTICVLS        = $constraint.\n";
		print STDERR " CHECK =$str.\n";
	}

	my $csum = md5_hex($str);

#print STDERR "CSUMS: $csum\n     : ".$formdata->{' csum'}."\n";
	return 0 unless $csum eq $formdata->{' csum'};		# invalid signature

	for my $k (keys %$formdata) {
#print STDERR " CHECKING KEY $k ($vtypes{$k} - $formdata->{$k}).\n";
		next if $k =~ /^ /;
		return 0 unless $vtypes{$k};			# extra fields
		my $val = $formdata->{$k};
		return 0 if ref($val)
			&& ! uc($vtypes{$k}) eq $vtypes{$k};
		if ($vtypes{$k} eq 'm' || $vtypes{$k} eq 'M') {
			my @v = ref($val) 
				? @$val
				: $val;
			for my $v (@v) {
#print STDERR "CHECKING VALUE $v\n";
				return 0 unless $pval{$k}{$v}	# illegal value
			}
		} else {
			return 0 if ref($val);			# multiples not allowed
		}
#print STDERR "DONE\n";
	}

	return 1;
}

1;

__END__

"id" overrides "name"

=head1 BUGS

Although at least some browsers support using the name name/id for multiple
form element, with one exception, this module does not.  Multiple uses of the same
name for non-readonly checkbox is allowed.
