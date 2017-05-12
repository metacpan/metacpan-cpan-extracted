use Test::More;
use Test::Deep;
use HTTP::Body;
use HTTP::Body::MultiPart::Extend;

# The test data is borrowed from HTTP::Body::MultiPart

my @data_set = (
    [
	sub {
	    my ( $self, $part ) = @_;

	    unless ( exists $part->{name} ) {

		my $disposition = $part->{headers}->{'Content-Disposition'};
		my ($name)      = $disposition =~ / name="?([^\";]+)"?/;
		my ($filename)  = $disposition =~ / filename="?([^\"]*)"?/;
		# Need to match empty filenames above, so this part is flagged as an upload type

		$part->{name} = $name;
		$part->{value} = 0;
	    }

	    $part->{value} += $part->{data} =~ s/[aA]/./g;
	    $part->{data} = '';

	    $self->param( $part->{name}, $part->{value} ) if $part->{done};
	}, {
	    select => [1, 0],
	    text1 => 7,
	    text2 => 0,
	    textarea => 25,
	    upload => [1, 1],
	    upload1 => 0,
	    upload2 => 1,
	    upload3 => 0,
	    upload4 => 0,
	}
    ], [
	sub {
	    my ( $self, $part ) = @_;

	    unless ( exists $part->{name} ) {

		my $disposition = $part->{headers}->{'Content-Disposition'};
		my ($name)      = $disposition =~ / name="?([^\";]+)"?/;
		my ($filename)  = $disposition =~ / filename="?([^\"]*)"?/;
		# Need to match empty filenames above, so this part is flagged as an upload type

		$part->{name} = $name;
		$part->{value} = 0;
	    }

	    $part->{value} += $part->{data} =~ s/[bB]/./g;
	    $part->{data} = '';

	    $self->param( $part->{name}, $part->{value} ) if $part->{done};
	}, {
	    select => [0, 1],
	    text1 => 0,
	    text2 => 0,
	    textarea => 2,
	    upload => [1, 1],
	    upload1 => 0,
	    upload2 => 1,
	    upload4 => 0,
	    upload3 => 0,
        }
    ], [
	undef, {
	    select => ['A', 'B'],
	    text1 => 'Ratione accusamus aspernatur aliquam',
	    text2 => '',
	    textarea => "Voluptatem cumque voluptate sit recusandae at. Et quas facere rerum unde esse. Sit est et voluptatem. Vel temporibus velit neque odio non.\r\n\r\nMolestias rerum ut sapiente facere repellendus illo. Eum nulla quis aut. Quidem voluptas vitae ipsam officia voluptatibus eveniet. Aspernatur cupiditate ratione aliquam quidem corrupti. Eos sunt rerum non optio culpa.",
	}
    ]
);
my @test_set;

my $header = do("./t/data/headers.pml");

HTTP::Body::MultiPart::Extend::extend($data_set[0][0]);
push @test_set, [HTTP::Body::MultiPart::Extend::patch_new($data_set[1][0], @$header{qw(Content-Type Content-Length)}), $data_set[1][1], 'patch_new(1)'];
push @test_set, [HTTP::Body->new( @$header{qw(Content-Type Content-Length)} ), $data_set[0][1], 'extend(0)'];

HTTP::Body::MultiPart::Extend::extend($data_set[1][0]);
push @test_set, [HTTP::Body::MultiPart::Extend::patch_new($data_set[0][0], @$header{qw(Content-Type Content-Length)}), $data_set[0][1], 'patch_new(0)'];
push @test_set, [HTTP::Body->new( @$header{qw(Content-Type Content-Length)} ), $data_set[1][1], 'extend(1)'];

HTTP::Body::MultiPart::Extend::no_extend;
push @test_set, [HTTP::Body::MultiPart::Extend::patch_new($data_set[1][0], @$header{qw(Content-Type Content-Length)}), $data_set[1][1], 'patch_new(1)'];
push @test_set, [HTTP::Body->new( @$header{qw(Content-Type Content-Length)} ), $data_set[2][1], 'no_extend'];

$_->[0]->cleanup(1) for @test_set;

open my $content_f, "./t/data/content.dat";
while( read $content_f, my $content, 20 ) {
    $_->[0]->add($content) for @test_set;
}
close $content_f;

for( @test_set ) {
    cmp_deeply($_->[0]->param, $_->[1], $_->[2]);
}

is(0, 0, '');

done_testing;
