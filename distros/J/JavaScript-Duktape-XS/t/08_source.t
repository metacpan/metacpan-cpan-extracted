use strict;
use warnings;

use Data::Dumper;
use Path::Tiny;
use Test::More;
use Ref::Util qw/ is_arrayref /;
use JavaScript::Duktape::XS;

sub load_js_file {
    my ($file) = @_;

    my $path = Path::Tiny::path($file);
    my $code = $path->slurp_utf8();
}

sub save_tmp_file {
    my ($contents) = @_;

    my $path = Path::Tiny->tempfile();
    $path->spew_utf8($contents);
    return $path;
}

sub test_line_numbers {
    my $js_code = <<EOS;
var fail = true;

function d()
{
    if (fail) {
        throw new Error("failed");
    }
}

function c()
{
    if (fail) {
        return gonzo.length;
    }
}

function b()
{
    c();
}

function a() {
    b();
    return "ok";
}
EOS

    my $duk = JavaScript::Duktape::XS->new({save_messages => 1});
    ok($duk, "created JavaScript::Duktape::XS object that saves messages");

    my @js_files;
    my $js_file = save_tmp_file($js_code);
    push @js_files, $js_file;
    ok(1, "saved tp tmp file '$js_file'");

    foreach my $js_file (@js_files) {
        my $code = load_js_file($js_file);
        $duk->eval($code, $js_file);
        ok(1, "loaded file '$js_file'");
    }

    my $call = 'a';
    my %types = (
        normal     => {
            method => 'eval',
            args   => [ "$call()" ],
        },
        event_loop => {
            method => 'dispatch_function_in_event_loop',
            args   => [ $call ],
        },
    );
    foreach my $type (sort keys %types) {
        my $code = $types{$type};
        my $method = $code->{method};
        next unless $method;

        $duk->reset_msgs();
        $duk->$method(@{ $code->{args} });
        my $msgs = $duk->get_msgs();
        # print STDERR Dumper($msgs);

        ok($msgs, "got messages from JS for $type execution");
        next unless $msgs;

        ok($msgs->{stderr}, "got error messages from JS");
        next unless $msgs->{stderr};

        my $contexts = $duk->parse_js_stacktrace($msgs->{stderr}, 2);
        ok($contexts, "got parsed stacktrace");
        next unless $contexts;

        my $context_no = 0;
        foreach my $context (@$contexts) {
            ++$context_no;
            like($context->{message}, qr/identifier '.*' undefined/,
                 "context $context_no contains error message");
            is(scalar @{ $context->{frames} }, 2,
               "context $context_no contains correct number of frames");
            my $frame_no = 0;
            foreach my $frame (@{ $context->{frames} }) {
                ++$frame_no;
                ok(exists $frame->{file}, "frame $context_no.$frame_no has member file");
                ok(exists $frame->{line}, "frame $context_no.$frame_no has member line");
                ok(exists $frame->{line_offset}, "frame $context_no.$frame_no has member line_offset");
                ok(is_arrayref($frame->{lines}), "frame $context_no.$frame_no has member lines as arrayref");
            }
        }

        # print STDERR Dumper($contexts);
    }
}

sub main {
    test_line_numbers();
    done_testing;
    return 0;
}

exit main();
