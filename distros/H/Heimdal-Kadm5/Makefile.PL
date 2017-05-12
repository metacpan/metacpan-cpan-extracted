use ExtUtils::MakeMaker;
# $Id$

my $find_krb5_config;

my $lflags= '-L/pkg/heimdal/default/lib -lkrb5 -lroken -lasn1 -ldes -lkadm5clnt';
my $cflags= '-I/usr/heimdal/default/include' ;

my @args = ("krb5-config", "--version");
$find_krb5_config = system(@args);

if ($find_krb5_config eq 0) {
    $lflags = `krb5-config --libs kadm-client`;
    $cflags = `krb5-config --cflags kadm-client`;
    chomp $lflags;
    chomp $cflags;
}

printf "cflags: $cflags\n";
printf "lflags: $lflags\n";

WriteMakefile(
    'NAME'		=> 'Heimdal::Kadm5',
    'VERSION_FROM'	=> 'Kadm5.pm',
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Kadm5.pm',
       AUTHOR     => 'Leif Johansson <leifj@it.su.se>') : ()),
    'LIBS'      => [ $lflags ],
    'INC'       => $cflags ,
    'DEFINE'		=> '',
);
