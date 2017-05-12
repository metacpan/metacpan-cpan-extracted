use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::WidgetValidator::Widget::PixivEmbedFeature',
    VERSION_FROM      => 'lib/HTML/WidgetValidator/Widget/PixivEmbedFeature.pm', # finds $VERSION
    PREREQ_PM         => {Test::More => 0, HTML::WidgetValidator::Widget => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/WidgetValidator/Widget/PixivEmbedFeature.pm', # retrieve abstract from module
       AUTHOR         => 'pmint <pmint@cpan.org>',
       LICENSE        => 'perl') : ()),
);
