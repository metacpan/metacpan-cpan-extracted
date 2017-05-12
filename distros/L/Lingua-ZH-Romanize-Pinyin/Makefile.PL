use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                    =>  'Lingua::ZH::Romanize::Pinyin',
    VERSION_FROM            =>  'lib/Lingua/ZH/Romanize/Pinyin.pm',
    PREREQ_PM               =>  {
        'Test::More'        =>  '0',
        'Storable'          =>  '0',
    },
};

my $PERL581 = 1 if ( $] >= 5.008001 );
$opt->{PREREQ_PM}->{'Unicode::Map'} = '0' unless $PERL581;
$opt->{PREREQ_PM}->{'Unicode::String'} = '0' unless $PERL581;

WriteMakefile( %$opt );

sub MY::post_initialize {
    my $self = shift;
    $self->{clean}->{FILES} .= "lib/Lingua/ZH/Romanize/Pinyin.store lib/Lingua/ZH/Romanize/Cantonese.store";
    $self->{PM}->{"lib/Lingua/ZH/Romanize/Pinyin.store"} = "blib/lib/Lingua/ZH/Romanize/Pinyin.store";
    $self->{PM}->{"lib/Lingua/ZH/Romanize/Cantonese.store"} = "blib/lib/Lingua/ZH/Romanize/Cantonese.store";
    my $str  = "";
    $str;
}

sub MY::postamble {
    my $self = shift;
    my $str  = "";
    $str .= "lib/Lingua/ZH/Romanize/Pinyin.store :\n";
    $str .= "\t\$(PERL) -Ilib -MLingua::ZH::Romanize::DictZH -e 'Lingua::ZH::Romanize::DictZH::Pinyin->update();'\n\n";
    $str .= "lib/Lingua/ZH/Romanize/Cantonese.store :\n";
    $str .= "\t\$(PERL) -Ilib -MLingua::ZH::Romanize::DictZH -e 'Lingua::ZH::Romanize::DictZH::Cantonese->update();'\n\n";
    $str;
}
