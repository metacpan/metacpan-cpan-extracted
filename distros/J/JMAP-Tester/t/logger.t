use strict;
use warnings;

use File::Temp ();
use JMAP::Tester::LogWriter;

use Test::Deep ':v1';
use Test::More;
use Test::Abortable 'subtest';

subtest "log writers" => sub {
  {
    my @written;
    my $writer = JMAP::Tester::LogWriter::Code->new({
      code => sub { push @written, $_[0] },
    });

    $writer->write("hello");
    $writer->write("world");
    cmp_deeply(\@written, [ "hello", "world" ], "Code writer");
  }

  {
    my $output = '';
    open my $fh, '>', \$output or die "can't open string fh: $!";
    my $writer = JMAP::Tester::LogWriter::Handle->new({ handle => $fh });

    $writer->write("line one\n");
    $writer->write("line two\n");
    is($output, "line one\nline two\n", "Handle writer");
  }

  {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $template = "$dir/test-{PID}.log";
    my $writer = JMAP::Tester::LogWriter::Filename->new({
      filename_template => $template,
    });

    $writer->write("logged line\n");

    my $fn = "$dir/test-$$.log";
    ok(-f $fn, "Filename writer created file");
    open my $fh, '<', $fn or die "can't read $fn: $!";
    my $content = do { local $/; <$fh> };
    is($content, "logged line\n", "Filename writer content");
  }
};

subtest "logger writer coercion" => sub {
  require JMAP::Tester::Logger::HTTP;

  {
    my @lines;
    my $logger = JMAP::Tester::Logger::HTTP->new({
      writer => sub { push @lines, $_[0] },
    });

    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Code');
    $logger->write("test");
    cmp_deeply(\@lines, ["test"], "coderef coercion");
  }

  {
    my $output = '';
    open my $fh, '>', \$output or die $!;
    my $logger = JMAP::Tester::Logger::HTTP->new({ writer => $fh });

    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Handle');
    $logger->write("test");
    is($output, "test", "handle coercion");
  }

  {
    my $logger = JMAP::Tester::Logger::HTTP->new({ writer => \undef });
    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Code');
    $logger->write("goes nowhere");
    pass("undef scalar ref becomes no-op Code writer");
  }

  {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $logger = JMAP::Tester::Logger::HTTP->new({
      writer => "$dir/logger-{PID}.log",
    });
    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Filename');
  }
};

subtest "Logger::Null" => sub {
  require JMAP::Tester::Logger::Null;
  my $null = JMAP::Tester::Logger::Null->new({ writer => sub {} });

  for my $method (qw(
    log_jmap_request     log_jmap_response
    log_misc_request     log_misc_response
    log_upload_request   log_upload_response
    log_download_request log_download_response
  )) {
    my $ok = eval { $null->$method(); 1 };
    ok($ok, "$method doesn't die");
  }
};

done_testing;
