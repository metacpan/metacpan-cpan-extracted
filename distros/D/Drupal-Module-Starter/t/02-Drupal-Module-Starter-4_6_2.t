BEGIN {
	use strict;
	use Test::More qw 'no_plan';
	use_ok('Drupal::Module::Starter::4_6_2');
	use_ok('Drupal::Module::Starter');
}

ok(my $ms = Drupal::Module::Starter->new('t/config.yaml'));
#isa_ok($ms->{stubs},'Drupal::Module::Starter::4_6_2');

is($ms->{cfg}->{author},'Author not set');


ok(my $php = $ms->generate_php);
is($ms->{cfg}->{module},'FLEEBNATER');

ok($ms->generate_readme);
ok($ms->generate_license);
ok($ms->generate_install);
ok($ms->generate);

# verify that the generated code passes php's syntax check
my $diag = `/usr/bin/php -l $ms->{cfg}->{dir}/$ms->{cfg}->{module}/$ms->{cfg}->{module}.module`;
like($diag, '/No syntax errors detected/','Php syntax check');






# cleanup
END {

	for(qw(
	./t/output/FLEEBNATER/FLEEBNATER.module 
	./t/output/FLEEBNATER/README.txt 
	./t/output/FLEEBNATER/LICENSE.txt 
	./t/output/FLEEBNATER/INSTALL.txt)) {
		
		unlink $_;
	}

}


