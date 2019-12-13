use 5.006;
use strict;
use warnings;
use Module::Build;

my $sub = <<'END_SUBS';
use Carp;

sub ACTION_steps {
    print <<"END_TS";
perl build.pl
build test
build distcheck
build dist
build git
or build all
END_TS

}

sub ACTION_all {
	print `perl build.pl`;
# SET RELEASE_TESTING=1 & build test
	print map {`build $_`} qw(test distcheck dist git cpan);
  print 'git push (using GitGui)';
}

sub ACTION_cpan {
  my $mod = 'Excel::Template::XLSX';
  (my $path = $mod) =~ s|::|/|g;
  my $ver = eval qq{use $mod; \$${mod}::VERSION};
  (my $tgz = $mod) =~ s|::|\-|g;
  $tgz = "${tgz}-${ver}.tar.gz";
  print STDOUT `cpan-upload $tgz`; # add --dry-run option if needed
  # `mojo cpanify -u sri -p secr3t $tgz`;
}

sub ACTION_git {
	my $result;
	$result = `git add lib\*.pm lib\*\*.pm lib\*\*\*.pm lib\*\*\*\*.pm `;
	$result .= `git add Changes build.pl MANIFEST MANIFEST.SKIP`;
	$result .= `git add build.pl `;
	$result .= `git status -s`;
	print $result;
}

END_SUBS

my $class = Module::Build->subclass( class => 'Build_with_Zip', code => $sub );

my $builder = $class->new(
   module_name       => 'Excel::Template::XLSX',
   license           => 'perl',
   dist_author       => q{Dave Clarke <dclarke@cpan.org>},
   dist_version_from => 'lib/Excel/Template/XLSX.pm',
   dist_abstract     => q[
Re-creates Excel (.xlsx) files from a template.  Excel
content can be appended using Excel::Writer::XLSX. ],

   build_requires => {
      'Test::More'          => 0,
      'Test::Differences'   => 0,
      'Test::CheckManifest' => 1.29,
      'Template::Tiny'      => 0,
   },

   configure_requires => { 
    'Module::Build'  => 0.4,
    'CPAN::Uploader' => 0.1,
},

   requires => {
      'perl'                 => '5.12.0',
      'Excel::Writer::XLSX'  =>     1.01,
      'Archive::Zip'         =>        0,
      'Graphics::ColorUtils' =>        0,
      'Scalar::Util'         =>        0,
      'XML::Twig'            =>        0,
   },   
   add_to_cleanup => [qw(Excel-Template-XLSX-* *.zip *.pui *.prj make.bat)],
   create_makefile_pl => 'traditional',

);

$builder->create_build_script();
