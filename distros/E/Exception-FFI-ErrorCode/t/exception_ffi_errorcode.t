use Test2::V0 -no_srand => 1;

delete $ENV{EXCEPTION_FFI_ERROR_CODE_STACK_TRACE};

subtest 'basic' => sub {

  local *Exception::FFI::ErrorCode::Base::_carp_always = sub { 0 };

  package Ex1 {
    use Exception::FFI::ErrorCode
      codes => {
        FOO1 => [1, "human readable"],
        FOO2 => 2,
      };
  }

  is
    Ex1::FOO1(),
    1,
    'defined constant for FOO1';

  is
    Ex1::FOO2(),
    2,
    'defined constant for FOO2';

  my $ex1 = dies { Ex1->throw( code => 1 ) }; my $line = __LINE__;

  is
    $ex1,
    object {

      call [ isa => 'Exception::FFI::ErrorCode::Base' ] => T();
      call [ isa => 'Ex1' ] => T();

      call package   => 'main';
      call filename  => __FILE__;
      call line      => $line;
      call code      => 1;
      call strerror  => 'human readable';
      call as_string => "human readable at @{[ __FILE__ ]} line $line.";
      call sub { "$_[0]" } => "human readable at @{[ __FILE__ ]} line $line.\n";
      call trace     => U();

    },
    'throws code 1 ok';

  my $ex2 = dies { Ex1->throw( code => 2 ) }; $line = __LINE__;

  is
    $ex2,
    object {

      call [ isa => 'Exception::FFI::ErrorCode::Base' ] => T();
      call [ isa => 'Ex1' ] => T();

      call package   => 'main';
      call filename  => __FILE__;
      call line      => $line;
      call code      => 2;
      call strerror  => 'FOO2';
      call as_string => "FOO2 at @{[ __FILE__ ]} line $line.";

    },
    'throws code 2 ok, fallback on constant name';

  my $ex3 = dies { Ex1->throw( code => 3 ) }; $line = __LINE__;

  is
    $ex3,
    object {

      call [ isa => 'Exception::FFI::ErrorCode::Base' ] => T();
      call [ isa => 'Ex1' ] => T();

      call package   => 'main';
      call filename  => __FILE__;
      call line      => $line;
      call code      => 3;
      call strerror  => 'Ex1 error code 3';
      call as_string => "Ex1 error code 3 at @{[ __FILE__ ]} line $line.";

    },
    'throws code 3 ok, fallback on diagnostic with integer code';

  my $ex4 = dies {
    local $ENV{EXCEPTION_FFI_ERROR_CODE_STACK_TRACE} = 1;
    $line = __LINE__; Ex1->throw( code => 1 );
  };

  is
    $ex4,
    object {
      call trace => object {
        call [ isa => 'Devel::StackTrace' ] => T();
        call next_frame => object {
          call [ isa => 'Devel::StackTrace::Frame' ] => T();
          call package => 'main';
          call line => $line;
        };
      };
    },
    'stack trace on request';

};

subtest 'exceptions' => sub {

  subtest 'bad option' => sub {

    like(
      dies { Exception::FFI::ErrorCode->import('foo' => 'bar') },
      qr/^Unknown options: foo/
    );

  };

};

done_testing;
