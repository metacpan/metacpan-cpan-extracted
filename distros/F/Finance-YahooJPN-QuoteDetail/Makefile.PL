use 5.008003;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Finance::YahooJPN::QuoteDetail',
    VERSION_FROM      => 'lib/Finance/YahooJPN/QuoteDetail.pm', 
    PREREQ_PM         => {
                'HTML::TableExtract' => '1.08',
		'LWP::UserAgent' => '2.024',
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/YahooJPN/QuoteDetail.pm', 
       AUTHOR         => 'Takashi Saeki <tsaeki@yf7.so-net.ne.jp>') : ()),
);
