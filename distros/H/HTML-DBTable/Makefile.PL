use ExtUtils::MakeMaker;

my @dbInfo      = &_prompt_db_info;
if (@dbInfo) {	
	my @fld         = qw/dbconfigure driver host port db user pw/;

	open(F,">t/dbInfo.pl") or die "Unable to open t/dbInfo.pl";
	for (my $i=0;$i<scalar(@fld);$i++) {
   	     print F qq/sub $fld[$i] { return '$dbInfo[$i]' }\n/;
	}
	print F "\n\n#return true value\n1;";
	close(F);
}
    
sub _prompt_db_info {
        my @ret;
        my $questions=<<EOF;
Do you wish to skip database testing? [N]
Enter the DBD driver name [mysql]
Enter the database hostname [localhost]
Enter database port number [3128]
Enter database name [test]
Enter an userid which can manage tables [root]
Enter password
EOF
        my @q           = split(/\n/,$questions);
        foreach (@q) {
                my $hidden      = 1 if (/password/i);
                my $default = '';
                if (/.+\[(.+?)\]$/) { $default = $1 }
                push @ret,&_ask_for_prompt($_,$default,$hidden);
				return if ($ret[0]=~/^[YySs]/);
        }
        return @ret;
}


sub _ask_for_prompt {
        my ($question,$default)         = (shift,shift);
        my $hidden                                      = shift || 0;
        print $question . ': ';
        system "stty -echo" if ($hidden);
        chomp(my $word = <STDIN>);
        if ($hidden) {print "\n"; system "stty echo";}
        return $word || $default;
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'HTML::DBTable',
    'VERSION_FROM'  => 'DBTable.pm', # finds $VERSION
    'PREREQ_PM'     => {
                        DBI => 0.0,
                        DBIx::DBSchema=> 0.0,
                        HTML::Template => 0.0,
						Params::Validate => 0.0
                        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DBTable.pod', # retrieve abstract from module
       AUTHOR     => 'Emiliano Bruni <info@ebruni.it>') : ()),
);



