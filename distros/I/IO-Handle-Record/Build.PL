use 5.008008;
use strict;
use warnings;
use Module::Build;

# Which .pm contains the module version?
# This is also the file where the 'module_name' comes from. It's the string
# following the first 'package' keyword in the file up to the semicolon.
my $pm='lib/IO/Handle/Record.pm';

# What is used to create the README
my $pod=$pm;

# requirements: they appear in the README in the given order.
my @requires=(
	      'Class::Member' => '1.3',
	      'Storable' => '2.05',
	      'Test::Deep' => 0
	     );

my $code=<<"EOF";
\$ENV{GZIP}='-9f';
sub ACTION_distdir {
  my \$I = shift;

  \$I->log_info("Creating README.pod\n");
  open my \$out, '>', 'README.pod' or die "ERROR: Cannot open README.pod: \$!\\n";
  open my \$in,  '<', '$pod' or die "ERROR: Cannot open $pod: \$!\\n";
  my \$pr=0;
  local \$_;
  while( defined( \$_=<\$in> ) ) {
    if( \$pr ) {
      /^=cut\$/ and \$pr=0;
    } else {
      /^=/ and \$pr=1;
    }
    next unless \$pr;
    /=head1 DESCRIPTION/ and print \$out <<'XXX';
=head1 INSTALLATION

 perl Makefile.PL
 make test
 make install

or

 perl Build.PL
 ./Build test
 ./Build install

=head1 DEPENDENCIES

=over 4
${\do{my @l=@requires; my $out=''; while(my($m, $v)=splice @l, 0, 2) {$out.="\n=item B<*> $m".($v?" $v":"")."\n"} $out}}
=back

XXX
    print \$out \$_;
  }
  close \$out;

  if ( eval {require Pod::Readme; 1} ) {
    \$I->log_info("Creating README using Pod::Readme\n");

    my \$parser = Pod::Readme->new;
    \$parser->parse_from_file('README.pod', 'README');

  } elsif ( eval {require Pod::Text; 1} ) {
    \$I->log_info("Creating README using Pod::Text\n");

    Pod::Text->new()->parse_from_file( 'README.pod', 'README' );
  } else {
    \$I->log_warn("Can't load Pod::Readme or Pod::Text to create README\n");
    return;
  }

  \$I->_add_to_manifest('MANIFEST', 'README');

  return \$I->SUPER::ACTION_distdir(\@_);
}

sub ACTION_rpm {
  my \$version=\$_[0]->dist_version;
  open my \$out, '>', 'perl-IO-Handle-Record.spec.tmp' or die "ERROR: Cannot open perl-IO-Handle-Record.spec.tmp: \$!\\n";
  open my \$in,  '<', 'perl-IO-Handle-Record.spec' or die "ERROR: Cannot open perl-IO-Handle-Record.spec: \$!\\n";
  local \$_;
  while( defined( \$_=<\$in> ) ) {
    s/^(Version:\\s*).*/\${1}\$version/i;
    print \$out \$_;
  }
  rename 'perl-IO-Handle-Record.spec.tmp', 'perl-IO-Handle-Record.spec';
  system 'rpmbuild -ba perl-IO-Handle-Record.spec';
}
EOF

my $builder = Module::Build->subclass
  (
   code                => $code,
  )->new
  (
   module_name         => (sub {local @ARGV=($pm); while(<>){/package\s*(.*?)\s*;/ and return $1}})->(),
   license             => 'perl',
   dist_author         => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
   dist_version_from   => $pm,
   xs_files            => {'Record.xs'=>'lib/IO/Handle/Record.xs'},
   requires            => {@requires},
  );

$builder->create_build_script;
