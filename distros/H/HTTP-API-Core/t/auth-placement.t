use strict;
use warnings;
use Test::More;
use HTTP::API::Core::Auth qw(api_key_auth);

{
    package Local::PlacementAsQuery;
    our $COERCIONS = 0;
    use overload '""' => sub { $COERCIONS++; return 'query' }, fallback => 1;
}

{
    package Local::PlacementAsHeader;
    our $COERCIONS = 0;
    use overload '""' => sub { $COERCIONS++; return 'header' }, fallback => 1;
}

{
    package Local::PlacementExplodes;
    use overload '""' => sub { die "stringification must not run\n" }, fallback => 1;
}

sub rejected_placement {
    my ($value, $description) = @_;
    my $error;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval {
            api_key_auth(in => $value, name => 'X-API-Key', value => 'abc');
            1;
        } or $error = $@;
    }
    like $error, qr/api_key in must be header or query/,
        "$description is rejected with the stable diagnostic";
    is_deeply \@warnings, [], "$description produces no warnings";
}

rejected_placement([], 'array-reference placement');
rejected_placement({}, 'hash-reference placement');
rejected_placement(bless({}, '0'), 'false-valued blessed placement');
rejected_placement(bless({}, 'Local::PlacementAsQuery'), 'object stringifying to query');
rejected_placement(bless({}, 'Local::PlacementAsHeader'), 'object stringifying to header');
rejected_placement(bless({}, 'Local::PlacementExplodes'), 'object whose stringification dies');

is $Local::PlacementAsQuery::COERCIONS, 0,
    'query-like object is rejected without stringification';
is $Local::PlacementAsHeader::COERCIONS, 0,
    'header-like object is rejected without stringification';

sub context_for {
    my ($hook) = @_;
    my $ctx = {
        headers => {},
        url => 'https://api.example.test/items',
    };
    $hook->($ctx);
    return $ctx;
}

my $default = context_for(api_key_auth(
    in => undef, name => 'X-API-Key', value => 'abc',
));
is $default->{headers}{'X-API-Key'}, 'abc', 'undefined placement defaults to header';
is $default->{url}, 'https://api.example.test/items', 'header default leaves URL unchanged';

my $header = context_for(api_key_auth(
    in => 'header', name => 'X-API-Key', value => 'abc',
));
is $header->{headers}{'X-API-Key'}, 'abc', 'explicit header placement still works';

my $query = context_for(api_key_auth(
    in => 'query', name => 'token', value => 'abc',
));
is $query->{url}, 'https://api.example.test/items?token=abc',
    'explicit query placement still works';
is_deeply $query->{headers}, {}, 'query placement does not add headers';

done_testing;
