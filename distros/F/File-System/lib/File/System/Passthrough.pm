package File::System::Passthrough;

use strict;
use warnings;

our $VERSION = '1.02';

use Carp;
use base 'File::System::Object';

=head1 NAME

File::System::Passthrough - A file system module that delegates work to another

=head1 SYNOPSIS

  package File::System::MyModule;

  use strict;
  use base 'File::System::Passthrough';

  # You now have all methods available, just define those you must.

=head1 DESCRIPTION

This module is pretty useless on it's own. It simply delegates all the real work to an internal wrapped module. It shouldn't be used directly. However, I've found that many of the special modules written are used to wrap others and this provides the basic functionality.

=head2 SUBCLASSING

Basically, you can just declare L<File::System::Passthrough> as your base class and be done. You can define as many or few other methods as you prefer. You can refer to the wrapped class like so:

  sub my_method {
      my $self = shift;
      my $wrapped_fs = $self->{fs};

      # ...
  }

As of this writing, no other key in the C<$self> hash is used, so you can manipulate the other keys as you wish.

=head2 ADDITIONAL API

=over

=item $obj = File::System-E<gt>new('Passthrough', $wrapped_obj)

The constructor takes either a decendent of L<File::System::Object> or a reference to an array that can be used to construct such an object in C<$wrapped_obj>.

=cut

sub new {
	my $class = shift;
	my $fs    = shift;

	$fs = File::System->new(@$fs) if UNIVERSAL::isa($fs, 'ARRAY');

	UNIVERSAL::isa($fs, 'File::System::Object')
		or croak "Wrapped object must be of type File::System::Object.";

	return bless {
		fs => $fs,
	}, $class;
}

my @plain = qw/
	exists
	is_creatable
	is_valid
	basename
	dirname
	path
	is_root
	properties
	settable_properties
	get_property
	set_property
	rename
	move
	remove
	object_type
	has_content
	is_container
	is_readable
	is_seekable
	is_writable
	is_appendable
	open
	content
	has_children
	children_paths
/;

my @wrap_if_defined = qw/
	root
	lookup
	create
	parent
	copy
	child
/;

my @wrap_list = qw/
	glob
	children
/;

for my $sub (@plain) {
	eval <<EOF;
sub $sub {
	my \$self = shift;

	my \@args = map { 
		UNIVERSAL::isa(\$_, 'File::System::Passthrough') ?
			\$_->{fs} : \$_
	} \@_;

	return \$self->{fs}->$sub(\@args);
}
EOF

	die $@ if $@;
}

for my $sub (@wrap_if_defined) {
	eval <<EOF;
sub $sub {
	my \$self = shift;

	my \@args = map { 
		UNIVERSAL::isa(\$_, 'File::System::Passthrough') ?
			\$_->{fs} : \$_
	} \@_;

	my \$obj = \$self->{fs}->$sub(\@args);

	if (defined \$obj) {
		return bless {
			fs => \$obj,
		}, ref \$self;
	} else {
		return undef;
	}
}
EOF

	die $@ if $@;
}

for my $sub (@wrap_list) {
	eval <<EOF;
sub $sub {
	my \$self = shift;

	my \@args = map { 
		UNIVERSAL::isa(\$_, 'File::System::Passthrough') ?
			\$_->{fs} : \$_
	} \@_;

	return map {
		bless {
			fs => \$_,
		}, ref \$self;
	} \$self->{fs}->$sub(\@args);
}
EOF

	die $@ if $@;
}

sub find {
	my $self = shift;
	my $want = shift;

	my @args = (sub { 
		my $file = shift;
		return $want->(bless { fs => $file }, ref $self);
	});

	push @args, map { 
		UNIVERSAL::isa($_, 'File::System::Passthrough') ?
			$_->{fs} : $_
	} @_;

	return map {
		bless {
			fs => $_,
		}, ref $self;
	} $self->{fs}->find(@args);
}

=back

=head1 SEE ALSO

L<File::System>, L<File::System::Object>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

This software is distributed and licensed under the same terms as Perl itself.

=cut

1
