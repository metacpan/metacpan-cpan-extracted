package EntityModel::Class::Accessor;
$EntityModel::Class::Accessor::VERSION = '0.016';
use strict;
use warnings;

=head1 NAME

EntityModel::Class::Accessor - generic class accessor

=head1 VERSION

Version 0.016

=head1 DESCRIPTION

See L<EntityModel::Class>.

=cut

=head2 add_to_class

Returns (method name, coderef) pairs for new methods to add.

=cut

sub add_to_class {
	my ($class, $pkg, $k, $v) = @_;

	return $k => $class->method_list(
		pkg => $pkg,
		k => $k,
		pre => $v->{pre},
		post => $v->{post},
		allowed => $v->{valid},
		validate => defined $v->{valid}
		 ? ref $v->{valid} eq 'CODE'
		 ? $v->{valid} : sub { $_[0] eq $v->{valid} }
		 : undef
	);
}

=head2 method_list

Returns the coderef for the method that should be applied to the requesting class.

=cut

sub method_list {
	my ($self, %opt) = @_;
	my $k = delete $opt{k};
	if($opt{pre} || $opt{post}) {
		return sub {
			my $self = shift;
			if($opt{pre}) {
				$opt{pre}->($self, @_)
				 or return;
			}
			if(@_) {
				die $_[0] . ' is invalid' if $opt{validate} && !$opt{validate}->($_[0]);
				my $v = $_[0];
				# Readonly values can be problematic, make a copy if we can - but don't trash refs.
				$v = "$v" if Scalar::Util::readonly($v) && !ref $v;
				$self->{$k} = $v;
			}
			$opt{post}->($self, @_) if $opt{post};
			return $self if @_;
			$self->{$k};
		};
	} else {
		return sub {
			return $_[0]->{$k} unless @_ > 1;
			die $_[1] . ' is invalid' if $opt{validate} && !$opt{validate}->(@_);
			my $v = $_[1];
			# Readonly values can be problematic, make a copy if we can - but don't trash refs.
			$v = "$v" if Scalar::Util::readonly($v) && !ref $v;
			$_[0]->{$k} = $v;
			return $_[0];
		};
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2014. Licensed under the same terms as Perl itself.
