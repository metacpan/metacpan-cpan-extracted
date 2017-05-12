use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => ['Casey West <casey@geeknest.com>', 'Ian Stuart <Ian.Stuart@ed.ac.uk>'],
               ABSTRACT      => "Retrieve GET/POST Parameters from HTTP Requests",
               NAME          => 'HTTP::Request::Params',
               PREREQ_PM     => {
                                 'CGI' => '3.00',
                                 'Class::Accessor::Fast' => '0.19',
                                 'Email::MIME::ContentType' => '1.0',
                                 'Email::MIME' => '1.42',
                                 'HTTP::Request' => '1.40',
                                 'HTTP::Request::Common' => '1.26',
                                },
               VERSION_FROM  => 'lib/HTTP/Request/Params.pm',
              );
