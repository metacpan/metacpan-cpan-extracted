use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Metadata::DB::WUI',
   VERSION_FROM => 'lib/Metadata/DB/WUI.pm',

   EXE_FILES=> [qw(bin/mdri bin/mdfi bin/mdse)],

   # gen /usr/bin/pmused by Wed Feb 13 17:43:58 EST 2008
   PREREQ_PM => {
      'Test::Simple' => '0',
      'CGI::Application::Plugin::AutoRunmode' => '0.15',

      'File::MimeInfo' =>'0.15' ,
      'DBD::mysql' => 3,
      'LEOCHARRE::Class::Accessors' => '1.12',
      'CGI::Application' => '4.0',
      'LEOCHARRE::Database' => '0',
      'CGI::Application::Plugin::Session' => '1.02',
      'LEOCHARRE::CLI' => '1.09',
      'CGI::Application::Plugin::TmplInnerOuter' => '1.10',
      'CGI::Application::Plugin::Forward' => '1',
      'CGI::Application::Plugin::Feedback' => '1.05',
      'Metadata::DB' => '1.09',
      'Cwd' => '3',

   },


   
);
