use Kelp::Base -strict;
use Test::More;
use Kelp::Test -utf8;
use HTTP::Request::Common;
use Kelp;
use YAML::PP qw(Dump);
use Encode qw(encode);
use utf8;

my $app = Kelp->new(mode => 'test_extensions');
my $t = Kelp::Test->new(app => $app);

$app->add_route(
	'/positive' => sub {
		my $self = shift;
		ok $self->req->is_yaml, 'is_yaml ok';
		is $self->req->yaml_param('śś'), 'ąść', 'yaml_param ok';

		ok scalar(grep { $_ eq 'test' } $self->req->yaml_param), 'yaml param list item ok';
		ok scalar(grep { $_ eq 'śś' } $self->req->yaml_param), 'yaml param list item ok';

		$self->res->yaml;
		return [
			'ok',
			$self->req->yaml_content,
		];
	}
);

$app->add_route(
	'/positive_arr' => sub {
		my $self = shift;
		ok $self->req->is_yaml, 'is_yaml ok';

		my @param_list = @{$self->req->yaml_param('ARRAY')};
		ok scalar(grep { $_ eq 'one' } @param_list), 'yaml param list item ok';
		ok scalar(grep { $_ eq '1' } @param_list), 'yaml param list item ok';
		ok scalar(grep { $_ eq 'two' } @param_list), 'yaml param list item ok';
		ok scalar(grep { $_ eq '2' } @param_list), 'yaml param list item ok';

		$self->res->yaml;
		return [
			'ok',
			$self->req->yaml_content,
		];
	}
);

$app->add_route(
	'/negative' => sub {
		my $self = shift;
		ok !$self->req->is_yaml, 'is_yaml ok';
		ok !defined $self->req->yaml_param('test'), 'yaml_param ok';
		ok !scalar $self->req->yaml_param, 'yaml_param list ok';
		ok !defined $self->req->yaml_content, 'yaml content ok';

		return 'ok';
	}
);

$app->add_route(
	'/broken' => sub {
		my $self = shift;
		ok $self->req->is_yaml, 'is_yaml ok';
		ok !defined $self->req->yaml_content, 'yaml content ok';

		return 'ok';
	}
);

subtest 'should handle hashes' => sub {
	my $struct = {test => 'hello', 'śś' => 'ąść'};
	$t->request(
		POST '/positive',
		Content_Type => 'text/yaml',
		Content => encode 'UTF-8', Dump($struct)
		)
		->code_is(200)
		->yaml_cmp(
			[
				'ok',
				$struct
			]
		);
};

subtest 'should handle arrays' => sub {
	my $struct = ['one', 1, 'two', 2];
	$t->request(
		POST '/positive_arr',
		Content_Type => 'text/yaml',
		Content => encode 'UTF-8', Dump($struct)
		)
		->code_is(200)
		->yaml_cmp(
			[
				'ok',
				$struct
			]
		);
};

subtest 'should handle edge cases' => sub {
	$t->request(
		POST '/negative',
		Content_Type => 'text/plain',
		Content => 'not yaml'
		)
		->code_is(200);

	$t->request(
		POST '/broken',
		Content_Type => 'text/yaml',
		Content => '::'
		)
		->code_is(200);

	# multidocuments should fail even if valid
	my @documents = ([1, 2], [3, 4]);
	$t->request(
		POST '/broken',
		Content_Type => 'text/yaml',
		Content => encode 'UTF-8', Dump(@documents)
		)
		->code_is(200);
};

done_testing;

