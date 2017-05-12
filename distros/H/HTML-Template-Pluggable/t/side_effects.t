use Test::More;
use Test::MockObject;

use strict;

plan tests => 3						# use_ok
			+ 12					# hash keys, dying methods
	;

use_ok 'HTML::Template::Pluggable';
use_ok 'HTML::Template::Plugin::Dot';
use_ok 'Test::MockObject';

my $mock = Test::MockObject->new();
$mock->mock( 'method_that_dies' => sub { die "horribly..." } );
$mock->mock( 'nested'           => sub { $_[0] } );

# methods that die
{
    my $ex = get_output(
            '<tmpl_var name="object.method_that_dies">',
            $mock,
            { die_on_bad_params => 1 },
        );
    like $@, qr/horribly... at /, "method calls die loudly with die_on_bad_params off";
    unlike $ex, qr/0x/, "exception doesn't leave a stringified object behind";
}

{
    my $ex = get_output(
            '<tmpl_var name="object.nested.method_that_dies">',
            $mock,
            { die_on_bad_params => 1 },
        );
    like $@, qr/horribly... at /, "nested method calls die loudly with die_on_bad_params off";
    unlike $ex, qr/0x/, "exception doesn't leave a stringified object behind";
}

{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift; };

    my $ex = get_output(
            '<tmpl_var name="object.method_that_dies">',
            $mock,
            { die_on_bad_params => 0 },
        );
    is $@,  '', "method calls fail silently with die_on_bad_params off";
    is $ex, '', "exception doesn't leave a stringified object behind";
    like $warning, qr/horribly/, 'but emits a warning';

    $ex = get_output(
            '<tmpl_var name="object.nested.method_that_dies">',
            $mock,
            { die_on_bad_params => 0 },
        );
    is $@,  '', "nested method calls fail silently with die_on_bad_params off";
    is $ex, '', "exception doesn't leave a stringified object behind";
    like $warning, qr/horribly/, 'but emits a warning';
}

# accessing non-existent hash keys
	my %in = ( a => 1, b => 2 );
	get_output(
		'<tmpl_var object.a><tmpl_var name="object.c.e">',
		\%in,
	);
is_deeply(\%in, { a=>1, b=>2 }, 'No side effects on hashes');

# accessing non-existent object properties
	$mock->{old_key} = 'old value';
	get_output(
		'<tmpl_var object.old_key><tmpl_var name="object.new_key">',
		$mock,
	);
ok(!exists($mock->{new_key}), 'No side effects on object properties');


sub get_output {
	my ($tag, $data, $params) = @_;
	my $output = '';
	my $t = HTML::Template::Pluggable->new(
			scalarref => \$tag,
			debug => 0,
            %$params,
		);
	eval {
		$t->param( object => $data );
		$output = $t->output;
	};

	# diag("template tag is $tag");
	# diag("output is $output");
	# diag("exception is $@") if $@;
	return $output;
}

# vi: filetype=perl

__END__
