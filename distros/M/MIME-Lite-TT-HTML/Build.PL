use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'MIME::Lite::TT::HTML',
      license         => 'perl',
      requires        => {
          Encode        => 0,
          Template      => 0,
          'MIME::Lite'  => 0,
          'MIME::Words' => 0,
          Carp          => 0,
          perl          => '5.6.0',
          'DateTime::Format::Mail' => 0,
          'HTML::FormatText::WithLinks' => 0,
      },
    )->create_build_script;
