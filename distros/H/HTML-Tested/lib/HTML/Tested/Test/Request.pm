use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test::Request::Upload;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(name filename fh size));

package HTML::Tested::Test::Request;
use base 'Class::Accessor';
use HTML::Tested::Seal;
use Data::Dumper;
use File::Basename qw(basename);

__PACKAGE__->mk_accessors(qw(_param _pnotes _uploads _dir_config uri));

sub hostname { return "some.host"; }
sub server { return shift(); }
sub port { return 80; }

sub server_root_relative {
	return $_[1];
}

sub body_status { return 'Success'; }

sub param {
	my ($self, $name, $val) = @_;
	return $self->_param unless (wantarray || $name);
	$self->_param({}) unless $self->_param;
	$self->_param->{$name} = $val if @_ == 3;
	return $self->_param->{$name} if ($name);
	return keys %{ $self->_param || {} };
}

sub dir_config {
	my ($self, $name, $val) = @_;
	my $dc = $self->_dir_config;
	if (!$dc) {
		$dc = {};
		$self->_dir_config($dc);
	}
	return $dc->{$name} if (@_ < 3);
	$dc->{$name} = $val if defined($val);
	delete $dc->{$name} if !defined($val);
}

=head2 $object->set_params($paramref)

Sets param values according to C<$paramref> hash. Clears old params first.

Parameter names starting with C<HT_SEALED_> are encrypted and C<HT_SEALED_>
prefix is removed.

=cut
sub set_params {
	my ($self, $p) = @_;
	$self->_param({});
	while (my ($n, $v) = each %$p) {
		$v = HTML::Tested::Seal->instance->encrypt($v)
				if ($n =~ s/^HT_SEALED_//);
		$self->param($n, $v);
	}
}

sub parse_url {
	my ($self, $url) = @_;
	my ($arg_str) = ($url =~ /\?(.+)/);
	return unless $arg_str;
	my @nvs = split('&', $arg_str);
	my %res = map {
		my @a = split('=', $_);
		($a[0], ($a[1] || ''));
	} @nvs;
	$self->_param(\%res);
}

sub pnotes {
	my ($self, $name, $val) = @_;
	$self->_pnotes({}) unless $self->_pnotes;
	return $self->_pnotes->{$name} unless scalar(@_) > 2;
	$self->_pnotes->{$name} = $val;
}

sub add_upload {
	my ($self, $n, $v) = @_;
	$self->_uploads([]) unless $self->_uploads;
	open(my $fh, $v) or die "Unable to open $v";
	push @{ $self->_uploads }, HTML::Tested::Test::Request::Upload->new({
		name => $n, filename => $v , fh => $fh, size => -s $v });
}

sub upload {
	my ($self, $n) = @_;
	my $ups = $self->_uploads || [];
	return $n ? (grep { $_->name eq $n } @$ups)[0] : map { $_->name } @$ups;
}

sub as_string {
	return Dumper(shift());
}

1;
