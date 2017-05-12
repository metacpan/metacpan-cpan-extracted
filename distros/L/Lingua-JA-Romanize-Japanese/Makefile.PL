use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                    =>  'Lingua::JA::Romanize::Japanese',
    VERSION_FROM            =>  'lib/Lingua/JA/Romanize/Japanese.pm',
    PREREQ_PM               =>  {
        'Test::More'        =>  '0',
        'DB_File'           =>  '0',
        'LWP::UserAgent'    =>  '0',
    },
};

my $PERL581 = 1 if ( $] >= 5.008001 );
$opt->{PREREQ_PM}->{Jcode} = '0' unless $PERL581;

WriteMakefile( %$opt );

sub MY::post_initialize {
    my $self = shift;
    $self->{clean}->{FILES} .= "lib/Lingua/JA/Romanize/Japanese.bdb";
    $self->{PM}->{"lib/Lingua/JA/Romanize/Japanese.bdb"} = "blib/lib/Lingua/JA/Romanize/Japanese.bdb";
    my $str  = "";
    $str;
}

sub MY::postamble {
    my $self = shift;
    my $str  = "";
    $str .= "lib/Lingua/JA/Romanize/Japanese.bdb :\n";
    $str .= "\t\$(PERL) -Ilib -MLingua::JA::Romanize::DictJA -e 'Lingua::JA::Romanize::DictJA->update();'\n\n";
    $str;
}
