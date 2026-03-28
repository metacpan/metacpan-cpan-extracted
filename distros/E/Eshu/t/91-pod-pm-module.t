use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# Typical CPAN module with POD at bottom after __END__
{
	my $input = <<'END';
package My::Module;
use strict;
use warnings;
our $VERSION = '0.01';

sub new {
my ($class, %args) = @_;
return bless \%args, $class;
}

sub process {
my ($self, $data) = @_;
return $self->{handler}->($data);
}

1;

__END__

=head1 NAME

My::Module - does something useful

=head1 SYNOPSIS

    use My::Module;

    my $obj = My::Module->new(
        handler => sub { return shift },
    );

    my $result = $obj->process($data);

=head1 METHODS

=head2 new

    my $obj = My::Module->new(%args);

Create a new instance.

=head2 process

    my $result = $obj->process($data);

Process the given data and return the result.

=head1 AUTHOR

Jane Doe

=head1 LICENSE

Same as Perl itself.

=cut
END

	my $expected = <<'END';
package My::Module;
use strict;
use warnings;
our $VERSION = '0.01';

sub new {
	my ($class, %args) = @_;
	return bless \%args, $class;
}

sub process {
	my ($self, $data) = @_;
	return $self->{handler}->($data);
}

1;

__END__

=head1 NAME

My::Module - does something useful

=head1 SYNOPSIS

	use My::Module;

	my $obj = My::Module->new(
	handler => sub { return shift },
	);

	my $result = $obj->process($data);

=head1 METHODS

=head2 new

	my $obj = My::Module->new(%args);

Create a new instance.

=head2 process

	my $result = $obj->process($data);

Process the given data and return the result.

=head1 AUTHOR

Jane Doe

=head1 LICENSE

Same as Perl itself.

=cut
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'typical CPAN module with POD after __END__');
}

# Inline method-level POD interleaved with subs
{
	my $input = <<'END';
package Foo;

=head2 alpha

    $foo->alpha;

Returns alpha value.

=cut

sub alpha {
my $self = shift;
return $self->{alpha};
}

=head2 beta

    $foo->beta($value);

Sets beta value.

=cut

sub beta {
my ($self, $val) = @_;
$self->{beta} = $val;
return $self;
}
END

	my $expected = <<'END';
package Foo;

=head2 alpha

	$foo->alpha;

Returns alpha value.

=cut

sub alpha {
	my $self = shift;
	return $self->{alpha};
}

=head2 beta

	$foo->beta($value);

Sets beta value.

=cut

sub beta {
	my ($self, $val) = @_;
	$self->{beta} = $val;
	return $self;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'inline method-level POD between subs');
}

# POD with complex code example (nested structures)
{
	my $input = <<'END';
=head1 CONFIGURATION

    my $config = {
        database => {
            host => 'localhost',
            port => 5432,
        },
        cache => {
            ttl => 3600,
        },
    };

Pass it to the constructor:

    my $app = App->new(config => $config);

=cut
END

	my $expected = <<'END';
=head1 CONFIGURATION

	my $config = {
	database => {
	host => 'localhost',
	port => 5432,
	},
	cache => {
	ttl => 3600,
	},
	};

Pass it to the constructor:

	my $app = App->new(config => $config);

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'POD with complex nested code example');
}

# Module with =for and =begin/=end blocks
{
	my $input = <<'END';
package Bar;

sub new { bless {}, shift }

=head1 NAME

Bar - a bar

=for comment
This is a comment that won't render.

=begin text

    Plain text block
    with code indentation

=end text

=cut

sub run {
my $self = shift;
return 1;
}
END

	my $expected = <<'END';
package Bar;

sub new { bless {}, shift }

=head1 NAME

Bar - a bar

=for comment
This is a comment that won't render.

=begin text

	Plain text block
	with code indentation

=end text

=cut

sub run {
	my $self = shift;
	return 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'module with =for and =begin/=end');
}

# POD with =over/=back list documenting methods
{
	my $input = <<'END';
package Registry;

sub new { bless {}, shift }
sub register { }
sub lookup { }
sub remove { }

1;

=head1 METHODS

=over 4

=item register($name, $handler)

Register a handler:

    $reg->register(foo => sub {
        return 'bar';
    });

=item lookup($name)

    my $handler = $reg->lookup('foo');

=item remove($name)

    $reg->remove('foo');

=back

=cut
END

	my $expected = <<'END';
package Registry;

sub new { bless {}, shift }
sub register { }
sub lookup { }
sub remove { }

1;

=head1 METHODS

=over 4

=item register($name, $handler)

Register a handler:

	$reg->register(foo => sub {
	return 'bar';
	});

=item lookup($name)

	my $handler = $reg->lookup('foo');

=item remove($name)

	$reg->remove('foo');

=back

=cut
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'POD =over/=back method documentation');
}
