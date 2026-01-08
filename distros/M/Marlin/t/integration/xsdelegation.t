use Test2::V0;
use Data::Dumper;

{
	package Local::Joiner;
	use Marlin 'str!';
	no warnings 'once';
	*join = sub {
		my $self = shift;
		return join $self->str, @_;
	};
}

{
	package Local::Joiners;
	use Marlin
		comma => {
			is      => 'lazy',
			isa     => 'Object',
			builder => sub { Local::Joiner->new( str => ',' ) },
			handles => { join_comma => 'join' },
		},
		nl => {
			is      => 'lazy',
			isa     => 'Object',
			builder => sub { Local::Joiner->new( str => "\n" ) },
			handles => { join_nl => 'join' },
		};
}

sub is_xs {
	my $sub = $_[0];
	if ( Scalar::Util::blessed($sub) and $sub->isa( "Class::MOP::Method" ) ) {
		$sub = $sub->body;
	}
	elsif ( not ref $sub ) {
		no strict "refs";
		if ( not exists &{$sub} ) {
			my ( $pkg, $method ) = ( $sub =~ /\A(.+)::([^:]+)\z/ );
			if ( my $found = $pkg->can($method) ) {
				return lc(is_xs($found));
			}
			return "--";
		}
		$sub = \&{$sub};
	}
	require B;
	B::svref_2object( $sub )->XSUB ? 'XS' : 'PP';
}

is is_xs("Local::Joiners::join_comma"), 'XS';
is is_xs("Local::Joiners::join_nl"), 'XS';

my $J = Local::Joiners->new;
ok !!$J;

is( $J->nl->join(qw/foo bar/), "foo\nbar" );
is( $J->join_nl(qw/foo bar/), "foo\nbar" );
is( $J->join_comma(qw/foo bar/), "foo,bar" );

done_testing;
