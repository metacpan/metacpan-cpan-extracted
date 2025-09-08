use 5.014;
use strict;
use warnings;
use Test::More;

use Dist::PolicyFiles;

use Cwd;
use File::Basename;
use File::Spec::Functions;
use File::Temp;
use Test::File::Cmp qw(file_is);


my $Test_Data_Dir = Cwd::abs_path(catfile(dirname(__FILE__), '02-data'));


subtest 'John Doe' => sub {
  my $dobj = File::Temp->newdir();
  my $out_dir = $dobj->dirname;
  my $dp_obj = Dist::PolicyFiles->new(module    => 'My::Great::Module',
                                      login     => 'jd',
                                      email     => 'john-doe@mail.org',
                                      full_name => 'John Doe',
                                      dir       => $out_dir
                                     );

  $dp_obj->create_security_md(maintainer => 'Other Person <other@person.blah>',
                              url        => q{},
                              program    => 'Other-Program-Name');
  $dp_obj->create_contrib_md(catfile($Test_Data_Dir, 'CONTRIBUTING.md.tmpl'));
  policies_ok($out_dir, 'johndoe');
};


subtest 'Klaus Rindfrey' => sub {
  subtest 'methods' => sub {
    my $dobj = File::Temp->newdir();
    my $out_dir = $dobj->dirname;
    my $dp_obj = Dist::PolicyFiles->new(module       => 'Dist::PolicyFiles',
                                        login        => 'klaus-rindfrey',
                                        email        => 'klausrin@cpan.org',
                                        full_name    => 'Klaus Rindfrey',
                                        dir          => $out_dir,
                                        prefix       => 'perl-',
                                        uncapitalize => 1
                                       );

    $dp_obj->create_security_md(minimum_perl_version => '5.14',
                                timeframe            => '10 days');
    $dp_obj->create_contrib_md();
    policies_ok($out_dir, 'klaus-rindfrey');
  };

  subtest 'script' => sub {
    my $script =  Cwd::abs_path(catfile(dirname(__FILE__), qw(.. script dist-policyfiles)));
    local $ENV{HOME} = $Test_Data_Dir;
    ok(-f $script, "$script: exists");

    subtest 'long options' => sub {
      my $dobj = File::Temp->newdir();
      my $out_dir = $dobj->dirname;
      system($^X, $script,
             '--module'        => 'Dist::PolicyFiles',
             '--login'         => 'klaus-rindfrey',
             '--dir'           => $out_dir,
             '--prefix'        => 'perl-',
             '--uncapitalize'  => 1,
             '--sec_md_params' => 'minimum_perl_version=5.14;timeframe=10 days'
            ) == 0 or die("system() call failed: $?");
      policies_ok($out_dir, 'klaus-rindfrey');
    };

    subtest 'short options' => sub {
      my $dobj = File::Temp->newdir();
      my $out_dir = $dobj->dirname;
      system($^X, $script,
             '-m' => 'Dist::PolicyFiles',
             '-l' => 'klaus-rindfrey',
             '-d' => $out_dir,
             '-p' => 'perl-',
             '-u' => 1,
             '-s' => 'minimum_perl_version=5.14;timeframe=10 days'
            ) == 0 or die("system() call failed: $?");
      policies_ok($out_dir, 'klaus-rindfrey');
    };
  };
};



#---------------------------------------------------------------------------------------------------
sub policies_ok {
  my ($dir, $nm) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $ok = file_is(catfile($dir, 'SECURITY.md'), catfile($Test_Data_Dir, "SECURITY-$nm.md"),
                   "$nm: SECURITY.md");
  $ok &&= file_is(catfile($dir, 'CONTRIBUTING.md'), catfile($Test_Data_Dir, "CONTRIBUTING-$nm.md"),
                  "$nm: CONTRIBUTING.md");
  return $ok;
}

#==================================================================================================
done_testing();

