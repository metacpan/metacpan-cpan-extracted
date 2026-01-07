use v5.40;
use Test2::V1 -ipP;
use Gears::Template;

use autodie;

################################################################################
# This tests whether the basic template engine works
################################################################################

package Gears::Test::Template {
	use Mooish::Base -standard;

	extends 'Gears::Template';

	sub _render_template ($self, $template_content, $vars)
	{
		# Simple variable substitution for testing
		foreach my $key (keys %$vars) {
			$template_content =~ s/\Q{{$key}}\E/$vars->{$key}/g;
		}

		return $template_content;
	}
}

subtest 'should process scalar reference template' => sub {
	my $template = Gears::Test::Template->new;
	my $content = \'Hello, {{name}}!';

	my $result = $template->process($content, {name => 'World'});
	is $result, 'Hello, World!', 'scalar ref template processed';
};

subtest 'should process file template' => sub {
	my $template = Gears::Test::Template->new(
		paths => ['t/template']
	);

	my $result = $template->process('test.tmpl', {title => 'Test', content => 'Content'});
	like $result, qr/Test/, 'file template processed';
	like $result, qr/Content/, 'variables substituted';

	isa_ok dies { $template->process('nonexistent.tmpl') }, 'Gears::X::Template';
};

subtest 'should process glob reference template' => sub {
	my $template = Gears::Test::Template->new;

	open my $fh, '<', 't/template/test.tmpl';
	my $result = $template->process($fh, {title => 'Glob', content => 'Test'});
	close $fh;

	like $result, qr/Glob/, 'glob ref template processed';
};

subtest 'should use custom encoding' => sub {
	my $template = Gears::Test::Template->new(
		encoding => 'latin1',
		paths => ['t/template']
	);

	my $result = $template->process('latin1.tmpl', {name => 'José'});
	like $result, qr/\Q¿Cómo estás? ¡Qué día más hermoso!\E/, 'latin1 from template ok';
	like $result, qr/\QHola, José\E/, 'UTF8 from placeholder merged with latin1 ok';
};

subtest 'should rewind file handle after reading' => sub {
	my $template = Gears::Test::Template->new;

	# Create a test with __DATA__ section
	my $data = do {
		local $/ = undef;
		\<DATA>;
	};

	# Process the same handle multiple times
	my $result1 = $template->process($data, {value => 'First'});
	like $result1, qr/First/, 'first read ok';

	my $result2 = $template->process($data, {value => 'Second'});
	like $result2, qr/Second/, 'second read ok (handle rewound)';
	unlike $result2, qr/done_testing/, 'no perl source in the result';

	my $result3 = $template->process($data, {value => 'Third'});
	like $result3, qr/Third/, 'third read ok (handle rewound again)';
	unlike $result3, qr/done_testing/, 'no perl source in the result';
};

done_testing;

__DATA__
Template content: {{value}}

