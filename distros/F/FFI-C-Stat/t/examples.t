use Test2::V0 -no_srand => 1;
use Test::Script 1.09;
use File::chdir;
use File::Spec;
use Path::Tiny qw( path );

@INC = map { File::Spec->rel2abs($_) } @INC;

{
  local $CWD = 'examples';

  path(".")->visit(sub {
    my($path) = @_;

    return if $path->is_dir;
    return unless $path->basename =~ /\.pl$/;

    script_compiles("$path");
    my $stdout = '';
    my $stderr = '';
    script_runs("$path", { stdout => \$stdout, stderr => \$stderr } );
    note "[out]\n$stdout" if $stdout ne '';
    note "[err]\n$stderr" if $stderr ne '';

  }, { recurse => 1});
}

unlink 'examples/archive/foo.txt';
unlink 'examples/archive/bar.txt';
rmdir 'examples/archive';
unlink 'examples/outarchive.tar';
unlink 'examples/hello.txt';

done_testing;
