use strict;
use warnings;

use File::Spec;
use Test::More;
use File::Temp 'tempdir';

use Git::Hooks::RubyNoDebugger;

package MyGit;

sub new
{
    my $class = shift;
    bless {
	files  => [ @_ ],
	errors => []
    }, $class;
}

sub nocarp {}
sub filter_files_in_index { @{shift->{files}} }
sub error { push @{shift->{errors}}, pop }

package main;

sub create_file
{
    my $dir  = shift;
    my $path = File::Spec->catfile($dir, shift);

    open my $in, '>', $path or die $!;
    print $in shift;
    close $in;

    return $path;
}

my $dir  = tempdir();
my $data = do { local $/ = undef; <DATA> };
my $file = create_file($dir, 'bs.rb', $data);

my $git = MyGit->new($file);
is(Git::Hooks::RubyNoDebugger::check_commit($git), 0, 'commit failure');

my @errors = @{$git->{errors}};
is(@errors, 11, 'error count');

like($errors[0], qr/=\s+debug\s+obj/, 'debug obj');
like($errors[1], qr/=\s+debug\(obj/, 'debug(obj)');
like($errors[2], qr/\s+debugger/, 'debugger');
like($errors[3], qr/\s+debugger()/, 'debugger()');
like($errors[4], qr/\s+binding\.pry/, 'binding.pry');
like($errors[5], qr/\s+binding\.pry()/, 'binding.pry()');
like($errors[6], qr/\s+byebug/, 'byebug');
like($errors[7], qr/\s+byebug()/, 'byebug()');
like($errors[8], qr/byebug/, 'byebug');
like($errors[9], qr/raise\s+byebug/, 'raise byebug');
like($errors[10], qr/debug\s*:x/, 'debug :x => 123');

$file = create_file($dir, 'bs.txt', $data);
$git = MyGit->new($file);
is(Git::Hooks::RubyNoDebugger::check_commit($git), 1, 'commit success');

@errors = @{$git->{errors}};
is(@errors, 0, 'error count');


done_testing();

__DATA__
Blah: <%= debug obj %>
Whaa: <%= debug(obj) %>
Nah:  <%# debug obj %>

class Foo
  def bar
    puts "debugger"
    debugger
    debugger()
    # debugger()
#     debugger()
    baz.debugger
    binding.pry
    binding.pry()
    baz.binding.pry
    byebug
    byebug()
byebug
    baz.byebug

    raise byebug  # raize up
    x = "debugger iz good"
    x = "debugger"
    x = 'debugger'
    debug :x => 123
  end
end
