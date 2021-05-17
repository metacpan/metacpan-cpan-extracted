use lib 't/lib';
use Test2::Require::Module 'Test2::Tools::Process';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxOS 'linux';
use Test2::Tools::NoteStderr qw( note_stderr );
use Test2::Tools::Process;
use FFI::CheckLib;

@$FFI::CheckLib::system_path = (
  'corpus/unix/usr/lib',
  'corpus/unix/lib',
);

subtest 'check_lib_or_exit' => sub {

  subtest 'found' => sub {
    process { check_lib_or_exit( lib => 'foo' ) } [];
  };

  subtest 'not found' => sub {
    process { note_stderr { check_lib_or_exit( lib => 'foobar') } } [
      proc_event( exit => 0 ),
    ];
  };

};

subtest 'find_lib_or_exit' => sub {

  subtest 'found' => sub {
    process { my $path = find_lib_or_exit( lib => 'foo' ) } [];
  };

  subtest 'not found' => sub {
    process { note_stderr { my $path = find_lib_or_exit( lib => 'foobar') } } [
      proc_event( exit => 0 ),
    ];
  };

};

done_testing;
