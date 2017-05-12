use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::Krb4',
    'VERSION_FROM' => 'Krb4.pm',
    # Remove '-lresolv' if you're not using KTH Kerberos libraries
    'LIBS'	=> ['-L/usr/local/krb4/lib -lkrb -ldes -lresolv'],
    'DEFINE'	=> '',
    'INC'	=> '-I/usr/local/krb4/include'
);
